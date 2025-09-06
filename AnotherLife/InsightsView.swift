//
//  InsightsView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var habitManager: HabitManager
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedHabit: Habit?
    @State private var showingWeeklyReport = false
    
    enum TimeRange: String, CaseIterable {
        case week = "week"
        case month = "month"
        case threeMonths = "threeMonths"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .threeMonths: return "3 Months"
            case .year: return "Year"
            }
        }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Streak Overview
                    streakOverviewView
                    
                    // Habit Streak Graphs
                    habitStreakGraphsView
                    
                    // Correlation Analysis
                    correlationAnalysisView
                    
                    // Weekly Report Button
                    weeklyReportButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingWeeklyReport) {
            WeeklyReportView()
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: { selectedTimeRange = range }) {
                        Text(range.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTimeRange == range ? .white : .textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimeRange == range ? Color.primaryBlue : Color.backgroundGray)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Streak Overview
    private var streakOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streak Overview")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                StreakCardView(
                    title: "Longest Streak",
                    value: "\(longestStreakEver)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StreakCardView(
                    title: "Current Streak",
                    value: "\(longestCurrentStreak)",
                    subtitle: "days",
                    icon: "bolt.fill",
                    color: .primaryBlue
                )
            }
            
            HStack(spacing: 16) {
                StreakCardView(
                    title: "Total Streaks",
                    value: "\(totalStreaks)",
                    subtitle: "completed",
                    icon: "star.fill",
                    color: .primaryGreen
                )
                
                StreakCardView(
                    title: "Success Rate",
                    value: "\(Int(overallSuccessRate))",
                    subtitle: "%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Habit Streak Graphs
    private var habitStreakGraphsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habit Streak Patterns")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if habitManager.habits.isEmpty {
                emptyHabitsView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(habitManager.habits) { habit in
                        HabitStreakGraphView(habit: habit, timeRange: selectedTimeRange)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Correlation Analysis
    private var correlationAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habit Correlations")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if habitManager.habits.count < 2 {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.textSecondary.opacity(0.6))
                    
                    Text("Need at least 2 habits to show correlations")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(correlationInsights, id: \.id) { insight in
                        CorrelationInsightView(insight: insight)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Weekly Report Button
    private var weeklyReportButton: some View {
        Button(action: { showingWeeklyReport = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Report")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("View detailed insights and progress")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primaryBlue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .primaryBlue.opacity(0.3), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty Habits View
    private var emptyHabitsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.textSecondary.opacity(0.6))
            
            Text("No habits to analyze")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Computed Properties
    private var longestStreakEver: Int {
        habitManager.habits.compactMap { habit in
            habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).longestStreak
        }.max() ?? 0
    }
    
    private var longestCurrentStreak: Int {
        habitManager.habits.compactMap { habit in
            habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).currentStreak
        }.max() ?? 0
    }
    
    private var totalStreaks: Int {
        habitManager.habits.reduce(0) { total, habit in
            let stats = habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date()))
            return total + stats.completedDays
        }
    }
    
    private var overallSuccessRate: Double {
        guard !habitManager.habits.isEmpty else { return 0 }
        
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date(),
            end: Date()
        )
        
        let totalPossibleEntries = habitManager.habits.count * selectedTimeRange.days
        let completedEntries = habitManager.habits.reduce(0) { total, habit in
            let entries = habitManager.getEntries(for: habit, in: dateRange)
            return total + entries.filter { $0.status == .completed }.count
        }
        
        return totalPossibleEntries > 0 ? Double(completedEntries) / Double(totalPossibleEntries) * 100 : 0
    }
    
    private var correlationInsights: [CorrelationInsight] {
        guard habitManager.habits.count >= 2 else { return [] }
        
        var insights: [CorrelationInsight] = []
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date(),
            end: Date()
        )
        
        for i in 0..<habitManager.habits.count {
            for j in (i+1)..<habitManager.habits.count {
                let habit1 = habitManager.habits[i]
                let habit2 = habitManager.habits[j]
                
                let correlation = calculateCorrelation(between: habit1, and: habit2, in: dateRange)
                
                if abs(correlation) > 0.3 { // Only show significant correlations
                    insights.append(CorrelationInsight(
                        habit1: habit1,
                        habit2: habit2,
                        correlation: correlation,
                        strength: abs(correlation)
                    ))
                }
            }
        }
        
        return insights.sorted { $0.strength > $1.strength }
    }
    
    private func calculateCorrelation(between habit1: Habit, and habit2: Habit, in dateRange: DateInterval) -> Double {
        let entries1 = habitManager.getEntries(for: habit1, in: dateRange)
        let entries2 = habitManager.getEntries(for: habit2, in: dateRange)
        
        var habit1Values: [Double] = []
        var habit2Values: [Double] = []
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: dateRange.start)
        let endDate = calendar.startOfDay(for: dateRange.end)
        
        var currentDate = startDate
        while currentDate <= endDate {
            let entry1 = entries1.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let entry2 = entries2.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            
            habit1Values.append(entry1?.status == .completed ? 1.0 : 0.0)
            habit2Values.append(entry2?.status == .completed ? 1.0 : 0.0)
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return calculatePearsonCorrelation(x: habit1Values, y: habit2Values)
    }
    
    private func calculatePearsonCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0.0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator == 0 ? 0.0 : numerator / denominator
    }
}

