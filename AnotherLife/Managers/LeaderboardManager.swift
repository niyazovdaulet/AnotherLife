//
//  LeaderboardManager.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class LeaderboardManager: ObservableObject {
    @Published var topUsers: [User] = []
    @Published var currentUserRank: Int = 0
    @Published var totalPlayers: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var leaderboardListener: ListenerRegistration?
    
    init() {
        setupLeaderboardListener()
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - Public Methods
    
    func setupLeaderboardListener() {
        guard Auth.auth().currentUser != nil else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        // Listen to users collection ordered by totalPoints descending
        leaderboardListener = db.collection("users")
            .order(by: "totalPoints", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
                        print("❌ Leaderboard error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.errorMessage = "No leaderboard data available"
                        return
                    }
                    
                    self?.processLeaderboardData(documents)
                }
            }
    }
    
    func refreshLeaderboard() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            // Get top 20 users
            let topUsersSnapshot = try await db.collection("users")
                .order(by: "totalPoints", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            // Get total user count
            let totalUsersSnapshot = try await db.collection("users")
                .getDocuments()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.processLeaderboardData(topUsersSnapshot.documents)
                self.totalPlayers = totalUsersSnapshot.documents.count
                self.calculateCurrentUserRank()
            }
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to refresh leaderboard: \(error.localizedDescription)"
                print("❌ Failed to refresh leaderboard: \(error.localizedDescription)")
            }
        }
    }
    
    func getCurrentUserRank() async -> Int {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return 0 }
        
        do {
            // Get all users ordered by points
            let snapshot = try await db.collection("users")
                .order(by: "totalPoints", descending: true)
                .getDocuments()
            
            // Find current user's rank
            for (index, document) in snapshot.documents.enumerated() {
                if document.documentID == currentUserId {
                    return index + 1
                }
            }
            
            return 0
            
        } catch {
            print("❌ Failed to get current user rank: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Private Methods
    
    private func processLeaderboardData(_ documents: [QueryDocumentSnapshot]) {
        var users: [User] = []
        
        for document in documents {
            do {
                let user = try document.data(as: User.self)
                users.append(user)
            } catch {
                print("❌ Failed to parse user data: \(error.localizedDescription)")
            }
        }
        
        // This method is called from main thread, so no need for DispatchQueue.main.async
        self.topUsers = users
        self.totalPlayers = users.count // This will be updated with actual total count
        self.calculateCurrentUserRank()
    }
    
    private func calculateCurrentUserRank() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Find current user in the top users list
        if let index = topUsers.firstIndex(where: { $0.id == currentUserId }) {
            self.currentUserRank = index + 1
        } else {
            // If current user is not in top 20, we need to calculate their rank
            Task {
                let rank = await getCurrentUserRank()
                DispatchQueue.main.async {
                    self.currentUserRank = rank
                }
            }
        }
    }
    
    private func removeAllListeners() {
        leaderboardListener?.remove()
        leaderboardListener = nil
    }
    
    // MARK: - Debug Methods
    
    func clearAllData() {
        topUsers = []
        currentUserRank = 0
        totalPlayers = 0
        errorMessage = nil
        removeAllListeners()
    }
}
