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
                .padding(.bottom, 20)
            }
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
                        LeaderboardRowView(player: player, rank: sampleLeaderboard.firstIndex(where: { $0.id == player.id })! + 1)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
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
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("0 / \(challenge.targetValue) \(challenge.targetUnit)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                }
                
                ProgressView(value: 0.0, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primaryBlue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Footer
            HStack {
                // Privacy Badge
                Text(challenge.privacy.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(privacyColor.opacity(0.1))
                    )
                    .foregroundColor(privacyColor)
                
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
                
                // Member Count (for public challenges)
                if challenge.privacy == .publicChallenge {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text("\(challenge.memberCount)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Join/Leave Button (for public challenges)
                if !isMyChallenge && challenge.privacy == .publicChallenge {
                    Button(action: {
                        Task {
                            if challengeManager.challengeProgress[challenge.id] != nil {
                                await challengeManager.leaveChallenge(challenge)
                            } else {
                                await challengeManager.joinChallenge(challenge)
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: challengeManager.challengeProgress[challenge.id] != nil ? "minus.circle" : "plus.circle")
                                .font(.caption)
                            Text(challengeManager.challengeProgress[challenge.id] != nil ? "Leave" : "Join")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(challengeManager.challengeProgress[challenge.id] != nil ? Color.red : Color.primaryBlue)
                        )
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
    }
    
    private var privacyColor: Color {
        switch challenge.privacy {
        case .privateChallenge: return .gray
        case .group: return .primaryBlue
        case .publicChallenge: return .primaryGreen
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

// MARK: - Leaderboard Row View
struct LeaderboardRowView: View {
    let player: User
    let rank: Int
    
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
            
            // Points
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.totalPoints)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("points")
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
