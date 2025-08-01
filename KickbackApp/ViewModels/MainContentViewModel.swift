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
        
        // Hide launch animation and show main interface
        withAnimation(.easeInOut(duration: 0.8)) {
            showLaunchAnimation = false
            isInitializing = false
        }
    }
    
    /// Selects a card and triggers flip animation
    /// - Parameter index: Index of the card to select
    func selectCard(at index: Int) {
        guard index < cardViewModels.count else { return }
        
        // Deselect other cards
        for (i, cardVM) in cardViewModels.enumerated() {
            if i != index && cardVM.isFlipped {
                cardVM.flipDown()
            }
        }
        
        // Select the tapped card
        selectedCardIndex = index
        cardViewModels[index].flipUp()
        
        // Haptic feedback for card selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Deselects all cards and returns to deck view
    func deselectAllCards() {
        selectedCardIndex = nil
        
        for cardVM in cardViewModels {
            if cardVM.isFlipped {
                cardVM.flipDown()
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
        
        await withTaskGroup(of: Void.self) { group in
            for (index, category) in initialCategories.enumerated() {
                guard index < cardViewModels.count else { break }
                
                group.addTask {
                    await self.cardViewModels[index].loadQuestion(for: category)
                }
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
}

// MARK: - Preview Support

#if DEBUG
extension MainContentViewModel {
    /// Creates a mock MainContentViewModel for SwiftUI previews
    static func mock(
        showLaunchAnimation: Bool = false,
        isInitializing: Bool = false,
        selectedCardIndex: Int? = nil
    ) -> MainContentViewModel {
        let viewModel = MainContentViewModel(questionEngine: MockQuestionEngine())
        viewModel.showLaunchAnimation = showLaunchAnimation
        viewModel.isInitializing = isInitializing
        viewModel.selectedCardIndex = selectedCardIndex
        viewModel.launchAnimationProgress = showLaunchAnimation ? 0.5 : 1.0
        
        // Setup mock cards
        viewModel.cardViewModels = [
            CardViewModel.mock(
                question: "What's something that always makes you laugh?",
                category: .firstDate,
                isFlipped: selectedCardIndex == 0
            ),
            CardViewModel.mock(
                question: "What's something you've learned about yourself recently?",
                category: .personalGrowth,
                isFlipped: selectedCardIndex == 1
            ),
            CardViewModel.mock(
                question: "If you could have any superpower for a day, what would it be?",
                category: .funAndPlayful,
                isFlipped: selectedCardIndex == 2
            )
        ]
        
        return viewModel
    }
}

/// Mock QuestionEngine for previews (shared with CardViewModel)
private class MockQuestionEngine: QuestionEngine {
    func generateQuestion(for category: QuestionCategory) async throws -> String {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        let mockQuestions: [QuestionCategory: [String]] = [
            .firstDate: [
                "What's something that always makes you laugh?",
                "If you could travel anywhere right now, where would you go?",
                "What's your favorite way to spend a weekend?"
            ],
            .personalGrowth: [
                "What's something you've learned about yourself in the past year?",
                "What habit would you most like to develop?",
                "What's a fear you've overcome recently?"
            ],
            .funAndPlayful: [
                "If you could have any superpower for a day, what would it be?",
                "What's the most spontaneous thing you've ever done?",
                "If you were a character in a movie, what genre would it be?"
            ],
            .deepCouple: [
                "What's something you appreciate about our relationship that you rarely mention?",
                "How do you prefer to be comforted when you're feeling down?",
                "What's a dream you have that you've never shared with me?"
            ]
        ]
        
        let questions = mockQuestions[category] ?? ["What's on your mind today?"]
        return questions.randomElement() ?? "What's on your mind today?"
    }
    
    func generateQuestion(with configuration: QuestionConfiguration) async throws -> QuestionResult {
        let question = try await generateQuestion(for: configuration.category)
        let metadata = ProcessingMetadata(
            promptUsed: "Mock prompt",
            rawLLMResponse: question,
            processingDuration: 0.5
        )
        
        return QuestionResult(
            question: question,
            category: configuration.category,
            configuration: configuration,
            processingMetadata: metadata
        )
    }
}
#endif