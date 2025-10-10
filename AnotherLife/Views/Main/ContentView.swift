

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
                    
                    // Analytics Tab
                    AnalyticsView()
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Analytics")
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
                    // Authentication
                    AuthView()
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
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.1),
                    Color.primaryGreen.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.primaryBlue, Color.primaryGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .primaryBlue.opacity(0.4), radius: 25, x: 0, y: 12)
                    
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .scaleEffect(splashIconScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        splashIconScale = 1.1
                    }
                }
                
                VStack(spacing: 12) {
                    Text("AnotherLife")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Loading your data...")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))
                        .scaleEffect(1.2)
                        .padding(.top, 8)
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Welcome Message View
    private var welcomeMessageView: some View {
        VStack(spacing: 16) {
            // Checkmark animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.primaryGreen.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(showWelcomeMessage ? 1.0 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showWelcomeMessage)
            
            VStack(spacing: 8) {
                Text("Welcome back, \(authManager.currentUser?.displayName ?? "")! 👋")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Let's build great habits today")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
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
                Color.backgroundGray
                    .ignoresSafeArea()
                
                // Subtle gradient overlay for depth
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.backgroundGray,
                        Color.backgroundGray.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerView
                        
                        // Habits List
                        habitsListView
                        
                        // Quick Stats
                        quickStatsView
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryBlue)
                            .font(.title2)
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
    
    // MARK: - Habits List View
    private var habitsListView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Habits")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(habitManager.habits.count) habits • Track your progress")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            
            if habitManager.habits.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(habitManager.habits) { habit in
                        HabitGridView(habit: habit)
                    }
                }
            }
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
            if let entry = habitManager.getEntry(for: habit, on: habitManager.selectedDate) {
                return entry.status == .completed
            }
            return false
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
                            Text(habit.frequency.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.primaryBlue.opacity(0.1))
                                )
                                .foregroundColor(.primaryBlue)
                            
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
            NotesView(habit: habit)
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
                .fill(Color.backgroundGray)
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
        case "magenta": self = .magenta
        case "lime": self = .lime
        case "navy": self = .navy
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
    @State private var showingNotes = false
    @State private var selectedTileDate: Date?
    
    private let daysToShow = 50
    private let columns = 10 // 10 columns for 50 days (5 rows)
    
    var body: some View {
        // Main Card Content
        VStack(spacing: 8) {
            // Header with Icon, Info, and Completion Button
            HStack(spacing: 10) {
                // Habit Icon
                habitIconView
                
                // Habit Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    if !habit.description.isEmpty {
                        Text(habit.description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                    
                    // Tags
                    HStack(spacing: 6) {
                        Text(habit.frequency.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.primaryBlue.opacity(0.1))
                            )
                            .foregroundColor(.primaryBlue)
                        
                        Text(habit.isPositive ? "Positive" : "Negative")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(habit.isPositive ? Color.primaryGreen.opacity(0.1) : Color.primaryRed.opacity(0.1))
                            )
                            .foregroundColor(habit.isPositive ? .primaryGreen : .primaryRed)
                    }
                }
                
                Spacer()
                
                // Completion Button
                completionButton
            }
            
            // Grid of Days
            VStack(spacing: 4) {
                // Current streak
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(currentStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                
                // Grid Layout
                VStack(spacing: 6) {
                    ForEach(0..<5) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<10) { col in
                                let index = row * 10 + col
                                if index < dayTiles.count {
                                    DayTileView(
                                        dayTile: dayTiles[index],
                                        habitColor: habitColor,
                                        onTap: { 
                                            selectedTileDate = dayTiles[index].date
                                            updateStatus(for: dayTiles[index].date)
                                        }
                                    )
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
            }
            
            // Notes Button
            if selectedTileDate != nil {
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingNotes) {
            NotesView(habit: habit)
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
        Button(action: {
            toggleTodayStatus()
        }) {
            ZStack {
                Circle()
                    .fill(todayStatus == .completed ? .primaryGreen : habitColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .shadow(color: todayStatus == .completed ? .primaryGreen.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                
                Image(systemName: todayStatus == .completed ? "checkmark" : "circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(todayStatus == .completed ? .white : habitColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(todayStatus == .completed ? 1.0 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: todayStatus)
    }
    
    private var todayStatus: HabitStatus? {
        habitManager.getEntry(for: habit, on: Date())?.status
    }
    
    private var dayTiles: [DayTile] {
        let calendar = Calendar.current
        let today = Date()
        var tiles: [DayTile] = []
        
        for i in 0..<daysToShow {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let entry = habitManager.getEntry(for: habit, on: date)
            let isToday = calendar.isDateInToday(date)
            
            tiles.append(DayTile(
                date: date,
                status: entry?.status,
                isToday: isToday,
                dayNumber: calendar.component(.day, from: date)
            ))
        }
        
        return tiles.reversed() // Show oldest first
    }
    
    private var currentStreak: Int {
        habitManager.getStatistics(for: habit, in: DateInterval(start: Date().addingTimeInterval(-365*24*60*60), end: Date())).currentStreak
    }
    
    
    private func updateStatus(for date: Date) {
        let currentEntry = habitManager.getEntry(for: habit, on: date)
        let currentStatus = currentEntry?.status
        
        // Cycle through statuses: none -> completed -> failed -> skipped -> none
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
        }
        
        if let status = nextStatus {
            habitManager.updateEntry(for: habit, status: status)
        } else {
            // Remove entry (set to none)
            if let index = habitManager.entries.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                habitManager.entries.remove(at: index)
                habitManager.saveEntries()
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func toggleTodayStatus() {
        let today = Date()
        let currentEntry = habitManager.getEntry(for: habit, on: today)
        let currentStatus = currentEntry?.status
        
        if currentStatus == .completed {
            // Mark as failed (leave it)
            habitManager.updateEntry(for: habit, status: .failed)
        } else {
            // Mark as completed
            habitManager.updateEntry(for: habit, status: .completed)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Day Tile View
struct DayTileView: View {
    let dayTile: DayTile
    let habitColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(tileBackgroundColor)
                    .frame(width: 28, height: 28)
                
                // Content
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
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(dayTile.isToday ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dayTile.isToday)
    }
    
    private var tileBackgroundColor: Color {
        if dayTile.isToday {
            return habitColor.opacity(0.4)
        }
        
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
struct DayTile {
    let date: Date
    let status: HabitStatus?
    let isToday: Bool
    let dayNumber: Int
}

#Preview {
    ContentView()
}
