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
    // MARK: - Modern Primary Colors (iOS 17+ inspired)
    static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 1.0)      // System Blue
    static let primaryGreen = Color(red: 0.20, green: 0.78, blue: 0.35)   // System Green
    static let primaryRed = Color(red: 1.0, green: 0.23, blue: 0.19)      // System Red
    static let primaryOrange = Color(red: 1.0, green: 0.58, blue: 0.0)    // System Orange
    static let primaryPurple = Color(red: 0.69, green: 0.32, blue: 0.87)  // System Purple
    static let primaryPink = Color(red: 1.0, green: 0.18, blue: 0.33)     // System Pink
    static let primaryTeal = Color(red: 0.35, green: 0.78, blue: 0.98)    // System Teal
    static let primaryIndigo = Color(red: 0.35, green: 0.34, blue: 0.84)  // System Indigo
    
    // MARK: - Semantic Colors
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let error = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let info = Color(red: 0.0, green: 0.48, blue: 1.0)
    
    // MARK: - Light Theme Colors (iOS 17+ inspired)
    static let lightBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let lightCardBackground = Color.white
    static let lightSecondaryBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let lightTextPrimary = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let lightTextSecondary = Color(red: 0.24, green: 0.24, blue: 0.26)
    static let lightTextTertiary = Color(red: 0.43, green: 0.43, blue: 0.45)
    static let lightSeparator = Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.29)
    
    // MARK: - Dark Theme Colors (iOS 17+ inspired)
    static let darkBackground = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let darkCardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let darkSecondaryBackground = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let darkTextPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let darkTextSecondary = Color(red: 0.92, green: 0.92, blue: 0.96)
    static let darkTextTertiary = Color(red: 0.64, green: 0.64, blue: 0.68)
    static let darkSeparator = Color(red: 0.33, green: 0.33, blue: 0.36)
    
    // MARK: - Dynamic Colors (Theme-aware)
    static var background: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkBackground) : UIColor(lightBackground)
        })
    }
    
    static var secondaryBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkSecondaryBackground) : UIColor(lightSecondaryBackground)
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
    
    static var textTertiary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkTextTertiary) : UIColor(lightTextTertiary)
        })
    }
    
    static var separator: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(darkSeparator) : UIColor(lightSeparator)
        })
    }
    
    // MARK: - Modern Gradient Colors
    static let primaryGradient = LinearGradient(
        colors: [primaryBlue, primaryPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [primaryGreen, primaryTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [primaryOrange, primaryPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let errorGradient = LinearGradient(
        colors: [primaryRed, primaryPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Habit Colors (Modern palette)
    static let habitBlue = primaryBlue
    static let habitGreen = primaryGreen
    static let habitRed = primaryRed
    static let habitOrange = primaryOrange
    static let habitPurple = primaryPurple
    static let habitPink = primaryPink
    static let habitTeal = primaryTeal
    static let habitIndigo = primaryIndigo
    static let habitMint = Color(red: 0.0, green: 0.8, blue: 0.6)
    static let habitYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let habitBrown = Color(red: 0.6, green: 0.4, blue: 0.2)
    static let habitGray = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    // Additional colors for enhanced UI
    static let primaryYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
}

// MARK: - Habit Note
struct HabitNote: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var date: Date
    var habitId: UUID? // Optional - can be a general note
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(content: String, date: Date = Date(), habitId: UUID? = nil, tags: [String] = []) {
        self.id = UUID()
        self.content = content
        self.date = date
        self.habitId = habitId
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var wordCount: Int {
        return content.split(separator: " ").count
    }
    
    var preview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
}
