
import SwiftUI
import Charts

struct AnalyticsView: View {
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
                    
                    // Overview Cards
                    overviewCardsView
                    
                    // Overall Progress
                    overallProgressView
                    
                    // Habits Performance
//                    habitsPerformanceView
                    
                    // Completion Rate Over Time
                    completionRateChart
                    
                    // Habit Streak Graphs
                    habitStreakGraphsView
                    
                    // Correlation Analysis
//                    correlationAnalysisView
                    
                    // Weekly Report Button
                    weeklyReportButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingWeeklyReport) {
            WeeklyReportView()
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Range")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            // Improved segmented control style selector
            VStack(spacing: 8) {
                // First row: Week and Month
                HStack(spacing: 8) {
                    TimeRangeButton(
                        range: .week,
                        isSelected: selectedTimeRange == .week,
                        action: { selectedTimeRange = .week }
                    )
                    
                    TimeRangeButton(
                        range: .month,
                        isSelected: selectedTimeRange == .month,
                        action: { selectedTimeRange = .month }
                    )
                }
                
                // Second row: 3 Months and Year
                HStack(spacing: 8) {
                    TimeRangeButton(
                        range: .threeMonths,
                        isSelected: selectedTimeRange == .threeMonths,
                        action: { selectedTimeRange = .threeMonths }
                    )
                    
                    TimeRangeButton(
                        range: .year,
                        isSelected: selectedTimeRange == .year,
                        action: { selectedTimeRange = .year }
                    )
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
    
    // MARK: - Overview Cards
    private var overviewCardsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
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
                    title: "Success Rate",
                    value: "\(Int(overallSuccessRate))",
                    subtitle: "%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
                
                StreakCardView(
                    title: "Total Habits",
                    value: "\(habitManager.habits.count)",
                    subtitle: "active",
                    icon: "star.fill",
                    color: .primaryGreen
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
                
                // Total Completed
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Total Completed")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(totalCompletedEntries)")
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
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeRange.days / 7))) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
    
    // MARK: - Habit Streak Graphs
    private var habitStreakGraphsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habit Streak Patterns")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if habitManager.habits.isEmpty {
                emptyHabitsView
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(habitManager.habits) { habit in
                        ImprovedHabitStreakView(habit: habit, timeRange: selectedTimeRange)
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
    
    private var totalCompletedEntries: Int {
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date(),
            end: Date()
        )
        
        return habitManager.habits.reduce(0) { total, habit in
            let entries = habitManager.getEntries(for: habit, in: dateRange)
            return total + entries.filter { $0.status == .completed }.count
        }
    }
    
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

// MARK: - Time Range Button
struct TimeRangeButton: View {
    let range: AnalyticsView.TimeRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(range.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primaryBlue : Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.primaryBlue.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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
                .fill(Color.background)
        )
    }
}

// MARK: - Habit Performance Row
struct HabitPerformanceRow: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    let timeRange: AnalyticsView.TimeRange
    
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
                .fill(Color.background)
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

// MARK: - Habit Streak Graph View
struct HabitStreakGraphView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    let timeRange: AnalyticsView.TimeRange
    
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
                if streakData.count >= 2 {
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
                    // Fallback for insufficient data
                    HStack(spacing: 2) {
                        ForEach(streakData, id: \.date) { data in
                            Rectangle()
                                .fill(data.status == 1 ? (Color(hex: habit.color) ?? .primaryBlue) : Color.gray.opacity(0.3))
                                .frame(width: 4, height: 20)
                        }
                    }
                    .frame(height: 60)
                }
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
                .fill(Color.background)
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
        
        // Ensure we always have at least 2 data points to prevent chart crashes
        if data.count < 2 {
            let today = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            data = [
                StreakData(date: yesterday, status: 0),
                StreakData(date: today, status: 0)
            ]
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
                .fill(Color.background)
        )
    }
}

// MARK: - Data Models
struct StreakData: Identifiable {
    let id = UUID()
    let date: Date
    let status: Int // 1 = completed, 0 = not completed
}

struct CompletionData: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
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

// MARK: - Improved Habit Streak View
struct ImprovedHabitStreakView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    let timeRange: AnalyticsView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with habit info
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
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(completionRate, specifier: "%.0f")%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBlue)
                    
                    Text("completion")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Improved visual representation
            VStack(spacing: 8) {
                // Date labels
                HStack {
                    Text("Start")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                // Visual streak representation
                if #available(iOS 16.0, *) {
                    Chart(streakData) { data in
                        BarMark(
                            x: .value("Date", data.date),
                            y: .value("Status", data.status)
                        )
                        .foregroundStyle(data.status == 1 ? (Color(hex: habit.color) ?? .primaryBlue) : Color.gray.opacity(0.3))
                    }
                    .frame(height: 40)
                    .chartYAxis(.hidden)
                    .chartXAxis(.hidden)
                } else {
                    // Fallback for iOS < 16
                    HStack(spacing: 2) {
                        ForEach(streakData, id: \.date) { data in
                            VStack(spacing: 2) {
                                Rectangle()
                                    .fill(data.status == 1 ? (Color(hex: habit.color) ?? .primaryBlue) : Color.gray.opacity(0.3))
                                    .frame(width: 6, height: 20)
                                
                                Text(dayLabel(for: data.date))
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .frame(height: 40)
                }
                
                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: habit.color) ?? .primaryBlue)
                            .frame(width: 8, height: 8)
                        Text("Completed")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text("Missed")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.background)
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
    
    private var completionRate: Double {
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date(),
            end: Date()
        )
        
        let stats = habitManager.getStatistics(for: habit, in: dateRange)
        return stats.completionRate
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
        
        // Ensure we always have at least 2 data points to prevent chart crashes
        if data.count < 2 {
            let today = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            data = [
                StreakData(date: yesterday, status: 0),
                StreakData(date: today, status: 0)
            ]
        }
        
        return data
    }
    
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "T"
        } else if calendar.isDateInYesterday(date) {
            return "Y"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(HabitManager())
}
