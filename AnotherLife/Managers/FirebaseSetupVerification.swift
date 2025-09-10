//
//  FirebaseSetupVerification.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseSetupVerification: ObservableObject {
    @Published var isFirebaseConnected = false
    @Published var connectionStatus = "Checking..."
    
    init() {
        verifyFirebaseSetup()
    }
    
    private func verifyFirebaseSetup() {
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            connectionStatus = "❌ Firebase not configured"
            return
        }
        
        // Check Firestore connection
        let db = Firestore.firestore()
        let testDoc = db.collection("test").document("connection")
        
        testDoc.setData(["timestamp": Timestamp(date: Date())]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.connectionStatus = "❌ Firestore error: \(error.localizedDescription)"
                } else {
                    self?.connectionStatus = "✅ Firebase connected successfully!"
                    self?.isFirebaseConnected = true
                    
                    // Clean up test document
                    testDoc.delete()
                }
            }
        }
    }
    
    func testAuthentication() {
        // Test anonymous authentication
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.connectionStatus = "❌ Auth error: \(error.localizedDescription)"
                } else {
                    self?.connectionStatus = "✅ Authentication working!"
                    
                    // Sign out anonymous user
                    try? Auth.auth().signOut()
                }
            }
        }
    }
}
