//
//  CardDeckView.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Modern card deck interface with horizontal 3-card layout in bottom third
/// Features smooth flip animations with matched geometry and brand-consistent design
struct CardDeckView: View {
    
    // MARK: - Properties
    
    @ObservedObject var mainViewModel: MainContentViewModel
    @Namespace private var cardNamespace
    
    /// Gesture state for swipe-to-refresh
    @GestureState private var dragOffset: CGSize = .zero
    @State private var refreshOffset: CGFloat = 0.0
    @State private var isRefreshing: Bool = false
    
    /// Layout constants for modern design
    private let cardWidth: CGFloat = 100
    private let cardHeight: CGFloat = 140
    private let expandedCardWidth: CGFloat = 320
    private let expandedCardHeight: CGFloat = 400
    private let cardSpacing: CGFloat = 20
    private let deckPadding: CGFloat = 20
    private let refreshThreshold: CGFloat = 80
    
    /// Animation constants for smooth 60fps performance
    private let cardFlipDuration: Double = 0.8
    private let cardLayoutDuration: Double = 0.6
    private let refreshAnimationDuration: Double = 0.3
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Brand gradient background
                brandBackgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top 2/3 area for expanded card or empty state
                    topContentArea(geometry: geometry)
                    
                    // Bottom 1/3 area for horizontal card deck
                    bottomCardDeck(geometry: geometry)
                }
            }
        }
        .gesture(refreshGesture)
        .onChange(of: dragOffset) { _, newValue in
            updateRefreshOffset(newValue)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kickback card deck")
        .accessibilityHint("Three conversation cards in bottom section. Tap a card to expand it.")
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
    
    /// Top 2/3 area for expanded card or empty state
    @ViewBuilder
    private func topContentArea(geometry: GeometryProxy) -> some View {
        let topHeight = geometry.size.height * 0.67
        
        VStack {
            // Refresh indicator
            if refreshOffset > 10 {
                refreshIndicator
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer()
            
            // Expanded card area or empty state
            if let selectedIndex = mainViewModel.selectedCardIndex {
                // Show expanded card
                ConversationCard(
                    viewModel: mainViewModel.cardViewModels[selectedIndex],
                    cardIndex: selectedIndex,
                    isExpanded: true
                )
                .matchedGeometryEffect(id: "card_\(selectedIndex)", in: cardNamespace)
                .frame(width: expandedCardWidth, height: expandedCardHeight)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                ))
            } else if mainViewModel.cardViewModels.isEmpty {
                // Empty state with koala mascot
                emptyStateView
                    .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            // Close button when card is expanded
            if mainViewModel.selectedCardIndex != nil {
                closeButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: topHeight)
        .animation(.spring(response: cardLayoutDuration, dampingFraction: 0.8), value: mainViewModel.selectedCardIndex)
    }
    
    /// Bottom 1/3 horizontal card deck
    @ViewBuilder
    private func bottomCardDeck(geometry: GeometryProxy) -> some View {
        let bottomHeight = geometry.size.height * 0.33
        
        HStack(spacing: cardSpacing) {
            ForEach(Array(mainViewModel.cardViewModels.enumerated()), id: \.element.id) { index, cardViewModel in
                if mainViewModel.selectedCardIndex != index {
                    KickbackCardView(
                        viewModel: cardViewModel,
                        cardIndex: index,
                        isBack: true
                    )
                    .matchedGeometryEffect(id: "card_\(index)", in: cardNamespace)
                    .frame(width: cardWidth, height: cardHeight)
                    .onTapGesture {
                        handleCardTap(at: index)
                    }
                    .scaleEffect(cardScale(at: index))
                    .opacity(cardOpacity(at: index))
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                } else {
                    // Invisible placeholder to maintain layout
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: cardWidth, height: cardHeight)
                }
            }
        }
        .frame(height: bottomHeight)
        .padding(.horizontal, deckPadding)
        .animation(.spring(response: cardLayoutDuration, dampingFraction: 0.8), value: mainViewModel.selectedCardIndex)
    }
    
    
    // MARK: - Computed Properties
    
    /// Brand-consistent background gradient using brand colors
    private var brandBackgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple"),
                Color("BrandPurpleLight")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Empty state view with koala mascot
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image("KoalaMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.white.opacity(0.8))
            
            Text("No cards available")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            Text("Pull down to refresh and get new conversation starters")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    /// Close button for expanded card
    @ViewBuilder
    private var closeButton: some View {
        Button(action: {
            mainViewModel.deselectAllCards()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.caption)
                Text("Close")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
        }
        .padding(.bottom, 20)
    }
    
    /// Pull-to-refresh gesture with smooth swipe detection
    private var refreshGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                // Only allow downward pulls when no card is selected
                if mainViewModel.selectedCardIndex == nil && value.translation.height > 0 {
                    state = value.translation
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height
                let shouldRefresh = value.translation.height > refreshThreshold || 
                                  (value.translation.height > 40 && velocity > 200)
                
                if shouldRefresh && !isRefreshing {
                    triggerRefresh()
                }
                
                // Reset refresh offset with velocity-based animation
                let animationSpeed = min(0.6, max(0.3, abs(velocity) / 1000))
                withAnimation(.spring(response: animationSpeed, dampingFraction: 0.8)) {
                    refreshOffset = 0.0
                }
            }
    }
    
    // MARK: - Layout Helpers
    
    /// Calculates card scale for subtle hover effect
    private func cardScale(at index: Int) -> CGFloat {
        return mainViewModel.selectedCardIndex == index ? 1.05 : 1.0
    }
    
    /// Calculates card opacity for selection feedback
    private func cardOpacity(at index: Int) -> Double {
        if let selectedIndex = mainViewModel.selectedCardIndex {
            return selectedIndex == index ? 0.3 : 1.0
        }
        return 1.0
    }
    
    // MARK: - Gesture Handlers
    
    /// Updates refresh offset based on drag gesture
    private func updateRefreshOffset(_ dragValue: CGSize) {
        if mainViewModel.selectedCardIndex == nil && dragValue.height > 0 {
            refreshOffset = min(dragValue.height * 0.8, 120) // Cap maximum offset
        }
    }
    
    /// Handles card tap with haptic feedback and flip animation
    private func handleCardTap(at index: Int) {
        // Prevent interaction during refresh
        guard !isRefreshing else { return }
        
        if mainViewModel.selectedCardIndex == index {
            // Tapping selected card deselects it with flip down animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                mainViewModel.deselectAllCards()
            }
        } else {
            // Select the tapped card with horizontal flip up animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                mainViewModel.selectCard(at: index)
            }
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

#Preview("Modern Kickback Deck - Default") {
    CardDeckView(mainViewModel: MainContentViewModel.mock())
        .preferredColorScheme(.light)
}

#Preview("Modern Kickback Deck - Expanded Card") {
    CardDeckView(mainViewModel: MainContentViewModel.mock(selectedCardIndex: 1))
        .preferredColorScheme(.light)
}

#Preview("Modern Kickback Deck - Empty State") {
    let emptyViewModel = MainContentViewModel.mock()
    emptyViewModel.cardViewModels = []
    return CardDeckView(mainViewModel: emptyViewModel)
        .preferredColorScheme(.light)
}

#Preview("Complete Modern Interface") {
    CardDeckView(mainViewModel: MainContentViewModel.mock())
        .preferredColorScheme(.light)
        .statusBarHidden()
}