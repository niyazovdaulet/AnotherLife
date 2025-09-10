//
//  ChallengeManager.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ChallengeManager: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var myChallenges: [Challenge] = []
    @Published var publicChallenges: [Challenge] = []
    @Published var challengeProgress: [String: ChallengeProgress] = [:] // challengeId: progress
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var challengeListeners: [ListenerRegistration] = []
    private var progressListeners: [ListenerRegistration] = []
    
    init() {
        setupRealTimeListeners()
    }
    
    deinit {
        Task { @MainActor in
            removeAllListeners()
        }
    }
    
    // MARK: - Challenge Creation
    
    func createChallenge(
        title: String,
        description: String,
        type: ChallengeType,
        privacy: ChallengePrivacy,
        targetValue: Int,
        targetUnit: String,
        duration: Int, // in days
        pointsReward: Int = 100,
        badgeReward: String? = nil,
        habitIds: [String] = []
    ) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create challenge
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? startDate
            
            let challenge = Challenge(
                title: title,
                description: description,
                type: type,
                privacy: privacy,
                createdBy: currentUserId,
                startDate: startDate,
                endDate: endDate,
                targetValue: targetValue,
                targetUnit: targetUnit,
                habitIds: habitIds,
                pointsReward: pointsReward,
                badgeReward: badgeReward
            )
            
            // Save challenge to Firestore
            try await db.collection("challenges").document(challenge.id).setData(challengeToDictionary(challenge))
            
            // Create user's progress entry
            let progress = ChallengeProgress(challengeId: challenge.id, userId: currentUserId)
            try await db.collection("challengeProgress").document(progress.id).setData(progressToDictionary(progress))
            
            // Award "Challenge Creator" badge if first challenge
            await awardBadgeIfNeeded(badgeId: "challenge_creator")
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to create challenge: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Challenge Joining
    
    func joinChallenge(_ challenge: Challenge) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return false
        }
        
        // Check if user is already in this challenge
        if challengeProgress[challenge.id] != nil {
            errorMessage = "You're already participating in this challenge"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create progress entry
            let progress = ChallengeProgress(challengeId: challenge.id, userId: currentUserId)
            try await db.collection("challengeProgress").document(progress.id).setData(progressToDictionary(progress))
            
            // Update member count
            try await db.collection("challenges").document(challenge.id).updateData([
                "memberCount": FieldValue.increment(Int64(1))
            ])
            
            // Award "Challenge Rookie" badge if first challenge
            await awardBadgeIfNeeded(badgeId: "first_challenge")
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to join challenge: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Challenge Leaving
    
    func leaveChallenge(_ challenge: Challenge) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let progress = challengeProgress[challenge.id] else {
            errorMessage = "User not in this challenge"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Remove progress entry
            try await db.collection("challengeProgress").document(progress.id).delete()
            
            // Update member count
            try await db.collection("challenges").document(challenge.id).updateData([
                "memberCount": FieldValue.increment(Int64(-1))
            ])
            
            // Remove from local cache
            challengeProgress.removeValue(forKey: challenge.id)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to leave challenge: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Progress Updates
    
    func updateChallengeProgress(_ challengeId: String, newValue: Int) async -> Bool {
        guard let progress = challengeProgress[challengeId] else {
            errorMessage = "Challenge progress not found"
            return false
        }
        
        do {
            // Update progress in Firestore
            try await db.collection("challengeProgress").document(progress.id).updateData([
                "currentValue": newValue,
                "lastUpdatedAt": Timestamp(date: Date())
            ])
            
            // Check if challenge is completed
            if let challenge = challenges.first(where: { $0.id == challengeId }) {
                if newValue >= challenge.targetValue {
                    await completeChallenge(challenge)
                }
            }
            
            return true
            
        } catch {
            errorMessage = "Failed to update progress: \(error.localizedDescription)"
            return false
        }
    }
    
    private func completeChallenge(_ challenge: Challenge) async {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let progress = challengeProgress[challenge.id] else { return }
        
        do {
            // Update progress status to completed
            try await db.collection("challengeProgress").document(progress.id).updateData([
                "status": ChallengeStatus.completed.rawValue,
                "completedAt": Timestamp(date: Date())
            ])
            
            // Award points
            // Note: This would typically be handled by AuthManager
            print("Challenge completed! Awarding \(challenge.pointsReward) points")
            
            // Award badge if specified
            if let badgeReward = challenge.badgeReward {
                await awardBadgeIfNeeded(badgeId: badgeReward)
            }
            
        } catch {
            print("Failed to complete challenge: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Real-time Listeners
    
    private func setupRealTimeListeners() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to user's challenges
        let myChallengesQuery = db.collection("challenges")
            .whereField("createdBy", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
        
        challengeListeners.append(
            myChallengesQuery.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to load challenges: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.myChallenges = documents.compactMap { document in
                    self.dictionaryToChallenge(document.data())
                }
            }
        )
        
        // Listen to public challenges
        let publicChallengesQuery = db.collection("challenges")
            .whereField("privacy", isEqualTo: ChallengePrivacy.publicChallenge.rawValue)
            .order(by: "memberCount", descending: true)
            .limit(to: 20)
        
        challengeListeners.append(
            publicChallengesQuery.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to load public challenges: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.publicChallenges = documents.compactMap { document in
                    self.dictionaryToChallenge(document.data())
                }
            }
        )
        
        // Listen to user's challenge progress
        let progressQuery = db.collection("challengeProgress")
            .whereField("userId", isEqualTo: currentUserId)
        
        progressListeners.append(
            progressQuery.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to load progress: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var progressDict: [String: ChallengeProgress] = [:]
                for document in documents {
                    if let progress = self.dictionaryToChallengeProgress(document.data()) {
                        progressDict[progress.challengeId] = progress
                    }
                }
                
                self.challengeProgress = progressDict
            }
        )
    }
    
    private func removeAllListeners() {
        challengeListeners.forEach { $0.remove() }
        progressListeners.forEach { $0.remove() }
        challengeListeners.removeAll()
        progressListeners.removeAll()
    }
    
    // MARK: - Search and Discovery
    
    func searchChallenges(query: String) async -> [Challenge] {
        do {
            let snapshot = try await db.collection("challenges")
                .whereField("privacy", isEqualTo: ChallengePrivacy.publicChallenge.rawValue)
                .whereField("title", isGreaterThanOrEqualTo: query)
                .whereField("title", isLessThan: query + "z")
                .limit(to: 10)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                self.dictionaryToChallenge(document.data())
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            return []
        }
    }
    
    func getChallengesByType(_ type: ChallengeType) async -> [Challenge] {
        do {
            let snapshot = try await db.collection("challenges")
                .whereField("privacy", isEqualTo: ChallengePrivacy.publicChallenge.rawValue)
                .whereField("type", isEqualTo: type.rawValue)
                .order(by: "memberCount", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                self.dictionaryToChallenge(document.data())
            }
        } catch {
            errorMessage = "Failed to load challenges by type: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Helper Methods
    
    private func challengeToDictionary(_ challenge: Challenge) -> [String: Any] {
        return [
            "id": challenge.id,
            "title": challenge.title,
            "description": challenge.description,
            "type": challenge.type.rawValue,
            "privacy": challenge.privacy.rawValue,
            "createdBy": challenge.createdBy,
            "createdAt": Timestamp(date: challenge.createdAt),
            "startDate": Timestamp(date: challenge.startDate),
            "endDate": Timestamp(date: challenge.endDate),
            "targetValue": challenge.targetValue,
            "targetUnit": challenge.targetUnit,
            "habitIds": challenge.habitIds,
            "pointsReward": challenge.pointsReward,
            "badgeReward": challenge.badgeReward as Any,
            "memberCount": challenge.memberCount,
            "isActive": challenge.isActive
        ]
    }
    
    private func progressToDictionary(_ progress: ChallengeProgress) -> [String: Any] {
        return [
            "id": progress.id,
            "challengeId": progress.challengeId,
            "userId": progress.userId,
            "joinedAt": Timestamp(date: progress.joinedAt),
            "currentValue": progress.currentValue,
            "status": progress.status.rawValue,
            "lastUpdatedAt": Timestamp(date: progress.lastUpdatedAt),
            "completedAt": progress.completedAt != nil ? Timestamp(date: progress.completedAt!) : NSNull()
        ]
    }
    
    private func awardBadgeIfNeeded(badgeId: String) async {
        // This would typically integrate with AuthManager
        // For now, just print the badge award
        print("🏆 Badge awarded: \(badgeId)")
    }
    
    // MARK: - Dictionary Conversion Helpers
    
    private func dictionaryToChallenge(_ data: [String: Any]) -> Challenge? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let typeRaw = data["type"] as? String,
              let type = ChallengeType(rawValue: typeRaw),
              let privacyRaw = data["privacy"] as? String,
              let privacy = ChallengePrivacy(rawValue: privacyRaw),
              let createdBy = data["createdBy"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let startDateTimestamp = data["startDate"] as? Timestamp,
              let endDateTimestamp = data["endDate"] as? Timestamp,
              let targetValue = data["targetValue"] as? Int,
              let targetUnit = data["targetUnit"] as? String,
              let habitIds = data["habitIds"] as? [String],
              let pointsReward = data["pointsReward"] as? Int,
              let memberCount = data["memberCount"] as? Int,
              let isActive = data["isActive"] as? Bool else {
            return nil
        }
        
        let badgeReward = data["badgeReward"] as? String
        
        return Challenge(
            title: title,
            description: description,
            type: type,
            privacy: privacy,
            createdBy: createdBy,
            startDate: startDateTimestamp.dateValue(),
            endDate: endDateTimestamp.dateValue(),
            targetValue: targetValue,
            targetUnit: targetUnit,
            habitIds: habitIds,
            pointsReward: pointsReward,
            badgeReward: badgeReward,
            memberCount: memberCount
        )
    }
    
    private func dictionaryToChallengeProgress(_ data: [String: Any]) -> ChallengeProgress? {
        guard let id = data["id"] as? String,
              let challengeId = data["challengeId"] as? String,
              let userId = data["userId"] as? String,
              let joinedAtTimestamp = data["joinedAt"] as? Timestamp,
              let currentValue = data["currentValue"] as? Int,
              let statusRaw = data["status"] as? String,
              let status = ChallengeStatus(rawValue: statusRaw),
              let lastUpdatedAtTimestamp = data["lastUpdatedAt"] as? Timestamp else {
            return nil
        }
        
        let completedAtTimestamp = data["completedAt"] as? Timestamp
        let completedAt = completedAtTimestamp?.dateValue()
        
        var progress = ChallengeProgress(
            challengeId: challengeId,
            userId: userId
        )
        
        // Update the properties that aren't set in the initializer
        progress.currentValue = currentValue
        progress.status = status
        progress.lastUpdatedAt = lastUpdatedAtTimestamp.dateValue()
        progress.completedAt = completedAt
        
        return progress
    }
    
    // MARK: - Computed Properties
    
    var activeChallenges: [Challenge] {
        myChallenges.filter { challenge in
            challenge.isActive && 
            challenge.endDate > Date() &&
            (challengeProgress[challenge.id]?.status == .active || challengeProgress[challenge.id] == nil)
        }
    }
    
    var completedChallenges: [Challenge] {
        myChallenges.filter { challenge in
            challengeProgress[challenge.id]?.status == .completed
        }
    }
    
    var availablePublicChallenges: [Challenge] {
        publicChallenges.filter { challenge in
            challenge.isActive && 
            challenge.endDate > Date() &&
            challengeProgress[challenge.id] == nil // User not already in this challenge
        }
    }
}
