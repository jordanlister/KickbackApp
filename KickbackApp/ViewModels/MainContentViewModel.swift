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
    @Published var showPlayerSetup: Bool = false
    @Published var showCards: Bool = false
    
    /// Global loading state for initial app setup
    @Published var isInitializing: Bool = true
    
    /// Available question categories for the current session
    @Published var availableCategories: [QuestionCategory] = []
    
    /// Error state for critical app failures
    @Published var criticalError: String?
    
    /// Completed card answers for compatibility analysis
    @Published var completedCardAnswers: [CardAnswers] = []
    
    /// Game completion analysis results
    @Published var gameCompletionResult: GameCompletionResult?
    
    /// Game completion state management
    @Published var isAnalyzingGame: Bool = false
    @Published var showGameResults: Bool = false
    @Published var gameAnalysisError: String?
    
    /// Onboarding state management
    @Published var showOnboarding: Bool = false
    
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
    private let gameCompletionService: GameCompletionService
    
    // MARK: - Gameplay Integration
    
    @Published var gameplayIntegration = GameplayIntegration()
    @Published var playerManager = PlayerManager()
    
    // MARK: - Initialization
    
    /// Initializes MainContentViewModel with dependency injection
    /// - Parameters:
    ///   - questionEngine: Service for generating questions
    ///   - gameCompletionService: Service for analyzing completed games
    init(questionEngine: QuestionEngine? = nil, gameCompletionService: GameCompletionService? = nil) {
        // Use real services for actual AI-powered question generation and analysis
        self.questionEngine = questionEngine ?? QuestionEngineService()
        self.gameCompletionService = gameCompletionService ?? GameCompletionServiceImpl()
        setupInitialState()
        
        // Initialize gameplay integration
        gameplayIntegration = GameplayIntegration(mainContentViewModel: self)
        
        // Check if onboarding should be shown
        checkOnboardingStatus()
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
        // Don't refresh cards if game is complete or analysis is in progress
        guard !isAnalyzingGame && !showGameResults else {
            print("Skipping card refresh - game analysis in progress or complete")
            return
        }
        
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
        
        // After pills disappear, show player setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                self.showPlayerSetup = true
            }
        }
        
        // Update cards with mode-specific categories
        Task {
            await updateCardsForMode(mode)
        }
    }
    
    /// Returns to mode selection screen
    func returnToModeSelection() {
        // First hide cards and deselect any selected card
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCards = false
            selectedCardIndex = nil
        }
        
        // Reset selected mode and show mode selection
        selectedMode = nil
        
        // After cards disappear, show mode selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                self.showModeSelection = true
            }
        }
        
        // Reset all cards to initial state
        for cardVM in cardViewModels {
            cardVM.reset()
        }
    }
    
    /// Handles completion of player setup and starts the game
    func completePlayerSetup() {
        // Enable turn-based mode with player data
        gameplayIntegration.enableTurnBasedMode(with: playerManager)
        
        // Hide player setup and show cards with game start
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showPlayerSetup = false
        }
        
        // After setup disappears, show cards
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                self.showCards = true
            }
        }
    }
    
    /// Handles onboarding completion and transitions to main app
    func completeOnboarding() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            showOnboarding = false
        }
        
        // Start the launch sequence after onboarding is hidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                await self.startLaunchSequence()
            }
        }
    }
    
    /// Stores completed card answers for compatibility analysis
    /// - Parameter cardAnswers: The completed card answers to store
    func storeCompletedCardAnswers(_ cardAnswers: CardAnswers) {
        guard cardAnswers.isComplete else {
            print("Warning: Attempting to store incomplete card answers")
            return
        }
        
        completedCardAnswers.append(cardAnswers)
        print("Stored completed card answers. Total cards: \(completedCardAnswers.count)")
        
        // Check if we have enough cards for game completion (5 questions)
        let requiredQuestions = getRequiredQuestionsForGameMode()
        if completedCardAnswers.count >= requiredQuestions {
            print("Game complete! \(completedCardAnswers.count)/\(requiredQuestions) questions answered")
            triggerGameCompletion()
        } else {
            print("Progress: \(completedCardAnswers.count)/\(requiredQuestions) questions answered")
        }
    }
    
    /// Gets the required number of questions based on the current game mode
    /// - Returns: Number of questions required to complete the game
    func getRequiredQuestionsForGameMode() -> Int {
        // All game modes require 5 questions for completion
        return 5
    }
    
    /// Triggers game completion flow with comprehensive compatibility analysis
    private func triggerGameCompletion() {
        print("Triggering game completion with \(completedCardAnswers.count) completed cards")
        
        Task {
            await performGameCompletionAnalysis()
        }
    }
    
    /// Stops all card loading and question generation
    private func stopAllCardLoading() {
        print("🛑 Stopping all card loading and question generation")
        for cardVM in cardViewModels {
            cardVM.isLoading = false
        }
    }
    
    /// Performs comprehensive game completion analysis
    @MainActor
    private func performGameCompletionAnalysis() async {
        guard completedCardAnswers.count >= getRequiredQuestionsForGameMode() else {
            print("❌ Insufficient completed cards for analysis: \(completedCardAnswers.count)/\(getRequiredQuestionsForGameMode())")
            return
        }
        
        print("🎯 Starting game completion analysis with \(completedCardAnswers.count) answers...")
        isAnalyzingGame = true
        gameAnalysisError = nil
        
        // Stop all card loading and question generation immediately
        stopAllCardLoading()
        
        // Show results screen immediately to indicate processing
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showGameResults = true
            showCards = false
        }
        
        do {
            print("🧠 Processing compatibility analysis...")
            let analysisResult = try await gameCompletionService.processGameCompletion(completedCardAnswers)
            
            gameCompletionResult = analysisResult
            print("✅ Game analysis completed successfully!")
            
        } catch {
            print("❌ Game analysis failed: \(error.localizedDescription)")
            gameAnalysisError = error.localizedDescription
            
            // Create a basic fallback result if analysis fails
            if gameCompletionResult == nil {
                print("🔄 Creating fallback result...")
                gameCompletionResult = createFallbackGameResult()
            }
        }
        
        isAnalyzingGame = false
        print("🏁 Game completion analysis finished. Results: \(gameCompletionResult != nil ? "✅" : "❌")")
    }
    
    /// Retries game completion analysis after an error
    func retryGameAnalysis() {
        gameAnalysisError = nil
        Task {
            await performGameCompletionAnalysis()
        }
    }
    
    /// Starts a new game session, resetting all state
    func startNewGame() {
        // Reset all game state
        completedCardAnswers.removeAll()
        gameCompletionResult = nil
        gameAnalysisError = nil
        showGameResults = false
        
        // Reset player setup and return to mode selection
        playerManager = PlayerManager()
        gameplayIntegration = GameplayIntegration(mainContentViewModel: self)
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            showModeSelection = true
            showPlayerSetup = false
        }
        
        // Reset cards
        for cardVM in cardViewModels {
            cardVM.reset()
        }
        
        print("New game started - all state reset")
    }
    
    /// Creates a fallback game result when analysis fails
    private func createFallbackGameResult() -> GameCompletionResult {
        // Create basic fallback data
        let basicDimensions = CompatibilityDimensions(
            emotionalOpenness: 75, clarity: 70, empathy: 75, vulnerability: 65, communicationStyle: 70
        )
        
        let basicInsight = CompatibilityInsight(
            type: .compatibility,
            title: "Analysis Unavailable",
            description: "We couldn't complete the full analysis, but you both completed 5 questions together!",
            confidence: .medium
        )
        
        let basicMetadata = AnalysisMetadata(
            promptUsed: "fallback",
            rawLLMResponse: "fallback",
            processingDuration: 0.0,
            analysisType: .individual,
            questionCategory: .firstDate,
            responseLength: 0,
            seed: nil
        )
        
        let basicResult = CompatibilityResult(
            score: 70,
            summary: "You both engaged thoughtfully with the questions!",
            tone: "positive",
            dimensions: basicDimensions,
            insights: [basicInsight],
            analysisMetadata: basicMetadata
        )
        
        let sessionAnalysis = SessionAnalysis(
            sessionId: UUID(),
            responses: [basicResult, basicResult],
            overallSessionScore: 70,
            trendAnalysis: TrendAnalysis(
                scoreProgression: [65, 70, 75],
                improvingDimensions: ["Clarity"],
                consistentStrengths: ["Empathy"],
                developmentAreas: ["Vulnerability"],
                confidenceGrowth: 0.1
            ),
            categoryBreakdown: [.firstDate: 70],
            sessionInsights: [basicInsight]
        )
        
        let playerAnalysis = PlayerSessionAnalysis(
            playerNumber: 1,
            individualResults: [basicResult],
            sessionAnalysis: sessionAnalysis,
            responseCount: completedCardAnswers.count,
            averageScore: 70,
            strongestDimensions: ["Empathy", "Clarity"],
            growthAreas: ["Vulnerability"]
        )
        
        let comparativeAnalysis = ComparativeGameAnalysis(
            questionComparisons: [],
            overallCompatibilityScore: 70,
            compatibilityTier: .moderate,
            relationshipInsights: [],
            communicationSynergy: CommunicationSynergy(
                synergyScore: 0.7,
                strengths: ["Good engagement"],
                challenges: [],
                recommendations: ["Continue practicing open communication"]
            ),
            recommendedNextSteps: [
                "Continue having meaningful conversations",
                "Explore deeper topics together",
                "Practice active listening"
            ]
        )
        
        let gameMetrics = GameMetrics(
            overallScore: 70,
            compatibilityPotential: 75,
            communicationQuality: 70,
            engagementLevel: 80,
            balanceScore: 75,
            insightfulness: 65
        )
        
        return GameCompletionResult(
            id: UUID(),
            player1Analysis: playerAnalysis,
            player2Analysis: PlayerSessionAnalysis(
                playerNumber: 2,
                individualResults: [basicResult],
                sessionAnalysis: sessionAnalysis,
                responseCount: completedCardAnswers.count,
                averageScore: 70,
                strongestDimensions: ["Empathy", "Clarity"],
                growthAreas: ["Vulnerability"]
            ),
            comparativeAnalysis: comparativeAnalysis,
            sessionInsights: [
                SessionInsight(
                    type: .communicationStrength,
                    title: "Great Completion!",
                    description: "You both completed all \(completedCardAnswers.count) questions together.",
                    confidence: .high,
                    impact: .positive
                )
            ],
            gameMetrics: gameMetrics,
            cardAnswers: completedCardAnswers,
            completionDuration: 0.0,
            completedAt: Date()
        )
    }
    
    /// Returns to main menu from results screen
    func returnToMainMenu() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            showGameResults = false
            showModeSelection = true
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
    
    /// Checks if onboarding should be shown based on UserDefaults
    func checkOnboardingStatus() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "KickbackOnboardingCompleted")
        showOnboarding = !hasCompletedOnboarding
        
        // When resetting onboarding, ensure launch animation is off
        showLaunchAnimation = false
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
        showCards: Bool = true,
        showOnboarding: Bool = false
    ) -> MainContentViewModel {
        let viewModel = MainContentViewModel()
        viewModel.showLaunchAnimation = showLaunchAnimation
        viewModel.isInitializing = isInitializing
        viewModel.selectedCardIndex = selectedCardIndex
        viewModel.showModeSelection = showModeSelection
        viewModel.showCards = showCards
        viewModel.showOnboarding = showOnboarding
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