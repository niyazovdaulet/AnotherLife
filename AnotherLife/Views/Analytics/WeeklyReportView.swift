
import SwiftUI
import Charts

struct WeeklyReportView: View {
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeek: Date = Date()
    
    private var weekStart: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: selectedWeek)?.start ?? selectedWeek
    }
    
    private var weekEnd: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: selectedWeek)?.end ?? selectedWeek
    }
    
    private var weekRange: DateInterval {
        DateInterval(start: weekStart, end: weekEnd)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Week Selector
                    weekSelectorView
                    
                    // Week Summary
                    weekSummaryView
                    
                    // Streaks Kept
                    streaksKeptView
                    
                    // Streaks Broken
                    streaksBrokenView
                    
                    // Habits Skipped
                    habitsSkippedView
                    
                    // Daily Breakdown
                    dailyBreakdownView
                    
                    // Insights
                    insightsView
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Week Selector
    private var weekSelectorView: some View {
        VStack(spacing: 12) {
            Text("Select Week")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primaryBlue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(weekDateText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Week of \(weekStart, formatter: weekFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primaryBlue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Week Summary
    private var weekSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Week Summary")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                SummaryCardView(
                    title: "Completion Rate",
                    value: "\(Int(weekCompletionRate))%",
                    icon: "chart.pie.fill",
                    color: .primaryBlue
                )
                
                SummaryCardView(
                    title: "Total Habits",
                    value: "\(habitManager.habits.count)",
                    icon: "star.fill",
                    color: .primaryGreen
                )
            }
            
            HStack(spacing: 16) {
                SummaryCardView(
                    title: "Streaks Kept",
                    value: "\(streaksKeptCount)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                SummaryCardView(
                    title: "Streaks Broken",
                    value: "\(streaksBrokenCount)",
                    icon: "xmark.circle.fill",
                    color: .red
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
    
    // MARK: - Streaks Kept
    private var streaksKeptView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streaks Kept 🔥")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if streaksKept.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "flame")
                        .font(.system(size: 40))
                        .foregroundColor(.textSecondary.opacity(0.6))
                    
                    Text("No streaks kept this week")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(streaksKept, id: \.habit.id) { streak in
                        StreakItemView(
                            habit: streak.habit,
                            streakLength: streak.length,
                            isKept: true
                        )
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
    
    // MARK: - Streaks Broken
    private var streaksBrokenView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streaks Broken 💔")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if streaksBroken.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("All streaks maintained! 🎉")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(streaksBroken, id: \.habit.id) { streak in
                        StreakItemView(
                            habit: streak.habit,
                            streakLength: streak.length,
                            isKept: false
                        )
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
    
    // MARK: - Habits Skipped
    private var habitsSkippedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habits Skipped ⏭️")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if skippedHabits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("No habits skipped this week!")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(skippedHabits, id: \.habit.id) { skipped in
                        SkippedHabitView(
                            habit: skipped.habit,
                            skipCount: skipped.count
                        )
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
    
    // MARK: - Daily Breakdown
    private var dailyBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Breakdown")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if #available(iOS 16.0, *) {
                Chart(dailyData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Completion", data.completionRate)
                    )
                    .foregroundStyle(
                        data.completionRate == 100 ? .green :
                        data.completionRate >= 70 ? .orange : .red
                    )
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
                VStack(spacing: 8) {
                    ForEach(dailyData, id: \.day) { data in
                        HStack {
                            Text(data.day)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .frame(width: 40, alignment: .leading)
                            
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        data.completionRate == 100 ? .green :
                                        data.completionRate >= 70 ? .orange : .red
                                    )
                                    .frame(width: geometry.size.width * (data.completionRate / 100))
                            }
                            .frame(height: 20)
                            
                            Text("\(Int(data.completionRate))%")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Insights
    private var insightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Insights")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            LazyVStack(spacing: 12) {
                ForEach(weeklyInsights, id: \.id) { insight in
                    InsightCardView(insight: insight)
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
    
    // MARK: - Computed Properties
    private var weekDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedWeek)
    }
    
    private var weekFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    private var weekCompletionRate: Double {
        guard !habitManager.habits.isEmpty else { return 0 }
        
        let totalPossibleEntries = habitManager.habits.count * 7
        let completedEntries = habitManager.habits.reduce(0) { total, habit in
            let entries = habitManager.getEntries(for: habit, in: weekRange)
            return total + entries.filter { $0.status == .completed }.count
        }
        
        return totalPossibleEntries > 0 ? Double(completedEntries) / Double(totalPossibleEntries) * 100 : 0
    }
    
    private var streaksKept: [StreakInfo] {
        habitManager.habits.compactMap { habit in
            let stats = habitManager.getStatistics(for: habit, in: weekRange)
            if stats.currentStreak > 0 {
                return StreakInfo(habit: habit, length: stats.currentStreak)
            }
            return nil
        }
    }
    
    private var streaksBroken: [StreakInfo] {
        habitManager.habits.compactMap { habit in
            let stats = habitManager.getStatistics(for: habit, in: weekRange)
            if stats.failedDays > 0 {
                return StreakInfo(habit: habit, length: stats.currentStreak)
            }
            return nil
        }
    }
    
    private var skippedHabits: [SkippedHabit] {
        habitManager.habits.compactMap { habit in
            let entries = habitManager.getEntries(for: habit, in: weekRange)
            let skipCount = entries.filter { $0.status == .skipped }.count
            if skipCount > 0 {
                return SkippedHabit(habit: habit, count: skipCount)
            }
            return nil
        }
    }
    
    private var streaksKeptCount: Int {
        streaksKept.count
    }
    
    private var streaksBrokenCount: Int {
        streaksBroken.count
    }
    
    private var dailyData: [DailyData] {
        let calendar = Calendar.current
        var data: [DailyData] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                let totalHabits = habitManager.habits.count
                let completedHabits = habitManager.habits.filter { habit in
                    if let entry = habitManager.getEntry(for: habit, on: date) {
                        return entry.status == .completed
                    }
                    return false
                }.count
                
                let completionRate = totalHabits > 0 ? Double(completedHabits) / Double(totalHabits) * 100 : 0
                
                data.append(DailyData(day: dayName, completionRate: completionRate))
            }
        }
        
        return data
    }
    
    private var weeklyInsights: [WeeklyInsight] {
        var insights: [WeeklyInsight] = []
        
        // Completion rate insight
        if weekCompletionRate >= 80 {
            insights.append(WeeklyInsight(
                type: .success,
                title: "Excellent Week!",
                message: "You completed \(Int(weekCompletionRate))% of your habits this week. Keep up the great work!",
                icon: "star.fill"
            ))
        } else if weekCompletionRate >= 60 {
            insights.append(WeeklyInsight(
                type: .good,
                title: "Good Progress",
                message: "You completed \(Int(weekCompletionRate))% of your habits. Try to improve next week!",
                icon: "thumbsup.fill"
            ))
        } else {
            insights.append(WeeklyInsight(
                type: .warning,
                title: "Room for Improvement",
                message: "You completed \(Int(weekCompletionRate))% of your habits. Focus on consistency!",
                icon: "exclamationmark.triangle.fill"
            ))
        }
        
        // Streak insights
        if streaksKeptCount > 0 {
            insights.append(WeeklyInsight(
                type: .success,
                title: "Streaks Maintained",
                message: "You kept \(streaksKeptCount) habit streak(s) alive this week!",
                icon: "flame.fill"
            ))
        }
        
        if streaksBrokenCount > 0 {
            insights.append(WeeklyInsight(
                type: .warning,
                title: "Streaks Broken",
                message: "\(streaksBrokenCount) habit streak(s) were broken. Don't worry, start fresh!",
                icon: "heart.fill"
            ))
        }
        
        return insights
    }
    
    // MARK: - Actions
    private func previousWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeek) ?? selectedWeek
        }
    }
    
    private func nextWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeek) ?? selectedWeek
        }
    }
}

