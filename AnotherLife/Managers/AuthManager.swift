//
//  AuthManager.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation
import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var isInitializing = true  // New: Track initial app load
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        // Listen for authentication state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadUserData(uid: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    // Mark initialization as complete
                    self?.isInitializing = false
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await loadUserData(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUpWithEmail(email: String, password: String, username: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(id: result.user.uid, email: email, username: username, displayName: displayName)
            try await saveUserToFirestore(user)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            // For now, show a placeholder message
            // In a real implementation, you'd handle the ASAuthorizationControllerDelegate
            errorMessage = "Apple Sign-In will be implemented after Firebase setup"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - User Data Management
    
    private func loadUserData(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if let data = document.data() {
                var user = try User(
                    id: data["id"] as? String ?? uid,
                    email: data["email"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "",
                    profileImageURL: data["profileImageURL"] as? String
                )
                user.totalPoints = data["totalPoints"] as? Int ?? 0
                user.level = data["level"] as? Int ?? 1
                user.badges = data["badges"] as? [String] ?? []
                
                currentUser = user
                isAuthenticated = true
                
                // Mark initialization as complete
                isInitializing = false
            } else {
                // User document doesn't exist, create it
                if let firebaseUser = auth.currentUser {
                    let user = User(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? "",
                        username: firebaseUser.displayName ?? "User\(Int.random(in: 1000...9999))",
                        displayName: firebaseUser.displayName ?? "User"
                    )
                    try await saveUserToFirestore(user)
                    currentUser = user
                    isAuthenticated = true
                    
                    // Mark initialization as complete
                    isInitializing = false
                }
            }
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
            // Mark initialization as complete even on error
            isInitializing = false
        }
    }
    
    private func saveUserToFirestore(_ user: User) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "displayName": user.displayName,
            "profileImageURL": user.profileImageURL as Any,
            "createdAt": user.createdAt,
            "lastActiveAt": user.lastActiveAt,
            "totalPoints": user.totalPoints,
            "level": user.level,
            "badges": user.badges
        ]
        
        try await db.collection("users").document(user.id).setData(userData)
    }
    
    func updateUserProfile(username: String, displayName: String) async {
        guard var user = currentUser else { return }
        
        user.username = username
        user.displayName = displayName
        
        do {
            try await saveUserToFirestore(user)
            currentUser = user
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Password Management
    
    func changePassword(currentPassword: String, newPassword: String) async {
        guard let user = auth.currentUser, let email = user.email else {
            errorMessage = "User not authenticated"
            return
        }
        
        // Re-authenticate user with current password
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)
        } catch {
            errorMessage = "Current password is incorrect"
            return
        }
        
        // Update password
        do {
            try await user.updatePassword(to: newPassword)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to change password: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Username Validation
    
    func checkUsernameAvailability(_ username: String) async -> Bool {
        do {
            let query = db.collection("users").whereField("username", isEqualTo: username)
            let snapshot = try await query.getDocuments()
            return snapshot.documents.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - User Search
    
    func searchUsers(byUsername username: String) async -> [User] {
        do {
            let query = db.collection("users")
                .whereField("username", isGreaterThanOrEqualTo: username)
                .whereField("username", isLessThan: username + "z")
                .limit(to: 10)
            
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { document in
                try? document.data(as: User.self)
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Points and Level Management
    
    func addPoints(_ points: Int) {
        guard var user = currentUser else { return }
        user.totalPoints += points
        
        // Check for level up
        let newLevel = calculateLevel(for: user.totalPoints)
        if newLevel > user.level {
            user.level = newLevel
            // TODO: Show level up animation
        }
        
        currentUser = user
        
        // Update in Firestore
        Task {
            do {
                try await db.collection("users").document(user.id).updateData([
                    "totalPoints": user.totalPoints,
                    "level": user.level
                ])
            } catch {
                print("Failed to update points: \(error)")
            }
        }
    }
    
    private func calculateLevel(for points: Int) -> Int {
        // Simple level calculation: every 1000 points = 1 level
        return max(1, points / 1000 + 1)
    }
    
    // MARK: - Badge Management
    
    func addBadge(_ badgeId: String) {
        guard var user = currentUser else { return }
        
        if !user.badges.contains(badgeId) {
            user.badges.append(badgeId)
            currentUser = user
            
            // Update in Firestore
            Task {
                do {
                    try await db.collection("users").document(user.id).updateData([
                        "badges": user.badges
                    ])
                } catch {
                    print("Failed to update badges: \(error)")
                }
            }
        }
    }
    
    func hasBadge(_ badgeId: String) -> Bool {
        return currentUser?.badges.contains(badgeId) ?? false
    }
}
