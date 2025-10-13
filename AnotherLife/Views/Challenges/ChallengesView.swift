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
    @StateObject private var leaderboardManager = LeaderboardManager()
    @State private var selectedTab = 0
    @State private var showingCreateChallenge = false
    @State private var showingCompletionAlert = false
    @State private var completionMessage = ""
    @State private var completionPoints = 0
    @State private var showingJoinSuccessAlert = false
    @State private var joinSuccessMessage = ""
    @State private var selectedCategory: ChallengeType? = nil
    @State private var showingAllChallenges = false
    
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        Task {
                            // Refresh both challenge data and leaderboard
                            await challengeManager.refreshChallengeData()
                            await leaderboardManager.refreshLeaderboard()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryBlue)
                            .font(.title3)
                    }
                }
                
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
        .onAppear {
            challengeManager.setAuthManager(authManager)
            // Auto-complete any ended challenges
            Task {
                await challengeManager.autoCompleteEndedChallenges()
                // Refresh challenge data to reflect any auto-completions
                await challengeManager.refreshChallengeData()
            }
            // Initialize leaderboard
            leaderboardManager.setupLeaderboardListener()
        }
        .alert("Challenge Completed! 🎉", isPresented: $showingCompletionAlert) {
            Button("Awesome!") {
                showingCompletionAlert = false
            }
        } message: {
            Text(completionMessage)
        }
        .alert("Success! 🎉", isPresented: $showingJoinSuccessAlert) {
            Button("Great!") {
                showingJoinSuccessAlert = false
            }
        } message: {
            Text(joinSuccessMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // User Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time to x!")
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
    
    // MARK: - Computed Properties
    
    private var filteredChallenges: [Challenge] {
        let challenges = challengeManager.availablePublicChallenges
        
        if let selectedCategory = selectedCategory {
            return challenges.filter { $0.type == selectedCategory }
        } else {
            return challenges
        }
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
                    EmptyChallengesView(isMyChallenges: true) {
                        showingCreateChallenge = true
                    }
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
                            ChallengeCardView(
                                challenge: challenge, 
                                isMyChallenge: true,
                                showingCompletionAlert: $showingCompletionAlert,
                                completionMessage: $completionMessage,
                                completionPoints: $completionPoints,
                                showingJoinSuccessAlert: $showingJoinSuccessAlert,
                                joinSuccessMessage: $joinSuccessMessage
                            )
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
                                ChallengeCardView(
                                    challenge: challenge, 
                                    isMyChallenge: true,
                                    showingCompletionAlert: $showingCompletionAlert,
                                    completionMessage: $completionMessage,
                                    completionPoints: $completionPoints,
                                    showingJoinSuccessAlert: $showingJoinSuccessAlert,
                                    joinSuccessMessage: $joinSuccessMessage
                                )
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
                            // All Categories button
                            CategoryChipView(
                                type: nil, 
                                isSelected: selectedCategory == nil,
                                onTap: { selectedCategory = nil }
                            )
                            
                            ForEach(ChallengeType.allCases, id: \.self) { type in
                                CategoryChipView(
                                    type: type, 
                                    isSelected: selectedCategory == type,
                                    onTap: { selectedCategory = type }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Trending Challenges
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedCategory?.displayName ?? "All Challenges")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button("See All") {
                            showingAllChallenges = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.primaryBlue)
                    }
                    .padding(.horizontal, 20)
                    
                    ForEach(filteredChallenges, id: \.id) { challenge in
                        ChallengeCardView(
                            challenge: challenge, 
                            isMyChallenge: false,
                            showingCompletionAlert: $showingCompletionAlert,
                            completionMessage: $completionMessage,
                            completionPoints: $completionPoints,
                            showingJoinSuccessAlert: $showingJoinSuccessAlert,
                            joinSuccessMessage: $joinSuccessMessage
                        )
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingAllChallenges) {
            AllChallengesView(
                selectedCategory: selectedCategory,
                showingCompletionAlert: $showingCompletionAlert,
                completionMessage: $completionMessage,
                completionPoints: $completionPoints,
                showingJoinSuccessAlert: $showingJoinSuccessAlert,
                joinSuccessMessage: $joinSuccessMessage
            )
        }
    }
    
    // MARK: - Leaderboard View
    private var leaderboardView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if leaderboardManager.isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .foregroundColor(.primaryBlue)
                        
                        Text("Loading leaderboard...")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let errorMessage = leaderboardManager.errorMessage {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.primaryRed)
                        
                        Text("Failed to load leaderboard")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await leaderboardManager.refreshLeaderboard()
                            }
                        }
                        .foregroundColor(.primaryBlue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primaryBlue, lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Your Rank - Enhanced Luxury Design
                    VStack(spacing: 16) {
                        HStack {
                            Text("Your Performance")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            // Performance badge
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("Champion")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.1))
                            )
                        }
                        
                        ZStack {
                            // Gradient background
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primaryBlue.opacity(0.1),
                                    Color.primaryBlue.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            // Main content
                            VStack(spacing: 20) {
                                // Rank section
                                HStack(spacing: 20) {
                                    // Rank badge with glow effect
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.primaryBlue,
                                                        Color.primaryBlue.opacity(0.8)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 80, height: 80)
                                            .shadow(color: Color.primaryBlue.opacity(0.3), radius: 12, x: 0, y: 6)
                                        
                                        VStack(spacing: 2) {
                                            Text("#\(leaderboardManager.currentUserRank)")
                                                .font(.system(size: 24, weight: .black))
                                                .foregroundColor(.white)
                                            
                                            Text("RANK")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Out of \(leaderboardManager.totalPlayers) players")
                                            .font(.subheadline)
                                            .foregroundColor(.textSecondary)
                                        
                                        Text("Keep pushing forward!")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Stats row
                                HStack(spacing: 30) {
                                    // Points
                                    VStack(spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "star.fill")
                                                .font(.title3)
                                                .foregroundColor(.yellow)
                                            
                                            Text("\(authManager.currentUser?.totalPoints ?? 0)")
                                                .font(.system(size: 28, weight: .black))
                                                .foregroundColor(.textPrimary)
                                        }
                                        
                                        Text("Total Points")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Level
                                    VStack(spacing: 4) {
                                        Text("Level")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.textSecondary)
                                        
                                        Text("\(authManager.currentUser?.level ?? 1)")
                                            .font(.system(size: 28, weight: .black))
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                            .padding(24)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Top Players - Enhanced Design
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                Text("Hall of Fame")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Spacer()
                            
//                            Button(action: {
//                                Task {
//                                    await leaderboardManager.refreshLeaderboard()
//                                }
//                            })
//                                {
//                                HStack(spacing: 4) {
//                                    Image(systemName: "arrow.clockwise")
//                                        .font(.caption)
//                                    Text("Siu")
//                                        .font(.caption)
//                                        .fontWeight(.medium)
//                                }
//                                .foregroundColor(.primaryBlue)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 6)
//                                .background(
//                                    Capsule()
//                                        .fill(Color.primaryBlue.opacity(0.1))
//                                )
//                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if leaderboardManager.topUsers.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "trophy")
                                    .font(.largeTitle)
                                    .foregroundColor(.textSecondary)
                                
                                Text("No players yet")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                
                                Text("Be the first to complete a challenge!")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(Array(leaderboardManager.topUsers.enumerated()), id: \.element.id) { index, player in
                                LeaderboardRowView(
                                    player: player, 
                                    rank: index + 1, 
                                    completedDays: 0 // We can add completed days calculation later
                                )
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .refreshable {
            await leaderboardManager.refreshLeaderboard()
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
    
    // Parent view state bindings for alerts
    @Binding var showingCompletionAlert: Bool
    @Binding var completionMessage: String
    @Binding var completionPoints: Int
    @Binding var showingJoinSuccessAlert: Bool
    @Binding var joinSuccessMessage: String
    
    // Cache progress locally for better performance
    private var progress: ChallengeProgress? {
        challengeManager.challengeProgress[challenge.id]
    }
    
    // Check if user has checked in today
    private var hasCheckedInToday: Bool {
        guard let progress = progress else { return false }
        
        // For completed challenges, don't show check-in status
        if progress.status == .completed {
            return false
        }
        
        // For ended challenges, don't show check-in status
        if challenge.endDate <= Date() {
            return false
        }
        
        // This would ideally check the actual daily status, but for now use progress > 0
        // In a real implementation, you'd check the daily status for today specifically
        return progress.currentValue > 0
    }
    
    // Check if this is a completed challenge
    private var isCompletedChallenge: Bool {
        guard let progress = progress else { return false }
        return progress.status == .completed
    }
    
    // Check if user can undo today's check-in (same day only)
    private var canUndoToday: Bool {
        // Only allow undo if:
        // 1. They checked in today
        // 2. The challenge is still active (not completed)
        // 3. The challenge hasn't ended
        guard hasCheckedInToday else { return false }
        guard let progress = progress else { return false }
        
        // Don't allow undo for completed challenges
        if progress.status == .completed {
            return false
        }
        
        // Don't allow undo if challenge has ended
        if challenge.endDate <= Date() {
            return false
        }
        
        return true
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
                
                // Duration
                let duration = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
                Text("\(duration) days")
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
                    let challengeDuration = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 1
                    let progressPercentage = challengeDuration > 0 ? Double(currentProgress) / Double(challengeDuration) : 0.0
                    
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
                    
                    let duration = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
                    Text("\(duration) days")
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
                    
                    if !hasCheckedInToday && !isCompletedChallenge {
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
                                
                                // Show success alert for joining
                                if progress == nil {
                                    await MainActor.run {
                                        self.joinSuccessMessage = "Successfully joined '\(challenge.title)'! It's now added to My Challenges tab."
                                        self.showingJoinSuccessAlert = true
                                    }
                                }
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
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showCelebration = false
                            }
                        }
                    
                    CelebrationView(message: celebrationMessage, points: celebrationPoints)
                        .zIndex(1000)
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showCelebration = false
                            }
                        }
                }
            }
        )
    }
    
    private func performQuickCheckIn() async {
        guard !isCheckingIn else { return }
        
        isCheckingIn = true
        
        // Update daily status to completed
        let statusSaved = await challengeManager.updateDailyStatus(challenge.id, status: .completed)
        
        // Update challenge progress (will automatically calculate correct value from daily statuses)
        let progressSaved = await challengeManager.updateChallengeProgress(challenge.id, newValue: 0)
        
        // Add activity entry (will check for duplicates)
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
        
        // Update challenge progress (will automatically recalculate from daily statuses)
        let progressSaved = await challengeManager.updateChallengeProgress(challenge.id, newValue: 0)
        
        // Note: We don't add an activity for undo to avoid cluttering the feed
        // The daily status change is sufficient to track the undo
        
        await MainActor.run {
            if statusSaved && progressSaved {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            isUndoing = false
        }
    }
    
    private func checkForMilestones() {
        guard let progress = progress else { return }
        
        let newValue = progress.currentValue
        let duration = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
        
        // Check for completion milestone (completed all days)
        if newValue >= duration {
            // Complete the challenge with celebration
            Task {
                let (success, message, points) = await challengeManager.completeChallengeWithCelebration(challenge)
                if success {
                    await MainActor.run {
                        celebrationMessage = message
                        celebrationPoints = points
                        showCelebration = true
                        
                        // Also show the completion alert
                        self.completionMessage = message
                        self.completionPoints = points
                        self.showingCompletionAlert = true
                    }
                }
            }
        }
        // Check for streak milestones (every 3 days)
        else if newValue % 3 == 0 && newValue > 0 {
            celebrationMessage = "\(newValue) Day Streak! 🔥"
            celebrationPoints = 10
            showCelebration = true
        }
        // Check for halfway point
        else if newValue == duration / 2 {
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
                withAnimation(.easeOut(duration: 0.3)) {
                    showCelebration = false
                }
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
    let type: ChallengeType?
    let isSelected: Bool
    let onTap: () -> Void
    
    init(type: ChallengeType?, isSelected: Bool = false, onTap: @escaping () -> Void = {}) {
        self.type = type
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type?.icon ?? "list.bullet")
                    .font(.caption)
                Text(type?.displayName ?? "All")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primaryBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryBlue : Color.primaryBlue.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    let onCreateChallenge: (() -> Void)?
    
    init(isMyChallenges: Bool, onCreateChallenge: (() -> Void)? = nil) {
        self.isMyChallenges = isMyChallenges
        self.onCreateChallenge = onCreateChallenge
    }
    
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
                Button(action: { 
                    onCreateChallenge?()
                }) {
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
                withAnimation(.easeOut(duration: 0.3)) {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Enhanced Leaderboard Row View
struct LeaderboardRowView: View {
    let player: User
    let rank: Int
    let completedDays: Int
    @EnvironmentObject var authManager: AuthManager
    
    private var isCurrentUser: Bool {
        player.id == authManager.currentUser?.id
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank number (simple text)
            Text("#\(rank)")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(rankTextColor)
                .frame(width: 35, alignment: .leading)
            
            // Player Info with enhanced styling
            HStack(spacing: 12) {
                // Enhanced Avatar with glow for current user
                ZStack {
                    Circle()
                        .fill(isCurrentUser ? 
                              LinearGradient(
                                gradient: Gradient(colors: [Color.primaryBlue, Color.primaryBlue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ) :
                              LinearGradient(
                                gradient: Gradient(colors: [Color.primaryBlue.opacity(0.2), Color.primaryBlue.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: isCurrentUser ? Color.primaryBlue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    
                    Text(String(player.displayName.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isCurrentUser ? .white : .primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(player.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(playerTextColor)
                            .lineLimit(1)
                        
                        if isCurrentUser {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("You")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.15))
                            )
                        }
                    }
                    
                    Text("@\(player.username)")
                        .font(.caption)
                        .foregroundColor(usernameTextColor)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Enhanced Points Display
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Text("\(player.totalPoints)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(playerTextColor)
                }
                
                Text("points")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(usernameTextColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // Podium background gradients for top 3
                if rank <= 3 {
                    LinearGradient(
                        gradient: podiumGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Luxurious border for podium positions
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: podiumBorderGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else if isCurrentUser {
                    // Current user styling (if not in top 3)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.primaryBlue.opacity(0.08),
                            Color.primaryBlue.opacity(0.04)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primaryBlue.opacity(0.3),
                                    Color.primaryBlue.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                } else {
                    // Regular background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                }
                
                // Enhanced shadow based on position
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clear)
                    .shadow(
                        color: shadowColor,
                        radius: shadowRadius,
                        x: 0,
                        y: shadowY
                    )
            }
        )
    }
    
    // MARK: - Podium Styling
    private var podiumGradient: Gradient {
        switch rank {
        case 1: // Gold
            return Gradient(colors: [
                Color.yellow.opacity(0.15),
                Color.yellow.opacity(0.08),
                Color.yellow.opacity(0.05)
            ])
        case 2: // Silver
            return Gradient(colors: [
                Color.gray.opacity(0.15),
                Color.gray.opacity(0.08),
                Color.gray.opacity(0.05)
            ])
        case 3: // Bronze
            return Gradient(colors: [
                Color.orange.opacity(0.15),
                Color.orange.opacity(0.08),
                Color.orange.opacity(0.05)
            ])
        default:
            return Gradient(colors: [Color.clear])
        }
    }
    
    private var podiumBorderGradient: Gradient {
        switch rank {
        case 1: // Gold border
            return Gradient(colors: [
                Color.yellow.opacity(0.4),
                Color.yellow.opacity(0.2),
                Color.yellow.opacity(0.1)
            ])
        case 2: // Silver border
            return Gradient(colors: [
                Color.gray.opacity(0.4),
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.1)
            ])
        case 3: // Bronze border
            return Gradient(colors: [
                Color.orange.opacity(0.4),
                Color.orange.opacity(0.2),
                Color.orange.opacity(0.1)
            ])
        default:
            return Gradient(colors: [Color.clear])
        }
    }
    
    private var rankTextColor: Color {
        switch rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return .textSecondary
        }
    }
    
    private var playerTextColor: Color {
        if rank <= 3 {
            return .white
        } else {
            return .textPrimary
        }
    }
    
    private var usernameTextColor: Color {
        if rank <= 3 {
            return .white.opacity(0.8)
        } else {
            return .textSecondary
        }
    }
    
    private var shadowColor: Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.2)
        case 2: return Color.gray.opacity(0.2)
        case 3: return Color.orange.opacity(0.2)
        default: return isCurrentUser ? Color.primaryBlue.opacity(0.1) : Color.black.opacity(0.05)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch rank {
        case 1: return 15
        case 2: return 12
        case 3: return 10
        default: return isCurrentUser ? 12 : 6
        }
    }
    
    private var shadowY: CGFloat {
        switch rank {
        case 1: return 8
        case 2: return 6
        case 3: return 5
        default: return isCurrentUser ? 6 : 3
        }
    }
}

// MARK: - All Challenges View
struct AllChallengesView: View {
    let selectedCategory: ChallengeType?
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var showingCompletionAlert: Bool
    @Binding var completionMessage: String
    @Binding var completionPoints: Int
    @Binding var showingJoinSuccessAlert: Bool
    @Binding var joinSuccessMessage: String
    @State private var searchText = ""
    @State private var sortOption: SortOption = .popularity
    
    enum SortOption: String, CaseIterable {
        case popularity = "Popularity"
        case newest = "Newest"
        case endingSoon = "Ending Soon"
        case points = "Points"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Sort Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                        
                        TextField("Search challenges...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBackground)
                    )
                    
                    // Sort Options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortOption = option }) {
                                    Text(option.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(sortOption == option ? .white : .primaryBlue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(sortOption == option ? Color.primaryBlue : Color.primaryBlue.opacity(0.1))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Challenges List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredChallenges.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(filteredChallenges, id: \.id) { challenge in
                                ChallengeCardView(
                                    challenge: challenge,
                                    isMyChallenge: false,
                                    showingCompletionAlert: $showingCompletionAlert,
                                    completionMessage: $completionMessage,
                                    completionPoints: $completionPoints,
                                    showingJoinSuccessAlert: $showingJoinSuccessAlert,
                                    joinSuccessMessage: $joinSuccessMessage
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(selectedCategory?.displayName ?? "All Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredChallenges: [Challenge] {
        var challenges = challengeManager.availablePublicChallenges
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            challenges = challenges.filter { $0.type == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            challenges = challenges.filter { challenge in
                challenge.title.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort challenges
        switch sortOption {
        case .popularity:
            challenges.sort { $0.memberCount > $1.memberCount }
        case .newest:
            challenges.sort { $0.createdAt > $1.createdAt }
        case .endingSoon:
            challenges.sort { $0.endDate < $1.endDate }
        case .points:
            challenges.sort { $0.pointsReward > $1.pointsReward }
        }
        
        return challenges
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No challenges found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("Try adjusting your search or browse different categories")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    ChallengesView()
        .environmentObject(AuthManager())
}
