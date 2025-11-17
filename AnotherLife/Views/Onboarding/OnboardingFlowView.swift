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
    @StateObject private var authManager = AuthManager()
    @State private var showingPermissionAlert = false
    @State private var showingAuth = false
    @AppStorage("isFirstTimeRun") private var isFirstTimeRun = true
    
    var body: some View {
        ZStack {
            // Background
            Color.background
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
                    
                    // Step 3: Reminders & Finish
                    RemindersStep(
                        wantsReminders: $viewModel.wantsReminders,
                        time: $viewModel.reminderTime,
                        finish: {
                            if viewModel.wantsReminders {
                                viewModel.requestNotificationPermissionIfNeeded()
                            }
                            
                            // Check if first time before completing
                            let wasFirstTime = isFirstTimeRun
                            viewModel.complete(habitManager: habitManager)
                            
                            // If first time, navigate to Auth after a brief delay
                            if wasFirstTime {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showingAuth = true
                                }
                            }
                        },
                        back: { viewModel.previousStep() }
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.step)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Set up haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
        }
        .onChange(of: viewModel.step) { oldValue, newValue in
            // Haptic feedback on step change
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        .fullScreenCover(isPresented: $showingAuth) {
            AuthView()
                .environmentObject(authManager)
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            // Close auth view when authenticated
            if newValue {
                showingAuth = false
            }
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
