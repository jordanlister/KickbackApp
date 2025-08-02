//
//  CardDeckView.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Modern card deck interface with iOS 26 Liquid Glass design
/// Features stunning glass morphism throughout with smooth flip animations
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
    private let cardLayoutDuration: Double = 0.8
    private let refreshAnimationDuration: Double = 0.3
    
    /// Glass effect constants
    private let glassCornerRadius: CGFloat = 20
    private let glassBlurIntensity: CGFloat = 0.8
    
    /// Unified animation configuration for matched geometry effects
    private let matchedGeometryAnimation: Animation = .spring(response: 0.8, dampingFraction: 0.85)
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Glass-compatible background gradient
                glassCompatibleBackground
                    .ignoresSafeArea()
                
                if mainViewModel.showModeSelection {
                    // Mode selection interface - inline with smooth animations
                    modeSelectionView(geometry: geometry)
                } else {
                    // Main card interface
                    VStack(spacing: 0) {
                        // Top 2/3 area for expanded card or empty state
                        topContentArea(geometry: geometry)
                        
                        // Bottom 1/3 area with glass container for card deck
                        if mainViewModel.showCards {
                            GlassEffectContainer(glassEffectID: "card-deck-container") {
                                bottomCardDeck(geometry: geometry)
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
            .animation(matchedGeometryAnimation, value: mainViewModel.selectedCardIndex)
            .animation(.spring(response: 0.8, dampingFraction: 0.9), value: mainViewModel.showModeSelection)
            .animation(.spring(response: 0.8, dampingFraction: 0.9), value: mainViewModel.showCards)
        }
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
    
    /// Mode selection view with liquid glass pill buttons
    @ViewBuilder
    private func modeSelectionView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Mode selection pills with staggered animation
            VStack(spacing: 20) {
                ForEach(Array(ConversationMode.allCases.enumerated()), id: \.element) { index, mode in
                    modePillButton(for: mode, animationDelay: Double(index) * 0.1)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Individual mode pill button with liquid glass effects
    @ViewBuilder
    private func modePillButton(for mode: ConversationMode, animationDelay: Double) -> some View {
        Button(action: {
            handleModeSelection(mode)
        }) {
            HStack(spacing: 12) {
                Image(systemName: mode.iconName)
                    .font(.title2)
                    .foregroundColor(mode.primaryColor)
                
                Text(mode.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(minWidth: 200)
            .glassEffect(
                style: .prominent,
                tint: mode.primaryColor.opacity(0.15)
            )
            .interactive()
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: mode.primaryColor.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                mode.primaryColor.opacity(0.4),
                                mode.primaryColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(mainViewModel.showModeSelection ? 1.0 : 0.8)
            .opacity(mainViewModel.showModeSelection ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(animationDelay),
                value: mainViewModel.showModeSelection
            )
        }
        .accessibilityLabel("\(mode.title) mode")
        .accessibilityHint(mode.description)
        .accessibilityAddTraits(.isButton)
    }
    
    /// Pull-to-refresh indicator with glass effects
    @ViewBuilder
    private var refreshIndicator: some View {
        HStack {
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("BrandPurple")))
                
                Text("Refreshing cards...")
                    .font(.caption)
                    .foregroundColor(.primary)
            } else if refreshOffset > 20 {
                Image(systemName: refreshOffset > refreshThreshold ? "arrow.clockwise.circle.fill" : "arrow.down.circle")
                    .font(.title2)
                    .foregroundColor(Color("BrandPurple"))
                    .rotationEffect(.degrees(refreshOffset > refreshThreshold ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: refreshOffset > refreshThreshold)
                
                Text(refreshOffset > refreshThreshold ? "Release to refresh" : "Pull to refresh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect(
            style: .regular,
            tint: Color("BrandPurple").opacity(0.1)
        )
        .interactive()
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
                // Show expanded card with glass morphing
                ConversationCard(
                    viewModel: mainViewModel.cardViewModels[selectedIndex],
                    cardIndex: selectedIndex,
                    isExpanded: true
                )
                .matchedGeometryEffect(id: "card_\(selectedIndex)", in: cardNamespace)
                .matchedGeometryEffect(id: "glass_card_\(selectedIndex)", in: cardNamespace)
                .frame(width: expandedCardWidth, height: expandedCardHeight)
            } else if mainViewModel.cardViewModels.isEmpty {
                // Empty state with koala mascot
                emptyStateView
                    .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            // Close button when card is expanded - with glass effect
            if mainViewModel.selectedCardIndex != nil {
                glassCloseButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: topHeight)
        .gesture(
            mainViewModel.selectedCardIndex == nil ? refreshGesture : nil
        )
    }
    
    /// Bottom 1/3 horizontal card deck with glass morphism
    @ViewBuilder
    private func bottomCardDeck(geometry: GeometryProxy) -> some View {
        let bottomHeight = geometry.size.height * 0.33
        
        HStack(spacing: cardSpacing) {
            ForEach(Array(mainViewModel.cardViewModels.enumerated()), id: \.element.id) { index, cardViewModel in
                if mainViewModel.selectedCardIndex != index {
                    KickbackCardView(
                        viewModel: cardViewModel,
                        cardIndex: index,
                        isBack: true,
                        onTap: {
                            print("Card \(index) tapped - executing handleCardTap") // Debug log
                            handleCardTap(at: index)
                        }
                    )
                    .matchedGeometryEffect(id: "card_\(index)", in: cardNamespace)
                    .matchedGeometryEffect(id: "glass_card_\(index)", in: cardNamespace)
                    .frame(width: cardWidth, height: cardHeight)
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
    }
    
    
    // MARK: - Computed Properties
    
    /// Glass-compatible background gradient optimized for glass effects
    private var glassCompatibleBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Empty state view with glass morphism and koala mascot
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image("KoalaMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(Color("BrandPurple"))
                .glassEffect(
                    style: .prominent,
                    tint: Color("BrandPurple").opacity(0.1)
                )
                .interactive()
            
            VStack(spacing: 12) {
                Text("No cards available")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Pull down to refresh and get new conversation starters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .glassEffect(
                style: .regular,
                tint: Color("BrandPurple").opacity(0.05)
            )
            .interactive()
        }
        .padding(.horizontal, 40)
    }
    
    /// Glass close button for expanded card
    @ViewBuilder
    private var glassCloseButton: some View {
        Button(action: {
            handleCardClose()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.caption)
                Text("Close")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(
                style: .regular,
                tint: Color("BrandPurple").opacity(0.1)
            )
            .interactive()
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
        print("handleCardTap called for index: \(index), isRefreshing: \(isRefreshing)") // Debug log
        
        // Prevent interaction during refresh only - allow taps during card transitions
        guard !isRefreshing else { 
            print("Card tap blocked - refreshing in progress") // Debug log
            return 
        }
        
        if mainViewModel.selectedCardIndex == index {
            // Tapping selected card deselects it
            handleCardClose()
        } else {
            // Provide immediate haptic feedback for better responsiveness
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Select the tapped card with smooth matched geometry animation
            withAnimation(matchedGeometryAnimation) {
                mainViewModel.selectCard(at: index)
            }
        }
    }
    
    /// Handles card close with optimized animation
    private func handleCardClose() {
        // Add haptic feedback for card close
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(matchedGeometryAnimation) {
            mainViewModel.deselectAllCards()
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
    
    /// Handles mode selection with smooth animation flow
    private func handleModeSelection(_ mode: ConversationMode) {
        // Haptic feedback for mode selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Trigger the mode selection in the view model
        mainViewModel.selectMode(mode)
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

/// Conditional view modifier extension for gesture handling
extension View {
    @ViewBuilder
    func onlyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview Support

#Preview("Mode Selection Interface") {
    CardDeckView(mainViewModel: MainContentViewModel.preview(showModeSelection: true, showCards: false))
        .preferredColorScheme(.light)
}

#Preview("Card Deck - Default") {
    CardDeckView(mainViewModel: MainContentViewModel.preview(showModeSelection: false, showCards: true))
        .preferredColorScheme(.light)
}

#Preview("Card Deck - Expanded Card") {
    CardDeckView(mainViewModel: MainContentViewModel.preview(selectedCardIndex: 1, showModeSelection: false, showCards: true))
        .preferredColorScheme(.light)
}

#Preview("Card Deck - Empty State") {
    let emptyViewModel = MainContentViewModel.preview(showModeSelection: false, showCards: true)
    emptyViewModel.cardViewModels = []
    return CardDeckView(mainViewModel: emptyViewModel)
        .preferredColorScheme(.light)
}

#Preview("Complete Interface Flow") {
    CardDeckView(mainViewModel: MainContentViewModel.preview(showModeSelection: false, showCards: true))
        .preferredColorScheme(.light)
        .statusBarHidden()
}