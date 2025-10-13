import Foundation
import SwiftUI

// MARK: - Habit Status
enum HabitStatus: String, CaseIterable, Codable {
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"
    
    var color: Color {
        switch self {
        case .completed:
            return .primaryGreen
        case .failed:
            return .primaryRed
        case .skipped:
            return .primaryBlue
        }
    }
    
    var icon: String {
        switch self {
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }
}

// MARK: - Habit Frequency
enum HabitFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .custom:
            return "Custom"
        }
    }
}

// MARK: - Habit Duration
enum HabitDuration: Codable {
    case fixed(days: Int)
    case unlimited
    case custom(startDate: Date, endDate: Date)
    
    var displayName: String {
        switch self {
        case .fixed(let days):
            return "\(days) days"
        case .unlimited:
            return "Unlimited"
        case .custom(_, _):
            return "Custom range"
        }
    }
    
    var isUnlimited: Bool {
        if case .unlimited = self {
            return true
        }
        return false
    }
    
    func daysFromStart(_ startDate: Date) -> Int? {
        switch self {
        case .fixed(let days):
            return days
        case .unlimited:
            return nil
        case .custom(_, let endDate):
            return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }
    }
    
    func endDate(from startDate: Date) -> Date? {
        switch self {
        case .fixed(let days):
            return Calendar.current.date(byAdding: .day, value: days - 1, to: startDate)
        case .unlimited:
            return nil
        case .custom(_, let endDate):
            return endDate
        }
    }
}

// MARK: - Habit Completion
struct HabitCompletion: Identifiable, Codable {
    let id: UUID
    let time: Date
    var status: HabitStatus
    var notes: String
    
    init(time: Date = Date(), status: HabitStatus = .completed, notes: String = "") {
        self.id = UUID()
        self.time = time
        self.status = status
        self.notes = notes
    }
}

// MARK: - Habit
struct Habit: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var frequency: HabitFrequency
    var customDays: [Int] // 0 = Sunday, 1 = Monday, etc.
    var isPositive: Bool // true for good habits, false for bad habits
    var createdAt: Date
    var color: String // Hex color string
    var icon: String // SF Symbol name
    
    // New properties for enhanced functionality
    var duration: HabitDuration
    var targetCompletionsPerDay: Int
    var startDate: Date
    
    init(title: String, description: String = "", frequency: HabitFrequency = .daily, customDays: [Int] = [], isPositive: Bool = true, color: String = "blue", icon: String = "star.fill", duration: HabitDuration = .unlimited, targetCompletionsPerDay: Int = 1, startDate: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.frequency = frequency
        self.customDays = customDays
        self.isPositive = isPositive
        self.createdAt = Date()
        self.color = color
        self.icon = icon
        self.duration = duration
        self.targetCompletionsPerDay = targetCompletionsPerDay
        self.startDate = startDate
    }
    
    // Computed properties
    var endDate: Date? {
        return duration.endDate(from: startDate)
    }
    
    var totalDays: Int? {
        return duration.daysFromStart(startDate)
    }
    
    var isCompleted: Bool {
        if let endDate = endDate {
            return Date() > endDate
        }
        return false
    }
    
    var progressPercentage: Double {
        // This will be calculated by HabitManager based on actual completions
        // For now, return 0 - will be updated when HabitManager calculates it
        return 0.0
    }
}

// MARK: - Habit Entry
struct HabitEntry: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    let date: Date
    var status: HabitStatus // Legacy field for backward compatibility
    var notes: String
    var completions: [HabitCompletion] // New multi-completion support
    
    init(habitId: UUID, date: Date, status: HabitStatus = .skipped, notes: String = "", completions: [HabitCompletion] = []) {
        self.id = UUID()
        self.habitId = habitId
        self.date = date
        self.status = status
        self.notes = notes
        self.completions = completions
    }
    
    // Computed properties for multi-completion support
    var completedCount: Int {
        return completions.filter { $0.status == .completed }.count
    }
    
    var failedCount: Int {
        return completions.filter { $0.status == .failed }.count
    }
    
    var totalCompletions: Int {
        return completions.count
    }
    
    var completionPercentage: Double {
        guard totalCompletions > 0 else { return 0 }
        return Double(completedCount) / Double(totalCompletions)
    }
    
    var isFullyCompleted: Bool {
        return totalCompletions > 0 && completedCount == totalCompletions
    }
    
    var isPartiallyCompleted: Bool {
        return completedCount > 0 && completedCount < totalCompletions
    }
    
    var isNotStarted: Bool {
        return totalCompletions == 0
    }
    
    // Legacy compatibility - derive status from completions
    var derivedStatus: HabitStatus {
        if isNotStarted {
            return .skipped
        } else if isFullyCompleted {
            return .completed
        } else if failedCount > 0 {
            return .failed
        } else if isPartiallyCompleted {
            return .completed // Treat partial as completed for now
        } else {
            return .skipped
        }
    }
}

