//
//  CardDeckView.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Main card deck interface managing 3-card layout, gestures, and interactions
/// Optimized for 60fps performance with smooth animations and responsive gestures
struct CardDeckView: View {
    
    // MARK: - Properties
    
    @ObservedObject var mainViewModel: MainContentViewModel
    
    /// Gesture state for swipe-to-refresh
    @GestureState private var dragOffset: CGSize = .zero
    @State private var refreshOffset: CGFloat = 0.0
    @State private var isRefreshing: Bool = false
    
    /// Layout constants optimized for different screen sizes
    private let cardSpacing: CGFloat = 16
    private let deckPadding: CGFloat = 20
    private let refreshThreshold: CGFloat = 80
    
    /// Animation constants for smooth 60fps performance
    private let cardAnimationDuration: Double = 0.5
    private let refreshAnimationDuration: Double = 0.3
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Refresh indicator area
                refreshIndicator
                
                // Main card deck area
                cardDeckContent(geometry: geometry)
                
                Spacer(minLength: 0)
            }
        }
        .background(deckBackgroundGradient)
        .gesture(refreshGesture)
        .onChange(of: dragOffset) { _, newValue in
            updateRefreshOffset(newValue)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Card deck")
        .accessibilityHint("Contains three conversation cards. Pull down to refresh with new questions.")
        .accessibilityAction(named: "Refresh cards") {
            Task {
                await mainViewModel.refreshAllCards()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Pull-to-refresh indicator
    @ViewBuilder
    private var refreshIndicator: some View {
        HStack {
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Refreshing cards...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            } else if refreshOffset > 20 {
                Image(systemName: refreshOffset > refreshThreshold ? "arrow.clockwise.circle.fill" : "arrow.down.circle")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .rotationEffect(.degrees(refreshOffset > refreshThreshold ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: refreshOffset > refreshThreshold)
                
                Text(refreshOffset > refreshThreshold ? "Release to refresh" : "Pull to refresh")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(height: max(0, refreshOffset))
        .opacity(refreshOffset > 10 ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.2), value: refreshOffset)
    }
    
    /// Main card deck layout with responsive positioning
    @ViewBuilder
    private func cardDeckContent(geometry: GeometryProxy) -> some View {
        let availableHeight = geometry.size.height - refreshOffset
        let cardAreaHeight = availableHeight * 0.7 // Bottom 70% for cards
        let isCompactHeight = geometry.size.height < 700
        
        VStack(spacing: cardSpacing) {
            Spacer()
            
            // Card stack with staggered animations
            LazyVStack(spacing: cardSpacing) {
                ForEach(Array(mainViewModel.cardViewModels.enumerated()), id: \.element.id) { index, cardViewModel in
                    ConversationCard(viewModel: cardViewModel, cardIndex: index)
                        .onTapGesture {
                            handleCardTap(at: index)
                        }
                        .accessibilityAddTraits(.allowsDirectInteraction)
                        .accessibilityIdentifier("conversation_card_\(index)")
                        .scaleEffect(cardScale(at: index))
                        .offset(y: cardOffset(at: index, compactHeight: isCompactHeight))
                        .zIndex(cardZIndex(at: index))
                        .animation(
                            .spring(response: cardAnimationDuration, dampingFraction: 0.8, blendDuration: 0)
                                .delay(mainViewModel.cardAnimationDelays[safe: index] ?? 0),
                            value: mainViewModel.selectedCardIndex
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .frame(height: cardAreaHeight)
            
            // Bottom action area (future expansion for buttons/controls)
            bottomActionArea
        }
        .padding(.horizontal, deckPadding)
        .offset(y: refreshOffset * 0.3) // Subtle parallax effect during refresh
    }
    
    /// Bottom area for future action buttons or controls
    @ViewBuilder
    private var bottomActionArea: some View {
        if let selectedIndex = mainViewModel.selectedCardIndex {
            Button(action: {
                mainViewModel.deselectAllCards()
            }) {
                HStack {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                    Text("Close")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .backdrop(BlurView(style: .systemUltraThinMaterialLight))
                )
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedIndex)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic background gradient
    private var deckBackgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.9, green: 0.6, blue: 0.7), // Warm pink
                Color(red: 0.8, green: 0.5, blue: 0.9), // Soft purple
                Color(red: 0.6, green: 0.7, blue: 0.9)  // Light blue
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Pull-to-refresh gesture
    private var refreshGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                // Only allow downward pulls when no card is selected
                if mainViewModel.selectedCardIndex == nil && value.translation.y > 0 {
                    state = value.translation
                }
            }
            .onEnded { value in
                if value.translation.y > refreshThreshold && !isRefreshing {
                    triggerRefresh()
                }
                
                // Reset refresh offset
                withAnimation(.spring(response: refreshAnimationDuration, dampingFraction: 0.8)) {
                    refreshOffset = 0.0
                }
            }
    }
    
    // MARK: - Layout Helpers
    
    /// Calculates card scale based on selection state
    private func cardScale(at index: Int) -> CGFloat {
        if let selectedIndex = mainViewModel.selectedCardIndex {
            return selectedIndex == index ? 1.1 : 0.9
        }
        return 1.0
    }
    
    /// Calculates card vertical offset for stacking effect
    private func cardOffset(at index: Int, compactHeight: Bool) -> CGFloat {
        guard let selectedIndex = mainViewModel.selectedCardIndex else {
            // Default stacking offsets
            let baseOffset: CGFloat = compactHeight ? 10 : 15
            return CGFloat(index) * baseOffset
        }
        
        // Expanded state positioning
        if selectedIndex == index {
            return -50 // Move selected card up
        } else if index < selectedIndex {
            return -100 // Move cards above selected card further up
        } else {
            return 100 // Move cards below selected card down
        }
    }
    
    /// Calculates Z-index for proper card layering
    private func cardZIndex(at index: Int) -> Double {
        if let selectedIndex = mainViewModel.selectedCardIndex {
            return selectedIndex == index ? 10 : Double(-index)
        }
        return Double(mainViewModel.cardViewModels.count - index)
    }
    
    // MARK: - Gesture Handlers
    
    /// Updates refresh offset based on drag gesture
    private func updateRefreshOffset(_ dragValue: CGSize) {
        if mainViewModel.selectedCardIndex == nil && dragValue.y > 0 {
            refreshOffset = min(dragValue.y * 0.8, 120) // Cap maximum offset
        }
    }
    
    /// Handles card tap with haptic feedback
    private func handleCardTap(at index: Int) {
        // Prevent interaction during refresh
        guard !isRefreshing else { return }
        
        if mainViewModel.selectedCardIndex == index {
            // Tapping selected card deselects it
            mainViewModel.deselectAllCards()
        } else {
            // Select the tapped card
            mainViewModel.selectCard(at: index)
        }
    }
    
    /// Triggers card refresh with haptic feedback
    private func triggerRefresh() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            await mainViewModel.refreshAllCards()
            
            await MainActor.run {
                withAnimation(.spring(response: refreshAnimationDuration, dampingFraction: 0.8)) {
                    isRefreshing = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Blur effect view for backdrop effects
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Extensions

/// Safe array access extension
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview Support

#Preview("Card Deck - Default State") {
    CardDeckView(mainViewModel: MainContentViewModel.mock())
        .preferredColorScheme(.light)
}

#Preview("Card Deck - Selected Card") {
    CardDeckView(mainViewModel: MainContentViewModel.mock(selectedCardIndex: 1))
        .preferredColorScheme(.light)
}

#Preview("Card Deck - Dark Mode") {
    CardDeckView(mainViewModel: MainContentViewModel.mock())
        .preferredColorScheme(.dark)
}