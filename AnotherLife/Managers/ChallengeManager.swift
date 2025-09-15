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

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

@MainActor
class ChallengeManager: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var myChallenges: [Challenge] = []
    @Published var publicChallenges: [Challenge] = []
    @Published var joinedChallenges: [Challenge] = [] // Challenges user joined but didn't create
    @Published var challengeProgress: [String: ChallengeProgress] = [:] // challengeId: progress
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var challengeListeners: [ListenerRegistration] = []
    private var progressListeners: [ListenerRegistration] = []
    
    init() {
        // Don't set up listeners in init - wait for user to be authenticated
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
            print("🔄 Creating challenge document: \(challenge.id)")
            let challengeData = challengeToDictionary(challenge)
            print("🔄 Challenge data: \(challengeData)")
            try await db.collection("challenges").document(challenge.id).setData(challengeData)
            print("✅ Challenge document created successfully")
            
            // Create user's progress entry (creator automatically joins)
            let progress = ChallengeProgress(challengeId: challenge.id, userId: currentUserId)
            print("🔄 Creating progress document: \(progress.id)")
            let progressData = progressToDictionary(progress)
            print("🔄 Progress data: \(progressData)")
            try await db.collection("challengeProgress").document(progress.id).setData(progressData)
            print("✅ Progress document created successfully")
            
            // Update local progress cache immediately
            challengeProgress[challenge.id] = progress
            print("✅ Updated local progress cache for challenge: \(challenge.id)")
            
            // Don't add to myChallenges here - let the listener handle it
            // This prevents conflicts with the real-time listener
            
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
            print("🔄 Creating progress document: \(progress.id)")
            try await db.collection("challengeProgress").document(progress.id).setData(progressToDictionary(progress))
            print("✅ Progress document created successfully")
            
            // Update local progress cache
            challengeProgress[challenge.id] = progress
            
            // Add to joined challenges for better UX
            if !joinedChallenges.contains(where: { $0.id == challenge.id }) {
                joinedChallenges.append(challenge)
            }
            
            // Try to update member count, but don't fail if challenge doesn't exist
            do {
                try await db.collection("challenges").document(challenge.id).updateData([
                    "memberCount": FieldValue.increment(Int64(1))
                ])
            } catch {
                print("⚠️ Could not update member count for challenge \(challenge.id): \(error.localizedDescription)")
                // Don't fail the join operation if member count update fails
            }
            
            // Award "Challenge Rookie" badge if first challenge
            await awardBadgeIfNeeded(badgeId: "first_challenge")
            
            isLoading = false
            return true
            
        } catch {
            print("❌ Failed to create progress document: \(error.localizedDescription)")
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
            
            // Try to update member count, but don't fail if challenge doesn't exist
            do {
                try await db.collection("challenges").document(challenge.id).updateData([
                    "memberCount": FieldValue.increment(Int64(-1))
                ])
            } catch {
                print("⚠️ Could not update member count for challenge \(challenge.id): \(error.localizedDescription)")
                // Don't fail the leave operation if member count update fails
            }
            
            // Remove from local cache
            challengeProgress.removeValue(forKey: challenge.id)
            
            // Remove from joined challenges
            joinedChallenges.removeAll { $0.id == challenge.id }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to leave challenge: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func deleteChallenge(_ challenge: Challenge) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ deleteChallenge: No authenticated user")
            return false
        }
        
        // Only allow deletion if user created the challenge
        guard challenge.createdBy == currentUserId else {
            print("❌ deleteChallenge: User is not the creator of this challenge")
            errorMessage = "You can only delete challenges you created"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Deleting challenge: \(challenge.id)")
            
            // Delete all progress documents for this challenge
            let progressQuery = db.collection("challengeProgress")
                .whereField("challengeId", isEqualTo: challenge.id)
            
            let progressSnapshot = try await progressQuery.getDocuments()
            for document in progressSnapshot.documents {
                try await document.reference.delete()
                print("🗑️ Deleted progress document: \(document.documentID)")
            }
            
            // Delete all daily status documents for this challenge
            let dailyStatusQuery = db.collection("dailyStatus")
                .whereField("challengeId", isEqualTo: challenge.id)
            
            let dailyStatusSnapshot = try await dailyStatusQuery.getDocuments()
            for document in dailyStatusSnapshot.documents {
                try await document.reference.delete()
                print("🗑️ Deleted daily status document: \(document.documentID)")
            }
            
            // Delete all activity documents for this challenge
            let activityQuery = db.collection("challengeActivity")
                .whereField("challengeId", isEqualTo: challenge.id)
            
            let activitySnapshot = try await activityQuery.getDocuments()
            for document in activitySnapshot.documents {
                try await document.reference.delete()
                print("🗑️ Deleted activity document: \(document.documentID)")
            }
            
            // Finally, delete the challenge document itself
            try await db.collection("challenges").document(challenge.id).delete()
            print("🗑️ Deleted challenge document: \(challenge.id)")
            
            // Remove from local arrays
            await MainActor.run {
                self.myChallenges.removeAll { $0.id == challenge.id }
                self.joinedChallenges.removeAll { $0.id == challenge.id }
                self.challengeProgress.removeValue(forKey: challenge.id)
            }
            
            isLoading = false
            print("✅ Successfully deleted challenge and all related data")
            return true
            
        } catch {
            print("❌ deleteChallenge: Error - \(error.localizedDescription)")
            errorMessage = "Failed to delete challenge: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Progress Updates
    
    func updateChallengeProgress(_ challengeId: String, newValue: Int) async -> Bool {
        guard let progress = challengeProgress[challengeId] else {
            print("❌ updateChallengeProgress: Challenge progress not found for challengeId: \(challengeId)")
            print("❌ updateChallengeProgress: Available progress keys: \(Array(challengeProgress.keys))")
            errorMessage = "Challenge progress not found"
            return false
        }

        do {
            print("🔄 updateChallengeProgress: Updating progress for challengeId: \(challengeId)")
            print("🔄 updateChallengeProgress: Progress ID: \(progress.id)")
            print("🔄 updateChallengeProgress: New value: \(newValue)")

            let docRef = db.collection("challengeProgress").document(progress.id)
            
            // Check if document exists, if not create it
            let document = try await docRef.getDocument()
            if document.exists {
                print("✅ updateChallengeProgress: Updating existing document...")
                // Update progress in Firestore
                try await docRef.updateData([
                    "currentValue": newValue,
                    "lastUpdatedAt": Timestamp(date: Date())
                ])
            } else {
                print("✅ updateChallengeProgress: Creating new document...")
                // Create the document with full data
                let progressData = progressToDictionary(progress)
                var updatedData = progressData
                updatedData["currentValue"] = newValue
                updatedData["lastUpdatedAt"] = Timestamp(date: Date())
                try await docRef.setData(updatedData)
            }

            print("✅ updateChallengeProgress: Successfully updated progress")

            // Update the local progress cache
            if var progress = challengeProgress[challengeId] {
                progress.currentValue = newValue
                progress.lastUpdatedAt = Date()
                challengeProgress[challengeId] = progress
                print("✅ updateChallengeProgress: Updated local progress cache")
            }

            // Check if challenge is completed
            if let challenge = challenges.first(where: { $0.id == challengeId }) {
                if newValue >= challenge.targetValue {
                    await completeChallenge(challenge)
                }
            }

            return true

        } catch {
            print("❌ updateChallengeProgress: Error - \(error.localizedDescription)")
            errorMessage = "Failed to update progress: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Daily Status Updates
    
    func updateDailyStatus(_ challengeId: String, status: DailyStatus) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ updateDailyStatus: User not authenticated")
            errorMessage = "User not authenticated"
            return false
        }
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            // Use deterministic document ID for idempotent writes
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateKey = dateFormatter.string(from: today)
            let documentId = "\(challengeId)_\(currentUserId)_\(dateKey)"
            print("🔄 updateDailyStatus: Document ID: \(documentId)")
            
            let statusDocument = db.collection("dailyStatus").document(documentId)
            
            let data: [String: Any] = [
                "challengeId": challengeId,
                "userId": currentUserId,
                "date": Timestamp(date: today),
                "status": status.rawValue,
                "updatedAt": Timestamp(date: Date())
            ]
            
            print("🔄 updateDailyStatus: Data to save: \(data)")
            // Use setData with merge: false to ensure idempotent writes
            try await statusDocument.setData(data, merge: false)
            print("✅ updateDailyStatus: Successfully saved daily status")
            return true
            
        } catch {
            print("❌ updateDailyStatus: Error - \(error.localizedDescription)")
            errorMessage = "Failed to update daily status: \(error.localizedDescription)"
            return false
        }
    }
    
    func getDailyStatus(_ challengeId: String, for date: Date = Date()) async -> DailyStatus {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return .notStarted }
        
        do {
            let targetDate = Calendar.current.startOfDay(for: date)
            // Use same deterministic document ID format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateKey = dateFormatter.string(from: targetDate)
            let documentId = "\(challengeId)_\(currentUserId)_\(dateKey)"
            
            let statusDocument = db.collection("dailyStatus").document(documentId)
            
            let document = try await statusDocument.getDocument()
            if let data = document.data(),
               let statusString = data["status"] as? String,
               let status = DailyStatus(rawValue: statusString) {
                return status
            }
            
            return .notStarted
            
        } catch {
            print("Failed to get daily status: \(error.localizedDescription)")
            return .notStarted
        }
    }
    
    // MARK: - Streak Calculation
    
    func calculateStreak(_ challengeId: String) async -> Int {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return 0 }
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
            
            let query = db.collection("dailyStatus")
                .whereField("challengeId", isEqualTo: challengeId)
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: thirtyDaysAgo))
                .order(by: "date", descending: true)
            
            let snapshot = try await query.getDocuments()
            
            // Create a map of date -> status for easier lookup
            var statusMap: [String: DailyStatus] = [:]
            for doc in snapshot.documents {
                let data = doc.data()
                if let dateTimestamp = data["date"] as? Timestamp,
                   let statusString = data["status"] as? String,
                   let status = DailyStatus(rawValue: statusString) {
                    let dateKey = DateFormatter.dateKey.string(from: dateTimestamp.dateValue())
                    statusMap[dateKey] = status
                }
            }
            
            // Calculate consecutive completed days starting from today
            var streak = 0
            var currentDate = today
            
            for _ in 0..<30 { // Check last 30 days
                let dateKey = DateFormatter.dateKey.string(from: currentDate)
                
                if let status = statusMap[dateKey] {
                    if status == .completed {
                        streak += 1
                    } else if status == .skipped {
                        // Skipped days don't break the streak but don't count
                    } else {
                        // Not started or failed - streak breaks
                        break
                    }
                } else {
                    // No data for this day - streak breaks
                    break
                }
                
                // Move to previous day
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }
            
            return streak
            
        } catch {
            print("Failed to calculate streak: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getStreakHeatmapData(_ challengeId: String) async -> [String: DailyStatus] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [:] }
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
            
            let query = db.collection("dailyStatus")
                .whereField("challengeId", isEqualTo: challengeId)
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: thirtyDaysAgo))
                .order(by: "date", descending: true)
            
            let snapshot = try await query.getDocuments()
            
            var statusMap: [String: DailyStatus] = [:]
            for doc in snapshot.documents {
                let data = doc.data()
                if let dateTimestamp = data["date"] as? Timestamp,
                   let statusString = data["status"] as? String,
                   let status = DailyStatus(rawValue: statusString) {
                    let dateKey = DateFormatter.dateKey.string(from: dateTimestamp.dateValue())
                    statusMap[dateKey] = status
                }
            }
            
            return statusMap
            
        } catch {
            print("Failed to get streak heatmap data: \(error.localizedDescription)")
            return [:]
        }
    }
    
    // MARK: - Members Management
    
    func getChallengeMembers(_ challengeId: String) async -> [User] {
        do {
            let progressQuery = db.collection("challengeProgress")
                .whereField("challengeId", isEqualTo: challengeId)
            
            let progressSnapshot = try await progressQuery.getDocuments()
            let userIds = progressSnapshot.documents.compactMap { $0.data()["userId"] as? String }
            
            guard !userIds.isEmpty else { 
                // If no members found, return empty array
                return [] 
            }
            
            let usersQuery = db.collection("users")
                .whereField(FieldPath.documentID(), in: userIds)
            
            let usersSnapshot = try await usersQuery.getDocuments()
            let users = usersSnapshot.documents.compactMap { doc -> User? in
                let data = doc.data()
                guard let email = data["email"] as? String,
                      let username = data["username"] as? String,
                      let displayName = data["displayName"] as? String else { return nil }
                
                return User(
                    id: doc.documentID,
                    email: email,
                    username: username,
                    displayName: displayName,
                    profileImageURL: data["profileImageURL"] as? String
                )
            }
            
            return users
            
        } catch {
            print("Failed to get challenge members: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Leaderboard Management
    
    func getChallengeLeaderboard(_ challengeId: String) async -> [LeaderboardEntry] {
        do {
            let progressQuery = db.collection("challengeProgress")
                .whereField("challengeId", isEqualTo: challengeId)
                .order(by: "currentValue", descending: true)
                .limit(to: 10)
            
            let progressSnapshot = try await progressQuery.getDocuments()
            let progressData = progressSnapshot.documents.compactMap { doc -> (String, Int)? in
                let data = doc.data()
                guard let userId = data["userId"] as? String,
                      let currentValue = data["currentValue"] as? Int else { return nil }
                return (userId, currentValue)
            }
            
            guard !progressData.isEmpty else { return [] }
            
            let userIds = progressData.map { $0.0 }
            let usersQuery = db.collection("users")
                .whereField(FieldPath.documentID(), in: userIds)
            
            let usersSnapshot = try await usersQuery.getDocuments()
            let users = usersSnapshot.documents.compactMap { doc -> User? in
                let data = doc.data()
                guard let email = data["email"] as? String,
                      let username = data["username"] as? String,
                      let displayName = data["displayName"] as? String else { return nil }
                
                return User(
                    id: doc.documentID,
                    email: email,
                    username: username,
                    displayName: displayName,
                    profileImageURL: data["profileImageURL"] as? String
                )
            }
            
            // Create leaderboard entries with completed days, deduplicating by user ID
            var userProgressMap: [String: Int] = [:]
            for (userId, completedDays) in progressData {
                // Keep the highest progress for each user
                userProgressMap[userId] = max(userProgressMap[userId] ?? 0, completedDays)
            }
            
            let leaderboardEntries = userProgressMap.compactMap { (userId, completedDays) -> LeaderboardEntry? in
                guard let user = users.first(where: { $0.id == userId }) else { return nil }
                return LeaderboardEntry(user: user, completedDays: completedDays)
            }.sorted { $0.completedDays > $1.completedDays }
            
            return leaderboardEntries
            
        } catch {
            print("Failed to get challenge leaderboard: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Activity Feed
    
    func getChallengeActivity(_ challengeId: String) async -> [ActivityItem] {
        do {
            let activityQuery = db.collection("challengeActivity")
                .whereField("challengeId", isEqualTo: challengeId)
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
            
            let snapshot = try await activityQuery.getDocuments()
            let activities = snapshot.documents.compactMap { doc -> ActivityItem? in
                let data = doc.data()
                guard let userId = data["userId"] as? String,
                      let action = data["action"] as? String,
                      let createdAt = data["createdAt"] as? Timestamp else { return nil }
                
                // Get user display name
                let userDisplayName = data["userDisplayName"] as? String ?? "Unknown User"
                
                return ActivityItem(
                    id: doc.documentID,
                    user: userDisplayName,
                    action: action,
                    createdAt: createdAt.dateValue()
                )
            }
            
            return activities
            
        } catch {
            print("Failed to get challenge activity: \(error.localizedDescription)")
            return []
        }
    }
    
    
    // MARK: - Activity Management
    
    func addChallengeActivity(challengeId: String, action: String) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ addChallengeActivity: User not authenticated")
            errorMessage = "User not authenticated"
            return false
        }
        
        do {
            let activityData: [String: Any] = [
                "challengeId": challengeId,
                "userId": currentUserId,
                "userDisplayName": "You", // Will be replaced with actual user data
                "action": action,
                "createdAt": Timestamp(date: Date())
            ]
            
            print("🔄 addChallengeActivity: Adding activity for challengeId: \(challengeId)")
            print("🔄 addChallengeActivity: Activity data: \(activityData)")
            
            try await db.collection("challengeActivity").addDocument(data: activityData)
            print("✅ addChallengeActivity: Successfully added activity")
            return true
            
        } catch {
            print("❌ addChallengeActivity: Error - \(error.localizedDescription)")
            errorMessage = "Failed to add activity: \(error.localizedDescription)"
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
    
    func setupRealTimeListeners() {
        // Remove existing listeners first
        removeAllListeners()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            print("❌ setupRealTimeListeners: User not authenticated")
            return 
        }
        
        print("🔄 Setting up real-time listeners for user: \(currentUserId)")
        
        setupRealTimeListenersInternal()
    }
    
    private func setupRealTimeListenersInternal() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to user's challenges
        let myChallengesQuery = db.collection("challenges")
            .whereField("createdBy", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
        
        challengeListeners.append(
            myChallengesQuery.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ My challenges listener error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load challenges: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("⚠️ My challenges listener: No documents")
                    return 
                }
                
                print("🔄 My challenges listener: Received \(documents.count) documents")
                
                let newChallenges = documents.compactMap { document in
                    self.dictionaryToChallenge(document.data())
                }
                
                print("🔄 My challenges listener: Parsed \(newChallenges.count) challenges")
                
                self.myChallenges = newChallenges
                
                // Ensure progress entries exist for created challenges
                self.ensureCreatorProgressEntries()
                
                // Clean up any duplicate progress documents
                self.cleanupDuplicateProgress()
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
                
                let newPublicChallenges = documents.compactMap { document in
                    self.dictionaryToChallenge(document.data())
                }
                
                // Replace publicChallenges with new data to avoid duplicates
                self.publicChallenges = newPublicChallenges
            }
        )
        
        // Listen to user's challenge progress
        let progressQuery = db.collection("challengeProgress")
            .whereField("userId", isEqualTo: currentUserId)
        
        progressListeners.append(
            progressQuery.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Progress listener error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load progress: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("⚠️ Progress listener: No documents")
                    return 
                }
                
                print("🔄 Progress listener: Received \(documents.count) documents")
                
                var progressDict: [String: ChallengeProgress] = [:]
                var failedParses = 0
                
                for document in documents {
                    if let progress = self.dictionaryToChallengeProgress(document.data()) {
                        // Only keep the most recent progress for each challenge
                        if let existingProgress = progressDict[progress.challengeId] {
                            if progress.lastUpdatedAt > existingProgress.lastUpdatedAt {
                                progressDict[progress.challengeId] = progress
                                print("🔄 Progress listener: Updated progress for challenge \(progress.challengeId) (newer timestamp)")
                            }
                        } else {
                            progressDict[progress.challengeId] = progress
                        }
                    } else {
                        failedParses += 1
                        print("❌ Progress listener: Failed to parse document \(document.documentID)")
                    }
                }
                
                print("🔄 Progress listener: Parsed \(progressDict.count) progress entries (\(failedParses) failed)")
                
                if failedParses > 0 {
                    print("⚠️ Progress listener: \(failedParses) documents failed to parse - this may indicate data corruption")
                }
                
                self.challengeProgress = progressDict
                
                // Load challenges for which user has progress but didn't create
                self.loadJoinedChallenges()
            }
        )
    }
    
    private func loadJoinedChallenges() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let challengeIds = challengeProgress.keys.filter { challengeId in
            // Only load challenges that user didn't create
            !myChallenges.contains { $0.id == challengeId }
        }
        
        guard !challengeIds.isEmpty else { return }
        
        Task {
            do {
                var joinedChallenges: [Challenge] = []
                
                // Batch the queries to handle Firestore's 30-item limit for 'IN' queries
                let batchSize = 30
                let batches = challengeIds.chunked(into: batchSize)
                
                for batch in batches {
                    let challengesQuery = db.collection("challenges")
                        .whereField(FieldPath.documentID(), in: batch)
                    
                    let snapshot = try await challengesQuery.getDocuments()
                    let batchChallenges = snapshot.documents.compactMap { document in
                        self.dictionaryToChallenge(document.data())
                    }
                    joinedChallenges.append(contentsOf: batchChallenges)
                }
                
                await MainActor.run {
                    // Store joined challenges in the dedicated property
                    self.joinedChallenges = joinedChallenges
                    print("🔄 Loaded \(joinedChallenges.count) joined challenges")
                }
            } catch {
                print("Failed to load joined challenges: \(error.localizedDescription)")
            }
        }
    }
    
    func removeAllListeners() {
        challengeListeners.forEach { $0.remove() }
        progressListeners.forEach { $0.remove() }
        challengeListeners.removeAll()
        progressListeners.removeAll()
    }
    
    func clearAllData() {
        challenges.removeAll()
        myChallenges.removeAll()
        publicChallenges.removeAll()
        joinedChallenges.removeAll()
        challengeProgress.removeAll()
        removeAllListeners()
    }
    
    private func ensureCreatorProgressEntries() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            for challenge in myChallenges {
                // Check if progress entry exists for this challenge
                if challengeProgress[challenge.id] == nil {
                    print("🔄 Creating missing progress entry for created challenge: \(challenge.id)")
                    
                    do {
                        // Create progress entry for the creator
                        let progress = ChallengeProgress(challengeId: challenge.id, userId: currentUserId)
                        let progressData = progressToDictionary(progress)
                        
                        try await db.collection("challengeProgress").document(progress.id).setData(progressData)
                        
                        await MainActor.run {
                            // Update local cache
                            self.challengeProgress[challenge.id] = progress
                            print("✅ Created missing progress entry for challenge: \(challenge.id)")
                        }
                    } catch {
                        print("❌ Failed to create progress entry for challenge \(challenge.id): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func cleanupDuplicateProgress() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                // Get all progress documents for this user
                let snapshot = try await db.collection("challengeProgress")
                    .whereField("userId", isEqualTo: currentUserId)
                    .getDocuments()
                
                var challengeProgressMap: [String: [String]] = [:] // challengeId -> [documentIds]
                
                // Group documents by challengeId
                for document in snapshot.documents {
                    if let challengeId = document.data()["challengeId"] as? String {
                        if challengeProgressMap[challengeId] == nil {
                            challengeProgressMap[challengeId] = []
                        }
                        challengeProgressMap[challengeId]?.append(document.documentID)
                    }
                }
                
                // Find and delete duplicates
                for (challengeId, documentIds) in challengeProgressMap {
                    if documentIds.count > 1 {
                        print("🔄 Found \(documentIds.count) progress documents for challenge \(challengeId)")
                        
                        // Keep the most recent one, delete the rest
                        var documentsToDelete: [String] = []
                        
                        for documentId in documentIds {
                            let doc = try await db.collection("challengeProgress").document(documentId).getDocument()
                            if let data = doc.data(),
                               let lastUpdatedAt = data["lastUpdatedAt"] as? Timestamp {
                                // We'll keep the most recent one
                                documentsToDelete.append(documentId)
                            }
                        }
                        
                        // Keep the first one (most recent), delete the rest
                        if documentsToDelete.count > 1 {
                            documentsToDelete.removeFirst() // Keep the first one
                            
                            for documentId in documentsToDelete {
                                try await db.collection("challengeProgress").document(documentId).delete()
                                print("🗑️ Deleted duplicate progress document: \(documentId)")
                            }
                        }
                    }
                }
                
                print("✅ Cleanup completed")
                
            } catch {
                print("❌ Failed to cleanup duplicate progress: \(error.localizedDescription)")
            }
        }
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
        print("🔄 Parsing challenge data: \(data)")
        
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
            print("❌ Failed to parse challenge data - missing required fields")
            print("❌ Available fields: \(data.keys)")
            return nil
        }
        
        let badgeReward = data["badgeReward"] as? String
        
        let challenge = Challenge(
            id: id,
            title: title,
            description: description,
            type: type,
            privacy: privacy,
            createdBy: createdBy,
            createdAt: createdAtTimestamp.dateValue(),
            startDate: startDateTimestamp.dateValue(),
            endDate: endDateTimestamp.dateValue(),
            targetValue: targetValue,
            targetUnit: targetUnit,
            habitIds: habitIds,
            pointsReward: pointsReward,
            badgeReward: badgeReward,
            memberCount: memberCount,
            isActive: isActive
        )
        
        print("✅ Successfully parsed challenge: \(challenge.id) - \(challenge.title)")
        return challenge
    }
    
    private func dictionaryToChallengeProgress(_ data: [String: Any]) -> ChallengeProgress? {
        print("🔄 Parsing progress data: \(data)")
        
        guard let id = data["id"] as? String,
              let challengeId = data["challengeId"] as? String,
              let userId = data["userId"] as? String,
              let joinedAtTimestamp = data["joinedAt"] as? Timestamp,
              let currentValue = data["currentValue"] as? Int,
              let statusRaw = data["status"] as? String,
              let status = ChallengeStatus(rawValue: statusRaw),
              let lastUpdatedAtTimestamp = data["lastUpdatedAt"] as? Timestamp else {
            print("❌ Failed to parse progress data - missing required fields")
            print("❌ Available fields: \(data.keys)")
            return nil
        }
        
        let completedAtTimestamp = data["completedAt"] as? Timestamp
        let completedAt = completedAtTimestamp?.dateValue()
        
        let progress = ChallengeProgress(
            id: id,
            challengeId: challengeId,
            userId: userId,
            joinedAt: joinedAtTimestamp.dateValue(),
            currentValue: currentValue,
            status: status,
            lastUpdatedAt: lastUpdatedAtTimestamp.dateValue(),
            completedAt: completedAt
        )
        
        print("✅ Successfully parsed progress: \(progress.id) for challenge \(progress.challengeId)")
        return progress
    }
    
    // MARK: - Computed Properties
    
    var activeChallenges: [Challenge] {
        // Get challenges where user has progress (both created and joined)
        var challenges: [Challenge] = []
        
        // Add challenges created by user (they are automatically joined)
        challenges.append(contentsOf: myChallenges.filter { challenge in
            challenge.isActive && challenge.endDate > Date()
        })
        
        // Add challenges joined by user (but not created by them)
        challenges.append(contentsOf: joinedChallenges.filter { challenge in
            challenge.isActive && 
            challenge.endDate > Date() &&
            challengeProgress[challenge.id] != nil &&
            !myChallenges.contains { $0.id == challenge.id }
        })
        
        return challenges
    }

    var completedChallenges: [Challenge] {
        // Get challenges where user has progress (both created and joined)
        var challenges: [Challenge] = []
        
        // Add completed challenges created by user
        challenges.append(contentsOf: myChallenges.filter { challenge in
            challengeProgress[challenge.id]?.status == .completed
        })
        
        // Add completed challenges joined by user (but not created by them)
        challenges.append(contentsOf: joinedChallenges.filter { challenge in
            challengeProgress[challenge.id]?.status == .completed &&
            !myChallenges.contains { $0.id == challenge.id }
        })
        
        return challenges
    }
    
    var availablePublicChallenges: [Challenge] {
        publicChallenges.filter { challenge in
            challenge.isActive && 
            challenge.endDate > Date() &&
            challenge.privacy == .publicChallenge &&
            challengeProgress[challenge.id] == nil && // User hasn't joined this challenge
            !myChallenges.contains { $0.id == challenge.id } && // User didn't create this challenge
            !joinedChallenges.contains { $0.id == challenge.id } // User hasn't joined this challenge
        }
    }
}
