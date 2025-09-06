//
//  StatisticsView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var habitManager: HabitManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedHabit: Habit?
    
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
                    
                    // Overall Progress
                    overallProgressView
                    
                    // Habits Performance
                    habitsPerformanceView
                    
                    // Streak Analysis
                    streakAnalysisView
                    
                    // Completion Rate Chart
                    completionRateChart
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - Overall Progress View
    private var overallProgressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Progress")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 20) {
                // Completion Rate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completion Rate")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(overallCompletionRate, specifier: "%.1f")%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBlue)
                }
                
                Spacer()
                
                // Total Habits
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Total Habits")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(habitManager.habits.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen)
                }
            }
            
            // Progress Bar
            ProgressView(value: overallCompletionRate / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .primaryBlue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Habits Performance View
    private var habitsPerformanceView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habits Performance")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if habitManager.habits.isEmpty {
                emptyHabitsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(habitManager.habits) { habit in
                        HabitPerformanceRow(habit: habit, timeRange: selectedTimeRange)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
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
    
    // MARK: - Streak Analysis View
    private var streakAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streak Analysis")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                // Current Streak
                VStack(spacing: 8) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(longestCurrentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
                
                // Longest Streak
                VStack(spacing: 8) {
                    Text("Longest")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(longestStreakEver)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBlue)
                    
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primaryBlue.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Completion Rate Chart
    private var completionRateChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Completion Rate Over Time")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if #available(iOS 16.0, *) {
                Chart(completionData) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Rate", data.rate)
                    )
                    .foregroundStyle(Color.primaryBlue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Rate", data.rate)
                    )
                    .foregroundStyle(Color.primaryBlue.opacity(0.1))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(Int(rate))%")
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS < 16
                Text("Charts require iOS 16+")
                    .foregroundColor(.textSecondary)
                    .frame(height: 200)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Computed Properties
    private var overallCompletionRate: Double {
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
    
    private var longestCurrentStreak: Int {
        habitManager.habits.compactMap { habit in
            habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).currentStreak
        }.max() ?? 0
    }
    
    private var longestStreakEver: Int {
        habitManager.habits.compactMap { habit in
            habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).longestStreak
        }.max() ?? 0
    }
    
    private var completionData: [CompletionData] {
        let calendar = Calendar.current
        let endDate = Date()
        
        var data: [CompletionData] = []
        
        for i in 0..<selectedTimeRange.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                let totalHabits = habitManager.habits.count
                let completedHabits = habitManager.habits.filter { habit in
                    if let entry = habitManager.getEntry(for: habit, on: date) {
                        return entry.status == .completed
                    }
                    return false
                }.count
                
                let rate = totalHabits > 0 ? Double(completedHabits) / Double(totalHabits) * 100 : 0
                
                data.append(CompletionData(date: date, rate: rate))
            }
        }
        
        return data.sorted { $0.date < $1.date }
    }
}

// MARK: - Habit Performance Row
struct HabitPerformanceRow: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    let timeRange: StatisticsView.TimeRange
    
    var body: some View {
        HStack(spacing: 12) {
            // Habit Icon
            ZStack {
                Circle()
                    .fill(Color(hex: habit.color)?.opacity(0.2) ?? Color.primaryBlue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: habit.icon)
                    .font(.title3)
                    .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
            }
            
            // Habit Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("\(completionRate, specifier: "%.0f")% completion")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("day streak")
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
    
    private var completionRate: Double {
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date(),
            end: Date()
        )
        
        let stats = habitManager.getStatistics(for: habit, in: dateRange)
        return stats.completionRate
    }
    
    private var currentStreak: Int {
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date(),
            end: Date()
        )
        
        let stats = habitManager.getStatistics(for: habit, in: dateRange)
        return stats.currentStreak
    }
}

// MARK: - Completion Data
struct CompletionData: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
}

#Preview {
    StatisticsView()
        .environmentObject(HabitManager())
}
