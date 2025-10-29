

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var habitManager: HabitManager
    @StateObject private var authManager = AuthManager()
    @StateObject private var challengeManager = ChallengeManager()
    @State private var selectedTab = 0
    @State private var showWelcomeMessage = false
    @State private var justAuthenticated = false
    @State private var splashIconScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            if authManager.isInitializing {
                // Splash Screen / Loading State
                splashScreenView
            } else {
                Group {
                    if authManager.isAuthenticated {
                        // Main App
                        TabView(selection: $selectedTab) {
                    // Main Habit Tracking Tab
                    MainHabitView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Habits")
                        }
                        .tag(0)
                    
                    // Notes Tab (Replaced Analytics)
                    NotesTabView()
                        .tabItem {
                            Image(systemName: "note.text")
                            Text("Notes")
                        }
                        .tag(1)
                    
                    // Challenges Tab
                    ChallengesView()
                        .tabItem {
                            Image(systemName: "trophy.fill")
                            Text("Challenges")
                        }
                        .tag(2)
                    
                    // Profile Tab
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(3)
                }
                    .preferredColorScheme(habitManager.theme == .light ? .light : habitManager.theme == .dark ? .dark : nil)
                    .environmentObject(authManager)
                    .environmentObject(challengeManager)
                    .opacity(showWelcomeMessage ? 0.3 : 1.0)
                    .onAppear {
                        // Set up real-time listeners when user is authenticated
                        if authManager.isAuthenticated {
                            challengeManager.setAuthManager(authManager)
                            challengeManager.setupRealTimeListeners()
                        }
                    }
                    .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                        if isAuthenticated {
                            // Set up listeners when user becomes authenticated
                            challengeManager.setAuthManager(authManager)
                            challengeManager.setupRealTimeListeners()
                            
                            // Show welcome message
                            justAuthenticated = true
                            withAnimation(.easeIn(duration: 0.3)) {
                                showWelcomeMessage = true
                            }
                            
                            // Hide welcome message after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showWelcomeMessage = false
                                }
                            }
                        } else {
                            // Clean up data and listeners when user logs out
                            challengeManager.clearAllData()
                            justAuthenticated = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Welcome Landing Page (first time) or Auth
                    WelcomeLandingView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                }
                }
                .animation(.easeInOut(duration: 0.4), value: authManager.isAuthenticated)
                
                // Welcome Message Overlay
                if showWelcomeMessage {
                    welcomeMessageView
                }
            }
        }
    }
    
    // MARK: - Splash Screen View
    private var splashScreenView: some View {
        ZStack {
            // Modern background with subtle gradient
            Color.background
                .ignoresSafeArea()
            
            // Animated background elements
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.primaryBlue.opacity(0.05))
                    .frame(width: 200 + CGFloat(index * 100))
                    .offset(
                        x: CGFloat.random(in: -100...100),
                        y: CGFloat.random(in: -200...200)
                    )
                    .animation(
                        .easeInOut(duration: 3.0 + Double(index))
                        .repeatForever(autoreverses: true),
                        value: splashIconScale
                    )
            }
            
            VStack(spacing: 40) {
                // Modern app icon with sophisticated animation
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            Color.primaryGradient,
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .opacity(0.6)
                        .scaleEffect(splashIconScale * 1.2)
                    
                    // Main icon container
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 120, height: 120)
                        .shadow(
                            color: .primaryBlue.opacity(0.3),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    
                    // Icon
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(splashIconScale)
                }
                .scaleEffect(splashIconScale)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        splashIconScale = 1.05
                    }
                }
                
                VStack(spacing: 16) {
                    Text("AnotherLife")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Building better habits, one day at a time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                    
                    // Modern loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.primaryBlue)
                                .frame(width: 8, height: 8)
                                .scaleEffect(splashIconScale)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: splashIconScale
                                )
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Welcome Message View
    private var welcomeMessageView: some View {
        VStack(spacing: 24) {
            // Modern success animation
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(Color.successGradient, lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .opacity(0.6)
                    .scaleEffect(showWelcomeMessage ? 1.2 : 0.8)
                    .animation(
                        .easeOut(duration: 0.8)
                        .delay(0.2),
                        value: showWelcomeMessage
                    )
                
                // Main success circle
                Circle()
                    .fill(Color.successGradient)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: .primaryGreen.opacity(0.3),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
                
                // Success icon
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .scaleEffect(showWelcomeMessage ? 1.0 : 0.5)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                        .delay(0.3),
                        value: showWelcomeMessage
                    )
            }
            .scaleEffect(showWelcomeMessage ? 1.0 : 0.5)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.6),
                value: showWelcomeMessage
            )
            
            VStack(spacing: 12) {
                Text("Welcome back!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("\(authManager.currentUser?.displayName ?? "User")")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryBlue)
                
                Text("Ready to build amazing habits today? 🚀")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 25,
                    x: 0,
                    y: 12
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.separator, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 32)
        .scaleEffect(showWelcomeMessage ? 1.0 : 0.8)
        .opacity(showWelcomeMessage ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8),
            value: showWelcomeMessage
        )
        .transition(.scale.combined(with: .opacity))
        .zIndex(1000)
    }
}

