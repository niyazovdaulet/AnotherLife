
import SwiftUI

@main
struct AnotherLifeApp: App {
    @StateObject private var habitManager = HabitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitManager)
                .preferredColorScheme(habitManager.theme == .dark ? .dark : 
                                    habitManager.theme == .light ? .light : nil)
        }
    }
}
