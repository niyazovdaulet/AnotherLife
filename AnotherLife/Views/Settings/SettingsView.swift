
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearDataConfirmation = false
    @State private var showingDataClearedSuccess = false
    @AppStorage("dailyRemindersEnabled") private var dailyRemindersEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingTimePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Modern Header
//                    modernHeaderView
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        modernGeneralSection
                        modernDataSection
                        modernAboutSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Clear All Data", isPresented: $showingClearDataConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your habits, entries, notes, and statistics. This action cannot be undone.")
            }
            .alert("Data Cleared", isPresented: $showingDataClearedSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All your habits, entries, notes, and statistics have been successfully erased.")
            }
        }
        .onAppear {
            loadReminderSettings()
            checkNotificationPermission()
        }
        .onChange(of: dailyRemindersEnabled) { oldValue, newValue in
            if newValue {
                requestNotificationPermissionIfNeeded()
            } else {
                cancelDailyReminder()
            }
        }
        .onChange(of: reminderTime) { oldValue, newValue in
            if dailyRemindersEnabled {
                scheduleDailyReminder(at: newValue)
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheetView(
                selectedTime: $reminderTime,
                isPresented: $showingTimePicker
            )
        }
    }
    
//    // MARK: - Modern Header View
//    private var modernHeaderView: some View {
//        VStack(spacing: 12) {
//            ZStack {
//                Circle()
//                    .fill(
//                        LinearGradient(
//                            colors: [
//                                Color.primaryBlue.opacity(0.15),
//                                Color.primaryPurple.opacity(0.1)
//                            ],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 80, height: 80)
//                
//                Image(systemName: "gearshape.fill")
//                    .font(.system(size: 36, weight: .medium))
//                    .foregroundStyle(
//                        LinearGradient(
//                            colors: [Color.primaryBlue, Color.primaryPurple],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//            }
//            
//            Text("Settings")
//                .font(.system(size: 28, weight: .bold, design: .rounded))
//                .foregroundColor(.textPrimary)
//        }
//        .padding(.top, 20)
//        .padding(.bottom, 8)
//    }
    
    // MARK: - Modern General Section
    private var modernGeneralSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // Manage Habits
                NavigationLink(destination: HabitManagementView()) {
                    ModernSettingsRow(
                        icon: "list.bullet.rectangle",
                        iconColor: [Color.primaryBlue, Color.primaryPurple],
                        title: "Manage Habits",
                        subtitle: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Daily Reminders Toggle
                ModernToggleRow(
                    icon: "bell.fill",
                    iconColor: [Color.primaryBlue, Color.primaryPurple],
                    title: "Check-In Reminders",
                    subtitle: nil,
                    isOn: $dailyRemindersEnabled
                )
                
                // Time Selection (shown when enabled)
                if dailyRemindersEnabled {
                    Button(action: {
                        showingTimePicker = true
                    }) {
                        ModernSettingsRow(
                            icon: "clock.fill",
                            iconColor: [Color.primaryPurple, Color.primaryPink],
                            title: "Reminder Time",
                            subtitle: formatReminderTime(reminderTime),
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                    
                    // Permission Warning
                    if notificationPermissionStatus != .authorized {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            
                            Text("Notification permission required")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.leading, 56)
                        .padding(.top, -8)
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dailyRemindersEnabled)
        }
    }
    
    // MARK: - Modern Data Section
    private var modernDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                Button(action: exportData) {
                    ModernSettingsRow(
                        icon: "square.and.arrow.up",
                        iconColor: [Color.primaryBlue, Color.primaryPurple],
                        title: "Export Data",
                        subtitle: "Save your habits and progress",
                        showChevron: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    showingClearDataConfirmation = true
                }) {
                    ModernSettingsRow(
                        icon: "trash",
                        iconColor: [Color.primaryRed, Color.orange],
                        title: "Clear All Data",
                        subtitle: "Permanently delete all data",
                        titleColor: .primaryRed,
                        showChevron: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Modern About Section
    private var modernAboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 24) {
                // App Icon and Info
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.primaryBlue.opacity(0.2),
                                        Color.primaryPurple.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 6) {
                        Text("AnotherLife")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Version 1.3.3")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Description
                Text("Build better habits, one day at a time. Track your progress with beautiful visualizations and stay motivated with streaks and statistics.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(ModernCardBackground())
        }
    }
    
    // MARK: - Helper Methods
    private func formatReminderTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    private func exportData() {
        // TODO: Implement data export
        print("Export data functionality would be implemented here")
    }
    
    private func clearAllData() {
        habitManager.clearAllData()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showingDataClearedSuccess = true
    }
    
    // MARK: - Reminder Management
    private func loadReminderSettings() {
        dailyRemindersEnabled = UserDefaults.standard.bool(forKey: "dailyRemindersEnabled")
        if let savedTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date {
            reminderTime = savedTime
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        notificationPermissionStatus = granted ? .authorized : .denied
                        if granted {
                            scheduleDailyReminder(at: self.reminderTime)
                        }
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    scheduleDailyReminder(at: self.reminderTime)
                }
            } else {
                DispatchQueue.main.async {
                    notificationPermissionStatus = .denied
                }
            }
        }
    }
    
    private func scheduleDailyReminder(at time: Date) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_check_in"])
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "Daily Check-In"
            content.body = "Time to check in with your habits!"
            content.sound = .default
            content.badge = 1
            
            let request = UNNotificationRequest(
                identifier: "daily_check_in",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
            UserDefaults.standard.set(time, forKey: "dailyReminderTime")
        }
    }
    
    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_check_in"])
    }
}