// MARK: - Main Habit View
struct MainHabitView: View {
    @EnvironmentObject var habitManager: HabitManager
    @State private var showingAddHabit = false
    @State private var showingSettings = false
    
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
                    VStack(spacing: 20) {
                        // Habits List
                        habitsListView
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
//            .navigationTitle("AnotherLife")
//            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Progress")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(selectedDateText)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Overall completion rate
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(overallCompletionRate, specifier: "%.0f")%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(overallCompletionRate >= 80 ? .primaryGreen : .primaryBlue)
                
                Text("Complete")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Date Picker View
    private var datePickerView: some View {
        VStack(spacing: 16) {
            // Date Navigation
            HStack {
                Button(action: goToPreviousDay) {
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
                    Text(selectedDateText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(selectedDateSubtext)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: goToNextDay) {
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
            
            // Today Button
            if !Calendar.current.isDateInToday(habitManager.selectedDate) {
                Button(action: goToToday) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("Go to Today")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
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
    
    // MARK: - Computed Properties
    
    private var completionRate: Double {
        guard !habitManager.habits.isEmpty else { return 0 }
        
        let totalHabits = habitManager.habits.count
        let completedHabits = habitManager.habits.filter { habit in
            // Check if the day is fully completed according to the habit's criteria
            return habitManager.isDayComplete(for: habit, on: habitManager.selectedDate)
        }
        
        return Double(completedHabits.count) / Double(totalHabits) * 100
    }
    
    private var maxStreak: Int {
        habitManager.habits.compactMap { habit in
            habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).currentStreak
        }.max() ?? 0
    }
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    // MARK: - Habits List View
    private var habitsListView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Premium Header Section
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Habits")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(todayDateString)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            
            if habitManager.habits.isEmpty {
                emptyStateView
            } else {
                // Middle Section with Summary Stats and Add Habit Button
                middleSectionView
                
                // Premium Habits List with enhanced spacing
                LazyVStack(spacing: 20) {
                    ForEach(habitManager.habits) { habit in
                        HabitGridView(habit: habit)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .bottom))
                            ))
                            .id(habit.id)
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: habitManager.habits.count)
            }
        }
    }
    
    // MARK: - Middle Section View
    private var middleSectionView: some View {
        VStack(spacing: 16) {
            // Summary Stats Row
            HStack(spacing: 16) {
                // Total Habits Stat
                StatCardView(
                    title: "Total Habits",
                    value: "\(habitManager.habits.count)",
                    icon: "star.circle.fill",
                    color: .primaryBlue
                )
                
                // Completion Rate Stat
                StatCardView(
                    title: "Today's Progress",
                    value: "\(Int(completionRate))%",
                    icon: "chart.bar.fill",
                    color: .primaryGreen
                )
                
                // Current Streak Stat
                StatCardView(
                    title: "Best Streak",
                    value: "\(maxStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            // Add Habit Button
            Button(action: { showingAddHabit = true }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryBlue.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryBlue)
                    }
                    
                    Text("Add New Habit")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryBlue)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryBlue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primaryBlue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Stat Card View
    private struct StatCardView: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 60) // Fixed height for consistency
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryBlue)
            }
            
