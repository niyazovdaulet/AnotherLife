
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
    
    // MARK: - Multi-Completion Entry Management
    func addCompletion(for habit: Habit, on date: Date = Date(), status: HabitStatus = .completed, notes: String = "") {
        let completion = HabitCompletion(time: Date(), status: status, notes: notes)
        
        if let index = entries.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            entries[index].completions.append(completion)
            // Update legacy status for backward compatibility
            entries[index].status = entries[index].derivedStatus
        } else {
            let entry = HabitEntry(habitId: habit.id, date: date, status: status, notes: notes, completions: [completion])
            entries.append(entry)
        }
        
        saveEntries()
    }
    
    func removeCompletion(for habit: Habit, completionId: UUID, on date: Date = Date()) {
        if let entryIndex = entries.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            entries[entryIndex].completions.removeAll { $0.id == completionId }
            // Update legacy status for backward compatibility
            entries[entryIndex].status = entries[entryIndex].derivedStatus
            saveEntries()
        }
    }
    
    func updateCompletion(for habit: Habit, completionId: UUID, on date: Date = Date(), status: HabitStatus, notes: String = "") {
        if let entryIndex = entries.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: date) }),
           let completionIndex = entries[entryIndex].completions.firstIndex(where: { $0.id == completionId }) {
            entries[entryIndex].completions[completionIndex].status = status
            entries[entryIndex].completions[completionIndex].notes = notes
            // Update legacy status for backward compatibility
            entries[entryIndex].status = entries[entryIndex].derivedStatus
            saveEntries()
        }
    }
    
    func getCompletions(for habit: Habit, on date: Date = Date()) -> [HabitCompletion] {
        if let entry = getEntry(for: habit, on: date) {
            return entry.completions
        }
        return []
    }
    
    func isDayComplete(for habit: Habit, on date: Date = Date()) -> Bool {
        if habit.targetCompletionsPerDay > 1 {
            // Multi-completion habit: check completions array
            let completions = getCompletions(for: habit, on: date)
            let completedCount = completions.filter { $0.status == .completed }.count
            return completedCount >= habit.targetCompletionsPerDay
        } else {
            // Single-completion habit: check entry status
            if let entry = getEntry(for: habit, on: date) {
                return entry.status == .completed
            }
            return false
        }
    }
    
    func getCompletionProgress(for habit: Habit, on date: Date = Date()) -> (completed: Int, target: Int, percentage: Double) {
        if habit.targetCompletionsPerDay > 1 {
            // Multi-completion habit: check completions array
            let completions = getCompletions(for: habit, on: date)
            let completedCount = completions.filter { $0.status == .completed }.count
            let percentage = habit.targetCompletionsPerDay > 0 ? Double(completedCount) / Double(habit.targetCompletionsPerDay) : 0.0
            return (completedCount, habit.targetCompletionsPerDay, min(percentage, 1.0))
        } else {
            // Single-completion habit: check entry status
            let isCompleted = isDayComplete(for: habit, on: date)
            return (isCompleted ? 1 : 0, 1, isCompleted ? 1.0 : 0.0)
        }
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
    // MARK: - Progress Calculation
    
    func getCompletionProgress(for habit: Habit) -> Double {
        guard let totalDays = habit.totalDays, totalDays > 0 else { return 0.0 }
        
        // Calculate how many days have been successfully completed
        var completedDays = 0
        let calendar = Calendar.current
        
        for dayOffset in 0..<totalDays {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: habit.startDate) else { continue }
            
            // Check if this day is completed according to the habit's criteria
            if isDayComplete(for: habit, on: checkDate) {
                completedDays += 1
            }
        }
        
        return Double(completedDays) / Double(totalDays)
    }
    
    func getStatistics(for habit: Habit, in dateRange: DateInterval) -> HabitStatistics {
        let habitEntries = getEntries(for: habit, in: dateRange)
        
        let totalDays = habitEntries.count
        let completedDays = habitEntries.filter { isDayComplete(for: habit, on: $0.date) }.count
        let failedDays = habitEntries.filter { !isDayComplete(for: habit, on: $0.date) && $0.totalCompletions > 0 }.count
        let skippedDays = habitEntries.filter { $0.totalCompletions == 0 }.count
        
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
            // Check if the day is complete based on target completions
            if isDayComplete(for: habit, on: currentDate) {
                streak += 1
            } else if let entry = getEntry(for: habit, on: currentDate), entry.totalCompletions > 0 {
                // If there are entries but day isn't complete, streak is broken
                break
            } else {
                // No entries for this day, streak is broken
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
            // Check if the day is complete based on target completions
            if isDayComplete(for: habit, on: entry.date) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if entry.totalCompletions > 0 {
                // If there are entries but day isn't complete, streak is broken
                currentStreak = 0
            }
            // If no entries, continue without breaking streak (skipped days)
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
    
    func saveEntries() {
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
