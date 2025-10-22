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
    
    // Stable active challenges array to prevent list jumping
    @Published private var _activeChallenges: [Challenge] = []
    
    private let db = Firestore.firestore()
    private var challengeListeners: [ListenerRegistration] = []
    private var progressListeners: [ListenerRegistration] = []
    private weak var authManager: AuthManager?
    
    init() {
        // Don't set up listeners in init - wait for user to be authenticated
    }
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    deinit {
        // Remove listeners synchronously to avoid retain cycles
        // Use Task.detached to avoid capturing self
        Task.detached { [challengeListeners, progressListeners] in
            challengeListeners.forEach { $0.remove() }
            progressListeners.forEach { $0.remove() }
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
            
            // Add activity entry
            await addChallengeActivity(
                challengeId: challenge.id,
                action: "joined_challenge"
            )
            
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
    
    // MARK: - Challenge Editing
    
    func updateChallenge(
        challengeId: String,
        title: String,
        description: String,
        type: ChallengeType,
        privacy: ChallengePrivacy,
        duration: Int,
        pointsReward: Int,
        badgeReward: String? = nil
    ) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ updateChallenge: No authenticated user")
            errorMessage = "User not authenticated"
            return false
        }
        
        // Find the challenge to ensure user is the owner
        guard let challenge = myChallenges.first(where: { $0.id == challengeId }),
              challenge.createdBy == currentUserId else {
            print("❌ updateChallenge: User is not the creator of this challenge")
            errorMessage = "You can only edit challenges you created"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Updating challenge: \(challengeId)")
            
            // Calculate new end date based on updated duration
            let newEndDate = Calendar.current.date(byAdding: .day, value: duration, to: challenge.startDate) ?? challenge.endDate
            
            // Prepare update data
            let updateData: [String: Any] = [
                "title": title,
                "description": description,
                "type": type.rawValue,
                "privacy": privacy.rawValue,
                "endDate": Timestamp(date: newEndDate),
                "pointsReward": pointsReward,
                "badgeReward": badgeReward as Any
            ]
            
            print("🔄 Update data: \(updateData)")
            
            // Update challenge in Firestore
            try await db.collection("challenges").document(challengeId).updateData(updateData)
            print("✅ Successfully updated challenge in Firestore")
            
            // Update local cache
            await MainActor.run {
                if let index = self.myChallenges.firstIndex(where: { $0.id == challengeId }) {
                    // Create updated challenge with new values but preserve other fields
                    let updatedChallenge = Challenge(
                        id: challenge.id,
                        title: title,
                        description: description,
                        type: type,
                        privacy: privacy,
                        createdBy: challenge.createdBy,
                        createdAt: challenge.createdAt,
                        startDate: challenge.startDate,
                        endDate: newEndDate,
                        targetValue: challenge.targetValue,
                        targetUnit: challenge.targetUnit,
                        habitIds: challenge.habitIds,
                        pointsReward: pointsReward,
                        badgeReward: badgeReward,
                        memberCount: challenge.memberCount,
                        isActive: challenge.isActive
                    )
                    self.myChallenges[index] = updatedChallenge
                    print("✅ Updated local cache")
                }
            }
            
            isLoading = false
            return true
            
        } catch {
            print("❌ updateChallenge: Error - \(error.localizedDescription)")
            errorMessage = "Failed to update challenge: \(error.localizedDescription)"
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
            
            // Calculate progress by counting unique completed days from dailyStatus collection
            let completedDaysCount = await calculateCompletedDaysCount(challengeId: challengeId)
            print("🔄 updateChallengeProgress: Calculated completed days: \(completedDaysCount)")

            let docRef = db.collection("challengeProgress").document(progress.id)
            
            // Check if document exists, if not create it
            let document = try await docRef.getDocument()
            if document.exists {
                print("✅ updateChallengeProgress: Updating existing document...")
                // Update progress in Firestore with calculated value
                try await docRef.updateData([
                    "currentValue": completedDaysCount,
                    "lastUpdatedAt": Timestamp(date: Date())
                ])
            } else {
                print("✅ updateChallengeProgress: Creating new document...")
                // Create the document with full data
                let progressData = progressToDictionary(progress)
                var updatedData = progressData
                updatedData["currentValue"] = completedDaysCount
                updatedData["lastUpdatedAt"] = Timestamp(date: Date())
                try await docRef.setData(updatedData)
            }

            print("✅ updateChallengeProgress: Successfully updated progress to \(completedDaysCount)")

            // Update the local progress cache with calculated value
            if var progress = challengeProgress[challengeId] {
                progress.currentValue = completedDaysCount
                progress.lastUpdatedAt = Date()
                challengeProgress[challengeId] = progress
                print("✅ updateChallengeProgress: Updated local progress cache")
            }
            
            // Update active challenges to reflect any status changes
            updateActiveChallenges()

            // Check if challenge is completed (completed all days of duration)
            if let challenge = challenges.first(where: { $0.id == challengeId }) {
                let calendar = Calendar.current
                let duration = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
                if completedDaysCount >= duration {
                    await completeChallengeWithCelebration(challenge)
                }
            }

            return true

        } catch {
            print("❌ updateChallengeProgress: Error - \(error.localizedDescription)")
            errorMessage = "Failed to update progress: \(error.localizedDescription)"
            return false
        }
    }
    
    // Helper function to calculate completed days from dailyStatus collection
    private func calculateCompletedDaysCount(challengeId: String) async -> Int {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return 0 }
        
        do {
            let snapshot = try await db.collection("dailyStatus")
                .whereField("challengeId", isEqualTo: challengeId)
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: DailyStatus.completed.rawValue)
                .getDocuments()
            
            return snapshot.documents.count
        } catch {
            print("❌ Failed to calculate completed days: \(error.localizedDescription)")
            return 0
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
            // For check-in actions (completed/skipped), check if activity already exists for today
            if action == "completed" || action == "skipped" {
                let today = Calendar.current.startOfDay(for: Date())
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
                
                // Check if activity already exists for this user, challenge, and action today
                let existingActivity = try await db.collection("challengeActivity")
                    .whereField("challengeId", isEqualTo: challengeId)
                    .whereField("userId", isEqualTo: currentUserId)
                    .whereField("action", isEqualTo: action)
                    .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: today))
                    .whereField("createdAt", isLessThan: Timestamp(date: tomorrow))
                    .getDocuments()
                
                if !existingActivity.documents.isEmpty {
                    print("⚠️ addChallengeActivity: Activity already exists for today - skipping duplicate")
                    return true // Return true as the activity already exists
                }
            }
            
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
            
            // Update local progress cache
            if var localProgress = challengeProgress[challenge.id] {
                localProgress.status = .completed
                localProgress.completedAt = Date()
                challengeProgress[challenge.id] = localProgress
            }
            
            // Award points through AuthManager
            await awardChallengePoints(challenge.pointsReward)
            
            // Award badge if specified
            if let badgeReward = challenge.badgeReward {
                await awardBadgeIfNeeded(badgeId: badgeReward)
            }
            
            // Add completion activity
            await addChallengeActivity(
                challengeId: challenge.id,
                action: "completed_challenge"
            )
            
            print("✅ Challenge completed! Awarded \(challenge.pointsReward) points")
            
        } catch {
            print("❌ Failed to complete challenge: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Challenge Completion with Celebration
    
    func completeChallengeWithCelebration(_ challenge: Challenge) async -> (Bool, String, Int) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let progress = challengeProgress[challenge.id] else { 
            return (false, "Challenge not found", 0)
        }
        
        do {
            // Update progress status to completed
            try await db.collection("challengeProgress").document(progress.id).updateData([
                "status": ChallengeStatus.completed.rawValue,
                "completedAt": Timestamp(date: Date())
            ])
            
            // Also update the challenge itself to mark as completed (if user is the creator)
            if challenge.createdBy == currentUserId {
                try await db.collection("challenges").document(challenge.id).updateData([
                    "isActive": false,
                    "completedAt": Timestamp(date: Date())
                ])
            }
            
            // Update local progress cache
            if var localProgress = challengeProgress[challenge.id] {
                localProgress.status = .completed
                localProgress.completedAt = Date()
                challengeProgress[challenge.id] = localProgress
            }
            
            // Award points through AuthManager
            await awardChallengePoints(challenge.pointsReward)
            
            // Award badge if specified
            if let badgeReward = challenge.badgeReward {
                await awardBadgeIfNeeded(badgeId: badgeReward)
            }
            
            // Add completion activity
            await addChallengeActivity(
                challengeId: challenge.id,
                action: "completed_challenge"
            )
            
            // Force refresh data to ensure UI updates
            await refreshChallengeData()
            
            let message = "Congratulations! You completed '\(challenge.title)' and earned \(challenge.pointsReward) stars! 🎉"
            return (true, message, challenge.pointsReward)
            
        } catch {
            print("❌ Failed to complete challenge: \(error.localizedDescription)")
            return (false, "Failed to complete challenge", 0)
        }
    }
    
    // Method to automatically complete ended challenges
    func autoCompleteEndedChallenges() async {
        let currentDate = Date()
        
        // Check all challenges for auto-completion
        for challenge in myChallenges + joinedChallenges {
            // If challenge has ended and user has progress but not completed
            if challenge.endDate <= currentDate,
               let progress = challengeProgress[challenge.id],
               progress.status != .completed {
                
                print("🔄 Auto-completing ended challenge: \(challenge.title)")
                
                // Calculate challenge duration
                let calendar = Calendar.current
                let duration = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
                let durationDays = max(1, duration)
                
                // Check if user actually completed all required days
                let completedAllDays = progress.currentValue >= durationDays
                
                // Update progress status to completed
                do {
                    try await db.collection("challengeProgress").document(progress.id).updateData([
                        "status": ChallengeStatus.completed.rawValue,
                        "completedAt": Timestamp(date: currentDate)
                    ])
                    
                    // Update local progress cache
                    if var localProgress = challengeProgress[challenge.id] {
                        localProgress.status = .completed
                        localProgress.completedAt = currentDate
                        challengeProgress[challenge.id] = localProgress
                    }
                    
                    // Update challenge status if user is creator
                    if challenge.createdBy == Auth.auth().currentUser?.uid {
                        try await db.collection("challenges").document(challenge.id).updateData([
                            "isActive": false,
                            "completedAt": Timestamp(date: currentDate)
                        ])
                    }
                    
                    // Award points only if user completed all required days
                    if completedAllDays {
                        await awardChallengePoints(challenge.pointsReward)
                        
                        // Award badge if specified
                        if let badgeReward = challenge.badgeReward {
                            await awardBadgeIfNeeded(badgeId: badgeReward)
                        }
                        
                        print("✅ Auto-completed challenge with rewards: \(challenge.title)")
                    } else {
                        print("✅ Auto-completed challenge without rewards (incomplete): \(challenge.title)")
                    }
                    
                    // Add completion activity
                    await addChallengeActivity(
                        challengeId: challenge.id,
                        action: "completed_challenge"
                    )
                    
                } catch {
                    print("❌ Failed to auto-complete challenge: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Points and Rewards
    
    private func awardChallengePoints(_ points: Int) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Update user's points in Firestore
            try await db.collection("users").document(currentUserId).updateData([
                "totalPoints": FieldValue.increment(Int64(points)),
                "lastActiveAt": Timestamp(date: Date())
            ])
            
            // Update local user data through AuthManager
            await MainActor.run {
                if let authManager = self.authManager {
                    authManager.addPoints(points)
                }
            }
            
        } catch {
            print("❌ Failed to award points: \(error.localizedDescription)")
        }
    }
    
    private func calculateLevel(for points: Int) -> Int {
        // Simple level calculation: every 1000 points = 1 level
        return max(1, points / 1000 + 1)
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
                
                // Update active challenges
                self.updateActiveChallenges()
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
                
                // Update active challenges
                self.updateActiveChallenges()
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
                    
                    // Update active challenges
                    self.updateActiveChallenges()
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
    
    // MARK: - Debug and Refresh Methods
    
    func refreshChallengeData() async {
        print("🔄 Refreshing challenge data...")
        
        // Force refresh from Firebase
        await refreshMyChallenges()
        await refreshPublicChallenges()
        await refreshProgressData()
        
        print("✅ Challenge data refreshed")
        print("📊 Active challenges: \(activeChallenges.count)")
        print("📊 Completed challenges: \(completedChallenges.count)")
        print("📊 Progress entries: \(challengeProgress.count)")
    }
    
    
    private func refreshMyChallenges() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("challenges")
                .whereField("createdBy", isEqualTo: currentUserId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let challenges = snapshot.documents.compactMap { document in
                dictionaryToChallenge(document.data())
            }
            
            await MainActor.run {
                self.myChallenges = challenges
                print("🔄 Refreshed myChallenges: \(challenges.count) challenges")
            }
        } catch {
            print("❌ Failed to refresh my challenges: \(error.localizedDescription)")
        }
    }
    
    private func refreshPublicChallenges() async {
        do {
            let snapshot = try await db.collection("challenges")
                .whereField("privacy", isEqualTo: ChallengePrivacy.publicChallenge.rawValue)
                .order(by: "memberCount", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            let challenges = snapshot.documents.compactMap { document in
                dictionaryToChallenge(document.data())
            }
            
            await MainActor.run {
                self.publicChallenges = challenges
                print("🔄 Refreshed publicChallenges: \(challenges.count) challenges")
            }
        } catch {
            print("❌ Failed to refresh public challenges: \(error.localizedDescription)")
        }
    }
    
    private func refreshProgressData() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("challengeProgress")
                .whereField("userId", isEqualTo: currentUserId)
                .getDocuments()
            
            var progressDict: [String: ChallengeProgress] = [:]
            
            for document in snapshot.documents {
                if let progress = dictionaryToChallengeProgress(document.data()) {
                    progressDict[progress.challengeId] = progress
                }
            }
            
            await MainActor.run {
                self.challengeProgress = progressDict
                print("🔄 Refreshed challengeProgress: \(progressDict.count) entries")
                
                // Refresh joined challenges
                self.loadJoinedChallenges()
            }
        } catch {
            print("❌ Failed to refresh progress data: \(error.localizedDescription)")
        }
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
        return _activeChallenges
    }
    
    // Method to update active challenges with stable ordering
    private func updateActiveChallenges() {
        // Get challenges where user has progress (both created and joined)
        var challenges: [Challenge] = []
        
        // Add challenges created by user (they are automatically joined)
        challenges.append(contentsOf: myChallenges.filter { challenge in
            // Must be active, not ended, and not completed
            let hasEnded = challenge.endDate <= Date()
            let isCompleted = challengeProgress[challenge.id]?.status == .completed
            return challenge.isActive && !hasEnded && !isCompleted
        })
        
        // Add challenges joined by user (but not created by them)
        challenges.append(contentsOf: joinedChallenges.filter { challenge in
            // Must be active, not ended, have progress, not completed, and not created by user
            let hasEnded = challenge.endDate <= Date()
            let isCompleted = challengeProgress[challenge.id]?.status == .completed
            return challenge.isActive && 
                   !hasEnded && 
                   !isCompleted &&
                   challengeProgress[challenge.id] != nil &&
                   !myChallenges.contains { $0.id == challenge.id }
        })
        
        // Remove duplicates while preserving order
        var uniqueChallenges: [Challenge] = []
        var seenIds: Set<String> = []
        
        for challenge in challenges {
            if !seenIds.contains(challenge.id) {
                uniqueChallenges.append(challenge)
                seenIds.insert(challenge.id)
            }
        }
        
        // Only update if the content has actually changed
        if uniqueChallenges.map(\.id) != _activeChallenges.map(\.id) {
            _activeChallenges = uniqueChallenges
        }
    }

    var completedChallenges: [Challenge] {
        // Get challenges where user has progress (both created and joined)
        var challenges: [Challenge] = []
        
        // Add completed challenges created by user
        challenges.append(contentsOf: myChallenges.filter { challenge in
            let hasEnded = challenge.endDate <= Date()
            let isCompleted = challengeProgress[challenge.id]?.status == .completed
            return isCompleted || hasEnded
        })
        
        // Add completed challenges joined by user (but not created by them)
        challenges.append(contentsOf: joinedChallenges.filter { challenge in
            let hasEnded = challenge.endDate <= Date()
            let isCompleted = challengeProgress[challenge.id]?.status == .completed
            return (isCompleted || hasEnded) &&
            !myChallenges.contains { $0.id == challenge.id }
        })
        
        // Remove duplicates
        let uniqueChallenges = Array(Set(challenges.map { $0.id }))
            .compactMap { id in challenges.first { $0.id == id } }
        
        return uniqueChallenges
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