            VStack(spacing: 12) {
                Text("Start Your Journey")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Build better habits, one day at a time.\nAdd your first habit to get started.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: { showingAddHabit = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Habit")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.primaryBlue)
                        .shadow(color: .primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Quick Stats View
    private var quickStatsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Quick Stats")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatCardView(
                    title: "Current Streak",
                    value: "\(longestCurrentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCardView(
                    title: "Total Habits",
                    value: "\(habitManager.habits.count)",
                    icon: "star.fill",
                    color: .primaryBlue
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var selectedDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: habitManager.selectedDate)
    }
    
    private var selectedDateSubtext: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: habitManager.selectedDate)
    }
    
    private var overallCompletionRate: Double {
        guard !habitManager.habits.isEmpty else { return 0 }
        
        let totalHabits = habitManager.habits.count
        let completedHabits = habitManager.habits.filter { habit in
            // Check if the day is fully completed according to the habit's criteria
            return habitManager.isDayComplete(for: habit, on: habitManager.selectedDate)
        }.count
        
        return Double(completedHabits) / Double(totalHabits) * 100
    }
    
    private var longestCurrentStreak: Int {
        habitManager.habits.compactMap { habit in
            habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).currentStreak
        }.max() ?? 0
    }
    
    // MARK: - Date Navigation Methods
    private func goToPreviousDay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            habitManager.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: habitManager.selectedDate) ?? habitManager.selectedDate
        }
    }
    
    private func goToNextDay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            habitManager.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: habitManager.selectedDate) ?? habitManager.selectedDate
        }
    }
    
    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            habitManager.selectedDate = Date()
        }
    }
}

