//
//  UserModels.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation
import SwiftUI

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable {
    let id: String
    let user: User
    let completedDays: Int
    
    init(user: User, completedDays: Int) {
        self.id = user.id
        self.user = user
        self.completedDays = completedDays
    }
}

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String // Firebase UID
    let email: String
    var username: String
    var displayName: String
    let profileImageURL: String?
    let createdAt: Date
    var lastActiveAt: Date
    var totalPoints: Int
    var level: Int
    var badges: [String] // Badge IDs
    
    init(id: String, email: String, username: String, displayName: String, profileImageURL: String? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.totalPoints = 0
        self.level = 1
        self.badges = []
    }
}

// MARK: - Challenge Types
enum ChallengeType: String, CaseIterable, Codable {
    case streak = "streak"
    case frequency = "frequency"
    case timeBased = "timeBased"
    case habitSpecific = "habitSpecific"
    case combination = "combination"
    
    var displayName: String {
        switch self {
        case .streak: return "Streak"
        case .frequency: return "Frequency"
        case .timeBased: return "Time-Based"
        case .habitSpecific: return "Habit-Specific"
        case .combination: return "Combination"
        }
    }
    
    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .frequency: return "repeat"
        case .timeBased: return "clock.fill"
        case .habitSpecific: return "star.fill"
        case .combination: return "link"
        }
    }
}

enum ChallengePrivacy: String, CaseIterable, Codable {
    case privateChallenge = "private"
    case group = "group"
    case publicChallenge = "public"
    
    var displayName: String {
        switch self {
        case .privateChallenge: return "Private"
        case .group: return "Group"
        case .publicChallenge: return "Public"
        }
    }
}

enum ChallengeStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case failed = "failed"
    case paused = "paused"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .primaryBlue
        case .completed: return .primaryGreen
        case .failed: return .primaryRed
        case .paused: return .orange
        case .cancelled: return .gray
        }
    }
}

// MARK: - Challenge Model
struct Challenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: ChallengeType
    let privacy: ChallengePrivacy
    let createdBy: String // User ID
    let createdAt: Date
    let startDate: Date
    let endDate: Date
    let targetValue: Int // e.g., 7 for 7-day streak
    let targetUnit: String // e.g., "days", "times", "hours"
    let habitIds: [String] // For habit-specific challenges
    let pointsReward: Int
    let badgeReward: String? // Badge ID
    var memberCount: Int
    var isActive: Bool
    
    init(title: String, description: String, type: ChallengeType, privacy: ChallengePrivacy, createdBy: String, startDate: Date, endDate: Date, targetValue: Int, targetUnit: String, habitIds: [String] = [], pointsReward: Int = 100, badgeReward: String? = nil, memberCount: Int = 1) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.type = type
        self.privacy = privacy
        self.createdBy = createdBy
        self.createdAt = Date()
        self.startDate = startDate
        self.endDate = endDate
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.habitIds = habitIds
        self.pointsReward = pointsReward
        self.badgeReward = badgeReward
        self.memberCount = memberCount
        self.isActive = true
    }
    
    // Custom initializer for parsing from Firebase
    init(id: String, title: String, description: String, type: ChallengeType, privacy: ChallengePrivacy, createdBy: String, createdAt: Date, startDate: Date, endDate: Date, targetValue: Int, targetUnit: String, habitIds: [String], pointsReward: Int, badgeReward: String?, memberCount: Int, isActive: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.privacy = privacy
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.habitIds = habitIds
        self.pointsReward = pointsReward
        self.badgeReward = badgeReward
        self.memberCount = memberCount
        self.isActive = isActive
    }
}

// MARK: - Challenge Progress Model
struct ChallengeProgress: Identifiable, Codable {
    let id: String
    let challengeId: String
    let userId: String
    let joinedAt: Date
    var currentValue: Int
    var status: ChallengeStatus
    var lastUpdatedAt: Date
    var completedAt: Date?
    
