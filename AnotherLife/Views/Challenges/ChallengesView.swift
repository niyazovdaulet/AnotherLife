//
//  ChallengesView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var selectedTab = 0
    @State private var showingCreateChallenge = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelectorView
                
                // Content
                TabView(selection: $selectedTab) {
                    // My Challenges
                    myChallengesView
                        .tag(0)
                    
                    // Discover
                    discoverView
                        .tag(1)
                    
                    // Leaderboard
                    leaderboardView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateChallenge = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryBlue)
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // User Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(authManager.currentUser?.displayName ?? "User")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Points and Level
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(authManager.currentUser?.totalPoints ?? 0)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Text("Level \(authManager.currentUser?.level ?? 1)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Tab Selector View
    private var tabSelectorView: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 8) {
                        Text(tabTitles[index])
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == index ? .primaryBlue : .textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.primaryBlue : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var tabTitles: [String] {
        ["My Challenges", "Discover", "Leaderboard"]
    }
    
    // MARK: - My Challenges View
    private var myChallengesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if challengeManager.isLoading {
                    // Skeleton loading
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            ChallengeCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 20)
                } else if challengeManager.activeChallenges.isEmpty && challengeManager.completedChallenges.isEmpty {
                    // Empty state
                    EmptyChallengesView(isMyChallenges: true)
                        .padding(.horizontal, 20)
                } else {
                    // Active Challenges
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Active Challenges")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text("\(challengeManager.activeChallenges.count)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.primaryBlue.opacity(0.1))
                                )
                        }
                        
                        // Active Challenges
                        ForEach(challengeManager.activeChallenges, id: \.id) { challenge in
                            ChallengeCardView(challenge: challenge, isMyChallenge: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Completed Challenges
                    if !challengeManager.completedChallenges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Completed")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Text("\(challengeManager.completedChallenges.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primaryGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.primaryGreen.opacity(0.1))
                                    )
                            }
                            
                            // Completed Challenges
                            ForEach(challengeManager.completedChallenges, id: \.id) { challenge in
                                ChallengeCardView(challenge: challenge, isMyChallenge: true)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Discover View
    private var discoverView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ChallengeType.allCases, id: \.self) { type in
                                CategoryChipView(type: type)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Trending Challenges
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Trending")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button("See All") {
                            // TODO: Navigate to all challenges
                        }
                        .font(.subheadline)
                        .foregroundColor(.primaryBlue)
                    }
                    .padding(.horizontal, 20)
                    
                    ForEach(challengeManager.availablePublicChallenges, id: \.id) { challenge in
                        ChallengeCardView(challenge: challenge, isMyChallenge: false)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Leaderboard View
    private var leaderboardView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Your Rank
                VStack(spacing: 12) {
                    Text("Your Rank")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("#42")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryBlue)
                            
                            Text("of 1,234 players")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(authManager.currentUser?.totalPoints ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text("points")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }
                .padding(.horizontal, 20)
                
                // Top Players
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Players")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 20)
                    
                    ForEach(sampleLeaderboard, id: \.id) { player in
                        LeaderboardRowView(player: player, rank: sampleLeaderboard.firstIndex(where: { $0.id == player.id })! + 1, completedDays: 0)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Sample Data
    private var sampleActiveChallenges: [Challenge] {
        [
            Challenge(title: "7-Day Streak", description: "Complete any habit for 7 days in a row", type: .streak, privacy: .privateChallenge, createdBy: "user1", startDate: Date(), endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, targetValue: 7, targetUnit: "days", pointsReward: 100),
            Challenge(title: "Morning Warrior", description: "Complete 3 habits before 9 AM", type: .timeBased, privacy: .group, createdBy: "user2", startDate: Date(), endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!, targetValue: 14, targetUnit: "days", pointsReward: 200)
        ]
    }
    
    private var sampleCompletedChallenges: [Challenge] {
        [
            Challenge(title: "First Week", description: "Complete your first week of habits", type: .streak, privacy: .privateChallenge, createdBy: "user1", startDate: Date().addingTimeInterval(-14*24*60*60), endDate: Date().addingTimeInterval(-7*24*60*60), targetValue: 7, targetUnit: "days", pointsReward: 50)
        ]
    }
    
    private var samplePublicChallenges: [Challenge] {
        [
            Challenge(title: "30-Day Fitness", description: "Complete exercise habit for 30 days", type: .streak, privacy: .publicChallenge, createdBy: "user3", startDate: Date(), endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!, targetValue: 30, targetUnit: "days", pointsReward: 500, memberCount: 156),
            Challenge(title: "Weekend Warrior", description: "Complete 5 habits on weekends", type: .frequency, privacy: .publicChallenge, createdBy: "user4", startDate: Date(), endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, targetValue: 5, targetUnit: "times", pointsReward: 150, memberCount: 89)
        ]
    }
    
    private var sampleLeaderboard: [User] {
        [
            User(id: "1", email: "user1@example.com", username: "HabitMaster", displayName: "Alex Johnson"),
            User(id: "2", email: "user2@example.com", username: "StreakKing", displayName: "Sarah Chen"),
            User(id: "3", email: "user3@example.com", username: "GoalCrusher", displayName: "Mike Davis")
        ]
    }
}

// MARK: - Challenge Card View
struct ChallengeCardView: View {
    let challenge: Challenge
    let isMyChallenge: Bool
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var showingDetail = false
    @State private var isJoining = false
    @State private var showingPreview = false
    @State private var isCheckingIn = false
    @State private var isUndoing = false
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var celebrationPoints = 0
    
    // Cache progress locally for better performance
    private var progress: ChallengeProgress? {
        challengeManager.challengeProgress[challenge.id]
    }
    
    // Check if user has checked in today
    private var hasCheckedInToday: Bool {
        guard let progress = progress else { return false }
        // This would need to check daily status - for now, assume if progress > 0
        return progress.currentValue > 0
    }
    
    // Check if user can undo today's check-in (same day only)
    private var canUndoToday: Bool {
        // For now, allow undo if they checked in today
        // In a real implementation, you'd check the daily status date
        return hasCheckedInToday
    }
    
    // Time remaining
    private var timeRemaining: String {
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: challenge.endDate).day ?? 0
        if daysLeft <= 0 {
            return "Ended"
        } else if daysLeft == 1 {
            return "1d left"
        } else {
            return "\(daysLeft)d left"
        }
    }
    
    // Period chip
    private var periodChip: String {
        let days = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
        if days <= 7 {
            return "Week"
        } else if days <= 30 {
            return "Month"
        } else {
            return "Long-term"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and type icon
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Type Icon
                Image(systemName: challenge.type.icon)
                    .font(.title2)
                    .foregroundColor(.primaryBlue)
            }
            
            // At-a-glance info row
            HStack(spacing: 12) {
                // Period chip
                Text(periodChip)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.primaryBlue.opacity(0.1))
                    )
                    .foregroundColor(.primaryBlue)
                
                // Target
                Text("\(challenge.targetValue) \(challenge.targetUnit)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                
                // Members (mini avatar stack)
                if challenge.privacy == .publicChallenge {
                    HStack(spacing: -4) {
                        ForEach(0..<min(challenge.memberCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.7))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        if challenge.memberCount > 3 {
                            Text("+\(challenge.memberCount - 3)")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Time remaining
                Text(timeRemaining)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(timeRemaining == "Ended" ? .red : .textSecondary)
            }
            
            // Progress ring
            HStack {
                // Compact progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    let currentProgress = progress?.currentValue ?? 0
                    let progressPercentage = challenge.targetValue > 0 ? Double(currentProgress) / Double(challenge.targetValue) : 0.0
                    
                    Circle()
                        .trim(from: 0, to: min(progressPercentage, 1.0))
                        .stroke(
                            progressPercentage >= 1.0 ? Color.primaryGreen : Color.primaryBlue,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(currentProgress)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(challenge.targetValue) \(challenge.targetUnit)")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Points
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(challenge.pointsReward)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Primary CTA row
            HStack(spacing: 12) {
                if isMyChallenge {
                    // My Challenges: Open + Check-in
                    Button(action: { showingDetail = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                            Text("Open")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.primaryBlue)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if !hasCheckedInToday {
                        Button(action: { 
                            Task {
                                await performQuickCheckIn()
                            }
                        }) {
                            HStack(spacing: 4) {
                                if isCheckingIn {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.primaryBlue)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                        .font(.caption)
                                }
                                Text(isCheckingIn ? "Checking in..." : "Check-in")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.primaryBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(Color.primaryBlue, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isCheckingIn)
                    } else if hasCheckedInToday && canUndoToday {
                        // Show undo button for today's check-in
                        Button(action: { 
                            Task {
                                await undoTodayCheckIn()
                            }
                        }) {
                            HStack(spacing: 4) {
                                if isUndoing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .font(.caption)
                                }
                                Text(isUndoing ? "Undoing..." : "Undo")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(Color.orange, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isUndoing)
                    }
                } else {
                    // Discover: Join + Preview
                    Button(action: {
                        Task {
                            isJoining = true
                            let success = if progress != nil {
                                await challengeManager.leaveChallenge(challenge)
                            } else {
                                await challengeManager.joinChallenge(challenge)
                            }
                            
                            if success {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                            isJoining = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            if isJoining {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: progress != nil ? "minus.circle.fill" : "plus.circle.fill")
                                    .font(.caption)
                            }
                            Text(progress != nil ? "Leave" : "Join")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(progress != nil ? Color.red : Color.primaryBlue)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isJoining)
                    
                    Button(action: { showingPreview = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            showingDetail = true
        }
        .fullScreenCover(isPresented: $showingDetail) {
            ChallengeDetailView(challenge: challenge)
        }
        .sheet(isPresented: $showingPreview) {
            ChallengePreviewView(challenge: challenge)
        }
        .overlay(
            // Celebration overlay
            Group {
                if showCelebration {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .zIndex(999)
                    
                    CelebrationView(message: celebrationMessage, points: celebrationPoints)
                        .zIndex(1000)
                }
            }
        )
    }
    
    private func performQuickCheckIn() async {
        guard !isCheckingIn else { return }
        
        isCheckingIn = true
        
        // Update daily status to completed
        let statusSaved = await challengeManager.updateDailyStatus(challenge.id, status: .completed)
        
        // Update challenge progress
        let currentValue = progress?.currentValue ?? 0
        let progressSaved = await challengeManager.updateChallengeProgress(challenge.id, newValue: currentValue + 1)
        
        // Add activity entry
        let activitySaved = await challengeManager.addChallengeActivity(
            challengeId: challenge.id,
            action: "completed"
        )
        
        await MainActor.run {
            if statusSaved && progressSaved && activitySaved {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Check for milestones and show celebration
                checkForMilestones()
            }
            isCheckingIn = false
        }
    }
    
    private func undoTodayCheckIn() async {
        guard !isUndoing else { return }
        
        isUndoing = true
        
        // Update daily status to not started
        let statusSaved = await challengeManager.updateDailyStatus(challenge.id, status: .notStarted)
        
        // Update challenge progress (decrease by 1)
        let currentValue = progress?.currentValue ?? 0
        let progressSaved = await challengeManager.updateChallengeProgress(challenge.id, newValue: max(0, currentValue - 1))
        
        // Add activity entry for undo
        let activitySaved = await challengeManager.addChallengeActivity(
            challengeId: challenge.id,
            action: "undid_checkin"
        )
        
        await MainActor.run {
            if statusSaved && progressSaved && activitySaved {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            isUndoing = false
        }
    }
    
    private func checkForMilestones() {
        guard let progress = progress else { return }
        
        let newValue = progress.currentValue + 1
        let targetValue = challenge.targetValue
        
        // Check for completion milestone
        if newValue >= targetValue {
            celebrationMessage = "Challenge Completed! 🎉"
            celebrationPoints = challenge.pointsReward
            showCelebration = true
        }
        // Check for streak milestones (every 3 days)
        else if newValue % 3 == 0 && newValue > 0 {
            celebrationMessage = "\(newValue) Day Streak! 🔥"
            celebrationPoints = 10
            showCelebration = true
        }
        // Check for halfway point
        else if newValue == targetValue / 2 {
            celebrationMessage = "Halfway There! 💪"
            celebrationPoints = 5
            showCelebration = true
        }
        // Check for first completion
        else if newValue == 1 {
            celebrationMessage = "Great Start! 🚀"
            celebrationPoints = 2
            showCelebration = true
        }
        
        // Hide celebration after 2 seconds
        if showCelebration {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCelebration = false
            }
        }
    }
    
    private var privacyColor: Color {
        switch challenge.privacy {
        case .privateChallenge: return .gray
        case .group: return .primaryBlue
        case .publicChallenge: return .primaryGreen
        }
    }
}

// MARK: - Challenge Preview View
struct ChallengePreviewView: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: challenge.type.icon)
                            .font(.title)
                            .foregroundColor(.primaryBlue)
                        
                        Spacer()
                        
                        Text(challenge.privacy.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.primaryBlue.opacity(0.1))
                            )
                            .foregroundColor(.primaryBlue)
                    }
                    
                    Text(challenge.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(challenge.description)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
                
                // Challenge Details
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Target")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("\(challenge.targetValue) \(challenge.targetUnit)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            let days = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
                            Text("\(days) days")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Points Reward")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("\(challenge.pointsReward)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Members")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("\(challenge.memberCount)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Challenge Preview")
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
}

// MARK: - Category Chip View
struct CategoryChipView: View {
    let type: ChallengeType
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: type.icon)
                .font(.caption)
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.primaryBlue)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.primaryBlue.opacity(0.1))
        )
    }
}

// MARK: - Skeleton Views
struct ChallengeCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 16)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
            
            // At-a-glance info skeleton
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 16)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 16)
            }
            
            // Progress skeleton
            HStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 10)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 16)
            }
            
            // CTA skeleton
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 32)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 28)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .redacted(reason: .placeholder)
    }
}