// MARK: - Modern Settings Row
struct ModernSettingsRow: View {
    let icon: String
    let iconColor: [Color]
    let title: String
    let subtitle: String?
    var titleColor: Color = .textPrimary
    var showChevron: Bool = true
    
    init(icon: String, iconColor: [Color], title: String, subtitle: String? = nil, titleColor: Color = .textPrimary, showChevron: Bool = true) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor[0].opacity(0.15),
                                iconColor[1].opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: iconColor,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(titleColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
        }
        .padding(16)
        .background(ModernCardBackground())
    }
}

// MARK: - Modern Toggle Row
struct ModernToggleRow: View {
    let icon: String
    let iconColor: [Color]
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor[0].opacity(0.15),
                                iconColor[1].opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: iconColor,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(
                    LinearGradient(
                        colors: iconColor,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(16)
        .background(ModernCardBackground())
    }
}

// MARK: - Modern Card Background
struct ModernCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                // Enhanced background with subtle gradient for depth
                LinearGradient(
                    colors: [
                        Color.cardBackground,
                        Color.cardBackground.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Subtle border for definition
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 16,
                x: 0,
                y: 6
            )
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Habit Management View
struct HabitManagementView: View {
    @EnvironmentObject var habitManager: HabitManager
    @State private var showingAddHabit = false
    @State private var showingEditHabit: Habit?
    @State private var showingDeleteConfirmation: Habit?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if habitManager.habits.isEmpty {
                    modernEmptyStateView
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(habitManager.habits) { habit in
                            ModernHabitManagementRow(
                                habit: habit,
                                onEdit: { showingEditHabit = habit },
                                onDelete: { showingDeleteConfirmation = habit }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Manage Habits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddHabit = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primaryBlue, Color.primaryPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
        .sheet(item: $showingEditHabit) { habit in
            EditHabitView(habit: habit)
        }
        .alert("Delete Habit", isPresented: Binding<Bool>(
            get: { showingDeleteConfirmation != nil },
            set: { if !$0 { showingDeleteConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let habit = showingDeleteConfirmation {
                    habitManager.deleteHabit(habit)
                }
            }
        } message: {
            if let habit = showingDeleteConfirmation {
                Text("Are you sure you want to delete '\(habit.title)'? This action cannot be undone.")
            }
        }
    }
    
    private var modernEmptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryBlue.opacity(0.15),
                                Color.primaryPurple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryBlue, Color.primaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Habits Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Add your first habit to get started with tracking your progress.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Habit Management Row
struct ModernHabitManagementRow: View {
    let habit: Habit
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Habit Icon
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
                    .frame(width: 50, height: 50)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [habitColor, habitColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Habit Info
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                if !habit.description.isEmpty {
                    Text(habit.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    Text(habit.isPositive ? "Positive" : "Negative")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    habit.isPositive ?
                                    LinearGradient(
                                        colors: [Color.primaryGreen.opacity(0.15), Color.mint.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.primaryRed.opacity(0.15), Color.orange.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(habit.isPositive ? .primaryGreen : .primaryRed)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryBlue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primaryBlue.opacity(0.15), Color.primaryPurple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryRed)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primaryRed.opacity(0.15), Color.orange.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(ModernCardBackground())
    }
    
    private var habitColor: Color {
        Color(hex: habit.color) ?? .primaryBlue
    }
}

// MARK: - Edit Habit View
struct EditHabitView: View {
    @State private var habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    init(habit: Habit) {
        self._habit = State(initialValue: habit)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.primaryBlue.opacity(0.15),
                                            Color.primaryPurple.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 35, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.primaryBlue, Color.primaryPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        Text("Edit Habit")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Habit Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Habit Details")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Habit Title")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    
                                    TextField("Habit Title", text: $habit.title)
                                        .textFieldStyle(ModernTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description (Optional)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    
                                    TextField("Description", text: $habit.description, axis: .vertical)
                                        .textFieldStyle(ModernTextFieldStyle())
                                        .lineLimit(3...6)
                                }
                            }
                        }
                        .padding(20)
                        .background(ModernCardBackground())
                        
                        // Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Frequency")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    
                                    Picker("Frequency", selection: $habit.frequency) {
                                        ForEach(HabitFrequency.allCases, id: \.self) { frequency in
                                            Text(frequency.displayName).tag(frequency)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.separator, lineWidth: 1)
                                            )
                                    )
                                }
                                
                                Toggle("Positive Habit", isOn: $habit.isPositive)
                                    .tint(
                                        LinearGradient(
                                            colors: [Color.primaryGreen, Color.mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .padding(20)
                        .background(ModernCardBackground())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        habitManager.updateHabit(habit)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Time Picker Sheet View
struct TimePickerSheetView: View {
    @Binding var selectedTime: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.primaryBlue.opacity(0.15),
                                            Color.primaryPurple.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "clock.fill")
                                .font(.system(size: 35, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.primaryBlue, Color.primaryPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Select Reminder Time")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("Choose when you'd like to receive your daily check-in reminder")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Time Picker
                    DatePicker(
                        "Reminder Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 200)
                    .padding()
                    .background(ModernCardBackground())
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Confirm Button
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack {
                            Spacer()
                            Text("Confirm")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primaryBlue, Color.primaryPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(
                                    color: Color.primaryBlue.opacity(0.4),
                                    radius: 20,
                                    x: 0,
                                    y: 10
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.separator, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    SettingsView()
        .environmentObject(HabitManager())
}
