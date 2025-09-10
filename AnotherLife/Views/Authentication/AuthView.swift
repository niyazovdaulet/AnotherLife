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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.backgroundGray
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
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
            
            // Auth Button
            Button(action: handleAuthAction) {
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
}

// MARK: - Auth Text Field Style
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.backgroundGray)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
