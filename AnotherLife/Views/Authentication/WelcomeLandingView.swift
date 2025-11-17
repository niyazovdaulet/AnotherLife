import SwiftUI

struct WelcomeLandingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAuth = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.background
                .ignoresSafeArea()
            
            // Enhanced gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.15),
                    Color.primaryPurple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TabView with 2 pages
                TabView(selection: $currentPage) {
                    // Page 1: Welcome & First Feature
                    WelcomePageOne(currentPage: $currentPage)
                        .tag(0)
                    
                    // Page 2: All Features & Get Started
                    WelcomePageTwo(showingAuth: $showingAuth)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .fullScreenCover(isPresented: $showingAuth) {
            AuthView()
                .environmentObject(authManager)
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue {
                showingAuth = false
            }
        }
    }
}

// MARK: - Welcome Page One
struct WelcomePageOne: View {
    @Binding var currentPage: Int
    @State private var animateIndicator = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 50) {
                Spacer()
                
                // App Icon with enhanced glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 140, height: 140)
                        .blur(radius: 16)
                        .opacity(0.4)
                    
                    // Main icon
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .primaryBlue.opacity(0.4), radius: 24, x: 0, y: 12)
                    
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    }
                
                // App Name & Tagline
                VStack(spacing: 12) {
                    Text("AnotherLife")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Build better habits, one day at a time")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // First Feature
                FeatureCard(
                    icon: "calendar.badge.checkmark",
                    title: "Track Your Habits",
                    description: "Easily log your daily habits with quick taps and beautiful visualizations"
                )
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 60)
            
            // Swipe Indicator (only show on page 1)
            if currentPage == 0 {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Swipe to explore")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.textSecondary.opacity(0.6))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary.opacity(0.6))
                            .offset(x: animateIndicator ? 4 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: animateIndicator
                            )
                    }
                    .padding(.bottom, 50)
                }
                .onAppear {
                    animateIndicator = true
                }
            }
        }
    }
}

// MARK: - Welcome Page Two
struct WelcomePageTwo: View {
    @Binding var showingAuth: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // Header section
            VStack(spacing: 12) {
                Text("Powerful Features")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Everything you need to succeed")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 20)
            
            // All Features with tighter spacing
            VStack(spacing: 20) {
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "See Your Progress",
                    description: "Visualize your journey with insightful analytics and streak tracking"
                )
                
                FeatureCard(
                    icon: "trophy.fill",
                    title: "Join Challenges",
                    description: "Compete with friends and build habits together through engaging challenges"
                )
                
                FeatureCard(
                    icon: "note.text",
                    title: "Reflect & Grow",
                    description: "Capture your thoughts and track your progress with personal notes"
                )
            }
            .padding(.horizontal, 24)
            
            // Additional benefit highlight
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primaryGreen)
                    
                    Text("Join thousands building better habits")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .padding(.top, 10)
            
            Spacer()
            
            // Get Started Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingAuth = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Get Started")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryGradient)
                            .shadow(color: .primaryBlue.opacity(0.4), radius: 16, x: 0, y: 8)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryBlue.opacity(0.15),
                                Color.primaryPurple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.primaryBlue.opacity(0.3),
                                        Color.primaryPurple.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.primaryBlue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

#Preview {
    WelcomeLandingView()
        .environmentObject(AuthManager())
}

