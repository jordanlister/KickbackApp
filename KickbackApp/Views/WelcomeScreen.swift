//
//  WelcomeScreen.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Welcome screen introducing Kickback app with liquid glass design
/// Features animated app logo, headline text, and smooth entrance animations
struct WelcomeScreen: View {
    
    // MARK: - Properties
    
    /// Whether the screen is currently visible
    let isVisible: Bool
    
    /// Action to perform when Next button is tapped
    let onNext: () -> Void
    
    /// Animation state properties
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0.0
    @State private var subtitleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0.0
    @State private var descriptionOffset: CGFloat = 30
    @State private var descriptionOpacity: Double = 0.0
    
    /// Animation timing constants
    private let logoAnimationDelay: Double = 0.2
    private let titleAnimationDelay: Double = 0.5
    private let subtitleAnimationDelay: Double = 0.8
    private let descriptionAnimationDelay: Double = 1.1
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Main content area
                VStack(spacing: 32) {
                    // App logo/icon section
                    logoSection
                    
                    // Text content section
                    textContentSection
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Next button
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color("BrandPurple"))
                    )
                }
                .padding(.bottom, 50)
                
                Spacer() // Extra spacer for better balance
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                startEntranceAnimation()
            } else {
                resetAnimationState()
            }
        }
        .onAppear {
            if isVisible {
                startEntranceAnimation()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to Kickback")
        .accessibilityHint("Introduction screen for the conversation card app")
    }
    
    // MARK: - Subviews
    
    /// App logo with glass morphism effects and scaling animation
    @ViewBuilder
    private var logoSection: some View {
        VStack(spacing: 20) {
            // Main logo container with glass effects
            ZStack {
                // Background glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color("BrandPurple").opacity(0.4),
                                        Color("BrandPurpleLight").opacity(0.2),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(
                        color: Color("BrandPurple").opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                
                // Logo icon (using conversation bubble for Kickback)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color("BrandPurple"),
                                Color("BrandPurpleLight")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .repeating)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
    }
    
    /// Text content with staggered animations
    @ViewBuilder
    private var textContentSection: some View {
        VStack(spacing: 24) {
            // Main title
            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(.secondary)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                
                Text("Kickback")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color("BrandPurple"),
                                Color("BrandPurpleLight")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
            }
            
            // Subtitle
            Text("The Modern Way to Connect")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .offset(y: subtitleOffset)
                .opacity(subtitleOpacity)
            
            // Description text with glass container
            VStack(spacing: 16) {
                Text("Transform conversations into meaningful connections with AI-powered question cards designed for dating and relationships.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("Discover compatibility through authentic dialogue.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .glassEffect(
                style: .regular,
                tint: Color("BrandPurple").opacity(0.08)
            )
            .offset(y: descriptionOffset)
            .opacity(descriptionOpacity)
        }
    }
    
    // MARK: - Animation Methods
    
    /// Starts the staggered entrance animation sequence
    private func startEntranceAnimation() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(logoAnimationDelay)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(titleAnimationDelay)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Subtitle animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(subtitleAnimationDelay)) {
            subtitleOffset = 0
            subtitleOpacity = 1.0
        }
        
        // Description animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(descriptionAnimationDelay)) {
            descriptionOffset = 0
            descriptionOpacity = 1.0
        }
    }
    
    /// Resets all animation states to initial values
    private func resetAnimationState() {
        logoScale = 0.8
        logoOpacity = 0.0
        titleOffset = 30
        titleOpacity = 0.0
        subtitleOffset = 30
        subtitleOpacity = 0.0
        descriptionOffset = 30
        descriptionOpacity = 0.0
    }
}

// MARK: - Preview Support

#Preview("Welcome Screen - Visible") {
    ZStack {
        // Background gradient matching the main app
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        WelcomeScreen(isVisible: true, onNext: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Welcome Screen - Hidden") {
    ZStack {
        // Background gradient matching the main app
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        WelcomeScreen(isVisible: false, onNext: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Welcome Screen - Animation Sequence") {
    struct WelcomeAnimationDemo: View {
        @State private var isVisible = false
        
        var body: some View {
            ZStack {
                // Background gradient matching the main app
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("BrandPurple").opacity(0.4),
                        Color("BrandPurpleLight").opacity(0.3),
                        Color.clear.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                WelcomeScreen(isVisible: isVisible, onNext: {})
                
                // Control button for preview
                VStack {
                    Spacer()
                    Button(isVisible ? "Hide" : "Show") {
                        withAnimation {
                            isVisible.toggle()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                // Auto-start animation after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isVisible = true
                }
            }
        }
    }
    
    return WelcomeAnimationDemo()
        .preferredColorScheme(.light)
}