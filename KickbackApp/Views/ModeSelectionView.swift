//
//  ModeSelectionView.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Mode selection screen showcasing iOS 26 Liquid Glass design
/// Features stunning glass morphism cards for different conversation modes
struct ModeSelectionView: View {
    
    // MARK: - Properties
    
    @Binding var selectedMode: ConversationMode?
    let onModeSelected: (ConversationMode) -> Void
    
    @State private var animateIn = false
    @State private var selectedGlassID: String?
    
    /// Layout constants optimized for all iPhone sizes
    private let cardSpacing: CGFloat = 16
    private let cardCornerRadius: CGFloat = 24
    private let titleSpacing: CGFloat = 32
    private let sideInset: CGFloat = 20
    
    /// Animation constants for 60fps performance
    private let staggerDelay: Double = 0.1
    private let cardAnimationDuration: Double = 0.8
    private let selectionAnimationDuration: Double = 0.6
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with glass-compatible gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: titleSpacing) {
                    // Title section with glass effect
                    titleSection
                        .opacity(animateIn ? 1.0 : 0.0)
                        .offset(y: animateIn ? 0 : -30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateIn)
                    
                    // Mode selection cards with glass container
                    GlassEffectContainer(glassEffectID: "mode-container") {
                        modeSelectionGrid(geometry: geometry)
                    }
                    .padding(.horizontal, sideInset)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(y: animateIn ? 0 : 50)
                    .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.4), value: animateIn)
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mode selection screen")
        .accessibilityHint("Choose a conversation mode to begin")
    }
    
    // MARK: - Subviews
    
    /// Title section with glass effects
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Conversation Style")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .glassEffect(
                    style: .regular,
                    tint: Color("BrandPurple").opacity(0.1)
                )
                .interactive()
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            
            Text("Select the perfect mood for your connection")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, sideInset)
        }
    }
    
    /// Mode selection grid with responsive layout
    @ViewBuilder
    private func modeSelectionGrid(geometry: GeometryProxy) -> some View {
        let gridColumns = [
            GridItem(.flexible(), spacing: cardSpacing),
            GridItem(.flexible(), spacing: cardSpacing)
        ]
        
        LazyVGrid(columns: gridColumns, spacing: cardSpacing) {
            ForEach(ConversationMode.allCases, id: \.self) { mode in
                modeCard(for: mode, geometry: geometry)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(y: animateIn ? 0 : 30)
                    .animation(
                        .spring(response: cardAnimationDuration, dampingFraction: 0.8)
                            .delay(Double(ConversationMode.allCases.firstIndex(of: mode) ?? 0) * staggerDelay),
                        value: animateIn
                    )
            }
        }
        .padding(20)
    }
    
    /// Individual mode card with stunning glass morphism
    @ViewBuilder
    private func modeCard(for mode: ConversationMode, geometry: GeometryProxy) -> some View {
        let isSelected = selectedGlassID == mode.glassID
        let cardHeight: CGFloat = min(geometry.size.height * 0.25, 200)
        
        VStack(spacing: 16) {
            // Mode icon with glass effect
            Image(systemName: mode.iconName)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(mode.primaryColor)
                .glassEffect(
                    style: .prominent,
                    tint: mode.primaryColor.opacity(0.2)
                )
                .interactive()
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
            
            // Mode title
            Text(mode.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Mode description
            Text(mode.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(20)
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .glassEffect(
            style: .regular,
            tint: mode.primaryColor.opacity(0.1)
        )
        .interactive()
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: isSelected ? mode.primaryColor.opacity(0.3) : .black.opacity(0.1),
                    radius: isSelected ? 16 : 8,
                    x: 0,
                    y: isSelected ? 8 : 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            mode.primaryColor.opacity(isSelected ? 0.4 : 0.1),
                            mode.primaryColor.opacity(isSelected ? 0.2 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: selectionAnimationDuration, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            handleModeSelection(mode)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.title) mode")
        .accessibilityHint(mode.description)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Computed Properties
    
    /// Glass-compatible background gradient
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2),
                Color.clear
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Actions
    
    /// Handles mode selection with glass morphing animation
    private func handleModeSelection(_ mode: ConversationMode) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Update selection with glass morphing effect
        withAnimation(.spring(response: selectionAnimationDuration, dampingFraction: 0.7)) {
            selectedGlassID = mode.glassID
            selectedMode = mode
        }
        
        // Delay the callback to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + selectionAnimationDuration) {
            onModeSelected(mode)
        }
    }
}

// Glass effects are imported from GlassEffectExtensions.swift
// ConversationMode is imported from Models/ConversationMode.swift

// MARK: - Preview Support

#Preview("Mode Selection - Default") {
    ModeSelectionView(
        selectedMode: .constant(nil),
        onModeSelected: { mode in
            print("Selected mode: \(mode.title)")
        }
    )
    .preferredColorScheme(.light)
}

#Preview("Mode Selection - Dark Mode") {
    ModeSelectionView(
        selectedMode: .constant(.couples),
        onModeSelected: { mode in
            print("Selected mode: \(mode.title)")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Single Mode Card") {
    VStack {
        ConversationMode.blindDate.primaryColor
        Text("Preview")
    }
    .padding()
    .glassEffect(
        style: .regular,
        tint: ConversationMode.blindDate.primaryColor.opacity(0.1)
    )
    .interactive()
    .padding(40)
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}