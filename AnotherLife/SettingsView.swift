//
//  SettingsView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Theme Section
                Section {
                    themeSection
                } header: {
                    Text("Appearance")
                }
                
                // Statistics Section
                Section {
                    statisticsSection
                } header: {
                    Text("Statistics")
                }
                
                // Data Section
                Section {
                    dataSection
                } header: {
                    Text("Data")
                }
                
                // About Section
                Section {
                    aboutSection
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
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
    
    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: { habitManager.updateTheme(theme) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Text(themeDescription(theme))
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: habitManager.theme == theme ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(habitManager.theme == theme ? .primaryBlue : .textSecondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            StatRowView(
                title: "Total Habits",
                value: "\(habitManager.habits.count)",
                icon: "star.fill",
                color: .primaryBlue
            )
            
            StatRowView(
                title: "Total Entries",
                value: "\(habitManager.entries.count)",
                icon: "chart.bar.fill",
                color: .primaryGreen
            )
            
            StatRowView(
                title: "Days Tracked",
                value: "\(uniqueDaysTracked)",
                icon: "calendar",
                color: .orange
            )
            
            // Habit Management Button
            NavigationLink(destination: HabitManagementView(habitManager: habitManager)) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.primaryBlue)
                        .frame(width: 24)
                    
                    Text("Manage Habits")
                        .font(.body)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        VStack(spacing: 16) {
            Button(action: exportData) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.primaryBlue)
                    
                    Text("Export Data")
                        .font(.body)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: clearAllData) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    
                    Text("Clear All Data")
                        .font(.body)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.primaryBlue)
                
                Text("AnotherLife")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.vertical, 16)
            
            Text("Build better habits, one day at a time. Track your progress with beautiful visualizations and stay motivated with streaks and statistics.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    private func themeDescription(_ theme: AppTheme) -> String {
        switch theme {
        case .light:
            return "Always use light mode"
        case .dark:
            return "Always use dark mode"
        case .system:
            return "Follow system setting"
        }
    }
    
    private var uniqueDaysTracked: Int {
        let uniqueDates = Set(habitManager.entries.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDates.count
    }
    
    private func exportData() {
        // TODO: Implement data export
        print("Export data functionality would be implemented here")
    }
    
    private func clearAllData() {
        // TODO: Implement data clearing with confirmation
        print("Clear data functionality would be implemented here")
    }
}

// MARK: - Stat Row View
struct StatRowView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Habit Management View
struct HabitManagementView: View {
    @ObservedObject var habitManager: HabitManager
    @State private var showingAddHabit = false
    @State private var showingEditHabit: Habit?
    @State private var showingDeleteConfirmation: Habit?
    
    var body: some View {
        List {
            if habitManager.habits.isEmpty {
                emptyStateView
            } else {
                ForEach(habitManager.habits) { habit in
                    HabitManagementRowView(
                        habit: habit,
                        onEdit: { showingEditHabit = habit },
                        onDelete: { showingDeleteConfirmation = habit }
                    )
                }
            }
        }
        .navigationTitle("Manage Habits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddHabit = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView(habitManager: habitManager)
        }
        .sheet(item: $showingEditHabit) { habit in
            EditHabitView(habit: habit, habitManager: habitManager)
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
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 50))
                .foregroundColor(.primaryBlue)
            
            Text("No Habits Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Add your first habit to get started with tracking your progress.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Habit Management Row View
struct HabitManagementRowView: View {
    let habit: Habit
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Habit Icon
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: habit.icon)
                    .font(.title3)
                    .foregroundColor(habitColor)
            }
            
            // Habit Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                if !habit.description.isEmpty {
                    Text(habit.description)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
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
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.primaryBlue)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
    
    private var habitColor: Color {
        Color(hex: habit.color) ?? .primaryBlue
    }
}

// MARK: - Edit Habit View
struct EditHabitView: View {
    @State private var habit: Habit
    @ObservedObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    init(habit: Habit, habitManager: HabitManager) {
        self._habit = State(initialValue: habit)
        self.habitManager = habitManager
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Title", text: $habit.title)
                    TextField("Description (Optional)", text: $habit.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Settings") {
                    Picker("Frequency", selection: $habit.frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    
                    Toggle("Positive Habit", isOn: $habit.isPositive)
                }
                
                Section("Appearance") {
                    // Color picker would go here
                    Text("Color: \(habit.color)")
                        .foregroundColor(.textSecondary)
                    
                    Text("Icon: \(habit.icon)")
                        .foregroundColor(.textSecondary)
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

#Preview {
    SettingsView(habitManager: HabitManager())
}
