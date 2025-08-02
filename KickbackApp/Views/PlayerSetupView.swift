//
//  PlayerSetupView.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Player setup container with animated glass morphism cards for iOS 26
/// Features staggered entrance animations and proper form validation feedback
struct PlayerSetupView: View {
    
    // MARK: - Properties
    
    /// Player data bindings for external view model management
    @Binding var player1Name: String
    @Binding var player1Gender: String
    @Binding var player2Name: String
    @Binding var player2Gender: String
    
    /// Setup completion callback
    let onSetupComplete: () -> Void
    
    /// Animation state management
    @State private var animateIn = false
    @State private var showValidationFeedback = false
    @State private var currentFocusedField: PlayerInputField?
    
    /// Glass effect IDs for smooth morphing transitions
    private let containerGlassID = "player-setup-container"
    private let titleGlassID = "player-setup-title"
    
    /// Layout constants optimized for all iPhone sizes
    private let cardSpacing: CGFloat = 24
    private let containerPadding: CGFloat = 20
    private let titleSpacing: CGFloat = 32
    private let buttonSpacing: CGFloat = 40
    
    /// Animation constants for 60fps performance
    private let staggerDelay: Double = 0.15
    private let entranceAnimationDuration: Double = 0.9
    private let validationAnimationDuration: Double = 0.4
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with glass-compatible gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: titleSpacing) {
                        // Title section with glass effect
                        titleSection
                            .opacity(animateIn ? 1.0 : 0.0)
                            .offset(y: animateIn ? 0 : -40)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateIn)
                        
                        // Player input cards with glass container
                        GlassEffectContainer(glassEffectID: containerGlassID) {
                            playerInputCardsSection(geometry: geometry)
                        }
                        .padding(.horizontal, containerPadding)
                        .opacity(animateIn ? 1.0 : 0.0)
                        .offset(y: animateIn ? 0 : 60)
                        .animation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8).delay(0.4), value: animateIn)
                        
                        // Continue button with validation feedback
                        continueButton
                            .opacity(animateIn ? 1.0 : 0.0)
                            .offset(y: animateIn ? 0 : 80)
                            .animation(.spring(response: entranceAnimationDuration, dampingFraction: 0.8).delay(0.6), value: animateIn)
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.top, 80)
                }
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Player setup screen")
        .accessibilityHint("Enter names and genders for both players to begin")
    }
    
    // MARK: - Subviews
    
    /// Title section with glass effects
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 16) {
            Text("Player Setup")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .glassEffect(
                    style: .prominent,
                    tint: Color("BrandPurple").opacity(0.1),
                    glassID: titleGlassID
                )
                .interactive()
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                )
            
            Text("Enter player information to start your conversation journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, containerPadding)
        }
    }
    
    /// Player input cards section with staggered animations
    @ViewBuilder
    private func playerInputCardsSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: cardSpacing) {
            // Player 1 input card
            PlayerInputCard(
                playerNumber: 1,
                name: $player1Name,
                gender: $player1Gender,
                currentFocusedField: $currentFocusedField,
                glassID: "player1-input"
            )
            .opacity(animateIn ? 1.0 : 0.0)
            .offset(x: animateIn ? 0 : -60)
            .animation(
                .spring(response: entranceAnimationDuration, dampingFraction: 0.8)
                    .delay(0.6),
                value: animateIn
            )
            
            // Player 2 input card
            PlayerInputCard(
                playerNumber: 2,
                name: $player2Name,
                gender: $player2Gender,
                currentFocusedField: $currentFocusedField,
                glassID: "player2-input"
            )
            .opacity(animateIn ? 1.0 : 0.0)
            .offset(x: animateIn ? 0 : 60)
            .animation(
                .spring(response: entranceAnimationDuration, dampingFraction: 0.8)
                    .delay(0.6 + staggerDelay),
                value: animateIn
            )
        }
        .padding(24)
    }
    
    /// Continue button with validation feedback
    @ViewBuilder
    private var continueButton: some View {
        Button(action: handleContinue) {
            HStack(spacing: 12) {
                if isFormValid {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(isFormValid ? "Start Game" : "Complete All Fields")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isFormValid ? 
                                [Color("BrandPurple"), Color("BrandPurpleLight")] : 
                                [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isFormValid ? Color("BrandPurple").opacity(0.3) : .clear,
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            )
            .glassEffect(
                style: .prominent,
                tint: isFormValid ? Color("BrandPurple").opacity(0.1) : .clear
            )
            .interactive()
        }
        .disabled(!isFormValid)
        .scaleEffect(showValidationFeedback ? 0.95 : 1.0)
        .animation(.spring(response: validationAnimationDuration, dampingFraction: 0.6), value: showValidationFeedback)
        .padding(.horizontal, containerPadding)
        .accessibilityLabel(isFormValid ? "Start game" : "Complete all player information first")
        .accessibilityHint("Begins the conversation game with the entered player information")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Computed Properties
    
    /// Glass-compatible background gradient
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.25),
                Color("BrandPurpleLight").opacity(0.15),
                Color.clear
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Form validation state
    private var isFormValid: Bool {
        return !player1Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !player1Gender.isEmpty &&
               !player2Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !player2Gender.isEmpty
    }
    
    // MARK: - Actions
    
    /// Handles continue button tap with validation feedback
    private func handleContinue() {
        if isFormValid {
            // Haptic feedback for success
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Call completion handler
            onSetupComplete()
        } else {
            // Validation feedback animation
            withAnimation(.spring(response: validationAnimationDuration, dampingFraction: 0.6)) {
                showValidationFeedback = true
            }
            
            // Reset feedback state
            DispatchQueue.main.asyncAfter(deadline: .now() + validationAnimationDuration) {
                withAnimation {
                    showValidationFeedback = false
                }
            }
            
            // Haptic feedback for error
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }
}

// MARK: - Preview Support

#Preview("Player Setup - Empty") {
    PlayerSetupView(
        player1Name: .constant(""),
        player1Gender: .constant(""),
        player2Name: .constant(""),
        player2Gender: .constant(""),
        onSetupComplete: {
            print("Setup completed in preview")
        }
    )
    .preferredColorScheme(.light)
}

#Preview("Player Setup - Partially Filled") {
    PlayerSetupView(
        player1Name: .constant("Alex"),
        player1Gender: .constant("They/Them"),
        player2Name: .constant(""),
        player2Gender: .constant(""),
        onSetupComplete: {
            print("Setup completed in preview")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Player Setup - Complete") {
    PlayerSetupView(
        player1Name: .constant("Alex"),
        player1Gender: .constant("They/Them"),
        player2Name: .constant("Jordan"),
        player2Gender: .constant("She/Her"),
        onSetupComplete: {
            print("Setup completed in preview")
        }
    )
    .preferredColorScheme(.light)
}