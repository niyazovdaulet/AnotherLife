//
//  ChallengeDetailView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

// MARK: - Daily Status Enum
enum DailyStatus: String, CaseIterable {
    case notStarted = "notStarted"
    case completed = "completed"
    case skipped = "skipped"
    
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        }
    }
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .completed: return .primaryGreen
        case .skipped: return .orange
        }
    }
}

struct ChallengeDetailView: View {
    let challenge: Challenge
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingInviteSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var currentValue: Int = 0
    @State private var isSaved = false
    @State private var todayStatus: DailyStatus = .notStarted
    @State private var currentStreak: Int = 0
    @State private var members: [User] = []
    @State private var leaderboard: [LeaderboardEntry] = []
    @State private var activityFeed: [ActivityItem] = []
    @State private var isLoading = false
    @State private var streakHeatmapData: [String: DailyStatus] = [:]
    @State private var isProgressSaved = false
    @State private var isSaving = false
    @State private var showSaveConfirmation = false
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var celebrationPoints = 0
    @State private var showingMembersSheet = false
    @State private var showingLeaderboardSheet = false
    @State private var showingCompletionAlert = false
    @State private var completionAlertMessage = ""
    
    private var progress: ChallengeProgress? {
        challengeManager.challengeProgress[challenge.id]
    }
    
    private var isOwner: Bool {
        challenge.createdBy == authManager.currentUser?.id
    }
    
    private var isParticipant: Bool {
        progress != nil
    }
    
