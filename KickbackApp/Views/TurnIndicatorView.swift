//
//  TurnIndicatorView.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Turn indicator with iOS 26 glass morphism and smooth player transitions
/// Features character-by-character text reveal and buttery smooth animations
struct TurnIndicatorView: View {
    
    // MARK: - Properties
    
    let currentPlayerName: String
    let playerNumber: Int
    @Binding var isVisible: Bool
    
    /// Animation state management
    @State private var animateIn = false
    @State private var textRevealIndex = 0
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    
    /// Glass effect ID for smooth morphing
    private let glassID = "turn-indicator"
    
    /// Layout constants optimized for all screen sizes
    private let containerPadding: CGFloat = 24
    private let iconSize: CGFloat = 32
    private let cornerRadius: CGFloat = 20
    private let shadowRadius: CGFloat = 16
    
    /// Animation constants for 60fps performance
    private let textRevealDelay: Double = 0.05
    private let entranceAnimationDuration: Double = 0.8
    private let pulseAnimationDuration: Double = 2.0
    private let rotationAnimationDuration: Double = 1.5
    
    /// Complete display text for character reveal
    private var displayText: String {
        return "\(currentPlayerName), it's your turn!"
    }
    
    /// Character-by-character revealed text
    private var revealedText: String {
        let endIndex = min(textRevealIndex, displayText.count)
        return String(displayText.prefix(endIndex))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Turn indicator card with glass morphism
            HStack(spacing: 16) {
                // Animated turn icon with glass effect
                turnIcon
                    .glassEffect(
                        style: .prominent,
                        tint: playerColor.opacity(0.2)
                    )
                    .interactive()
                
                // Turn message with character reveal animation
                turnMessage
                    .glassEffect(
                        style: .regular,
                        tint: playerColor.opacity(0.1)
                    )
                    .interactive()
                
                Spacer()
            }
            .padding(.horizontal, containerPadding)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        playerColor.opacity(0.15),
                                        playerColor.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.overlay)
                    )
                    .shadow(
                        color: playerColor.opacity(0.3),
                        radius: shadowRadius,
                        x: 0,
                        y: 8
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                playerColor.opacity(0.4),
                                playerColor.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .glassEffect(
                style: .prominent,
                tint: playerColor.opacity(0.1),
                glassID: glassID
            )
            .interactive()
            
            // Subtitle with glass effect
            subtitleMessage
                .glassEffect(
                    style: .regular,
                    tint: playerColor.opacity(0.05)
                )
                .interactive()
        }
        .scaleEffect(animateIn ? 1.0 : 0.8)
        .opacity(isVisible && animateIn ? 1.0 : 0.0)
        .animation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8), value: animateIn)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                startRevealAnimation()
            } else {
                resetAnimation()
            }
        }
        .onAppear {
            if isVisible {
                startRevealAnimation()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Turn indicator for \(currentPlayerName)")
        .accessibilityHint("It's \(currentPlayerName)'s turn to pick a card")
    }
    
    // MARK: - Subviews
    
    /// Animated turn icon with glass effects
    @ViewBuilder
    private var turnIcon: some View {
        ZStack {
            // Background circle with glass effect
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: iconSize + 16, height: iconSize + 16)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    playerColor.opacity(0.3),
                                    playerColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                )
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: pulseAnimationDuration)
                        .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            // Player icon with rotation animation
            Image(systemName: "person.circle.fill")
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(playerColor)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    .linear(duration: rotationAnimationDuration)
                        .repeatForever(autoreverses: false),
                    value: rotationAngle
                )
        }
    }
    
    /// Turn message with character reveal animation
    @ViewBuilder
    private var turnMessage: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main turn message with character reveal
            HStack {
                Text(revealedText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .animation(.none, value: revealedText)
                
                // Typing cursor effect
                if textRevealIndex < displayText.count {
                    Rectangle()
                        .fill(playerColor)
                        .frame(width: 2, height: 16)
                        .opacity(pulseAnimation ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }
                
                Spacer()
            }
            
            // Player number indicator
            Text("Player \(playerNumber)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(playerColor)
                .textCase(.uppercase)
                .tracking(0.5)
                .opacity(animateIn ? 1.0 : 0.0)
                .animation(.easeInOut.delay(0.8), value: animateIn)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    /// Subtitle message with glass effect
    @ViewBuilder
    private var subtitleMessage: some View {
        Text("Pick a conversation card to continue")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .opacity(animateIn ? 1.0 : 0.0)
            .offset(y: animateIn ? 0 : 20)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.2), value: animateIn)
    }
    
    // MARK: - Computed Properties
    
    /// Player-specific color theming
    private var playerColor: Color {
        switch playerNumber {
        case 1:
            return Color("BrandPurple")
        case 2:
            return Color("BrandPurpleLight")
        default:
            return .blue
        }
    }
    
    // MARK: - Animation Methods
    
    /// Starts the complete reveal animation sequence
    private func startRevealAnimation() {
        // Reset state
        resetAnimation()
        
        // Start entrance animation
        withAnimation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8)) {
            animateIn = true
        }
        
        // Start character reveal after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            startTextReveal()
        }
        
        // Start pulsing animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            pulseAnimation = true
        }
        
        // Start rotation animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            rotationAngle = 360
        }
    }
    
    /// Starts character-by-character text reveal
    private func startTextReveal() {
        guard textRevealIndex < displayText.count else { return }
        
        textRevealIndex += 1
        
        // Continue revealing characters
        DispatchQueue.main.asyncAfter(deadline: .now() + textRevealDelay) {
            startTextReveal()
        }
    }
    
    /// Resets all animation states
    private func resetAnimation() {
        animateIn = false
        textRevealIndex = 0
        pulseAnimation = false
        rotationAngle = 0
    }
}

// MARK: - Preview Support

#Preview("Turn Indicator - Player 1") {
    TurnIndicatorView(
        currentPlayerName: "Alex",
        playerNumber: 1,
        isVisible: .constant(true)
    )
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2),
                Color.clear
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Turn Indicator - Player 2") {
    TurnIndicatorView(
        currentPlayerName: "Jordan",
        playerNumber: 2,
        isVisible: .constant(true)
    )
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2),
                Color.clear
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Turn Indicator - Animation States") {
    VStack(spacing: 32) {
        TurnIndicatorView(
            currentPlayerName: "Alex",
            playerNumber: 1,
            isVisible: .constant(false)
        )
        
        TurnIndicatorView(
            currentPlayerName: "Jordan",
            playerNumber: 2,
            isVisible: .constant(true)
        )
    }
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2),
                Color.clear
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}