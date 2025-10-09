//
//  LeaderboardListView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

struct LeaderboardListView: View {
    let challenge: Challenge
    let leaderboard: [LeaderboardEntry]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    private var processedLeaderboard: [LeaderboardEntry] {
        guard let currentUser = authManager.currentUser else { return leaderboard }
        
        // Find current user's entry
        let currentUserEntry = leaderboard.first { $0.user.id == currentUser.id }
        
        // Get top 5 entries
        let top5 = Array(leaderboard.prefix(5))
        
        // Check if current user is in top 5
        let isCurrentUserInTop5 = top5.contains { $0.user.id == currentUser.id }
        
        if isCurrentUserInTop5 {
            // If current user is in top 5, just return top 5
            return top5
        } else if let userEntry = currentUserEntry {
            // If current user is not in top 5, add them as 6th entry
            return top5 + [userEntry]
        } else {
            // If no current user entry found, just return top 5
            return top5
        }
    }
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Leaderboard List
                if processedLeaderboard.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No leaderboard data yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Complete your first day to see rankings")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(processedLeaderboard.enumerated()), id: \.element.id) { index, entry in
                            LeaderboardDetailRowView(
                                entry: entry,
                                rank: getActualRank(for: entry, at: index),
                                isCurrentUser: entry.user.id == authManager.currentUser?.id,
                                isTop5: index < 5
                            )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Leaderboard")
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
    
    private func getActualRank(for entry: LeaderboardEntry, at index: Int) -> Int {
        // If this is the 6th entry (index 5) and it's the current user, find their actual rank
        if index == 5 && entry.user.id == authManager.currentUser?.id {
            return leaderboard.firstIndex { $0.user.id == entry.user.id } ?? 0 + 1
        }
        return index + 1
    }
}

struct LeaderboardDetailRowView: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    let isTop5: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankBadgeColor)
                    .frame(width: 32, height: 32)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Avatar
            Circle()
                .fill(isCurrentUser ? Color.primaryBlue : Color.primaryBlue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(entry.user.displayName.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isCurrentUser ? .white : .primaryBlue)
                )
                .overlay(
                    Circle()
                        .stroke(Color.cardBackground, lineWidth: 2)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.user.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primaryBlue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.primaryBlue.opacity(0.1))
                            )
                    }
                }
                
                Text("@\(entry.user.username)")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Challenge Progress
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.completedDays)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("days")
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrentUser && !isTop5 ? Color.primaryBlue.opacity(0.05) : Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrentUser && !isTop5 ? Color.primaryBlue.opacity(0.2) : Color.clear, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
    }
    
    private var rankBadgeColor: Color {
        switch rank {
        case 1:
            return .yellow // Gold
        case 2:
            return .gray // Silver
        case 3:
            return .orange // Bronze
        default:
            return Color.primaryBlue
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1:
            return "crown.fill"
        case 2:
            return "medal.fill"
        case 3:
            return "medal.fill"
        default:
            return ""
        }
    }
}

#Preview {
    LeaderboardListView(
        challenge: Challenge(
            title: "Sample Challenge",
            description: "A sample challenge",
            type: .streak,
            privacy: .group,
            createdBy: "user1",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            targetValue: 7,
            targetUnit: "days",
            pointsReward: 100
        ),
        leaderboard: [
            LeaderboardEntry(user: User(id: "user1", email: "user1@example.com", username: "johndoe", displayName: "John Doe"), completedDays: 5),
            LeaderboardEntry(user: User(id: "user2", email: "user2@example.com", username: "janesmith", displayName: "Jane Smith"), completedDays: 4),
            LeaderboardEntry(user: User(id: "user3", email: "user3@example.com", username: "mikej", displayName: "Mike Johnson"), completedDays: 3),
            LeaderboardEntry(user: User(id: "user4", email: "user4@example.com", username: "sarahw", displayName: "Sarah Wilson"), completedDays: 2),
            LeaderboardEntry(user: User(id: "user5", email: "user5@example.com", username: "davidb", displayName: "David Brown"), completedDays: 1),
            LeaderboardEntry(user: User(id: "current", email: "current@example.com", username: "currentuser", displayName: "Current User"), completedDays: 0)
        ]
    )
    .environmentObject(AuthManager())
}