    private var isChallengeEnded: Bool {
        Date() > challenge.endDate
    }
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let endDate = challenge.endDate
        return max(0, calendar.dateComponents([.day], from: today, to: endDate).day ?? 0)
    }
    
    private var progressPercentage: Double {
        guard challengeDuration > 0 else { return 0 }
        return min(1.0, Double(currentValue) / Double(challengeDuration))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Header
                    heroHeaderView
                    
                    // Primary Action
                    primaryActionView
                    
                    // Progress Section
                    progressSectionView
                    
                    // Streak Section
                    streakSectionView
                    
                    // Leaderboard Section
                    leaderboardSectionView
                    
                    // Activity Feed
                    activityFeedView
                    
                    // Members Section
                    membersSectionView
                    
                    // Leave Challenge Button (for non-owners who are participants)
                    if isParticipant && !isOwner {
                        leaveChallengeButton
                    }
                    
                    // Owner Tools (if owner)
                    if isOwner {
                        ownerToolsView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadChallengeData()
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteMembersView(challenge: challenge)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditChallengeView(challenge: challenge)
        }
        .sheet(isPresented: $showingMembersSheet) {
            MembersListView(challenge: challenge, members: members)
        }
        .sheet(isPresented: $showingLeaderboardSheet) {
            LeaderboardListView(challenge: challenge, leaderboard: leaderboard)
        }
        .alert("Delete Challenge", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteChallenge()
                }
            }
        } message: {
            Text("Are you sure you want to delete this challenge? This action cannot be undone.")
        }
        .alert("Challenge Completed! 🎉", isPresented: $showingCompletionAlert) {
            Button("Awesome!") {
                showingCompletionAlert = false
                // Dismiss the detail view to return to challenges list
                dismiss()
            }
        } message: {
            Text(completionAlertMessage)
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
    
    // MARK: - Hero Header
    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(challenge.description)
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Type Icon
                Image(systemName: challenge.type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.primaryBlue)
            }
            
            // Pills Row
            HStack(spacing: 12) {
                // Visibility Pill
                Text(challenge.privacy.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(privacyColor.opacity(0.1))
                    )
                    .foregroundColor(privacyColor)
                
                // Duration Pill
                Text("\(challengeDuration) days")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.primaryGreen.opacity(0.1))
                    )
                    .foregroundColor(.primaryGreen)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Primary Action
    private var primaryActionView: some View {
        VStack(spacing: 16) {
            // Check if user is participating in the challenge
            if progress == nil {
                // Join Challenge Section
                VStack(spacing: 12) {
                    Text("Join this challenge to start tracking your progress!")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { joinChallenge() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Join Challenge")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primaryBlue)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                // Today's Status Header
                HStack {
                    Text("Today's Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    if isChallengeEnded {
                        Text("Challenge Ended")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    } else {
                        Text(todayStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(todayStatus.color)
                    }
                }
                
                // Daily Challenge Actions
                VStack(spacing: 12) {
                    if isChallengeEnded {
                        // Challenge ended - show read-only status
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: todayStatus == .completed ? "checkmark.circle.fill" : "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(todayStatus == .completed ? .primaryGreen : .orange)
                                
                                Text(todayStatus == .completed ? "Completed" : "Skipped")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                    Text("Locked")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cardBackground)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            
                            Text("This challenge has ended. Status changes are no longer allowed.")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    } else if isProgressSaved {
                        // Show saved status and edit button
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: todayStatus == .completed ? "checkmark.circle.fill" : "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(todayStatus == .completed ? .primaryGreen : .orange)
                                
                                Text(todayStatus == .completed ? "Completed" : "Skipped")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                    Text("Saved")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.primaryGreen)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cardBackground)
                                    .stroke(Color.primaryGreen, lineWidth: 1)
                            )
                            
                            Button(action: { 
                                isProgressSaved = false
                                todayStatus = .notStarted
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                        .font(.title3)
                                    Text("Edit")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.primaryBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.primaryBlue.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        // Show action buttons
                        HStack(spacing: 12) {
                            // Completed Button
                            Button(action: { 
                                updateTodayStatus(.completed)
                                Task {
                                    await autoSaveProgress()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isSaving && todayStatus == .completed {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                    }
                                    Text("Completed")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(todayStatus == .completed ? Color.primaryGreen : Color.primaryGreen.opacity(0.7))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isSaving || isChallengeEnded)
                            
                            // Skipped Button
                            Button(action: { 
                                updateTodayStatus(.skipped)
                                Task {
                                    await autoSaveProgress()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isSaving && todayStatus == .skipped {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                    }
                                    Text("Skipped")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(todayStatus == .skipped ? Color.orange : Color.orange.opacity(0.7))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isSaving || isChallengeEnded)
                        }
                        
                        // Undo Button (if status is not notStarted)
                        if todayStatus != .notStarted {
                            Button(action: { 
                                updateTodayStatus(.notStarted)
                                Task {
                                    await autoSaveProgress()
                                }
                            }) {
                                Text("Undo")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isSaving)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                // Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text("\(currentValue) / \(challengeDuration) days")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    
                    ProgressView(value: progressPercentage, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .primaryBlue))
                        .scaleEffect(x: 1, y: 3, anchor: .center)
                }
                
                // Days Left Info
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(daysRemaining) days left")
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
    }
    
    // MARK: - Streak Section
    private var streakSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streak")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                // Current Streak
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    Text("Current Streak: \(currentStreak)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                
                // Calendar Heatmap
                calendarHeatmapView
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Leaderboard Section
    private var leaderboardSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Leaderboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if !leaderboard.isEmpty {
                    Button("See all") {
                        showingLeaderboardSheet = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.primaryBlue)
                }
            }
            
            VStack(spacing: 8) {
                if leaderboard.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 32))
                            .foregroundColor(.textSecondary)
                        
                        Text("No leaderboard data yet")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Text("Complete your first day to see rankings")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 20)
                } else {
                    ForEach(Array(leaderboard.prefix(5).enumerated()), id: \.element.id) { index, entry in
                        LeaderboardDetailRowView(
                            entry: entry,
                            rank: index + 1,
                            isCurrentUser: entry.user.id == authManager.currentUser?.id,
                            isTop5: index < 5
                        )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Activity Feed
    private var activityFeedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                if activityFeed.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 32))
                            .foregroundColor(.textSecondary)
                        
                        Text("No activity yet")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Text("Activity will appear here as members participate")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 20)
                } else {
                    ForEach(activityFeed, id: \.id) { activity in
                        ActivityRowView(activity: activity)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Members Section
    private var membersSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Members")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(members.count)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Button(action: { showingMembersSheet = true }) {
                VStack(spacing: 12) {
                    if members.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2")
                                .font(.system(size: 32))
                                .foregroundColor(.textSecondary)
                            
                            Text("No members yet")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            
                            Text("Tap to invite friends to join this challenge")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 20)
                    } else {
                        // Member Avatars
                        HStack(spacing: -8) {
                            ForEach(Array(members.prefix(5)), id: \.id) { member in
                                Circle()
                                    .fill(Color.primaryBlue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(member.displayName.prefix(1)))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primaryBlue)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.cardBackground, lineWidth: 2)
                                    )
                            }
                            
                            if members.count > 5 {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("+\(members.count - 5)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.textSecondary)
                                    )
                            }
                        }
                        
                        // Tap hint
                        HStack {
                            Text("Tap to view all members")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Leave Challenge Button
    private var leaveChallengeButton: some View {
        VStack(spacing: 16) {
            Button(action: { 
                Task {
                    await leaveChallenge()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                    Text("Leave Challenge")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Owner Tools
    private var ownerToolsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Owner Tools")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                Button(action: { showingEditSheet = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Challenge")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: { showingInviteSheet = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Members")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Archive/Delete")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primaryRed)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Calendar Heatmap
    private var calendarHeatmapView: some View {
        VStack(spacing: 8) {
            Text("Challenge Progress")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
            
            let totalDays = challengeDuration
            let columns = min(7, totalDays) // Max 7 columns, but fewer if challenge is shorter
            let rows = (totalDays + columns - 1) / columns // Calculate rows needed
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: columns), spacing: 2) {
                ForEach(0..<totalDays, id: \.self) { day in
                    let date = Calendar.current.date(byAdding: .day, value: day, to: challenge.startDate) ?? challenge.startDate
                    let dateKey = DateFormatter.dateKey.string(from: date)
                    let status = streakHeatmapData[dateKey]
                    let dayNumber = Calendar.current.component(.day, from: date)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    ChallengeDayTileView(
                        dayNumber: dayNumber,
                        status: status,
                        isToday: isToday,
                        onTap: {
                            // Optional: Add tap functionality for editing daily status
                        }
                    )
                }
            }
        }
    }
    
    private var challengeDuration: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
        return max(1, days) // Ensure at least 1 day
    }
    
    private func heatmapColor(for status: DailyStatus?) -> Color {
        switch status {
        case .completed:
            return Color.primaryGreen
        case .skipped:
            return Color.orange
        case .notStarted, .none:
            return Color.gray.opacity(0.2)
        }
    }
    
    // MARK: - Helper Methods
    private var privacyColor: Color {
        switch challenge.privacy {
        case .privateChallenge: return .gray
        case .group: return .primaryBlue
        case .publicChallenge: return .primaryGreen
        }
    }
    
    private var periodText: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
        
        if days <= 7 {
            return "Week"
        } else if days <= 30 {
            return "Month"
        } else {
            return "Long-term"
        }
    }
    
    private var todayStatusText: String {
        if currentValue > 0 {
            return "Completed"
        } else {
            return "Not started"
        }
    }
    
    private var todayStatusColor: Color {
        if currentValue > 0 {
            return .primaryGreen
        } else {
            return .gray
        }
    }
    
    private func updateTodayStatus(_ status: DailyStatus) {
        todayStatus = status
        
        // Don't modify currentValue here - it represents total completed days
        // The autoSaveProgress function will handle the actual progress update 
    }
    
    private func autoSaveProgress() async {
        guard !isSaving else { return }
        
        isSaving = true
        
        // Check if user is in the challenge
        if challengeManager.challengeProgress[challenge.id] == nil {
            print("❌ User not in challenge - cannot save progress")
            isSaving = false
            return
        }
        
        // Save the daily status first
        let statusSaved = await challengeManager.updateDailyStatus(challenge.id, status: todayStatus)
        
        // Update challenge progress (this will automatically calculate the correct value from daily statuses)
        // Pass 0 as a placeholder - the function will calculate the actual value
        let progressSaved = await challengeManager.updateChallengeProgress(challenge.id, newValue: 0)
        
        // Add activity entry (this will check for duplicates)
        let activitySaved = await challengeManager.addChallengeActivity(
            challengeId: challenge.id,
            action: todayStatus == .completed ? "completed" : "skipped"
        )
        
        await MainActor.run {
            if statusSaved && progressSaved && activitySaved {
                print("✅ Progress saved successfully!")
                isProgressSaved = true
                
                // Reload the current value from the updated progress
                if let updatedProgress = challengeManager.challengeProgress[challenge.id] {
                    currentValue = updatedProgress.currentValue
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Show brief confirmation
                showSaveConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSaveConfirmation = false
                }
                
                // Check for milestones and show celebration
                if todayStatus == .completed {
                    checkForMilestones()
                }
            } else {
                print("❌ Failed to save progress")
            }
            isSaving = false
        }
    }
    
    private func joinChallenge() {
        Task {
            print("🔄 Joining challenge: \(challenge.id)")
            let joined = await challengeManager.joinChallenge(challenge)
            if joined {
                print("✅ Successfully joined challenge")
                await MainActor.run {
                    // Reload data to reflect the join
                    loadChallengeData()
                }
            } else {
                print("❌ Failed to join challenge")
                // TODO: Show error alert to user
            }
        }
    }
    
    private func leaveChallenge() async {
        print("🔄 Leaving challenge: \(challenge.id)")
        let left = await challengeManager.leaveChallenge(challenge)
        if left {
            print("✅ Successfully left challenge")
            await MainActor.run {
                // Don't dismiss - just update the UI state
                // The view will automatically update to show "Join Challenge" button
                // and the challenge will disappear from "My Challenges" tab
            }
        } else {
            print("❌ Failed to leave challenge")
            // TODO: Show error alert to user
        }
    }
    
    
    private func saveChallenge() {
        isSaved.toggle()
        // TODO: Save challenge to user's saved challenges in Firebase
        print("Saving challenge: \(challenge.id)")
    }
    
    private func loadChallengeData() {
        isLoading = true
        
        // Load current progress
        currentValue = progress?.currentValue ?? 0
        
        Task {
            // Load today's status
            let todayStatus = await challengeManager.getDailyStatus(challenge.id)
            await MainActor.run {
                self.todayStatus = todayStatus
            }
            
            await loadStreakData()
            await loadMembersData()
            await loadLeaderboardData()
            await loadActivityData()
            
            await MainActor.run {
                // Check if today's progress has already been saved
                if let progress = progress {
                    // Check if there's a daily status for today
                    let today = Date()
                    let dateKey = DateFormatter.dateKey.string(from: today)
                    // For now, assume progress is saved if user has any progress
                    isProgressSaved = progress.currentValue > 0
                } else {
                    isProgressSaved = false
                }
                
                isLoading = false
            }
        }
    }
    
    private func loadStreakData() async {
        let streak = await challengeManager.calculateStreak(challenge.id)
        let heatmapData = await challengeManager.getStreakHeatmapData(challenge.id)
        await MainActor.run {
            currentStreak = streak
            streakHeatmapData = heatmapData
        }
    }
    
    private func loadMembersData() async {
        let members = await challengeManager.getChallengeMembers(challenge.id)
        await MainActor.run {
            // If no members found but user is in the challenge, show current user
            if members.isEmpty && progress != nil {
                if let currentUser = authManager.currentUser {
                    self.members = [currentUser]
                } else {
                    self.members = []
                }
            } else {
                self.members = members
            }
        }
    }
    
    private func loadLeaderboardData() async {
        let leaderboard = await challengeManager.getChallengeLeaderboard(challenge.id)
        await MainActor.run {
            // If no leaderboard data but user is in the challenge, show current user
            if leaderboard.isEmpty && progress != nil {
                if let currentUser = authManager.currentUser {
                    let currentUserEntry = LeaderboardEntry(user: currentUser, completedDays: progress?.currentValue ?? 0)
                    self.leaderboard = [currentUserEntry]
                }
            } else {
                self.leaderboard = leaderboard
            }
        }
    }
    
    private func loadActivityData() async {
        let activity = await challengeManager.getChallengeActivity(challenge.id)
        await MainActor.run {
            // If no activity but user is in the challenge, show their recent activity
            if activity.isEmpty && progress != nil {
                // Create a sample activity entry for the current user
                let currentUserActivity = ActivityItem(
                    id: "current_user_activity",
                    user: "You",
                    action: "joined",
                    createdAt: Date()
                )
                self.activityFeed = [currentUserActivity]
            } else {
                self.activityFeed = activity
            }
        }
    }
    
    private func checkForMilestones() {
        guard let progress = progress else { return }
        
        let newValue = currentValue
        let duration = challengeDuration
        
        // Check for completion milestone (completed all days)
        if newValue >= duration {
            celebrationMessage = "Challenge Completed! 🎉\nYou earned \(challenge.pointsReward) points!"
            celebrationPoints = challenge.pointsReward
            showCelebration = true
            
            // Complete the challenge and award points
            Task {
                let (success, message, points) = await challengeManager.completeChallengeWithCelebration(challenge)
                if success {
                    print("✅ Challenge completed successfully! \(message)")
                    
                    await MainActor.run {
                        // Hide celebration overlay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCelebration = false
                            
                            // Show completion alert after celebration
                            completionAlertMessage = "You've successfully completed \(challenge.title)!\n\nYou earned \(challenge.pointsReward) points! 🎉"
                            showingCompletionAlert = true
                        }
                        
                        // Reload challenge data to reflect completion
                        loadChallengeData()
                    }
                } else {
                    print("❌ Failed to complete challenge: \(message)")
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
                showCelebration = false
            }
        }
    }
    
    private func deleteChallenge() async {
        print("🔄 Deleting challenge: \(challenge.id)")
        let deleted = await challengeManager.deleteChallenge(challenge)
        if deleted {
            print("✅ Successfully deleted challenge")
            await MainActor.run {
                // Dismiss the view after successful deletion
                dismiss()
            }
        } else {
            print("❌ Failed to delete challenge")
            // TODO: Show error alert to user
        }
    }
    
}

// MARK: - Supporting Views

struct ActivityRowView: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.primaryBlue.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(activity.user.prefix(1)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBlue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formatActivityMessage())
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                
                Text(activity.relativeTime)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
    
    private func formatActivityMessage() -> String {
        switch activity.action {
        case "completed":
            return "\(activity.user) checked in (+1)"
        case "skipped":
            return "\(activity.user) skipped the day"
        case "joined":
            return "\(activity.user) joined the challenge"
        case "left":
            return "\(activity.user) left the challenge"
        default:
            return "\(activity.user) \(activity.action)"
        }
    }
}