// MARK: - Habit Statistics
struct HabitStatistics {
    let habit: Habit
    let totalDays: Int
    let completedDays: Int
    let failedDays: Int
    let skippedDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let completionRate: Double
    
    var successRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays) / Double(totalDays) * 100
    }
}

// MARK: - Grid Layout
struct GridLayout {
    let rows: Int
    let columns: Int
    let isScrollable: Bool
    let totalCells: Int
    
    init(rows: Int, columns: Int, isScrollable: Bool = false, totalCells: Int? = nil) {
        self.rows = rows
        self.columns = columns
        self.isScrollable = isScrollable
        self.totalCells = totalCells ?? (rows * columns)
    }
    
    static func calculateForHabit(_ habit: Habit) -> GridLayout {
        guard let totalDays = habit.totalDays else {
            // Unlimited duration - use standard 5x10 scrollable grid
            return GridLayout(rows: 5, columns: 10, isScrollable: true, totalCells: 50)
        }
        
        if totalDays <= 50 {
            // Small habits - fit in a single grid
            let rows = (totalDays + 9) / 10 // Ceiling division
            return GridLayout(rows: rows, columns: 10, isScrollable: false, totalCells: totalDays)
        } else {
            // Large habits - use scrollable grid
            return GridLayout(rows: 5, columns: 10, isScrollable: true, totalCells: totalDays)
        }
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
}

// MARK: - Color Extensions
extension Color {
    // MARK: - Primary Colors
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let primaryGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let primaryRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    // MARK: - Light Theme Colors
    static let lightBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let lightCardBackground = Color.white
    static let lightTextPrimary = Color.primary
    static let lightTextSecondary = Color.secondary
    
    // MARK: - Dark Theme Colors
    static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let darkCardBackground = Color(red: 0.12, green: 0.12, blue: 0.16)
    static let darkTextPrimary = Color.white
    static let darkTextSecondary = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let darkAccent = Color(red: 0.3, green: 0.3, blue: 0.35)
    
    // MARK: - Dynamic Colors (Theme-aware)
    static var backgroundGray: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkBackground) : UIColor(lightBackground)
        })
    }
    
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkCardBackground) : UIColor(lightCardBackground)
        })
    }
    
    static var textPrimary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkTextPrimary) : UIColor(lightTextPrimary)
        })
    }
    
    static var textSecondary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkTextSecondary) : UIColor(lightTextSecondary)
        })
    }
    
    // MARK: - Additional colors for habits (Dark theme optimized)
    static let mint = Color(red: 0.0, green: 0.8, blue: 0.6)
    static let yellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let brown = Color(red: 0.6, green: 0.4, blue: 0.2)
    static let gray = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let cyan = Color(red: 0.0, green: 0.8, blue: 0.8)
    static let magenta = Color(red: 1.0, green: 0.0, blue: 1.0)
    static let lime = Color(red: 0.5, green: 1.0, blue: 0.0)
    static let navy = Color(red: 0.0, green: 0.0, blue: 0.5)
    
    // MARK: - Dark Theme Specific Colors
    static let darkBlue = Color(red: 0.3, green: 0.5, blue: 1.0)
    static let darkGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let darkRed = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let darkOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let darkPurple = Color(red: 0.7, green: 0.4, blue: 1.0)
    static let darkPink = Color(red: 1.0, green: 0.4, blue: 0.8)
    static let darkTeal = Color(red: 0.2, green: 0.8, blue: 0.8)
    static let darkIndigo = Color(red: 0.4, green: 0.4, blue: 1.0)
}
