//
//  AnotherLifeApp.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

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