struct ActivityItem: Identifiable {
    let id: String
    let user: String
    let action: String
    let createdAt: Date
    let relativeTime: String
    
    init(id: String, user: String, action: String, createdAt: Date) {
        self.id = id
        self.user = user
        self.action = action
        self.createdAt = createdAt
        self.relativeTime = Self.formatRelativeTime(from: createdAt)
    }
    
    static func formatRelativeTime(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(timeInterval / 604800)
            return "\(weeks)w ago"
        }
    }
}

// MARK: - Placeholder Views

struct InviteMembersView: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Invite Members")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Share this challenge with friends!")
                    .foregroundColor(.textSecondary)
                
                Spacer()
            }
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

struct EditChallengeView: View {
    let challenge: Challenge
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var selectedType: ChallengeType
    @State private var selectedPrivacy: ChallengePrivacy
    @State private var duration: Int
    @State private var pointsReward: Int
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    init(challenge: Challenge) {
        self.challenge = challenge
        
        // Initialize state with challenge values
        _title = State(initialValue: challenge.title)
        _description = State(initialValue: challenge.description)
        _selectedType = State(initialValue: challenge.type)
        _selectedPrivacy = State(initialValue: challenge.privacy)
        _pointsReward = State(initialValue: challenge.pointsReward)
        
        // Calculate current duration from start and end dates
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 7
        _duration = State(initialValue: max(1, days))
    }
    
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
                        
