
import SwiftUI
import Charts

struct WeeklyReportView: View {
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date = {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return weekStart
    }()
    @State private var endDate: Date = {
        let calendar = Calendar.current
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        return weekEnd
    }()
    @State private var showingDatePicker = false
    
    private var dateRange: DateInterval {
        DateInterval(start: startDate, end: endDate)
    }
    
    private var canGoToNextWeek: Bool {
        let calendar = Calendar.current
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        let today = calendar.startOfDay(for: Date())
        let nextWeekStartDay = calendar.startOfDay(for: nextWeekStart)
        return nextWeekStartDay <= today
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.background
                    .ignoresSafeArea()
                
                // Subtle gradient overlay for depth
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.background,
                        Color.background.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Week Selector
                        weekSelectorView
                        
                        // Week Summary
                        weekSummaryView
                        
                        // Streaks Kept
                        streaksKeptView
                        
                        // Daily Breakdown
                        dailyBreakdownView
                        
                        // Insights
                        insightsView
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryBlue)
                }
            }
        }
    }
    
    // MARK: - Week Selector
    private var weekSelectorView: some View {
        HStack(spacing: 12) {
            // Previous button
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .primaryBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Date range button
            Button(action: {
                showingDatePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryBlue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weekRangeText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Tap to change")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textSecondary.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.cardBackground.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primaryBlue.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Next button
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canGoToNextWeek ? .white : .gray.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                canGoToNextWeek ?
                                LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: canGoToNextWeek ? .primaryBlue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canGoToNextWeek)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .sheet(isPresented: $showingDatePicker) {
            WeekDatePickerView(startDate: $startDate, endDate: $endDate)
        }
    }
    
    private var weekRangeText: String {
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "MMM d"
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMM d, yyyy"
        return "\(startFormatter.string(from: startDate)) - \(endFormatter.string(from: endDate))"
    }
    
    // MARK: - Week Summary
    private var weekSummaryView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Week Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
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
                
                SummaryCardView(
                    title: "Streaks Kept",
                    value: "\(streaksKeptCount)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                SummaryCardView(
                    title: "Days Active",
                    value: "\(daysActive)",
                    icon: "calendar.badge.checkmark",
                    color: .primaryPurple
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Streaks Kept
    private var streaksKeptView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Streaks Kept")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            if streaksKept.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.textSecondary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "flame")
                            .font(.system(size: 50))
                            .foregroundColor(.textSecondary.opacity(0.6))
                    }
                    
                    Text("No streaks kept this week")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Start building your streaks by completing habits consistently!")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Daily Breakdown
    private var dailyBreakdownView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Daily Breakdown")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Insights
    private var insightsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Weekly Insight")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            if let weeklyInsight = currentWeeklyInsight {
                InsightCardView(insight: weeklyInsight)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Computed Properties
    
    private var daysActive: Int {
        let calendar = Calendar.current
        var activeDays = Set<Date>()
        
        var currentDate = calendar.startOfDay(for: startDate)
        let endDateDay = calendar.startOfDay(for: endDate)
        
        while currentDate <= endDateDay {
            let hasAnyEntry = habitManager.entries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: currentDate)
            }
            if hasAnyEntry {
                activeDays.insert(currentDate)
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return activeDays.count
    }
    
    private var weekCompletionRate: Double {
        guard !habitManager.habits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let daysInRange = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7
        let daysCount = max(daysInRange, 1)
        
        let totalPossibleEntries = habitManager.habits.count * daysCount
        let completedEntries = habitManager.habits.reduce(0) { total, habit in
            let entries = habitManager.getEntries(for: habit, in: dateRange)
            return total + entries.filter { $0.status == .completed }.count
        }
        
        return totalPossibleEntries > 0 ? Double(completedEntries) / Double(totalPossibleEntries) * 100 : 0
    }
    
    private var streaksKept: [StreakInfo] {
        habitManager.habits.compactMap { habit in
            let stats = habitManager.getStatistics(for: habit, in: dateRange)
            if stats.currentStreak > 0 {
                return StreakInfo(habit: habit, length: stats.currentStreak)
            }
            return nil
        }
    }
    
    private var streaksKeptCount: Int {
        streaksKept.count
    }
    
    // MARK: - Weekly Insights
    private static let motivationalInsights: [WeeklyInsight] = [
        WeeklyInsight(
            type: .success,
            title: "Consistency is Key",
            message: "Small daily actions compound into remarkable results. Every habit you complete today is a step toward your best self.",
            icon: "star.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "Progress Over Perfection",
            message: "Don't wait for the perfect moment. Start where you are, use what you have, and do what you can. Progress, not perfection, leads to success.",
            icon: "chart.line.uptrend.xyaxis"
        ),
        WeeklyInsight(
            type: .good,
            title: "Your Future Self Thanks You",
            message: "The habits you build today are gifts to your future self. Every completed habit is an investment in who you're becoming.",
            icon: "gift.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "Momentum Builds Momentum",
            message: "Success breeds success. Each completed habit creates momentum that makes the next one easier. Keep the streak alive!",
            icon: "arrow.triangle.2.circlepath"
        ),
        WeeklyInsight(
            type: .good,
            title: "You Are Stronger Than Your Excuses",
            message: "When motivation fades, discipline takes over. Your commitment to your habits defines your character more than your intentions.",
            icon: "shield.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "One Percent Better Every Day",
            message: "If you improve by just 1% each day, you'll be 37 times better by the end of the year. Small consistent changes create extraordinary results.",
            icon: "arrow.up.circle.fill"
        ),
        WeeklyInsight(
            type: .good,
            title: "Habits Shape Identity",
            message: "You become what you repeatedly do. Your habits are casting votes for the type of person you want to become. Make every day count.",
            icon: "person.fill.checkmark"
        ),
        WeeklyInsight(
            type: .success,
            title: "The Compound Effect",
            message: "Great things come from small beginnings. Your daily habits, no matter how small, compound over time into life-changing results.",
            icon: "sparkles"
        ),
        WeeklyInsight(
            type: .good,
            title: "Discipline is Freedom",
            message: "The freedom to do what you want comes from the discipline to do what you must. Your habits are the bridge between goals and achievement.",
            icon: "lock.open.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "Trust the Process",
            message: "Results take time. Trust that your consistent effort is building something meaningful, even when you can't see it yet.",
            icon: "eye.fill"
        ),
        WeeklyInsight(
            type: .good,
            title: "Your Habits Are Your Superpower",
            message: "While others rely on motivation, you've built discipline. Your habits are your superpower that works even when motivation doesn't.",
            icon: "bolt.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "The Journey Matters",
            message: "Focus on the process, not just the outcome. The person you become while building habits is more valuable than any single goal achieved.",
            icon: "map.fill"
        ),
        WeeklyInsight(
            type: .good,
            title: "Every Expert Was Once a Beginner",
            message: "Mastery comes from consistent practice. Your daily habits are turning you into an expert at living your best life, one day at a time.",
            icon: "graduationcap.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "Your Willpower is Renewable",
            message: "Each completed habit strengthens your willpower muscle. The more you use it, the stronger it becomes. Keep going!",
            icon: "battery.100"
        ),
        WeeklyInsight(
            type: .good,
            title: "Today's Actions Define Tomorrow",
            message: "The future is created by what you do today. Your habits today are shaping your life tomorrow. Make them count!",
            icon: "calendar.badge.clock"
        ),
        WeeklyInsight(
            type: .success,
            title: "Consistency Beats Intensity",
            message: "Showing up every day, even when it's hard, beats sporadic bursts of effort. Your consistent habits are your greatest asset.",
            icon: "clock.fill"
        ),
        WeeklyInsight(
            type: .good,
            title: "You're Building Your Legacy",
            message: "Every habit you complete is a brick in the foundation of your future. You're not just tracking habits—you're building your legacy.",
            icon: "building.columns.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "Your Best Investment is Yourself",
            message: "Time spent building good habits is the best investment you can make. The returns compound for the rest of your life.",
            icon: "dollarsign.circle.fill"
        ),
        WeeklyInsight(
            type: .good,
            title: "Progress is Perfection",
            message: "Don't aim for perfection—aim for progress. Every day you maintain your habits, you're winning. Keep moving forward!",
            icon: "arrow.forward.circle.fill"
        ),
        WeeklyInsight(
            type: .success,
            title: "You Are Capable of Amazing Things",
            message: "Your ability to maintain habits proves you're capable of amazing things. Trust yourself and keep going. You've got this!",
            icon: "hand.raised.fill"
        )
    ]
    
    private var currentWeeklyInsight: WeeklyInsight? {
        // Use the start date's week as a seed to get a consistent random insight per week
        let calendar = Calendar.current
        let weekNumber = calendar.component(.weekOfYear, from: startDate)
        let year = calendar.component(.year, from: startDate)
        
        // Create a unique seed from week number and year
        let seed = weekNumber + (year * 52)
        
        // Use the seed to select an insight (will be the same for the entire week)
        let index = seed % WeeklyReportView.motivationalInsights.count
        return WeeklyReportView.motivationalInsights[index]
    }
    
    private var dailyData: [DailyData] {
        let calendar = Calendar.current
        var data: [DailyData] = []
        
        var currentDate = calendar.startOfDay(for: startDate)
        let endDateDay = calendar.startOfDay(for: endDate)
        
        while currentDate <= endDateDay {
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: currentDate) - 1]
            let dayNumber = calendar.component(.day, from: currentDate)
            let monthAbbr = calendar.shortMonthSymbols[calendar.component(.month, from: currentDate) - 1]
            let displayName = "\(dayName)\n\(monthAbbr) \(dayNumber)"
            
            let totalHabits = habitManager.habits.count
            let completedHabits = habitManager.habits.filter { habit in
                if let entry = habitManager.getEntry(for: habit, on: currentDate) {
                    return entry.status == .completed
                }
                return false
            }.count
            
            let completionRate = totalHabits > 0 ? Double(completedHabits) / Double(totalHabits) * 100 : 0
            
            data.append(DailyData(day: displayName, completionRate: completionRate))
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return data
    }
    
    
    // MARK: - Actions
    private func previousWeek() {
        let calendar = Calendar.current
        let daysInRange = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newEndDate = calendar.date(byAdding: .day, value: -1, to: startDate) {
                if let newStartDate = calendar.date(byAdding: .day, value: -daysInRange, to: newEndDate) {
                    startDate = newStartDate
                    endDate = newEndDate
                }
            }
        }
    }
    
    private func nextWeek() {
        guard canGoToNextWeek else { return }
        
        let calendar = Calendar.current
        let daysInRange = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newStartDate = calendar.date(byAdding: .day, value: 1, to: endDate) {
                if let newEndDate = calendar.date(byAdding: .day, value: daysInRange, to: newStartDate) {
                    let today = calendar.startOfDay(for: Date())
                    let newEndDateDay = calendar.startOfDay(for: newEndDate)
                    
                    // Don't allow going past today
                    if newEndDateDay <= today {
                        startDate = newStartDate
                        endDate = newEndDate
                    } else {
                        // If the range would go past today, cap it at today
                        startDate = newStartDate
                        endDate = today
                    }
                }
            }
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct StreakItemView: View {
    let habit: Habit
    let streakLength: Int
    let isKept: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                (Color(hex: habit.color) ?? .primaryBlue).opacity(0.2),
                                (Color(hex: habit.color) ?? .primaryBlue).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 6) {
                    Image(systemName: isKept ? "flame.fill" : "xmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isKept ? .orange : .red)
                    
                    Text("\(streakLength) day streak")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            (Color(hex: habit.color) ?? .primaryBlue).opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct InsightCardView: View {
    let insight: WeeklyInsight
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                insight.type.color.opacity(0.2),
                                insight.type.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: insight.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(insight.type.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(insight.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(insight.type.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(insight.type.color.opacity(0.2), lineWidth: 1)
                )
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
