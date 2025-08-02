//
//  GameStatusView.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Game status display with iOS 26 glass morphism and smooth state transitions
/// Shows current game state, player information, and progress with elegant animations
struct GameStatusView: View {
    
    // MARK: - Properties
    
    let player1Name: String
    let player1Gender: String
    let player2Name: String
    let player2Gender: String
    let currentPlayerNumber: Int
    let gameMode: ConversationMode?
    let cardsPlayed: Int
    let totalCards: Int
    @Binding var isVisible: Bool
    
    /// Animation state management
    @State private var animateIn = false
    @State private var progressAnimation: CGFloat = 0
    @State private var pulseCurrentPlayer = false
    
    /// Glass effect IDs for smooth morphing
    private let containerGlassID = "game-status-container"
    private let progressGlassID = "game-status-progress"
    
    /// Layout constants optimized for all screen sizes
    private let containerPadding: CGFloat = 20
    private let sectionSpacing: CGFloat = 16
    private let cornerRadius: CGFloat = 18
    private let playerCardHeight: CGFloat = 60
    
    /// Animation constants for 60fps performance
    private let entranceAnimationDuration: Double = 0.8
    private let progressAnimationDuration: Double = 1.2
    private let pulseAnimationDuration: Double = 2.0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: sectionSpacing) {
            // Game mode header with glass effect
            if let gameMode = gameMode {
                gameModeHeader(mode: gameMode)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(y: animateIn ? 0 : -30)
                    .animation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8).delay(0.1), value: animateIn)
            }
            
            // Players section with glass container
            GlassEffectContainer(glassEffectID: containerGlassID) {
                playersSection
            }
            .opacity(animateIn ? 1.0 : 0.0)
            .offset(y: animateIn ? 0 : -20)
            .animation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8).delay(0.3), value: animateIn)
            
            // Game progress section with glass effect
            gameProgressSection
                .opacity(animateIn ? 1.0 : 0.0)
                .offset(y: animateIn ? 0 : -10)
                .animation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8).delay(0.5), value: animateIn)
        }
        .padding(.horizontal, containerPadding)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
        .onAppear {
            if isVisible {
                startAnimation()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game status information")
        .accessibilityHint("Shows current players, game mode, and progress")
    }
    
    // MARK: - Subviews
    
    /// Game mode header with stunning glass morphism
    @ViewBuilder
    private func gameModeHeader(mode: ConversationMode) -> some View {
        HStack(spacing: 12) {
            // Mode icon with glass effect
            Image(systemName: mode.iconName)
                .font(.title2)
                .foregroundColor(mode.primaryColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(mode.primaryColor.opacity(0.1))
                                .blendMode(.overlay)
                        )
                )
                .glassEffect(
                    style: .prominent,
                    tint: mode.primaryColor.opacity(0.2)
                )
                .interactive()
            
            // Mode title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    mode.primaryColor.opacity(0.1),
                                    mode.primaryColor.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                )
                .shadow(
                    color: mode.primaryColor.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            mode.primaryColor.opacity(0.3),
                            mode.primaryColor.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .glassEffect(
            style: .regular,
            tint: mode.primaryColor.opacity(0.05)
        )
        .interactive()
    }
    
    /// Players section with glass cards
    @ViewBuilder
    private var playersSection: some View {
        VStack(spacing: 12) {
            // Section title
            Text("Players")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Player cards
            VStack(spacing: 8) {
                playerCard(
                    name: player1Name,
                    gender: player1Gender,
                    playerNumber: 1,
                    isCurrentPlayer: currentPlayerNumber == 1
                )
                
                playerCard(
                    name: player2Name,
                    gender: player2Gender,
                    playerNumber: 2,
                    isCurrentPlayer: currentPlayerNumber == 2
                )
            }
        }
        .padding(20)
    }
    
    /// Individual player card with glass morphism
    @ViewBuilder
    private func playerCard(name: String, gender: String, playerNumber: Int, isCurrentPlayer: Bool) -> some View {
        HStack(spacing: 16) {
            // Player avatar with glass effect
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .fill(playerColor(for: playerNumber).opacity(0.1))
                            .blendMode(.overlay)
                    )
                    .scaleEffect(isCurrentPlayer && pulseCurrentPlayer ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: pulseAnimationDuration)
                            .repeatForever(autoreverses: true),
                        value: pulseCurrentPlayer
                    )
                
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundColor(playerColor(for: playerNumber))
            }
            .glassEffect(
                style: .prominent,
                tint: playerColor(for: playerNumber).opacity(0.15)
            )
            .interactive()
            
            // Player information
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if isCurrentPlayer {
                        Text("TURN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(playerColor(for: playerNumber))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                
                Text(gender)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: playerCardHeight)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isCurrentPlayer ? 
                            playerColor(for: playerNumber).opacity(0.1) : 
                            Color.clear
                        )
                        .blendMode(.overlay)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isCurrentPlayer ? 
                    playerColor(for: playerNumber).opacity(0.3) : 
                    Color.clear,
                    lineWidth: isCurrentPlayer ? 2 : 0
                )
        )
        .glassEffect(
            style: .regular,
            tint: isCurrentPlayer ? playerColor(for: playerNumber).opacity(0.1) : Color.clear
        )
        .interactive()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Player \(playerNumber): \(name), \(gender)")
        .accessibilityHint(isCurrentPlayer ? "Current player's turn" : "Waiting for turn")
        .accessibilityAddTraits(isCurrentPlayer ? [.isSelected] : [])
    }
    
    /// Game progress section with animated progress bar
    @ViewBuilder
    private var gameProgressSection: some View {
        VStack(spacing: 12) {
            // Progress header
            HStack {
                Text("Game Progress")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                Text("\(cardsPlayed) / \(totalCards) cards")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            // Animated progress bar with glass effect
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .frame(height: 12)
                        .glassEffect(
                            style: .regular,
                            tint: Color.clear,
                            glassID: progressGlassID
                        )
                    
                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("BrandPurple"),
                                    Color("BrandPurpleLight")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progressAnimation,
                            height: 12
                        )
                        .glassEffect(
                            style: .prominent,
                            tint: Color("BrandPurple").opacity(0.2)
                        )
                        .interactive()
                }
            }
            .frame(height: 12)
            .animation(.spring(response: progressAnimationDuration, dampingFraction: 0.8), value: progressAnimation)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
        .glassEffect(
            style: .regular,
            tint: Color("BrandPurple").opacity(0.05)
        )
        .interactive()
    }
    
    // MARK: - Computed Properties
    
    /// Player-specific color theming
    private func playerColor(for playerNumber: Int) -> Color {
        switch playerNumber {
        case 1:
            return Color("BrandPurple")
        case 2:
            return Color("BrandPurpleLight")
        default:
            return .blue
        }
    }
    
    /// Calculated progress percentage
    private var progressPercentage: CGFloat {
        guard totalCards > 0 else { return 0 }
        return CGFloat(cardsPlayed) / CGFloat(totalCards)
    }
    
    // MARK: - Animation Methods
    
    /// Starts the complete animation sequence
    private func startAnimation() {
        // Reset state
        resetAnimation()
        
        // Start entrance animation
        withAnimation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8)) {
            animateIn = true
        }
        
        // Start progress bar animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: progressAnimationDuration, dampingFraction: 0.8)) {
                progressAnimation = progressPercentage
            }
        }
        
        // Start current player pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            pulseCurrentPlayer = true
        }
    }
    
    /// Resets all animation states
    private func resetAnimation() {
        animateIn = false
        progressAnimation = 0
        pulseCurrentPlayer = false
    }
}

// MARK: - Preview Support

#Preview("Game Status - Beginning") {
    GameStatusView(
        player1Name: "Alex",
        player1Gender: "They/Them",
        player2Name: "Jordan",
        player2Gender: "She/Her",
        currentPlayerNumber: 1,
        gameMode: .blindDate,
        cardsPlayed: 2,
        totalCards: 10,
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

#Preview("Game Status - Mid Game") {
    GameStatusView(
        player1Name: "Alex",
        player1Gender: "They/Them",
        player2Name: "Jordan",
        player2Gender: "She/Her",
        currentPlayerNumber: 2,
        gameMode: .couples,
        cardsPlayed: 7,
        totalCards: 12,
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

#Preview("Game Status - No Mode") {
    GameStatusView(
        player1Name: "Alex",
        player1Gender: "They/Them",
        player2Name: "Jordan",
        player2Gender: "She/Her",
        currentPlayerNumber: 1,
        gameMode: nil,
        cardsPlayed: 0,
        totalCards: 8,
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