//
//  AuthView.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var isSignUpMode = false
    @State private var showCustomError = false
    @State private var customErrorTitle = ""
    @State private var customErrorMessage = ""
    @State private var showForgotPassword = false
    @State private var isButtonPressed = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.background
                    .ignoresSafeArea()
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.primaryBlue.opacity(0.1),
                        Color.primaryGreen.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                        
                        // Auth Form
                        authFormView
                        
                        // Social Sign-In
                        socialSignInView
                        
                        // Toggle Auth Mode
                        toggleAuthModeView
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                }
                
                // Loading Overlay
                if authManager.isLoading {
                    loadingOverlay
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showCustomError) {
            CustomErrorView(
                title: customErrorTitle,
                message: customErrorMessage,
                showForgotPassword: showForgotPassword,
                onDismiss: { showCustomError = false },
                onForgotPassword: { handleForgotPassword() }
            )
            .presentationDetents([.height(300)])
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primaryBlue, Color.primaryGreen]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .primaryBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("AnotherLife")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(isSignUpMode ? "Create your account" : "Welcome back")
                    .font(.title3)
                    .foregroundColor(.textSecondary)
                
                Text("Build better habits, one day at a time")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Auth Form View
    private var authFormView: some View {
        VStack(spacing: 20) {
            if isSignUpMode {
                // Sign Up Fields
                VStack(spacing: 16) {
                    // Display Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("Your full name", text: $displayName)
                            .textFieldStyle(AuthTextFieldStyle())
                    }
                    
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("Choose a username", text: $username)
                            .textFieldStyle(AuthTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
            }
            
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(AuthTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(AuthTextFieldStyle())
            }
            
            if isSignUpMode {
                // Confirm Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(AuthTextFieldStyle())
                }
            }
            
            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.primaryRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primaryRed.opacity(0.1))
                    )
            }
            
            // Auth Button with Haptic Feedback
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Button press animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isButtonPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isButtonPressed = false
                    }
                }
                
                handleAuthAction()
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(isSignUpMode ? "Create Account" : "Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.primaryBlue, Color.primaryGreen]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            .disabled(authManager.isLoading || !isFormValid)
            .opacity(isFormValid ? 1.0 : 0.6)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Social Sign-In View
    private var socialSignInView: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle()
                    .fill(Color.textSecondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.textSecondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Apple Sign-In Button
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleAppleSignIn(result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Toggle Auth Mode View
    private var toggleAuthModeView: some View {
        HStack(spacing: 4) {
            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            Button(action: { isSignUpMode.toggle() }) {
                Text(isSignUpMode ? "Sign In" : "Sign Up")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryBlue)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        if isSignUpMode {
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !username.isEmpty && 
                   !displayName.isEmpty && 
                   password == confirmPassword &&
                   password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))
                    .scaleEffect(1.5)
                
                Text(isSignUpMode ? "Creating your account..." : "Signing you in...")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Please wait")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
    }
    
    // MARK: - Actions
    private func handleAuthAction() {
        Task {
            if isSignUpMode {
                await authManager.signUpWithEmail(
                    email: email,
                    password: password,
                    username: username,
                    displayName: displayName
                )
            } else {
                await authManager.signInWithEmail(
                    email: email,
                    password: password
                )
            }
            
            // Check for errors and show custom alert
            if let errorMessage = authManager.errorMessage {
                customErrorTitle = isSignUpMode ? "Sign Up Failed" : "Sign In Failed"
                customErrorMessage = getCustomErrorMessage(errorMessage)
                showForgotPassword = !isSignUpMode && errorMessage.contains("password")
                showCustomError = true
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            // Handle successful Apple Sign-In
            // This would need proper implementation with Firebase
            print("Apple Sign-In successful")
        case .failure(let error):
            authManager.errorMessage = error.localizedDescription
        }
    }
    
    private func handleForgotPassword() {
        // Implement password reset functionality
        print("Forgot password for: \(email)")
        // You can add Firebase password reset here
    }
    
    private func getCustomErrorMessage(_ errorMessage: String) -> String {
        if errorMessage.contains("password") || errorMessage.contains("INVALID_LOGIN_CREDENTIALS") {
            return "Incorrect password. Please try again or reset it below."
        } else if errorMessage.contains("email") {
            return "Invalid email address. Please check and try again."
        } else if errorMessage.contains("network") {
            return "Network error. Please check your connection and try again."
        } else if errorMessage.contains("user-not-found") {
            return "No account found with this email. Please sign up first."
        } else {
            return errorMessage
        }
    }
}

// MARK: - Auth Text Field Style
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Custom Error View
struct CustomErrorView: View {
    let title: String
    let message: String
    let showForgotPassword: Bool
    let onDismiss: () -> Void
    let onForgotPassword: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            ZStack {
                Circle()
                    .fill(Color.primaryRed.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.primaryRed)
            }
            
            // Error Message
            VStack(spacing: 12) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Actions
            VStack(spacing: 12) {
                if showForgotPassword {
                    Button(action: {
                        onForgotPassword()
                        onDismiss()
                    }) {
                        Text("Forgot Password?")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primaryBlue)
                            )
                    }
                }
                
                Button(action: onDismiss) {
                    Text(showForgotPassword ? "Try Again" : "OK")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(showForgotPassword ? .primaryBlue : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(showForgotPassword ? Color.primaryBlue.opacity(0.1) : Color.primaryBlue)
                        )
                }
            }
        }
        .padding(24)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
