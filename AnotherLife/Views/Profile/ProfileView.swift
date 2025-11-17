import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var habitManager: HabitManager
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var showingWeeklyReport = false
    @State private var showingAddHabit = false
    
    // MARK: - Level Calculation Helpers
    private func calculateLevel(from points: Int) -> Int {
        // Level 1: 0-99, Level 2: 100-199, etc.
        return (points / 100) + 1
    }
    
    private func pointsForLevel(_ level: Int) -> Int {
        // Level 1 starts at 0, Level 2 starts at 100, etc.
        return (level - 1) * 100
    }
    
    private func pointsForNextLevel(_ level: Int) -> Int {
        // Points needed for next level
        return level * 100
    }
    
    private func progressToNextLevel(points: Int, level: Int) -> Double {
        let currentLevelStart = pointsForLevel(level)
        let nextLevelStart = pointsForNextLevel(level)
        let pointsInCurrentLevel = points - currentLevelStart
        let pointsNeededForNext = nextLevelStart - currentLevelStart
        
        guard pointsNeededForNext > 0 else { return 1.0 }
        return min(Double(pointsInCurrentLevel) / Double(pointsNeededForNext), 1.0)
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
                        // Profile Header
                        profileHeaderView
                        
                        // Stats Overview
                        statsOverviewView
                        
                        // Weekly Report & Analytics
                        weeklyReportSection
                        
                        // Account Information
                        accountInfoView
                        
                        // App Information
                        appInfoView
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingWeeklyReport) {
            WeeklyReportView()
                .environmentObject(habitManager)
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
    }
    
    // MARK: - Profile Header View
    private var profileHeaderView: some View {
        VStack(spacing: 20) {
            // Profile Picture with enhanced glow
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 140, height: 140)
                    .blur(radius: 12)
                    .opacity(0.3)
                
                // Profile Picture
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .primaryBlue.opacity(0.4), radius: 24, x: 0, y: 12)
                
                if let profileImageURL = authManager.currentUser?.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(spacing: 12) {
                Text(authManager.currentUser?.displayName ?? "Welcome Back!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("@\(authManager.currentUser?.username ?? "user")")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryBlue)
                
                // Level and Points with Progress Bar
                VStack(spacing: 8) {
                    let userPoints = authManager.currentUser?.totalPoints ?? 0
                    let userLevel = calculateLevel(from: userPoints)
                    let progress = progressToNextLevel(points: userPoints, level: userLevel)
                    let pointsToNext = pointsForNextLevel(userLevel) - userPoints
                    
                    HStack(spacing: 12) {
                        // Level Badge
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primaryOrange)
                            
                            Text("Level \(userLevel)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.primaryOrange.opacity(0.2),
                                            Color.primaryYellow.opacity(0.15)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        
                        // Points Display
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primaryOrange)
                            
                            Text("\(userPoints)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("points")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Level Progress Bar
                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.primaryOrange, Color.primaryYellow],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progress, height: 8)
                                    .animation(.easeInOut(duration: 0.5), value: progress)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(pointsToNext) points until Level \(userLevel + 1)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Enhanced Edit Profile Button
            Button(action: { showingEditProfile = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Edit Profile")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        Capsule()
                            .fill(Color.primaryGradient)
                            .shadow(color: .primaryBlue.opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(28)
        .background(
            ZStack {
                // Glass-like background with gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Subtle accent gradient overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryBlue.opacity(0.05),
                                Color.primaryPurple.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(
            color: .black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 10
        )
    }
    
    // MARK: - Stats Overview View
    private var statsOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ProfileStatCard(
                    title: "Total Habits",
                    value: "\(habitManager.habits.count)",
                    icon: "star.fill",
                    color: .primaryBlue
                )
                
                ProfileStatCard(
                    title: "Current Streak",
                    value: "\(longestCurrentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                ProfileStatCard(
                    title: "This Week",
                    value: "\(String(format: "%.0f", weeklyCompletionRate))%",
                    icon: "chart.bar.fill",
                    color: .primaryGreen
                )
                
                ProfileStatCard(
                    title: "Total Days",
                    value: "\(totalDaysTracked)",
                    icon: "calendar",
                    color: .primaryPurple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Weekly Report Section
    private var weeklyReportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Habits Performance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            // Weekly Report Button
            Button(action: { showingWeeklyReport = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.doc.horizontal.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("Weekly Report")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Text("Detailed insights and progress")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .primaryBlue.opacity(0.4), radius: 16, x: 0, y: 8)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quick Analytics Cards
            VStack(spacing: 12) {
                // Completion Rate Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primaryGreen)
                        Text("This Week's Performance")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", weeklyCompletionRate))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (weeklyCompletionRate / 100), height: 10)
                                .animation(.easeInOut(duration: 0.5), value: weeklyCompletionRate)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                
                // Streak Info
                HStack(spacing: 12) {
                    // Current Streak
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "flame.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(longestCurrentStreak)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("Current Streak")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                    )
                    
                    // Total Completed
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primaryBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(totalCompletedThisWeek)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("This Week")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Quick Actions View
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                QuickActionRow(
                    icon: "plus.circle.fill",
                    title: "Add New Habit",
                    subtitle: "Start tracking a new habit",
                    color: .primaryBlue,
                    action: { showingAddHabit = true }
                )
                
                QuickActionRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Weekly Report",
                    subtitle: "Detailed insights and analytics",
                    color: .primaryGreen,
                    action: { showingWeeklyReport = true }
                )
                
                QuickActionRow(
                    icon: "trophy.fill",
                    title: "Challenges",
                    subtitle: "Join or create challenges",
                    color: .orange,
                    action: { }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Account Information View
    private var accountInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showingEditProfile = true
            }) {
                VStack(spacing: 12) {
                    AccountInfoRowDisplay(
                        icon: "person.fill",
                        title: "Username",
                        value: "@\(authManager.currentUser?.username ?? "user")"
                    )
                    
                    AccountInfoRowDisplay(
                        icon: "envelope.fill",
                        title: "Email",
                        value: authManager.currentUser?.email ?? "user@example.com"
                    )
                    
                    AccountInfoRowDisplay(
                        icon: "lock.fill",
                        title: "Password",
                        value: "••••••••"
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Sign Out")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await authManager.signOut()
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - App Info View
    private var appInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("About")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "info.circle",
                    title: "App Version",
                    value: "1.3.3"
                )
                
                InfoRow(
                    icon: "heart.fill",
                    title: "Made with",
                    value: "❤️ for better habits"
                )
                
                InfoRow(
                    icon: "star.fill",
                    title: "Rate App",
                    value: "Tap to rate"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Computed Properties
    private var longestCurrentStreak: Int {
        habitManager.habits.compactMap { habit in
            habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).currentStreak
        }.max() ?? 0
    }
    
    private var weeklyCompletionRate: Double {
        guard !habitManager.habits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        var totalPossible = 0
        var totalCompleted = 0
        
        for habit in habitManager.habits {
            let entries = habitManager.entries.filter { entry in
                entry.habitId == habit.id &&
                entry.date >= weekStart &&
                entry.date < weekEnd
            }
            
            let daysPerWeek: Int
            switch habit.frequency {
            case .daily:
                daysPerWeek = 7
            case .weekly:
                daysPerWeek = 1
            case .custom:
                daysPerWeek = habit.customDays.count
            }
            
            totalPossible += daysPerWeek
            totalCompleted += entries.filter { $0.status == .completed }.count
        }
        
        return totalPossible > 0 ? Double(totalCompleted) / Double(totalPossible) * 100 : 0
    }
    
    private var totalDaysTracked: Int {
        let uniqueDates = Set(habitManager.entries.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDates.count
    }
    
    private var totalCompletedThisWeek: Int {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        var totalCompleted = 0
        
        for habit in habitManager.habits {
            let entries = habitManager.entries.filter { entry in
                entry.habitId == habit.id &&
                entry.date >= weekStart &&
                entry.date < weekEnd
            }
            
            totalCompleted += entries.filter { $0.status == .completed }.count
        }
        
        return totalCompleted
    }
}

// MARK: - Quick Action Row
struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
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
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBackground.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primaryBlue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Account Info Row Display (without arrow)
struct AccountInfoRowDisplay: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primaryBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var displayName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingChangePassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChangingPassword = false
    @State private var passwordChangeError: String?
    @State private var showingPasswordChangeSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("PROFILE INFORMATION") {
                    HStack {
                        Text("Display Name")
                        Spacer()
                        TextField("Enter your name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Username")
                        Spacer()
                        TextField("Enter username", text: $username)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Change Password Button
                Section {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingChangePassword.toggle()
                        }
                    }) {
                        HStack {
                            Text("Change Password")
                                .foregroundColor(.primaryBlue)
                            Spacer()
                            Image(systemName: showingChangePassword ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.primaryBlue)
                        }
                    }
                }
                
                // Change Password Section
                if showingChangePassword {
                    Section("CHANGE PASSWORD") {
                        SecureField("Current Password", text: $currentPassword)
                        
                        SecureField("New Password", text: $newPassword)
                        
                        SecureField("Confirm New Password", text: $confirmPassword)
                        
                        if let passwordChangeError = passwordChangeError {
                            Text(passwordChangeError)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: {
                            changePassword()
                        }) {
                            HStack {
                                Spacer()
                                if isChangingPassword {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Update Password")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadUserData()
            }
            .alert("Password Changed", isPresented: $showingPasswordChangeSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been successfully changed.")
            }
        }
    }
    
    private func loadUserData() {
        if let user = authManager.currentUser {
            displayName = user.displayName
            username = user.username
            email = user.email
        }
    }
    
    private func saveProfile() {
        guard !displayName.isEmpty && !username.isEmpty else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            await authManager.updateUserProfile(username: username, displayName: displayName)
            
            await MainActor.run {
                isLoading = false
                if authManager.errorMessage == nil {
                    dismiss()
                } else {
                    errorMessage = authManager.errorMessage
                }
            }
        }
    }
    
    private func changePassword() {
        guard !newPassword.isEmpty else {
            passwordChangeError = "Please enter a new password"
            return
        }
        
        guard newPassword.count >= 6 else {
            passwordChangeError = "Password must be at least 6 characters"
            return
        }
        
        guard newPassword == confirmPassword else {
            passwordChangeError = "New passwords do not match"
            return
        }
        
        passwordChangeError = nil
        isChangingPassword = true
        
        Task {
            await authManager.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            
            await MainActor.run {
                isChangingPassword = false
                if authManager.errorMessage == nil {
                    // Success - clear fields and hide section
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    withAnimation {
                        showingChangePassword = false
                    }
                    
                    // Show success message
                    passwordChangeError = nil
                    showingPasswordChangeSuccess = true
                } else {
                    passwordChangeError = authManager.errorMessage
                }
            }
        }
    }
}

// MARK: - Profile Stat Card
struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(HabitManager())
}
