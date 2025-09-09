//
//  OnboardingFlowView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var habitManager: HabitManager
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: viewModel.progress)
                    .tint(.primaryBlue)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                
                // Step Content
                TabView(selection: $viewModel.step) {
                    // Step 0: Welcome
                    WelcomeStep(
                        next: { viewModel.nextStep() },
                        skip: { viewModel.skipOnboarding() }
                    )
                    .tag(0)
                    
                    // Step 1: Focus Areas
                    FocusAreasStep(
                        selected: $viewModel.selectedAreas,
                        next: {
                            viewModel.buildSuggestions()
                            viewModel.nextStep()
                        },
                        back: { viewModel.previousStep() }
                    )
                    .tag(1)
                    
                    // Step 2: Templates
                    TemplatesStep(
                        suggested: viewModel.suggested,
                        selected: $viewModel.selectedTemplates,
                        next: { viewModel.nextStep() },
                        back: { viewModel.previousStep() }
                    )
                    .tag(2)
                    
                    // Step 3: Reminders
                    RemindersStep(
                        wantsReminders: $viewModel.wantsReminders,
                        time: $viewModel.reminderTime,
                        next: {
                            if viewModel.wantsReminders {
                                viewModel.requestNotificationPermissionIfNeeded()
                            }
                            viewModel.nextStep()
                        },
                        back: { viewModel.previousStep() }
                    )
                    .tag(3)
                    
                    // Step 4: Theme & Finish
                    ThemeFinishStep(
                        theme: $viewModel.theme,
                        finish: {
                            viewModel.complete(habitManager: habitManager)
                        },
                        back: { viewModel.previousStep() }
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.step)
            }
        }
        .preferredColorScheme(viewModel.theme == .system ? nil : (viewModel.theme == .light ? .light : .dark))
        .onAppear {
            // Set up haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
        }
        .onChange(of: viewModel.step) {
            // Haptic feedback on step change
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Onboarding Container
struct OnboardingContainer: View {
    @EnvironmentObject var habitManager: HabitManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(habitManager)
            } else {
                OnboardingFlowView()
                    .environmentObject(habitManager)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(HabitManager())
}