                        // Challenge Type
                        challengeTypeSection
                        
                        // Privacy Settings
                        privacySection
                        
                        // Duration
                        durationSection
                        
                        // Rewards
                        rewardsSection
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Edit Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChallenge()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                        dismiss()
                    }
        } message: {
            Text("Challenge updated successfully!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.primaryBlue)
            
            Text("Edit Challenge")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Update your challenge details")
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
    
    // MARK: - Challenge Type Section
    private var challengeTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Challenge Type")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(selectedType == type ? .primaryBlue : .textSecondary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                Text(typeDescription(type))
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: selectedType == type ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedType == type ? .primaryBlue : .textSecondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedType == type ? Color.primaryBlue.opacity(0.1) : Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedType == type ? Color.primaryBlue : Color.clear, lineWidth: 2)
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
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                ForEach(ChallengePrivacy.allCases, id: \.self) { privacy in
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
                
                Text("Challenge will run for \(duration) days from the start date")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                // Show warning if extending duration
                if duration > originalDuration {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Extending duration will give participants more time to complete the challenge")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
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
    
    private var originalDuration: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 7
        return max(1, days)
    }
    
    // MARK: - Helper Methods
    private func typeDescription(_ type: ChallengeType) -> String {
        switch type {
        case .streak: return "Complete habits for consecutive days"
        case .frequency: return "Complete habits a certain number of times"
        case .timeBased: return "Complete habits within specific time frames"
        case .habitSpecific: return "Focus on specific habits"
        case .combination: return "Mix of different habit types"
        }
    }
    
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
    
    private func saveChallenge() {
        isLoading = true
        
        Task {
            let success = await challengeManager.updateChallenge(
                challengeId: challenge.id,
                title: title,
                description: description,
                type: selectedType,
                privacy: selectedPrivacy,
                duration: duration,
                pointsReward: pointsReward,
                badgeReward: challenge.badgeReward
            )
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    showingSuccessAlert = true
                } else {
                    errorMessage = challengeManager.errorMessage ?? "Failed to update challenge"
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Challenge Day Tile View
struct ChallengeDayTileView: View {
    let dayNumber: Int
    let status: DailyStatus?
    let isToday: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(tileBackgroundColor)
                    .frame(height: 24)
                
                // Content
                VStack(spacing: 1) {
                    Text("\(dayNumber)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(tileTextColor)
                    
                    if let status = status {
                        Image(systemName: statusIcon(for: status))
                            .font(.system(size: 7))
                            .foregroundColor(tileTextColor)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isToday ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isToday)
    }
    
    private var tileBackgroundColor: Color {
        switch status {
        case .completed:
            return Color.primaryGreen
        case .skipped:
            return Color.orange
        case .notStarted, .none:
            return Color.gray.opacity(0.15)
        }
    }
    
    private var tileTextColor: Color {
        switch status {
        case .completed:
            return .white
        case .skipped:
            return .white
        case .notStarted, .none:
            return Color.textSecondary
        }
    }
    
    private func statusIcon(for status: DailyStatus) -> String {
        switch status {
        case .completed:
            return "checkmark"
        case .skipped:
            return "minus"
        case .notStarted:
            return "circle"
        }
    }
}

#Preview {
    ChallengeDetailView(challenge: Challenge(
        title: "7-Day Fitness Streak",
        description: "Complete your workout routine for 7 consecutive days",
        type: .streak,
        privacy: .group,
        createdBy: "user1",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 9, to: Date())!,
        targetValue: 7,
        targetUnit: "days",
        pointsReward: 100
    ))
    .environmentObject(ChallengeManager())
    .environmentObject(AuthManager())
}

