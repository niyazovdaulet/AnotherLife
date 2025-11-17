
import SwiftUI
import Firebase
import UserNotifications

@main
struct AnotherLifeApp: App {
    @StateObject private var habitManager = HabitManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Initialize Firebase
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(habitManager)
//                        .preferredColorScheme(.dark) // Always use dark mode
                        .onAppear {
                            clearNotificationBadge()
                        }
                } else {
                    OnboardingFlowView()
                        .environmentObject(habitManager)
                        .preferredColorScheme(.dark) // Always use dark mode
                        .onAppear {
                            clearNotificationBadge()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        }
    }
    
    private func clearNotificationBadge() {
        // Clear the app badge when app opens
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error.localizedDescription)")
            }
        }
    }
}
