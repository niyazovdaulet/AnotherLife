//
//  FirebaseManager.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private init() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        // Check if Firebase is already configured
        guard FirebaseApp.app() == nil else { return }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        Firestore.firestore().settings = settings
        
        print("🔥 Firebase configured successfully!")
    }
    
    // MARK: - Firestore Collections
    enum Collection: String {
        case users = "users"
        case challenges = "challenges"
        case challengeProgress = "challengeProgress"
        case challengeInvitations = "challengeInvitations"
        case badges = "badges"
        
        var reference: CollectionReference {
            Firestore.firestore().collection(self.rawValue)
        }
    }
    
    // MARK: - Helper Methods
    func isUserAuthenticated() -> Bool {
        return Auth.auth().currentUser != nil
    }
}