// MARK: - Supporting Views
struct SummaryCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundGray)
        )
    }
}

struct StreakItemView: View {
    let habit: Habit
    let streakLength: Int
    let isKept: Bool
    
    var body: some View {
        HStack(spacing: 12) {
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("\(streakLength) day streak")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: isKept ? "flame.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(isKept ? .orange : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundGray)
        )
    }
}

struct SkippedHabitView: View {
    let habit: Habit
    let skipCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("Skipped \(skipCount) time\(skipCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "minus.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundGray)
        )
    }
}

struct InsightCardView: View {
    let insight: WeeklyInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(insight.type.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(insight.message)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(insight.type.backgroundColor)
        )
    }
}

// MARK: - Data Models
struct StreakInfo {
    let habit: Habit
    let length: Int
}

struct SkippedHabit {
    let habit: Habit
    let count: Int
}

struct DailyData: Identifiable {
    let id = UUID()
    let day: String
    let completionRate: Double
}

struct WeeklyInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let icon: String
}

enum InsightType {
    case success, good, warning, error
    
    var color: Color {
        switch self {
        case .success: return .green
        case .good: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return .green.opacity(0.1)
        case .good: return .blue.opacity(0.1)
        case .warning: return .orange.opacity(0.1)
        case .error: return .red.opacity(0.1)
        }
    }
}

#Preview {
    WeeklyReportView()
        .environmentObject(HabitManager())
}
