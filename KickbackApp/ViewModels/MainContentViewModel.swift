//
//  MainContentViewModel.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import Foundation
import SwiftUI

/// Main ViewModel orchestrating the entire card-based conversation interface
/// Manages app launch state, card deck coordination, and global app behaviors
@MainActor
public final class MainContentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Controls launch animation visibility
    @Published var showLaunchAnimation: Bool = true
    
    /// Array of card ViewModels for the three-card deck
    @Published var cardViewModels: [CardViewModel] = []
    
    /// Currently selected card index (if any)
    @Published var selectedCardIndex: Int?
    
    /// Tracks if animation is in progress to prevent rapid state changes
    @Published var isAnimatingCardTransition: Bool = false
    
    /// Mode selection state management
    @Published var selectedMode: ConversationMode? = nil
    @Published var showModeSelection: Bool = true
    @Published var showCards: Bool = false
    
    /// Global loading state for initial app setup
    @Published var isInitializing: Bool = true
    
    /// Available question categories for the current session
    @Published var availableCategories: [QuestionCategory] = []
    
    /// Error state for critical app failures
    @Published var criticalError: String?
    
    // MARK: - Animation Properties
    
    /// Controls staggered card entrance animations
    @Published var cardAnimationDelays: [Double] = [0.0, 0.2, 0.4]
    
    /// Launch animation progress
    @Published var launchAnimationProgress: Double = 0.0
    
    // MARK: - Configuration
    
    /// Number of cards in the deck
    private let cardCount: Int = 3
    
    /// Default categories for initial card load
    private let defaultCategories: [QuestionCategory] = [
        .firstDate,
        .personalGrowth,
        .funAndPlayful
    ]
    
    // MARK: - Dependencies
    
    private let questionEngine: QuestionEngine
    
    // MARK: - Initialization
    
    /// Initializes MainContentViewModel with dependency injection
    /// - Parameter questionEngine: Service for generating questions
    init(questionEngine: QuestionEngine? = nil) {
        // Use real QuestionEngineService for actual AI-powered question generation
        self.questionEngine = questionEngine ?? QuestionEngineService()
        setupInitialState()
    }
    
    // MARK: - Public Methods
    
    /// Starts the app launch sequence with animations
    func startLaunchSequence() async {
        // Launch animation duration
        let launchDuration: TimeInterval = 2.0
        
        // Animate launch progress
        await animateLaunchProgress(duration: launchDuration)
        
        // Initialize cards after launch animation
        await initializeCards()
        
        // Hide launch animation and show mode selection
        withAnimation(.easeInOut(duration: 0.8)) {
            showLaunchAnimation = false
            isInitializing = false
            showModeSelection = true
            showCards = false
        }
    }
    
    /// Selects a card and triggers flip animation with question loading
    /// - Parameter index: Index of the card to select
    func selectCard(at index: Int) {
        print("selectCard called for index: \(index), cardCount: \(cardViewModels.count), isAnimating: \(isAnimatingCardTransition)") // Debug log
        
        guard index < cardViewModels.count && !isAnimatingCardTransition else { 
            print("selectCard blocked - invalid index or animating") // Debug log
            return 
        }
        
        isAnimatingCardTransition = true
        
        // Deselect other cards
        for (i, cardVM) in cardViewModels.enumerated() {
            if i != index && cardVM.isFlipped {
                cardVM.flipDown()
            }
        }
        
        // Select the tapped card
        selectedCardIndex = index
        let cardVM = cardViewModels[index]
        cardVM.flipUp()
        
        // Haptic feedback for card selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Reset animation flag after transition completes - reduced time for better responsiveness
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds - allow quicker subsequent interactions
            await MainActor.run {
                isAnimatingCardTransition = false
            }
        }
        
        // Load question after animation completes (delay to allow smooth transition)
        if cardVM.question.isEmpty || cardVM.question == "Tap to reveal question..." {
            // Set loading state immediately for UI feedback
            cardVM.setLoadingState(for: cardVM.category)
            
            Task {
                // Wait for animation to start before starting generation for better UX
                try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds - start loading mid-animation
                await cardVM.loadQuestion(for: cardVM.category)
            }
        }
    }
    
    /// Deselects all cards and returns to deck view
    func deselectAllCards() {
        guard !isAnimatingCardTransition else { return }
        
        isAnimatingCardTransition = true
        selectedCardIndex = nil
        
        for cardVM in cardViewModels {
            if cardVM.isFlipped {
                cardVM.flipDown()
            }
        }
        
        // Reset animation flag after transition completes - reduced time for better responsiveness
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds - allow quicker subsequent interactions
            await MainActor.run {
                isAnimatingCardTransition = false
            }
        }
    }
    
    /// Refreshes all cards with new questions (swipe-to-refresh functionality)
    func refreshAllCards() async {
        let refreshCategories = getRandomCategories()
        
        await withTaskGroup(of: Void.self) { group in
            for (index, category) in refreshCategories.enumerated() {
                guard index < cardViewModels.count else { break }
                
                group.addTask {
                    await self.cardViewModels[index].loadQuestion(for: category)
                }
            }
        }
        
        // Light haptic feedback for refresh
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    /// Handles app going to background - pause animations
    func handleAppBackgrounding() {
        // Pause any ongoing animations or operations
        for cardVM in cardViewModels {
            cardVM.isAnimating = false
        }
    }
    
    /// Handles app returning to foreground - resume normal operation
    func handleAppForegrounding() {
        // Resume normal operation
        // Could refresh cards if they're stale
    }
    
    /// Handles mode selection with smooth animation transition
    /// - Parameter mode: The selected conversation mode
    func selectMode(_ mode: ConversationMode) {
        selectedMode = mode
        
        // Animate mode pills away first
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showModeSelection = false
        }
        
        // After pills disappear, slide cards up from bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                self.showCards = true
            }
        }
        
        // Update cards with mode-specific categories
        Task {
            await updateCardsForMode(mode)
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up initial app state
    private func setupInitialState() {
        availableCategories = QuestionCategory.allCases
        
        // Create card ViewModels
        cardViewModels = (0..<cardCount).map { _ in
            CardViewModel(questionEngine: questionEngine)
        }
    }
    
    /// Animates the launch progress with smooth transitions
    private func animateLaunchProgress(duration: TimeInterval) async {
        let steps = 60 // 60fps equivalent steps
        let stepDuration = duration / Double(steps)
        
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: stepDuration)) {
                    launchAnimationProgress = progress
                }
            }
            
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
    
    /// Initializes cards with initial questions
    private func initializeCards() async {
        let initialCategories = getRandomCategories()
        
        // Set up cards with categories but don't load questions yet
        // Questions will be generated when user actually flips a card
        for (index, category) in initialCategories.enumerated() {
            guard index < cardViewModels.count else { break }
            
            await MainActor.run {
                cardViewModels[index].category = category
                cardViewModels[index].question = "Tap to reveal question..."
                cardViewModels[index].isLoading = false
            }
        }
    }
    
    /// Gets random categories for card loading, avoiding duplicates
    private func getRandomCategories() -> [QuestionCategory] {
        var categories = availableCategories.shuffled()
        
        // Ensure we have enough categories
        while categories.count < cardCount {
            categories.append(contentsOf: availableCategories.shuffled())
        }
        
        return Array(categories.prefix(cardCount))
    }
    
    /// Updates cards with mode-specific categories
    private func updateCardsForMode(_ mode: ConversationMode) async {
        let modeCategories = mode.preferredCategories.shuffled()
        
        // Ensure we have enough categories for all cards
        var finalCategories = modeCategories
        while finalCategories.count < cardCount {
            finalCategories.append(contentsOf: modeCategories)
        }
        
        // Update cards with mode-specific categories
        for (index, category) in finalCategories.prefix(cardCount).enumerated() {
            guard index < cardViewModels.count else { break }
            
            await MainActor.run {
                cardViewModels[index].category = category
                cardViewModels[index].question = "Tap to reveal question..."
                cardViewModels[index].isLoading = false
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension MainContentViewModel {
    /// Creates a preview MainContentViewModel for SwiftUI previews
    static func preview(
        showLaunchAnimation: Bool = false,
        isInitializing: Bool = false,
        selectedCardIndex: Int? = nil,
        showModeSelection: Bool = false,
        showCards: Bool = true
    ) -> MainContentViewModel {
        let viewModel = MainContentViewModel()
        viewModel.showLaunchAnimation = showLaunchAnimation
        viewModel.isInitializing = isInitializing
        viewModel.selectedCardIndex = selectedCardIndex
        viewModel.showModeSelection = showModeSelection
        viewModel.showCards = showCards
        viewModel.launchAnimationProgress = showLaunchAnimation ? 0.5 : 1.0
        
        // Setup preview cards with placeholder content
        for (index, category) in [QuestionCategory.firstDate, .personalGrowth, .funAndPlayful].enumerated() {
            if index < viewModel.cardViewModels.count {
                viewModel.cardViewModels[index].category = category
                viewModel.cardViewModels[index].question = "Preview question for \(category.rawValue)"
                viewModel.cardViewModels[index].displayedQuestion = "Preview question for \(category.rawValue)"
                viewModel.cardViewModels[index].isFlipped = selectedCardIndex == index
                viewModel.cardViewModels[index].revealProgress = 1.0
            }
        }
        
        return viewModel
    }
}
#endif