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
    
    /// Gesture state for swipe-to-refresh and card dismissal
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var cardDragOffset: CGSize = .zero
    @State private var refreshOffset: CGFloat = 0.0
    @State private var isRefreshing: Bool = false
    @State private var cardDismissalOffset: CGFloat = 0.0
    
    /// Layout constants for modern design
    private let cardWidth: CGFloat = 100
    private let cardHeight: CGFloat = 140
    private let expandedCardWidth: CGFloat = 380
    private let expandedCardHeight: CGFloat = 680
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
                } else if mainViewModel.showPlayerSetup {
                    // Player setup interface
                    playerSetupView(geometry: geometry)
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
            .animation(.spring(response: 0.8, dampingFraction: 0.9), value: mainViewModel.showPlayerSetup)
            .animation(.spring(response: 0.8, dampingFraction: 0.9), value: mainViewModel.showCards)
        }
        .onChange(of: dragOffset) { _, newValue in
            updateRefreshOffset(newValue)
        }
        .onChange(of: cardDragOffset) { _, newValue in
            updateCardDragFeedback(newValue)
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
    
    /// Player setup view with smooth animations
    private func playerSetupView(geometry: GeometryProxy) -> some View {
        PlayerSetupView(
            player1Name: $mainViewModel.playerManager.player1Name,
            player1Gender: Binding(
                get: { mainViewModel.playerManager.player1Pronouns.displayString },
                set: { newValue in
                    if let pronoun = PlayerPronouns.allCases.first(where: { $0.displayString == newValue }) {
                        mainViewModel.playerManager.updatePlayer1Pronouns(pronoun)
                    }
                }
            ),
            player2Name: $mainViewModel.playerManager.player2Name,
            player2Gender: Binding(
                get: { mainViewModel.playerManager.player2Pronouns.displayString },
                set: { newValue in
                    if let pronoun = PlayerPronouns.allCases.first(where: { $0.displayString == newValue }) {
                        mainViewModel.playerManager.updatePlayer2Pronouns(pronoun)
                    }
                }
            ),
            onSetupComplete: {
                mainViewModel.completePlayerSetup()
            }
        )
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
    
    /// Top area for expanded card or empty state (increased to 80% for larger cards)
    @ViewBuilder
    private func topContentArea(geometry: GeometryProxy) -> some View {
        let topHeight = geometry.size.height * 0.80
        
        VStack {
            // Refresh indicator
            if refreshOffset > 10 {
                refreshIndicator
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Game progress indicator
            if mainViewModel.showCards && mainViewModel.gameplayIntegration.isTurnBasedModeEnabled {
                GameProgressIndicator(
                    questionsAnswered: mainViewModel.completedCardAnswers.count,
                    totalQuestions: mainViewModel.getRequiredQuestionsForGameMode()
                )
                .padding(.horizontal, 20)
                .padding(.top, refreshOffset > 10 ? 8 : 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer()
            
            // Expanded card area or empty state
            if let selectedIndex = mainViewModel.selectedCardIndex {
                // Show expanded card with glass morphing and drag dismissal
                ConversationCard(
                    viewModel: mainViewModel.cardViewModels[selectedIndex],
                    cardIndex: selectedIndex,
                    isExpanded: true
                )
                .matchedGeometryEffect(id: "card_\(selectedIndex)", in: cardNamespace)
                .matchedGeometryEffect(id: "glass_card_\(selectedIndex)", in: cardNamespace)
                .frame(width: expandedCardWidth, height: expandedCardHeight)
                .offset(y: cardDismissalOffset + cardDragOffset.height)
                .scaleEffect(1.0 - abs(cardDragOffset.height) / 1200.0)
                .opacity(1.0 - abs(cardDragOffset.height) / 1000.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: cardDismissalOffset)
                .gesture(cardDragGesture)
            } else if mainViewModel.cardViewModels.isEmpty {
                // Empty state with koala mascot
                emptyStateView
                    .transition(.scale.combined(with: .opacity))
            } else {
                // Turn indicator when no card is selected but cards are available
                turnIndicatorView
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        let currentPlayer = mainViewModel.gameplayIntegration.getCurrentPlayer()
                        print("CardDeckView.turnIndicatorView: currentPlayer=\(currentPlayer?.displayName ?? "nil")")
                    }
            }
            
            Spacer()
            
            // Spacer for better layout when card is expanded
            if mainViewModel.selectedCardIndex != nil {
                Spacer(minLength: 20)
            }
        }
        .frame(height: topHeight)
        .gesture(
            mainViewModel.selectedCardIndex == nil ? refreshGesture : nil
        )
    }
    
    /// Bottom horizontal card deck with glass morphism (reduced to 20% for larger expanded cards)
    @ViewBuilder
    private func bottomCardDeck(geometry: GeometryProxy) -> some View {
        let bottomHeight = geometry.size.height * 0.20
        
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
    
    /// Turn indicator view showing whose turn it is
    @ViewBuilder
    private var turnIndicatorView: some View {
        let currentPlayer = mainViewModel.gameplayIntegration.getCurrentPlayer()
        let turnBasedEnabled = mainViewModel.gameplayIntegration.isTurnBasedModeEnabled
        let gameplayViewModel = mainViewModel.gameplayIntegration.gameplayViewModel
        
        if let currentPlayer = currentPlayer {
            TurnIndicatorView(
                currentPlayerName: currentPlayer.displayName,
                playerNumber: currentPlayer.playerNumber,
                isVisible: .constant(true)
            )
            .padding(.horizontal, 20)
        } else {
            // Fallback text if no current player
            VStack(spacing: 12) {
                Text("Select a card to start")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Tap any card below to begin your conversation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
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
    
    /// Card drag gesture for slide-down dismissal
    private var cardDragGesture: some Gesture {
        DragGesture()
            .updating($cardDragOffset) { value, state, _ in
                // Allow both upward and downward drags for natural feel
                state = value.translation
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height
                let threshold: CGFloat = 120
                let velocityThreshold: CGFloat = 250
                
                // Dismiss if dragged down far enough or with sufficient velocity
                let shouldDismiss = value.translation.height > threshold ||
                                  (value.translation.height > 40 && velocity > velocityThreshold)
                
                if shouldDismiss {
                    // Animate card out and then close
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        cardDismissalOffset = 600
                    }
                    
                    // Close the card after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        handleCardClose()
                        cardDismissalOffset = 0
                    }
                } else {
                    // Snap back to original position
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        cardDismissalOffset = 0
                    }
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
    
    /// Provides haptic feedback during card drag
    private func updateCardDragFeedback(_ dragValue: CGSize) {
        let distance = abs(dragValue.height)
        
        // Provide subtle haptic feedback at certain thresholds
        if distance > 80 && distance < 85 {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else if distance > 120 && distance < 125 {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
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
            
            // Set up completion handler for the selected card
            let cardViewModel = mainViewModel.cardViewModels[index]
            cardViewModel.onCardCompleted = {
                handleCardCompletion(at: index)
            }
            
            // Set up player switching handler
            cardViewModel.onPlayerNeedsToSwitch = {
                handlePlayerSwitch(for: cardViewModel)
            }
            
            // Set up question loaded handler to initialize answer collection after question is ready
            cardViewModel.onQuestionLoaded = {
                setupAnswerCollectionForCard(cardViewModel)
            }
            
            // If the question is already loaded (not currently loading), set up immediately
            if !cardViewModel.isLoading && !cardViewModel.question.isEmpty {
                setupAnswerCollectionForCard(cardViewModel)
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
    
    /// Handles card completion with sweep-up animation and new card generation
    private func handleCardCompletion(at cardIndex: Int) {
        guard cardIndex < mainViewModel.cardViewModels.count else { return }
        
        let completedCard = mainViewModel.cardViewModels[cardIndex]
        
        // Haptic feedback for completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Start the sweep-up animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            completedCard.isCompletingCard = true
        }
        
        // After animation delay, generate new card and show it
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                // Store the completed answers before resetting
                if let cardAnswers = completedCard.cardAnswers, cardAnswers.isComplete {
                    mainViewModel.storeCompletedCardAnswers(cardAnswers)
                }
                
                // Reset the completed card and generate new question
                completedCard.isCompletingCard = false
                completedCard.reset()
                
                // Generate new question for the card
                Task {
                    await completedCard.loadQuestion(for: getRandomCategory())
                }
                
                // Animate new card appearing from bottom
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    // Card will naturally appear as isCompletingCard becomes false
                }
                
                // Deselect the card to return to deck view
                mainViewModel.deselectAllCards()
                
                // Advance turn or handle game flow
                handleTurnAdvancement()
            }
        }
    }
    
    /// Gets a random category for new card generation
    private func getRandomCategory() -> QuestionCategory {
        let categories: [QuestionCategory] = [
            .firstDate, .personalGrowth, .funAndPlayful, .deepCouple,
            .vulnerabilitySharing, .futureVisions, .conflictResolution,
            .loveLanguageDiscovery, .earlyDating, .valuesAlignment
        ]
        return categories.randomElement() ?? .personalGrowth
    }
    
    /// Sets up answer collection for a card after question is loaded
    private func setupAnswerCollectionForCard(_ cardViewModel: CardViewModel) {
        // Initialize answer collection - the OTHER player records first
        let players = mainViewModel.gameplayIntegration.getPlayers()
        
        if players.count >= 2 {
            let currentPlayer = mainViewModel.gameplayIntegration.getCurrentPlayer()
            // If Player 1 selected card, Player 2 answers first
            // If Player 2 selected card, Player 1 answers first
            let firstAnswerer = currentPlayer?.playerNumber == 1 ? players[1] : players[0]
            cardViewModel.initializeAnswerCollection(currentPlayer: firstAnswerer)
        }
    }
    
    /// Handles player switching when first player finishes answering
    private func handlePlayerSwitch(for cardViewModel: CardViewModel) {
        let players = mainViewModel.gameplayIntegration.getPlayers()
        guard players.count >= 2 else { return }
        
        // Find which player hasn't answered yet
        if let answers = cardViewModel.cardAnswers {
            if answers.player1Answer == nil {
                cardViewModel.setCurrentPlayer(players[0]) // Player 1
            } else if answers.player2Answer == nil {
                cardViewModel.setCurrentPlayer(players[1]) // Player 2
            }
        }
        
        // Haptic feedback for player switch
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Handles turn advancement after card completion
    private func handleTurnAdvancement() {
        // This will integrate with the gameplay system
        // For now, just print debug info
        if let currentPlayer = mainViewModel.gameplayIntegration.getCurrentPlayer() {
            print("Turn completed by \(currentPlayer.displayName), advancing to next player")
            
            Task {
                await mainViewModel.gameplayIntegration.completeTurnAndAdvance()
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