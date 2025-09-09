
import SwiftUI

@main
struct AnotherLifeApp: App {
    @StateObject private var habitManager = HabitManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(habitManager)
                        .preferredColorScheme(habitManager.theme == .dark ? .dark : 
                                            habitManager.theme == .light ? .light : nil)
                } else {
                    OnboardingFlowView()
                        .environmentObject(habitManager)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        }
    }
}
