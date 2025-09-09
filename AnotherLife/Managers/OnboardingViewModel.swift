//
//  OnboardingViewModel.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI
import UserNotifications

final class OnboardingViewModel: ObservableObject {
    @Published var step: Int = 0
    @Published var selectedAreas = Set<FocusArea>()
    @Published var suggested: [HabitTemplate] = []
    @Published var selectedTemplates = Set<HabitTemplate>()
    @Published var wantsReminders = false
    @Published var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var theme: AppTheme = .system
    
    @AppStorage("hasCompletedOnboarding") private var hasCompleted = false
    
    private let totalSteps = 5
    
    var progress: Double {
        return Double(step + 1) / Double(totalSteps)
    }
    
    var canProceed: Bool {
        switch step {
        case 0: return true // Welcome - can always proceed
        case 1: return !selectedAreas.isEmpty // Focus areas - need at least one
        case 2: return !selectedTemplates.isEmpty // Templates - need at least one
        case 3: return true // Reminders - optional
        case 4: return true // Theme - can always finish
        default: return false
        }
    }
    
    func nextStep() {
        if step < totalSteps - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                step += 1
            }
        }
    }
    
    func previousStep() {
        if step > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                step -= 1
            }
        }
    }
    
    func buildSuggestions() {
        let base = StarterHabits.templates.filter { selectedAreas.contains($0.area) }
        suggested = base.isEmpty ? Array(StarterHabits.templates.prefix(6)) : Array(base.prefix(6))
        
        // Pre-select only "Drink Water" habit
        if let drinkWater = suggested.first(where: { $0.title == "Drink Water" }) {
            selectedTemplates = Set([drinkWater])
        } else {
            selectedTemplates = Set(suggested.prefix(1))
        }
    }
    
    func complete(habitManager: HabitManager) {
        // Create habits from selected templates
        selectedTemplates.forEach { template in
            let habit = Habit(
                title: template.title,
                description: template.description,
                frequency: template.suggestedFrequency,
                customDays: [], // Will be handled by frequency
                isPositive: template.isPositive,
                color: template.colorHex,
                icon: template.icon
            )
            habitManager.addHabit(habit)
        }
        
        // Schedule single Daily Check-In reminder if enabled
        if wantsReminders {
            scheduleDailyCheckInReminder(at: reminderTime)
        }
        
        // Update theme settings
        habitManager.updateTheme(theme)
        
        // Mark onboarding as completed
        hasCompleted = true
    }
    
    private func scheduleDailyCheckInReminder(at time: Date) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "Daily Check-In"
            content.body = "Time to check in with your habits!"
            content.sound = .default
            content.badge = 1
            
            let request = UNNotificationRequest(
                identifier: "daily_check_in",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func requestNotificationPermissionIfNeeded() {
        guard wantsReminders else { return }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func skipOnboarding() {
        hasCompleted = true
    }
}
