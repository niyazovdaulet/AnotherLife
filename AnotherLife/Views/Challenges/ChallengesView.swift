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
    @State private var showingAllChallenges = false
    @State private var isCompletedChallengesExpanded = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header (includes integrated tab selector)
                headerView
                
                // Content with enhanced animations
                TabView(selection: $selectedTab) {
                    // My Challenges
                    myChallengesView
                        .tag(0)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                    
                    // Discover
                    discoverView
                        .tag(1)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                    
                    // Leaderboard
                    leaderboardView
                        .tag(2)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
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
        .overlay(
            // Luxury Join Success Alert
            Group {
                if showingJoinSuccessAlert {
                    LuxuryJoinSuccessAlert(
                        isPresented: $showingJoinSuccessAlert,
                        message: joinSuccessMessage
                    )
                }
            }
        )
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            // Premium Profile Summary Card
            VStack(spacing: 20) {
                // User Profile Section
                HStack(spacing: 16) {
                    // Enhanced Profile Avatar
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(Color.primaryGradient)
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)
                            .opacity(0.3)
                        
                        // Main avatar
                        Circle()
                            .fill(Color.primaryGradient)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                        
                        Text(String(authManager.currentUser?.displayName.first ?? "U"))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authManager.currentUser?.displayName ?? "User")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Growing Consistency 🌱")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Enhanced Stats Display
                    VStack(spacing: 16) {
                        // Points with XP Bar
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primaryOrange.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primaryOrange)
                                }
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(authManager.currentUser?.totalPoints ?? 0)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
//                                    Text("XP")
//                                        .font(.system(size: 11, weight: .semibold))
//                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            // XP Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.primaryOrange)
                                        .frame(width: geometry.size.width * 0.7, height: 6)
                                        .animation(.easeInOut(duration: 1.0), value: authManager.currentUser?.totalPoints)
                                }
                            }
                            .frame(height: 6)
                            .frame(width: 80)
                        }
                        
                        // Level with Streak
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primaryOrange)
                                
                                Text("Level \(authManager.currentUser?.level ?? 1)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primaryOrange)
                                
                                Text("5-day streak")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                
                // Enhanced Tab Selector with Icons
                enhancedTabSelector
                
                // Micro-info below tabs for context
                tabContextInfo
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16) // Further reduced for tighter spacing
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryBlue.opacity(0.8),
                                Color.primaryPurple.opacity(0.6),
                                Color.primaryIndigo.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: .primaryBlue.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
        .padding(.bottom, 20) // Add breathing room below header
    }
    
    // MARK: - Premium Capsule Tab Selector
    private var enhancedTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                capsuleTabButton(for: index)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 15,
                    x: 0,
                    y: 8
                )
        )
        .padding(.horizontal, -20)
        .offset(y: -4)
    }
    
    private func capsuleTabButton(for index: Int) -> some View {
        Button(action: { 
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = index
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: tabIcons[index])
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                
                Text(tabTitles[index])
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Selected state background
                    if selectedTab == index {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.primaryBlue.opacity(0.9),
                                        Color.primaryPurple.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: .primaryBlue.opacity(0.4),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    }
                }
            )
            .scaleEffect(selectedTab == index ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tabIcons: [String] {
        ["flag.fill", "globe", "trophy.fill"]
    }
    
    private var tabTitles: [String] {
        ["My Challenges", "Discover", "Leaderboard"]
    }
    
    // MARK: - Tab Context Info
    private var tabContextInfo: some View {
        HStack {
            Spacer()
            
            Text(contextText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            Spacer()
        }
        .padding(.top, 0) // Removed padding to minimize space
    }
    
    private var contextText: String {
        switch selectedTab {
        case 0:
            return "\(challengeManager.activeChallenges.count) Active Challenges"
        case 1:
            return "Popular this week"
        case 2:
            return "Top performers"
        default:
            return ""
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredChallenges: [Challenge] {
        return challengeManager.availablePublicChallenges
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
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .bottom))
                            ))
                        }
                        .animation(.easeInOut(duration: 0.3), value: challengeManager.activeChallenges.map(\.id))
                    }
                    .padding(.horizontal, 20)
                    
                    // Completed Challenges
                    if !challengeManager.completedChallenges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isCompletedChallengesExpanded.toggle()
                                }
                            }) {
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
                                    
                                    Image(systemName: isCompletedChallengesExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                        .rotationEffect(.degrees(isCompletedChallengesExpanded ? 0 : 0))
                                        .animation(.easeInOut(duration: 0.3), value: isCompletedChallengesExpanded)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Completed Challenges (collapsible)
                            if isCompletedChallengesExpanded {
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
                
                // Trending Challenges
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("All Challenges")
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
    @State private var showCheckInFeedback = false
    @State private var todayDailyStatus: DailyStatus = .notStarted
    
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
        
        // For now, use a simple check based on currentValue
        // In a real implementation, you'd check the actual daily status for today
        return progress.currentValue > 0
    }
    
    // Check if this is a completed challenge
    private var isCompletedChallenge: Bool {
        guard let progress = progress else { return false }
        return progress.status == .completed
    }
    
    // Get today's daily status - properly implemented using actual daily status
    private var todayStatus: DailyStatus {
        guard let progress = progress else { return .notStarted }
        
        // For completed challenges, return completed
        if progress.status == .completed {
            return .completed
        }
        
        // For ended challenges, return not started
        if challenge.endDate <= Date() {
            return .notStarted
        }
        
        // Return the actual daily status for today
        return todayDailyStatus
    }
    
    // Status indicator for the challenge card
    private var statusIndicator: some View {
        Group {
            switch todayStatus {
            case .completed:
                ZStack {
                    Circle()
                        .fill(Color.successGradient)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            case .skipped:
                ZStack {
                    Circle()
                        .fill(Color.warningGradient)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            case .notStarted:
                ZStack {
                    Circle()
                        .stroke(Color.separator, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(Color.separator)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    // Check if user can undo today's check-in (same day only)
    private var canUndoToday: Bool {
        // Only allow undo if:
        // 1. They checked in today (completed or skipped)
        // 2. The challenge is still active (not completed)
        // 3. The challenge hasn't ended
        guard todayStatus == .completed || todayStatus == .skipped else { return false }
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
//    private var periodChip: String {
//        let days = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
//        if days <= 7 {
//            return "Week"
//        } else if days <= 30 {
//            return "Month"
//        } else {
//            return "Long-term"
//        }
//    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            infoRowView
            progressView
            actionButtonsView
        }
        .padding(20)
        .background(enhancedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(
            color: .black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 8
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.primaryBlue.opacity(0.3),
                            Color.primaryPurple.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingDetail = true
            }
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingDetail)
        .fullScreenCover(isPresented: $showingDetail) {
            ChallengeDetailView(challenge: challenge)
        }
        .sheet(isPresented: $showingPreview) {
            ChallengePreviewView(challenge: challenge)
        }
        .overlay(checkInFeedbackOverlay)
        .overlay(celebrationOverlay)
        .onAppear {
            loadTodayStatus()
        }
        .task(id: progress?.lastUpdatedAt) {
            // Refresh daily status whenever progress is updated
            loadTodayStatus()
        }
        .onChange(of: progress?.currentValue) { _ in
            // Refresh daily status when progress changes
            loadTodayStatus()
        }
        .onChange(of: progress?.lastUpdatedAt) { _ in
            // Refresh daily status when progress is updated
            loadTodayStatus()
        }
        .onChange(of: showingDetail) { isShowing in
            // Refresh daily status when returning from detail view
            if !isShowing {
                loadTodayStatus()
            }
        }
    }
    
    private var enhancedCardBackground: some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.primaryBlue.opacity(0.01)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .top, spacing: 16) {
            // Challenge Icon/Emoji
            ZStack {
                Circle()
                    .fill(challengeIconBackground)
                    .frame(width: 40, height: 40)
                
                Text(challengeIcon)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text(challenge.description)
                    .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                    .lineSpacing(2)
                }
                
                Spacer()
                
            // Enhanced Status Indicator
            if !isCompletedChallenge && challenge.endDate > Date() {
                statusIndicator
            }
        }
    }
    
    private var challengeIcon: String {
        // Add challenge type icons based on title/content
        let title = challenge.title.lowercased()
        if title.contains("reading") || title.contains("book") {
            return "📖"
        } else if title.contains("fitness") || title.contains("exercise") || title.contains("workout") {
            return "🏃‍♂️"
        } else if title.contains("water") || title.contains("drink") {
            return "💧"
        } else if title.contains("sleep") || title.contains("bed") {
            return "😴"
        } else if title.contains("meditation") || title.contains("mindfulness") {
            return "🧘‍♀️"
        } else if title.contains("study") || title.contains("learn") {
            return "📚"
        } else {
            return "🎯"
        }
    }
    
    private var challengeIconBackground: LinearGradient {
        let title = challenge.title.lowercased()
        if title.contains("reading") || title.contains("book") {
            return LinearGradient(colors: [Color.primaryBlue.opacity(0.2), Color.primaryTeal.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if title.contains("fitness") || title.contains("exercise") || title.contains("workout") {
            return LinearGradient(colors: [Color.primaryRed.opacity(0.2), Color.primaryOrange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if title.contains("water") || title.contains("drink") {
            return LinearGradient(colors: [Color.primaryTeal.opacity(0.2), Color.primaryBlue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if title.contains("sleep") || title.contains("bed") {
            return LinearGradient(colors: [Color.primaryPurple.opacity(0.2), Color.primaryIndigo.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if title.contains("meditation") || title.contains("mindfulness") {
            return LinearGradient(colors: [Color.primaryGreen.opacity(0.2), Color.primaryTeal.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if title.contains("study") || title.contains("learn") {
            return LinearGradient(colors: [Color.primaryOrange.opacity(0.2), Color.primaryYellow.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.primaryBlue.opacity(0.2), Color.primaryPurple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var infoRowView: some View {
        HStack(spacing: 12) {
                // Duration
                let duration = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
                Text("\(duration) days")
                .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                
            // Members count (simplified)
            if challenge.privacy == .publicChallenge && challenge.memberCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                    
                    Text("\(challenge.memberCount)")
                        .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
            // Time remaining (simplified)
                Text(timeRemaining)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(timeRemaining == "Ended" ? .primaryRed : .textSecondary)
        }
    }
    
    private var progressView: some View {
        VStack(spacing: 12) {
            // Progress Header
            HStack {
                    let currentProgress = progress?.currentValue ?? 0
                    let challengeDuration = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 1
                
                Text("\(currentProgress)/\(challengeDuration)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Points with animation
                HStack(spacing: 6) {
                    ZStack {
                    Circle()
                            .fill(Color.primaryOrange.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primaryOrange)
                    }
                    
                    Text("\(challenge.pointsReward)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Enhanced Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.separator.opacity(0.3))
                        .frame(height: 12)
                    
                    // Progress fill with status-based colors
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressBarColor)
                        .frame(width: geometry.size.width * min(progressPercentage, 1.0), height: 12)
                        .animation(.easeInOut(duration: 1.0), value: progress?.currentValue)
                    
                    // Glow effect for active progress
                    if progressPercentage > 0 && progressPercentage < 1.0 {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(progressBarColor.opacity(0.3))
                            .frame(width: geometry.size.width * min(progressPercentage, 1.0), height: 12)
                            .blur(radius: 4)
                    }
                }
            }
            .frame(height: 12)
        }
    }
    
    private var progressPercentage: Double {
        let currentProgress = progress?.currentValue ?? 0
        let challengeDuration = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 1
        return challengeDuration > 0 ? Double(currentProgress) / Double(challengeDuration) : 0.0
    }
    
    private var progressBarColor: LinearGradient {
        let percentage = progressPercentage
        
        if percentage >= 1.0 {
            // Completed - Green
            return LinearGradient(colors: [Color.primaryGreen, Color.success], startPoint: .leading, endPoint: .trailing)
        } else if percentage >= 0.8 {
            // Nearly done - Gold
            return LinearGradient(colors: [Color.primaryOrange, Color.primaryYellow], startPoint: .leading, endPoint: .trailing)
        } else if percentage >= 0.5 {
            // Good progress - Blue to Purple
            return LinearGradient(colors: [Color.primaryBlue, Color.primaryPurple], startPoint: .leading, endPoint: .trailing)
        } else {
            // Early stage - Blue
            return LinearGradient(colors: [Color.primaryBlue, Color.primaryTeal], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var actionButtonsView: some View {
            HStack(spacing: 12) {
                if isMyChallenge {
                myChallengeButtons
            } else {
                discoverButtons
            }
        }
    }
    
    private var myChallengeButtons: some View {
        Group {
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
                    
            // Show appropriate button based on today's status
            if todayStatus == .notStarted && !isCompletedChallenge {
                checkInButton
            } else if (todayStatus == .completed || todayStatus == .skipped) && canUndoToday {
                undoButton
            }
        }
    }
    
    private var discoverButtons: some View {
        Group {
            // Discover: Join + Preview
            Button(action: {
                Task {
                    isJoining = true
                    let wasJoined = progress != nil
                    let success = if wasJoined {
                        await challengeManager.leaveChallenge(challenge)
                    } else {
                        await challengeManager.joinChallenge(challenge)
                    }
                    
                    await MainActor.run {
                        isJoining = false
                        
                        if success {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Show success alert for joining
                            if !wasJoined {
                                self.joinSuccessMessage = "Successfully joined '\(challenge.title)'! It's now added to My Challenges tab."
                                self.showingJoinSuccessAlert = true
                            }
                        }
                    }
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
    
    private var checkInButton: some View {
        Button(action: { 
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            Task {
                await performQuickCheckIn()
            }
        }) {
            HStack(spacing: 6) {
                if isCheckingIn {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCheckingIn)
                }
                Text(isCheckingIn ? "Checking in..." : "Check-in")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primaryGreen)
                    .shadow(color: .primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isCheckingIn ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCheckingIn)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCheckingIn)
    }
    
    private var undoButton: some View {
        Button(action: { 
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            Task {
                await undoTodayCheckIn()
            }
        }) {
            HStack(spacing: 6) {
                if isUndoing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isUndoing)
                }
                Text(isUndoing ? "Undoing..." : "Undo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primaryOrange)
                    .shadow(color: .primaryOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isUndoing ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isUndoing)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isUndoing)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.cardBackground)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var checkInFeedbackOverlay: some View {
        Group {
            if showCheckInFeedback {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCheckInFeedback)
                            
                            Text("Checked in!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.primaryGreen)
                                .shadow(color: .primaryGreen.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                        .scaleEffect(showCheckInFeedback ? 1.0 : 0.8)
                        .opacity(showCheckInFeedback ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showCheckInFeedback)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .zIndex(1000)
            }
        }
    }
    
    private var celebrationOverlay: some View {
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
                
                // Update today's status
                todayDailyStatus = .completed
                
                // Show check-in feedback
                showCheckInFeedback = true
                
                // Hide feedback after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCheckInFeedback = false
                    }
                }
                
                // Check for milestones and show celebration
                checkForMilestones()
            }
            isCheckingIn = false
        }
    }
    
    private func undoTodayCheckIn() async {
        guard !isUndoing else { return }
        
        isUndoing = true
        
        // Update daily status to not started (works for both completed and skipped)
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
                
                // Update today's status
                todayDailyStatus = .notStarted
                
                print("✅ ChallengeCardView: Successfully undone today's status for \(challenge.title)")
            }
            isUndoing = false
        }
    }
    
    private func loadTodayStatus() {
        Task {
            let status = await challengeManager.getDailyStatus(challenge.id)
            await MainActor.run {
                print("🔄 ChallengeCardView: Loading daily status for \(challenge.title) - Status: \(status.rawValue)")
                todayDailyStatus = status
            }
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
        // Removed intermediate milestone celebrations (streak, halfway, first completion)
        // Only show celebrations for full challenge completion
        
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
            .navigationTitle("All Challenges")
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

// MARK: - Luxury Join Success Alert
struct LuxuryJoinSuccessAlert: View {
    @Binding var isPresented: Bool
    let message: String
    
    @State private var animationOffset: CGFloat = -100
    @State private var animationOpacity: Double = 0
    @State private var scaleEffect: CGFloat = 0.8
    @State private var rotationAngle: Double = -10
    @State private var sparkleOffset: CGFloat = -50
    @State private var sparkleOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAlert()
                }
            
            VStack(spacing: 0) {
                // Main alert container
                VStack(spacing: 24) {
                    // Success icon with animation
                    ZStack {
                        // Background glow
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.primaryBlue.opacity(0.3), .primaryGreen.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .scaleEffect(scaleEffect * 1.2)
                        
                        // Main icon circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.primaryBlue, .primaryGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        // Checkmark icon
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(scaleEffect)
                    }
                    .rotationEffect(.degrees(rotationAngle))
                    
                    // Title
                    Text("Successfully Joined! 🎉")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(animationOpacity)
                    
                    // Message
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(animationOpacity)
                        .padding(.horizontal, 20)
                    
                    // Action button
                    Button(action: {
                        dismissAlert()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("Awesome!")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.primaryBlue, .primaryGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .primaryBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .scaleEffect(scaleEffect)
                    .opacity(animationOpacity)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.primaryBlue.opacity(0.3), .primaryGreen.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 40)
                .offset(y: animationOffset)
                .opacity(animationOpacity)
                
                // Floating sparkles
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primaryBlue)
                        .offset(
                            x: CGFloat.random(in: -100...100),
                            y: sparkleOffset + CGFloat.random(in: -20...20)
                        )
                        .opacity(sparkleOpacity)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: sparkleOffset
                        )
                }
            }
        }
        .onAppear {
            showAlert()
        }
    }
    
    private func showAlert() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            animationOffset = 0
            animationOpacity = 1
            scaleEffect = 1.0
            rotationAngle = 0
        }
        
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            sparkleOffset = 50
            sparkleOpacity = 1
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    private func dismissAlert() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            animationOffset = 100
            animationOpacity = 0
            scaleEffect = 0.8
            rotationAngle = 10
            sparkleOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPresented = false
        }
    }
}

#Preview {
    ChallengesView()
        .environmentObject(AuthManager())
}