// MARK: - Empty States
struct EmptyChallengesView: View {
    let isMyChallenges: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isMyChallenges ? "target" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(isMyChallenges ? "No challenges yet" : "No challenges found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(isMyChallenges ? "Create your first challenge or browse public ones to get started!" : "Try adjusting your search or browse all challenges")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if isMyChallenges {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Challenge")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.primaryBlue)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Celebration View
struct CelebrationView: View {
    let message: String
    let points: Int?
    @State private var isAnimating = false
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Confetti effect
                if showConfetti {
                    ForEach(0..<30, id: \.self) { _ in
                        Circle()
                            .fill([Color.primaryBlue, Color.primaryGreen, Color.yellow, Color.orange, Color.pink, Color.purple].randomElement() ?? Color.primaryBlue)
                            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
                            .offset(
                                x: CGFloat.random(in: -150...150),
                                y: CGFloat.random(in: -100...100)
                            )
                            .opacity(isAnimating ? 0 : 1)
                            .animation(
                                .easeOut(duration: 2.0)
                                .delay(Double.random(in: 0...0.8)),
                                value: isAnimating
                            )
                    }
                }
                
                // Main celebration content
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6), value: isAnimating)
                    
                    Text(message)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    if let points = points {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("+\(points) points")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.textPrimary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
                showConfetti = true
            }
            
            // Hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Leaderboard Row View
struct LeaderboardRowView: View {
    let player: User
    let rank: Int
    let completedDays: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 30, alignment: .leading)
            
            // Player Info
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.primaryBlue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(player.displayName.prefix(1)))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryBlue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("@\(player.username)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            // Completed Days
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(completedDays)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("days")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .textSecondary
        }
    }
}

#Preview {
    ChallengesView()
        .environmentObject(AuthManager())
}
