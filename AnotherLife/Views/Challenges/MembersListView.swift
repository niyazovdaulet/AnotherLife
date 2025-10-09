//
//  MembersListView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

struct MembersListView: View {
    let challenge: Challenge
    let members: [User]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var searchText = ""
    
    private var filteredMembers: [User] {
        if searchText.isEmpty {
            return members
        } else {
            return members.filter { member in
                member.displayName.localizedCaseInsensitiveContains(searchText) ||
                member.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    
                    TextField("Search members...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Members List
                if filteredMembers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(searchText.isEmpty ? "No members yet" : "No members found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        if searchText.isEmpty {
                            Text("Invite friends to join this challenge")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Try adjusting your search")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredMembers, id: \.id) { member in
                                MemberRowView(member: member, isCurrentUser: member.id == authManager.currentUser?.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Members")
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

struct MemberRowView: View {
    let member: User
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(isCurrentUser ? Color.primaryBlue : Color.primaryBlue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(member.displayName.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentUser ? .white : .primaryBlue)
                )
                .overlay(
                    Circle()
                        .stroke(Color.cardBackground, lineWidth: 2)
                )
            
            // Member Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.primaryBlue.opacity(0.1))
                            )
                    }
                }
                
                Text("@\(member.username)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Points/Level Info
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(member.totalPoints)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
                
                Text("Level \(member.level)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
    }
}

#Preview {
    MembersListView(
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
        members: [
            User(id: "user1", email: "user1@example.com", username: "johndoe", displayName: "John Doe"),
            User(id: "user2", email: "user2@example.com", username: "janesmith", displayName: "Jane Smith"),
            User(id: "user3", email: "user3@example.com", username: "mikej", displayName: "Mike Johnson")
        ]
    )
    .environmentObject(AuthManager())
}