// MARK: - Habit Card View
struct HabitCardView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @State private var showingNotes = false
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var progressAnimation: Double = 0
    @State private var showingDeleteConfirmation = false
    @State private var deleteOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Delete Button Background
            HStack {
                Spacer()
                
                Button(action: { showingDeleteConfirmation = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Delete")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(deleteOffset < -50 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: deleteOffset)
            }
            
            // Main Card Content
            VStack(spacing: 16) {
                // Header with Icon and Info
                HStack(spacing: 16) {
                    // Habit Icon with Progress Ring
                    habitIconView
                    
                    // Habit Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(habit.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        if !habit.description.isEmpty {
                            Text(habit.description)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .lineLimit(2)
                        }
                        
                        // Tags
                        HStack(spacing: 8) {
                            Text(habit.isPositive ? "Positive" : "Negative")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(habit.isPositive ? Color.primaryGreen.opacity(0.1) : Color.primaryRed.opacity(0.1))
                                )
                                .foregroundColor(habit.isPositive ? .primaryGreen : .primaryRed)
                        }
                    }
                    
                    Spacer()
                }
                
                // Swipeable Status Selection
                VStack(spacing: 12) {
                    Text("Swipe or tap to log")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    // Swipeable Card
                    swipeableCardView
                    
                    // Quick Action Buttons
                    HStack(spacing: 16) {
                        ForEach(HabitStatus.allCases, id: \.self) { status in
                            Button(action: {
                                updateStatus(status)
                            }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(currentStatus == status ? status.color : status.color.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: status.icon)
                                            .font(.title3)
                                            .foregroundColor(currentStatus == status ? .white : status.color)
                                    }
                                    
                                    Text(status.rawValue.capitalized)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(currentStatus == status ? status.color : .textSecondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(currentStatus == status ? 1.1 : 1.0)
                        }
                    }
                }
                
                // Notes Button
                if currentStatus != nil {
                    Button(action: { showingNotes = true }) {
                        HStack {
                            Image(systemName: "note.text")
                            Text("Add Notes")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
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
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .offset(x: deleteOffset)
            .gesture(deleteSwipeGesture)
        }
        .sheet(isPresented: $showingNotes) {
            NoteEditorView(note: nil, selectedHabit: habit)
                .environmentObject(habitManager)
        }
        .alert("Delete Habit", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    deleteOffset = 0
                }
            }
            Button("Delete", role: .destructive) {
                habitManager.deleteHabit(habit)
            }
        } message: {
            Text("Are you sure you want to delete '\(habit.title)'? This action cannot be undone.")
        }
        .onAppear {
            updateProgressAnimation()
        }
        .onChange(of: currentStatus) {
            updateProgressAnimation()
        }
    }
    
    private var currentStatus: HabitStatus? {
        habitManager.getEntry(for: habit, on: habitManager.selectedDate)?.status
    }
    
    private var habitIconView: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(habitColor.opacity(0.15))
                .frame(width: 60, height: 60)
            
            // Progress ring background
            Circle()
                .stroke(habitColor.opacity(0.2), lineWidth: 4)
                .frame(width: 70, height: 70)
            
            // Progress ring fill
            Circle()
                .trim(from: 0, to: progressAnimation)
                .stroke(habitColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progressAnimation)
            
            // Icon
            Image(systemName: habit.icon)
                .font(.title)
                .foregroundColor(habitColor)
        }
    }
    
    private var habitColor: Color {
        Color(hex: habit.color) ?? .primaryBlue
    }
    
    private var swipeableCardView: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.background)
                .frame(height: 80)
            
            // Swipeable Content
            HStack(spacing: 0) {
                // Left side - Skip
                skipButtonView
                
                // Center - Current Status
                currentStatusView
                
                // Right side - Done
                doneButtonView
            }
            .offset(x: dragOffset)
                                .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Only respond to horizontal swipes within the card bounds
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    dragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if value.translation.width > 100 {
                                        updateStatus(.completed)
                                        dragOffset = 0
                                    } else if value.translation.width < -100 {
                                        updateStatus(.skipped)
                                        dragOffset = 0
                                    } else {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .onTapGesture {
                        cycleStatus()
                    }
        }
    }
    
    private var skipButtonView: some View {
        VStack {
            Image(systemName: "minus.circle.fill")
                .font(.title)
                .foregroundColor(.blue)
            Text("Skip")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .opacity(dragOffset < -50 ? 1.0 : 0.3)
    }
    
    private var currentStatusView: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(currentStatus?.color ?? Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: currentStatus?.icon ?? "circle")
                    .font(.title2)
                    .foregroundColor(currentStatus == nil ? .gray : .white)
            }
            
            Text(currentStatus?.rawValue.capitalized ?? "Not Logged")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(currentStatus == nil ? .gray : currentStatus?.color)
        }
        .scaleEffect(isAnimating ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
    }
    
    private var doneButtonView: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(.green)
            Text("Done")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .opacity(dragOffset > 50 ? 1.0 : 0.3)
    }
    
    
    private var deleteSwipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow left swipe for delete
                if value.translation.width < 0 {
                    deleteOffset = max(value.translation.width, -100)
                }
            }
            .onEnded { value in
                // Use a more stable animation
                withAnimation(.easeInOut(duration: 0.25)) {
                    if value.translation.width < -80 {
                        // Show delete button
                        deleteOffset = -80
                    } else {
                        // Snap back
                        deleteOffset = 0
                    }
                }
            }
    }
    
    private func updateStatus(_ status: HabitStatus) {
        // Update data first
        habitManager.updateEntry(for: habit, status: status)
        
        // Then animate
        withAnimation(.easeInOut(duration: 0.2)) {
            isAnimating = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isAnimating = false
            }
        }
    }
    
    private func cycleStatus() {
        let statuses: [HabitStatus] = [.completed, .failed, .skipped]
        guard let current = currentStatus,
              let currentIndex = statuses.firstIndex(of: current) else {
            updateStatus(.completed)
            return
        }
        
        let nextIndex = (currentIndex + 1) % statuses.count
        updateStatus(statuses[nextIndex])
    }
    
    private func updateProgressAnimation() {
        let progress: Double
        switch currentStatus {
        case .completed:
            progress = 1.0
        case .failed:
            progress = 0.3
        case .skipped:
            progress = 0.6
        case .none:
            progress = 0.0
        }
        
        // Use a more stable animation
        withAnimation(.easeInOut(duration: 0.5)) {
            progressAnimation = progress
        }
    }
}

