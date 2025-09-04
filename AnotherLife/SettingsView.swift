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

#Preview {
    SettingsView(habitManager: HabitManager())
}
