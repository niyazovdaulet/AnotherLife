//
//  LuxuryJoinSuccessAlert.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

struct LuxuryJoinSuccessAlert: View {
    @Binding var isPresented: Bool
    let message: String
    var onAwesomeButtonTapped: (() -> Void)? = nil
    
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
                        // Call the callback if provided (e.g., navigate to My Challenges)
                        onAwesomeButtonTapped?()
                        // Then dismiss the alert
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