    init(challengeId: String, userId: String) {
        self.id = UUID().uuidString
        self.challengeId = challengeId
        self.userId = userId
        self.joinedAt = Date()
        self.currentValue = 0
        self.status = .active
        self.lastUpdatedAt = Date()
        self.completedAt = nil
    }
    
    // Custom initializer for parsing from Firebase
    init(id: String, challengeId: String, userId: String, joinedAt: Date, currentValue: Int, status: ChallengeStatus, lastUpdatedAt: Date, completedAt: Date?) {
        self.id = id
        self.challengeId = challengeId
        self.userId = userId
        self.joinedAt = joinedAt
        self.currentValue = currentValue
        self.status = status
        self.lastUpdatedAt = lastUpdatedAt
        self.completedAt = completedAt
    }
}

// MARK: - Challenge Invitation Model
struct ChallengeInvitation: Identifiable, Codable {
    let id: String
    let challengeId: String
    let fromUserId: String
    let toUserId: String?
    let toUsername: String?
    let inviteCode: String // For link-based invites
    let createdAt: Date
    var isAccepted: Bool
    var acceptedAt: Date?
    
    init(challengeId: String, fromUserId: String, toUserId: String? = nil, toUsername: String? = nil) {
        self.id = UUID().uuidString
        self.challengeId = challengeId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.toUsername = toUsername
        self.inviteCode = UUID().uuidString
        self.createdAt = Date()
        self.isAccepted = false
        self.acceptedAt = nil
    }
}

// MARK: - Badge Model
struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let rarity: BadgeRarity
    let pointsRequired: Int
    
    init(id: String, name: String, description: String, icon: String, color: String, rarity: BadgeRarity, pointsRequired: Int) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.rarity = rarity
        self.pointsRequired = pointsRequired
    }
}

enum BadgeRarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Predefined Badges
struct PredefinedBadges {
    static let badges: [Badge] = [
        // Streak Badges
        Badge(id: "streak_7", name: "Week Warrior", description: "Complete a 7-day streak", icon: "flame.fill", color: "#FF6B6B", rarity: .common, pointsRequired: 50),
        Badge(id: "streak_30", name: "Month Master", description: "Complete a 30-day streak", icon: "flame.fill", color: "#FF8C42", rarity: .rare, pointsRequired: 200),
        Badge(id: "streak_100", name: "Century Champion", description: "Complete a 100-day streak", icon: "flame.fill", color: "#FFD93D", rarity: .epic, pointsRequired: 500),
        
        // Challenge Badges
        Badge(id: "first_challenge", name: "Challenge Rookie", description: "Complete your first challenge", icon: "star.fill", color: "#4ECDC4", rarity: .common, pointsRequired: 25),
        Badge(id: "challenge_creator", name: "Challenge Creator", description: "Create your first challenge", icon: "plus.circle.fill", color: "#45B7D1", rarity: .common, pointsRequired: 25),
        Badge(id: "group_leader", name: "Group Leader", description: "Create a group challenge", icon: "person.3.fill", color: "#96CEB4", rarity: .rare, pointsRequired: 100),
        
        // Social Badges
        Badge(id: "inviter", name: "Social Butterfly", description: "Invite 5 friends to challenges", icon: "person.badge.plus", color: "#FECA57", rarity: .rare, pointsRequired: 150),
        Badge(id: "team_player", name: "Team Player", description: "Join 10 group challenges", icon: "person.2.fill", color: "#FF9FF3", rarity: .epic, pointsRequired: 300),
        
        // Achievement Badges
        Badge(id: "points_1000", name: "Point Collector", description: "Earn 1000 points", icon: "dollarsign.circle.fill", color: "#54A0FF", rarity: .rare, pointsRequired: 1000),
        Badge(id: "points_5000", name: "Point Master", description: "Earn 5000 points", icon: "dollarsign.circle.fill", color: "#5F27CD", rarity: .epic, pointsRequired: 5000),
        Badge(id: "points_10000", name: "Point Legend", description: "Earn 10000 points", icon: "dollarsign.circle.fill", color: "#FF9F43", rarity: .legendary, pointsRequired: 10000)
    ]
}
