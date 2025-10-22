//
//  CreateChallengeView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

struct CreateChallengeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPrivacy: ChallengePrivacy = .group
    @State private var targetValue = 7
    @State private var selectedHabits: Set<String> = []
    @State private var duration = 7 // days
    @State private var pointsReward = 100
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Form
                    VStack(spacing: 20) {
                        // Basic Info
                        basicInfoSection
                        
                        
                        // Privacy Settings
                        privacySection
                        
                        // Target Settings
//                        targetSection
                        
                        // Duration
                        durationSection
                        
                        // Rewards
                        rewardsSection
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createChallenge()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(.primaryBlue)
            
            Text("Create a Challenge")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Set a goal and invite others to join you")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("e.g., 30-Day Fitness Challenge", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Describe what participants need to do", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                ForEach([ChallengePrivacy.group, ChallengePrivacy.publicChallenge], id: \.self) { privacy in
                    Button(action: { selectedPrivacy = privacy }) {
                        VStack(spacing: 8) {
                            Image(systemName: privacyIcon(privacy))
                                .font(.title2)
                                .foregroundColor(selectedPrivacy == privacy ? privacyColor(privacy) : .textSecondary)
                            
                            Text(privacy.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Text(privacyDescription(privacy))
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPrivacy == privacy ? privacyColor(privacy).opacity(0.1) : Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPrivacy == privacy ? privacyColor(privacy) : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
//    // MARK: - Target Section
//    private var targetSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Target")
//                .font(.headline)
//                .foregroundColor(.textPrimary)
//            
//            VStack(spacing: 16) {
//                HStack {
//                    Text("Target Value")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(.textPrimary)
//                    
//                    Spacer()
//                    
//                    Stepper(value: $targetValue, in: 1...100) {
//                        Text("\(targetValue)")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.textPrimary)
//                    }
//                }
//                
//                Text("Participants need to complete \(targetValue) \(targetUnit)")
//                    .font(.caption)
//                    .foregroundColor(.textSecondary)
//            }
//        }
//        .padding(20)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color.cardBackground)
//                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
//        )
//    }
    
    // MARK: - Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Challenge Duration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Stepper(value: $duration, in: 1...365) {
                        Text("\(duration) days")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Text("Challenge will run for \(duration) days")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Rewards Section
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rewards")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Points Reward")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Stepper(value: $pointsReward, in: 10...1000, step: 10) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(pointsReward)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
                
                Text("Participants will earn \(pointsReward) points upon completion")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
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
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    private var targetUnit: String {
        return "days"
    }
    
    // MARK: - Helper Methods
    
    private func privacyIcon(_ privacy: ChallengePrivacy) -> String {
        switch privacy {
        case .privateChallenge: return "lock.fill"
        case .group: return "person.2.fill"
        case .publicChallenge: return "globe"
        }
    }
    
    private func privacyColor(_ privacy: ChallengePrivacy) -> Color {
        switch privacy {
        case .privateChallenge: return .gray
        case .group: return .primaryBlue
        case .publicChallenge: return .primaryGreen
        }
    }
    
    private func privacyDescription(_ privacy: ChallengePrivacy) -> String {
        switch privacy {
        case .privateChallenge: return "Just for you"
        case .group: return "Invite friends"
        case .publicChallenge: return "Anyone can join"
        }
    }
    
    private func createChallenge() {
        Task {
            let success = await challengeManager.createChallenge(
                title: title,
                description: description,
                type: .streak, // Default type since we removed type selection
                privacy: selectedPrivacy,
                targetValue: targetValue,
                targetUnit: targetUnit,
                duration: duration,
                pointsReward: pointsReward,
                badgeReward: nil,
                habitIds: []
            )
            
            if success {
                dismiss()
            } else {
                // Error is handled by ChallengeManager and displayed in UI
            }
        }
    }
}

#Preview {
    CreateChallengeView()
        .environmentObject(AuthManager())
}