// MARK: - Stat Card View
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        // Handle named colors first
        switch hex.lowercased() {
        case "blue": self = .blue
        case "green": self = .green
        case "red": self = .red
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink": self = .pink
        case "teal": self = .teal
        case "indigo": self = .indigo
        case "mint": self = .mint
        case "yellow": self = .yellow
        case "brown": self = .brown
        case "gray": self = .gray
        case "cyan": self = .cyan
        case "magenta": self = .habitPink
        case "lime": self = .habitMint
        case "navy": self = .habitIndigo
        default:
            // Handle hex colors
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            let a, r, g, b: UInt64
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                return nil
            }
            
            self.init(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue:  Double(b) / 255,
                opacity: Double(a) / 255
            )
        }
    }
}

// MARK: - Habit Grid View
struct HabitGridView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @State private var showingCompletionDetail = false
    @State private var isGlowing = false
    @State private var animatedProgress: Double = 0
    @State private var animatedStreak: Int = 0
    
    // Dynamic grid sizing based on habit duration
    private var gridLayout: GridLayout {
        GridLayout.calculateForHabit(habit)
    }
    
    private var daysToShow: Int {
        gridLayout.totalCells
    }
    
    private var columns: Int {
        gridLayout.columns
    }
    
    private var rows: Int {
        gridLayout.rows
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Premium Header Section
            HStack(spacing: 16) {
                // Enhanced Habit Icon with Glow Effect
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(habitColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .blur(radius: 8)
                        .opacity(isGlowing ? 0.8 : 0.3)
                        .animation(.easeInOut(duration: 0.6), value: isGlowing)
                    
                    // Main icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        habitColor.opacity(0.2),
                                        habitColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Circle()
                            .stroke(habitColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(habitColor)
                    }
                }
                
                // Habit Info Section
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    if !habit.description.isEmpty {
                        Text(habit.description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Premium Tags
                    HStack(spacing: 8) {
                        // Positive/Negative tag
                        Text(habit.isPositive ? "Positive" : "Negative")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(habit.isPositive ? Color.primaryGreen.opacity(0.15) : Color.primaryRed.opacity(0.15))
                            )
                            .foregroundColor(habit.isPositive ? .primaryGreen : .primaryRed)
                        
                        // Multi-completion tag
                        if habit.targetCompletionsPerDay > 1 {
                            Text("\(habit.targetCompletionsPerDay)x/day")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Enhanced Completion Button (visual indicator only)
                completionButton
                    .allowsHitTesting(false) // Make button non-interactive, whole cell handles taps
            }
            
            // Premium Stats Section
            HStack(spacing: 20) {
                // Animated Progress (if applicable)
                if !habit.duration.isUnlimited {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(habitColor)
                                .font(.caption)
                            Text("Progress")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Text("\(Int(animatedProgress))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(habitColor)
                            .animation(.easeOut(duration: 1.0), value: animatedProgress)
                    }
                }
                
                Spacer()
                
                // Animated Streak with Flickering Fire
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .scaleEffect(1.0)
                        
                        Text("Streak")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Text("\(animatedStreak)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .animation(.easeOut(duration: 1.0), value: animatedStreak)
                }
            }
            
            // Premium Calendar Grid
            VStack(spacing: 8) {
                // Grid Layout with smooth animations
                VStack(spacing: 6) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                if index < dayTiles.count {
                                    DayTileView(
                                        dayTile: dayTiles[index],
                                        habitColor: habitColor,
                                        habit: habit,
                                        onTap: { 
                                            // Disabled: No direct tap-to-complete on day tiles
                                        },
                                        onLongPress: habit.targetCompletionsPerDay > 1 ? {
                                            showingCompletionDetail = true
                                        } : nil
                                    )
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                                } else {
                                    // Empty space for incomplete rows
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 28, height: 28)
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: dayTiles.count)
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Glass-like background with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cardBackground,
                                Color.cardBackground.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle border with habit color accent
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                habitColor.opacity(0.3),
                                habitColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(
            color: habitColor.opacity(0.2),
            radius: 12,
            x: 0,
            y: 6
        )
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            // Single tap: mark as completed for today
            toggleTodayStatus()
        }
        .onTapGesture(count: 2) {
            // Double tap: undo last completion
            undoLastCompletion()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press: show completion detail for multi-completion habits
            if habit.targetCompletionsPerDay > 1 {
                showingCompletionDetail = true
            }
        }
        .onAppear {
            // Animate progress and streak on appear
            let progress = habitManager.getCompletionProgress(for: habit) * 100
            let streak = currentStreak
            
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
                animatedStreak = streak
            }
        }
        .onChange(of: currentStreak) { newValue in
            // Animate streak changes
            withAnimation(.easeOut(duration: 0.8)) {
                animatedStreak = newValue
            }
        }
        .onChange(of: habitManager.entries.count) { _ in
            // Update progress when entries change (completion toggled)
            let progress = habitManager.getCompletionProgress(for: habit) * 100
            if abs(animatedProgress - progress) > 0.1 {
                withAnimation(.easeOut(duration: 0.3)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: todayStatus) { _ in
            // Immediately update progress when today's status changes (faster response)
            let progress = habitManager.getCompletionProgress(for: habit) * 100
            if abs(animatedProgress - progress) > 0.1 {
                animatedProgress = progress // Update immediately without animation delay
            }
        }
        .sheet(isPresented: $showingCompletionDetail) {
            CompletionDetailView(habit: habit, date: Date())
                .environmentObject(habitManager)
        }
    }
    
    private var habitColor: Color {
        Color(hex: habit.color) ?? .primaryBlue
    }
    
    private var habitIconView: some View {
        ZStack {
            Circle()
                .fill(habitColor.opacity(0.15))
                .frame(width: 40, height: 40)
            
            Image(systemName: habit.icon)
                .font(.title3)
                .foregroundColor(habitColor)
        }
    }
    
    private var completionButton: some View {
        ZStack {
            if habit.targetCompletionsPerDay > 1 {
                // Multi-completion habit - show progress ring
                let progress = habitManager.getCompletionProgress(for: habit, on: Date())
                
                // Background circle
                Circle()
                    .fill(habitColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                // Progress ring
                Circle()
                    .stroke(habitColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: progress.percentage)
                    .stroke(habitColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress.percentage)
                
                // Center content
                VStack(spacing: 1) {
                    if progress.completed == progress.target && progress.target > 0 {
                        // Fully completed
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        // Show progress
                        Text("\(progress.completed)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(habitColor)
                    }
                    
                    if progress.target > 1 {
                        Text("\(progress.target)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(habitColor.opacity(0.7))
                    }
                    
                    // Undo hint for completed habits
                    if progress.completed > 0 {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.system(size: 8))
                            .foregroundColor(habitColor.opacity(0.5))
                    }
                }
            } else {
                // Single completion habit - original design
                Circle()
                    .fill(todayStatus == .completed ? .primaryGreen : habitColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .shadow(color: todayStatus == .completed ? .primaryGreen.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                
                VStack(spacing: 1) {
                    Image(systemName: todayStatus == .completed ? "checkmark" : "circle")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(todayStatus == .completed ? .white : habitColor)
                    
                    // Undo hint for completed habits
                    if todayStatus == .completed {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .scaleEffect(habit.targetCompletionsPerDay > 1 ? 1.0 : (todayStatus == .completed ? 1.0 : 0.9))
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: todayStatus)
    }
    
    private var todayStatus: HabitStatus? {
        habitManager.getEntry(for: habit, on: Date())?.status
    }
    
    private var dayTiles: [DayTile] {
        // Calculate tiles without modifying state
        let calendar = Calendar.current
        let today = Date()
        var tiles: [DayTile] = []
        
        // Calculate the start date based on habit duration
        let startDate: Date
        if !habit.duration.isUnlimited {
            startDate = habit.startDate
        } else {
            // For unlimited habits, show last 50 days from today
            startDate = calendar.date(byAdding: .day, value: -49, to: today) ?? today
        }
        
        // Generate tiles from start date to today (or habit end date)
        let endDate = habit.endDate ?? today
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        // For fixed duration habits, ensure we show exactly the total days
        let daysToGenerate = habit.duration.isUnlimited ? min(totalDays, daysToShow) : min(totalDays + 1, daysToShow)
        
        for i in 0..<daysToGenerate {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            let entry = habitManager.getEntry(for: habit, on: date)
            let isToday = calendar.isDateInToday(date)
            
            tiles.append(DayTile(
                date: date,
                status: entry?.status,
                isToday: isToday,
                dayNumber: calendar.component(.day, from: date)
            ))
        }
        
        return tiles
    }
    
    private var currentStreak: Int {
        habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).currentStreak
    }
    
    
    private func updateStatus(for date: Date) {
        // For multi-completion habits, add a completion instead of cycling status
        if habit.targetCompletionsPerDay > 1 {
            let progress = habitManager.getCompletionProgress(for: habit, on: date)
            
            if progress.completed < progress.target {
                // Add a completion
                habitManager.addCompletion(for: habit, on: date)
            } else {
                // Remove the last completion
                let completions = habitManager.getCompletions(for: habit, on: date)
                if let lastCompletion = completions.last {
                    habitManager.removeCompletion(for: habit, completionId: lastCompletion.id, on: date)
                }
            }
        } else {
            // Single completion habits - cycle through statuses
            let currentEntry = habitManager.getEntry(for: habit, on: date)
            let currentStatus = currentEntry?.status
            
            let nextStatus: HabitStatus?
            switch currentStatus {
            case .none:
                nextStatus = .completed
            case .completed:
                nextStatus = .failed
            case .failed:
                nextStatus = .skipped
            case .skipped:
                nextStatus = nil
            default:
                nextStatus = .completed
            }
            
            if let status = nextStatus {
                habitManager.updateEntry(for: habit, status: status, on: date)
            } else {
                // Remove entry (set to none)
                if let index = habitManager.entries.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    habitManager.entries.remove(at: index)
                    habitManager.saveEntries()
                }
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func toggleTodayStatus() {
        let today = Date()
        
        // Trigger glow effect
        withAnimation(.easeInOut(duration: 0.3)) {
            isGlowing = true
        }
        
        // Reset glow after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGlowing = false
            }
        }
        
        // For multi-completion habits, add a completion
        if habit.targetCompletionsPerDay > 1 {
            let progress = habitManager.getCompletionProgress(for: habit, on: today)
            
            if progress.completed < progress.target {
                // Add a completion
                habitManager.addCompletion(for: habit, on: today)
            }
        } else {
            // Single completion habits
            let currentEntry = habitManager.getEntry(for: habit, on: today)
            let currentStatus = currentEntry?.status
            
            if currentStatus == .completed {
                // Mark as failed (leave it)
                habitManager.updateEntry(for: habit, status: .failed, on: today)
            } else {
                // Mark as completed
                habitManager.updateEntry(for: habit, status: .completed, on: today)
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func undoLastCompletion() {
        if habit.targetCompletionsPerDay > 1 {
            // Multi-completion habit - remove last completion
            let completions = habitManager.getCompletions(for: habit, on: Date())
            if let lastCompletion = completions.last {
                habitManager.removeCompletion(for: habit, completionId: lastCompletion.id, on: Date())
            }
        } else {
            // Single completion habit - reset to skipped
            habitManager.updateEntry(for: habit, status: .skipped, on: Date())
        }
        
        // Haptic feedback for undo
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Day Tile View
struct DayTileView: View {
    let dayTile: DayTile
    let habitColor: Color
    let habit: Habit
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    @EnvironmentObject var habitManager: HabitManager
    
    init(dayTile: DayTile, habitColor: Color, habit: Habit, onTap: @escaping () -> Void, onLongPress: (() -> Void)? = nil) {
        self.dayTile = dayTile
        self.habitColor = habitColor
        self.habit = habit
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(tileBackgroundColor)
                    .frame(width: 28, height: 28)
                
                // Content
                if habit.targetCompletionsPerDay > 1 {
                    multiCompletionContent
                } else {
                    singleCompletionContent
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(dayTile.isToday ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dayTile.isToday)
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress?()
        }
    }
    
    private var singleCompletionContent: some View {
        VStack(spacing: 1) {
            Text("\(dayTile.dayNumber)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(tileTextColor)
            
            if let status = dayTile.status {
                Image(systemName: status.icon)
                    .font(.system(size: 8))
                    .foregroundColor(tileTextColor)
            }
        }
    }
    
    private var multiCompletionContent: some View {
        let progress = habitManager.getCompletionProgress(for: habit, on: dayTile.date)
        
        return VStack(spacing: 2) {
            Text("\(dayTile.dayNumber)")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(tileTextColor)
            
            // Enhanced progress indicator for multi-completion habits
            if progress.target > 1 {
                if progress.target <= 4 {
                    // For small targets (2-4), use individual dots
                    HStack(spacing: 1) {
                        ForEach(0..<progress.target, id: \.self) { index in
                            Circle()
                                .fill(index < progress.completed ? tileTextColor : tileTextColor.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    // For larger targets (5+), use a progress bar
                    VStack(spacing: 1) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(tileTextColor.opacity(0.2))
                                    .frame(height: 2)
                                
                                // Progress fill
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(tileTextColor)
                                    .frame(width: geometry.size.width * progress.percentage, height: 2)
                            }
                        }
                        .frame(height: 2)
                        
                        // Progress text (small)
                        Text("\(progress.completed)/\(progress.target)")
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(tileTextColor.opacity(0.8))
                    }
                }
            }
        }
    }
    
    private var tileBackgroundColor: Color {
        if dayTile.isToday {
            return habitColor.opacity(0.4)
        }
        
        // For multi-completion habits, use completion progress
        if habit.targetCompletionsPerDay > 1 {
            let progress = habitManager.getCompletionProgress(for: habit, on: dayTile.date)
            
            if progress.completed == progress.target && progress.target > 0 {
                return habitColor // Fully completed
            } else if progress.completed > 0 {
                return habitColor.opacity(0.6) // Partially completed
            } else {
                return Color.gray.opacity(0.15) // Not started
            }
        } else {
            // Single completion habits
            switch dayTile.status {
            case .completed:
                return habitColor
            case .failed:
                return habitColor.opacity(0.4)
            case .skipped:
                return habitColor.opacity(0.2)
            case .none:
                return Color.gray.opacity(0.15)
            }
        }
    }
    
    private var tileTextColor: Color {
        if dayTile.isToday {
            return .white
        }
        
        switch dayTile.status {
        case .completed:
            return .white
        case .failed:
            return .white
        case .skipped:
            return habitColor.opacity(0.8)
        case .none:
            return Color.textSecondary
        }
    }
}

// MARK: - Day Tile Model
struct DayTile: Identifiable {
    let id = UUID()
    let date: Date
    let status: HabitStatus?
    let isToday: Bool
    let dayNumber: Int
}

// MARK: - Completion Detail View
struct CompletionDetailView: View {
    let habit: Habit
    let date: Date
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    // Habit icon
                    ZStack {
                        Circle()
                            .fill(habitColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: habit.icon)
                            .font(.title)
                            .foregroundColor(habitColor)
                    }
                    
                    Text(habit.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(habit.targetCompletionsPerDay) completion\(habit.targetCompletionsPerDay == 1 ? "" : "s") per day")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 20)
                
                // Progress section
                VStack(spacing: 16) {
                    let progress = habitManager.getCompletionProgress(for: habit, on: date)
                    
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(habitColor.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: progress.percentage)
                            .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: progress.percentage)
                        
                        VStack(spacing: 4) {
                            Text("\(progress.completed)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(habitColor)
                            
                            Text("of \(progress.target)")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Progress text
                    Text(progress.completed == progress.target ? "Goal completed! 🎉" : "Keep going! 💪")
                        .font(.headline)
                        .foregroundColor(progress.completed == progress.target ? .primaryGreen : .textPrimary)
                }
                
                // Completion buttons
                VStack(spacing: 12) {
                    let progress = habitManager.getCompletionProgress(for: habit, on: date)
                    
                    if progress.completed < progress.target {
                        // Add completion button
                        Button(action: {
                            habitManager.addCompletion(for: habit, on: date)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Completion")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(habitColor)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if progress.completed > 0 {
                        // Remove completion button
                        Button(action: {
                            let completions = habitManager.getCompletions(for: habit, on: date)
                            if let lastCompletion = completions.last {
                                habitManager.removeCompletion(for: habit, completionId: lastCompletion.id, on: date)
                            }
                        }) {
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                Text("Remove Last Completion")
                            }
                            .font(.headline)
                            .foregroundColor(.primaryRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primaryRed.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle(isToday ? "Today's Progress" : "Progress Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var habitColor: Color {
        Color(hex: habit.color) ?? .primaryBlue
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

#Preview {
    ContentView()
}
