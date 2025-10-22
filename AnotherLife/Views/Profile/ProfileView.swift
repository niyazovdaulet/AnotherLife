import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var habitManager: HabitManager
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var showingWeeklyReport = false
    
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
                        
                        // Quick Actions
                        quickActionsView
                        
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
    }
    
    // MARK: - Profile Header View
    private var profileHeaderView: some View {
        VStack(spacing: 20) {
            // Profile Picture
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.primaryBlue, .primaryBlue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .primaryBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                
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
            VStack(spacing: 8) {
                Text(authManager.currentUser?.displayName ?? "Welcome Back!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("@\(authManager.currentUser?.username ?? "user")")
                    .font(.subheadline)
                    .foregroundColor(.primaryBlue)
                
                Text("Level \(authManager.currentUser?.level ?? 1) • \(authManager.currentUser?.totalPoints ?? 0) points")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            // Edit Profile Button
            Button(action: { showingEditProfile = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primaryBlue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.primaryBlue.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Stats Overview View
    private var statsOverviewView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Your Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCardView(
                    title: "Total Habits",
                    value: "\(habitManager.habits.count)",
                    icon: "star.fill",
                    color: .primaryBlue
                )
                
                StatCardView(
                    title: "Current Streak",
                    value: "\(longestCurrentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCardView(
                    title: "This Week",
                    value: "\(String(format: "%.0f", weeklyCompletionRate))%",
                    icon: "chart.bar.fill",
                    color: .primaryGreen
                )
                
                StatCardView(
                    title: "Total Days",
                    value: "\(totalDaysTracked)",
                    icon: "calendar",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Weekly Report Section
    private var weeklyReportSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Performance Report")
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
            
            // Quick Analytics Cards
            VStack(spacing: 12) {
                // Completion Rate Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
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
                    
                    ProgressView(value: weeklyCompletionRate / 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .primaryGreen))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                )
                
                // Streak Info
                HStack(spacing: 12) {
                    // Current Streak
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(longestCurrentStreak)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Current Streak")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    
                    // Total Completed
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.primaryBlue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(totalCompletedThisWeek)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text("This Week")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                }
            }
        }
    }
    
    // MARK: - Quick Actions View
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                    action: { /* Add habit action */ }
                )
                
                QuickActionRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "View Analytics",
                    subtitle: "See your progress over time",
                    color: .primaryGreen,
                    action: { /* Analytics action */ }
                )
                
                QuickActionRow(
                    icon: "trophy.fill",
                    title: "Challenges",
                    subtitle: "Join or create challenges",
                    color: .orange,
                    action: { /* Challenges action */ }
                )
                
            }
        }
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
            
            VStack(spacing: 12) {
                AccountInfoRow(
                    icon: "person.fill",
                    title: "Username",
                    value: "@\(authManager.currentUser?.username ?? "user")",
                    action: { showingEditProfile = true }
                )
                
                AccountInfoRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: authManager.currentUser?.email ?? "user@example.com",
                    action: { showingEditProfile = true }
                )
                
                AccountInfoRow(
                    icon: "lock.fill",
                    title: "Password",
                    value: "••••••••",
                    action: { /* Change password action - empty for now */ }
                )
                
                Divider()
                    .padding(.vertical, 8)
                
                Button(action: {
                    Task {
                        await authManager.signOut()
                    }
                }) {
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
                }
                .buttonStyle(PlainButtonStyle())
            }
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
                    value: "1.2.2"
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
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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

// MARK: - Account Info Row
struct AccountInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var displayName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var selectedTheme: AppTheme = .system
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
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
                
                Section("Preferences") {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("System").tag(AppTheme.system)
                        Text("Light").tag(AppTheme.light)
                        Text("Dark").tag(AppTheme.dark)
                    }
                    .pickerStyle(SegmentedPickerStyle())
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
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(HabitManager())
}