// MARK: - Streak Card View
struct StreakCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundGray)
        )
    }
}

// MARK: - Habit Streak Graph View
struct HabitStreakGraphView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    let timeRange: InsightsView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.color)?.opacity(0.15) ?? Color.primaryBlue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: habit.icon)
                        .font(.title3)
                        .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text("Current streak: \(currentStreak) days")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            
            if #available(iOS 16.0, *) {
                Chart(streakData) { data in
                    BarMark(
                        x: .value("Date", data.date),
                        y: .value("Status", data.status)
                    )
                    .foregroundStyle(data.status == 1 ? Color(hex: habit.color) ?? .primaryBlue : Color.gray.opacity(0.3))
                }
                .frame(height: 60)
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
            } else {
                // Fallback for iOS < 16
                HStack(spacing: 2) {
                    ForEach(streakData, id: \.date) { data in
                        Rectangle()
                            .fill(data.status == 1 ? (Color(hex: habit.color) ?? .primaryBlue) : Color.gray.opacity(0.3))
                            .frame(width: 4, height: 20)
                    }
                }
                .frame(height: 60)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundGray)
        )
    }
    
    private var currentStreak: Int {
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date(),
            end: Date()
        )
        
        let stats = habitManager.getStatistics(for: habit, in: dateRange)
        return stats.currentStreak
    }
    
    private var streakData: [StreakData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate) ?? endDate
        
        var data: [StreakData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let entry = habitManager.getEntry(for: habit, on: currentDate)
            let status = entry?.status == .completed ? 1 : 0
            
            data.append(StreakData(date: currentDate, status: status))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return data
    }
}

// MARK: - Correlation Insight View
struct CorrelationInsightView: View {
    let insight: CorrelationInsight
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("Correlation: \(String(format: "%.2f", insight.correlation))")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(insight.strengthText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(insight.strengthColor)
                
                Text("\(Int(insight.strength * 100))%")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundGray)
        )
    }
}

// MARK: - Data Models
struct StreakData: Identifiable {
    let id = UUID()
    let date: Date
    let status: Int // 1 = completed, 0 = not completed
}

struct CorrelationInsight: Identifiable {
    let id = UUID()
    let habit1: Habit
    let habit2: Habit
    let correlation: Double
    let strength: Double
    
    var description: String {
        if correlation > 0 {
            return "You \(habit1.title.lowercased()) more often on days when you also \(habit2.title.lowercased())"
        } else {
            return "You \(habit1.title.lowercased()) less often on days when you \(habit2.title.lowercased())"
        }
    }
    
    var strengthText: String {
        if strength > 0.7 {
            return "Strong"
        } else if strength > 0.5 {
            return "Moderate"
        } else {
            return "Weak"
        }
    }
    
    var strengthColor: Color {
        if strength > 0.7 {
            return .green
        } else if strength > 0.5 {
            return .orange
        } else {
            return .gray
        }
    }
}

#Preview {
    InsightsView()
        .environmentObject(HabitManager())
}
