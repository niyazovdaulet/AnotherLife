//
//  HabitManager.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation
import SwiftUI

class HabitManager: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var entries: [HabitEntry] = []
    @Published var selectedDate: Date = Date()
    @Published var theme: AppTheme = .system
    
    private let habitsKey = "saved_habits"
    private let entriesKey = "saved_entries"
    private let themeKey = "app_theme"
    
    init() {
        loadHabits()
        loadEntries()
        loadTheme()
    }
    
    // MARK: - Habit Management
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        entries.removeAll { $0.habitId == habit.id }
        saveHabits()
        saveEntries()
    }
    
    // MARK: - Entry Management
    func updateEntry(for habit: Habit, status: HabitStatus, notes: String = "") {
        let entry = HabitEntry(habitId: habit.id, date: selectedDate, status: status, notes: notes)
        
        if let index = entries.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        
        saveEntries()
    }
    
    func getEntry(for habit: Habit, on date: Date) -> HabitEntry? {
        return entries.first { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func getEntries(for habit: Habit, in dateRange: DateInterval) -> [HabitEntry] {
        return entries.filter { entry in
            entry.habitId == habit.id && dateRange.contains(entry.date)
        }
    }
    
    // MARK: - Statistics
    func getStatistics(for habit: Habit, in dateRange: DateInterval) -> HabitStatistics {
        let habitEntries = getEntries(for: habit, in: dateRange)
        
        let totalDays = habitEntries.count
        let completedDays = habitEntries.filter { $0.status == .completed }.count
        let failedDays = habitEntries.filter { $0.status == .failed }.count
        let skippedDays = habitEntries.filter { $0.status == .skipped }.count
        
        let currentStreak = calculateCurrentStreak(for: habit)
        let longestStreak = calculateLongestStreak(for: habit, in: dateRange)
        let completionRate = totalDays > 0 ? Double(completedDays) / Double(totalDays) * 100 : 0
        
        return HabitStatistics(
            habit: habit,
            totalDays: totalDays,
            completedDays: completedDays,
            failedDays: failedDays,
            skippedDays: skippedDays,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            completionRate: completionRate
        )
    }
    
    private func calculateCurrentStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0
        
        while true {
            if let entry = getEntry(for: habit, on: currentDate) {
                if entry.status == .completed {
                    streak += 1
                } else {
                    break
                }
            } else {
                break
            }
            
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func calculateLongestStreak(for habit: Habit, in dateRange: DateInterval) -> Int {
        let habitEntries = getEntries(for: habit, in: dateRange).sorted { $0.date < $1.date }
        var maxStreak = 0
        var currentStreak = 0
        
        for entry in habitEntries {
            if entry.status == .completed {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    // MARK: - Persistence
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        }
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([HabitEntry].self, from: data) {
            entries = decoded
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }
    
    private func loadTheme() {
        if let themeString = UserDefaults.standard.string(forKey: themeKey),
           let loadedTheme = AppTheme(rawValue: themeString) {
            theme = loadedTheme
        }
    }
    
    func updateTheme(_ newTheme: AppTheme) {
        theme = newTheme
        saveTheme()
    }
}
