//
//  OnboardingSteps.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

// MARK: - Welcome Step
struct WelcomeStep: View {
    let next: () -> Void
    let skip: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Hero Image/Icon with enhanced glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 140, height: 140)
                    .blur(radius: 12)
                    .opacity(0.3)
                
                // Main icon container
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primaryBlue.opacity(0.15), Color.primaryPurple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .primaryBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.primaryBlue)
            }
            
            VStack(spacing: 16) {
                Text("Build Better Habits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Fast logging, smart reminders, beautiful streaks. Transform your life one habit at a time.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: next) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primaryGradient)
                                .shadow(color: .primaryBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                            
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
                
                Button(action: skip) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.background.ignoresSafeArea())
    }
}

// MARK: - Focus Areas Step
struct FocusAreasStep: View {
    @Binding var selected: Set<FocusArea>
    let next: () -> Void
    let back: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you want to improve?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Select areas that matter to you")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            // Focus Area Chips
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 12)
                ], spacing: 12) {
                    ForEach(FocusArea.allCases) { area in
                        FocusAreaChip(
                            area: area,
                            isSelected: selected.contains(area),
                            onTap: {
                                if selected.contains(area) {
                                    selected.remove(area)
                                } else {
                                    selected.insert(area)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                Button("Back") {
                    back()
                }
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                Button("Continue") {
                    next()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.background.ignoresSafeArea())
    }
}

// MARK: - Focus Area Chip
struct FocusAreaChip: View {
    let area: FocusArea
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: area.symbol)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : area.color)
                
                Text(area.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textPrimary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isSelected ? area.color : Color.cardBackground)
                    .shadow(
                        color: isSelected ? area.color.opacity(0.3) : .black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Templates Step
struct TemplatesStep: View {
    let suggested: [HabitTemplate]
    @Binding var selected: Set<HabitTemplate>
    let next: () -> Void
    let back: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick starter habits")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("You can change these later")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            // Habit Templates List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(suggested) { template in
                        HabitTemplateRow(
                            template: template,
                            isSelected: selected.contains(template),
                            onTap: {
                                if selected.contains(template) {
                                    selected.remove(template)
                                } else {
                                    selected.insert(template)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                Button("Back") {
                    back()
                }
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                Button("Continue") {
                    next()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.background.ignoresSafeArea())
    }
}

// MARK: - Habit Template Row
struct HabitTemplateRow: View {
    let template: HabitTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: template.colorHex)?.opacity(0.15) ?? Color.primaryBlue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: template.colorHex) ?? .primaryBlue)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if !template.description.isEmpty {
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack(spacing: 8) {
                        Text(template.area.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(template.area.color.opacity(0.1))
                            )
                            .foregroundColor(template.area.color)
                        
                        Text(template.isPositive ? "Positive" : "Negative")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(template.isPositive ? Color.primaryGreen.opacity(0.1) : Color.primaryRed.opacity(0.1))
                            )
                            .foregroundColor(template.isPositive ? .primaryGreen : .primaryRed)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .primaryBlue : .textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: isSelected ? .primaryBlue.opacity(0.2) : .black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Reminders Step
struct RemindersStep: View {
    @Binding var wantsReminders: Bool
    @Binding var time: Date
    let next: () -> Void
    let back: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Stay on track")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Enable a single Daily Check-In reminder for all habits. You can add per-habit reminders later.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            VStack(spacing: 24) {
                // Reminder Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminders")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Get notified to check in with your habits")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $wantsReminders)
                        .tint(.primaryBlue)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                
                // Time Picker
                if wantsReminders {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminder Time")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        
                        Text("We'll send one reminder for all habits at this time.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                Button("Back") {
                    back()
                }
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                Button("Continue") {
                    next()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: wantsReminders)
    }
}

// MARK: - Theme & Finish Step
struct ThemeFinishStep: View {
    @Binding var theme: AppTheme
    let finish: () -> Void
    let back: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Make it yours")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("You're set. Let's start Day One.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            VStack(spacing: 24) {
                // Theme Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Picker("Theme", selection: $theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Finish Button
            VStack(spacing: 16) {
                Button(action: finish) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Start Day One")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primaryGradient)
                                .shadow(color: .primaryBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                            
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
                
                Button("Back") {
                    back()
                }
                .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.background.ignoresSafeArea())
    }
}
