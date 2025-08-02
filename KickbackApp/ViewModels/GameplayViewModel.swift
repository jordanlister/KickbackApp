//
//  GameplayViewModel.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation
import SwiftUI
import OSLog

/// Main ViewModel orchestrating turn-based gameplay
/// Integrates with MainContentViewModel and manages the complete game flow
@MainActor
public final class GameplayViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current turn manager handling game state
    @Published public private(set) var turnManager: TurnManager?
    
    /// Current gameplay phase
    @Published public private(set) var gameplayPhase: GameplayPhase = .playerSetup
    
    /// Player setup data
    @Published public var playerSetupData: PlayerSetupData?
    
    /// Loading states
    @Published public private(set) var isInitializingGame: Bool = false
    @Published public private(set) var isGeneratingQuestion: Bool = false
    @Published public private(set) var isTransitioningTurn: Bool = false
    
    /// Current generated question for display
    @Published public private(set) var currentQuestion: String?
    
    /// Error states
    @Published public private(set) var gameplayError: GameplayError?
    
    /// Turn indicator visibility
    @Published public var showTurnIndicator: Bool = false
    
    /// Question reveal animation state
    @Published public var questionRevealProgress: Double = 0.0
    
    // MARK: - Dependencies
    
    private let questionEngine: QuestionEngine
    private let logger: Logger
    
    // MARK: - Integration with MainContentViewModel
    
    /// Reference to main content view model for coordination
    public weak var mainContentViewModel: MainContentViewModel?
    
    // MARK: - Initialization
    
    /// Initializes gameplay view model with dependencies
    /// - Parameters:
    ///   - questionEngine: Service for generating questions
    ///   - mainContentViewModel: Main content view model for integration
    public init(
        questionEngine: QuestionEngine = QuestionEngineService(),
        mainContentViewModel: MainContentViewModel? = nil
    ) {
        self.questionEngine = questionEngine
        self.mainContentViewModel = mainContentViewModel
        self.logger = Logger(subsystem: "com.kickbackapp.gameplay", category: "GameplayViewModel")
    }
    
    // MARK: - Player Setup
    
    /// Completes player setup and transitions to mode selection
    /// - Parameter setupData: Validated player setup data
    public func completePlayerSetup(with setupData: PlayerSetupData) {
        logger.info("Completing player setup for players: \(setupData.player1.displayName), \(setupData.player2.displayName)")
        
        playerSetupData = setupData
        gameplayPhase = .modeSelection
        clearError()
        
        // Show turn indicator after setup completion
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5)) {
            showTurnIndicator = false
        }
    }
    
    /// Returns to player setup from mode selection
    public func returnToPlayerSetup() {
        logger.info("Returning to player setup")
        
        gameplayPhase = .playerSetup
        playerSetupData = nil
        showTurnIndicator = false
        clearError()
    }
    
    // MARK: - Mode Selection and Game Start
    
    /// Selects conversation mode and starts the game
    /// - Parameter mode: Selected conversation mode
    public func selectModeAndStartGame(_ mode: ConversationMode) async {
        logger.info("Starting game with mode: \(mode.rawValue)")
        
        guard let setupData = playerSetupData else {
            setError(.missingPlayerSetup("Player setup must be completed before starting game"))
            return
        }
        
        isInitializingGame = true
        gameplayPhase = .initializing
        
        do {
            // Create game state and turn manager
            let gameState = GameState(
                player1: setupData.player1,
                player2: setupData.player2,
                conversationMode: mode
            )
            
            let newTurnManager = TurnManager(gameState: gameState, questionEngine: questionEngine)
            turnManager = newTurnManager
            
            // Start the game
            try newTurnManager.startGame()
            
            // Transition to active gameplay
            gameplayPhase = .activeGame
            
            // Update main content view model to show cards
            await updateMainContentForGameplay(mode: mode)
            
            // Show turn indicator
            await showCurrentPlayerTurn()
            
            clearError()
            logger.info("Game started successfully")
            
        } catch {
            setError(.gameInitializationFailed("Failed to start game: \(error.localizedDescription)"))
            logger.error("Failed to start game: \(error.localizedDescription)")
            gameplayPhase = .modeSelection
        }
        
        isInitializingGame = false
    }
    
    // MARK: - Active Gameplay
    
    /// Gets the current player whose turn it is
    /// - Returns: Current player or nil if game not active
    public func getCurrentPlayer() -> Player? {
        guard gameplayPhase == .activeGame else {
            print("GameplayViewModel.getCurrentPlayer: Game not in active phase (\(gameplayPhase)), returning nil")
            return nil
        }
        
        guard let currentPlayer = turnManager?.getCurrentPlayer() else {
            print("GameplayViewModel.getCurrentPlayer: No turn manager or current player, returning nil")
            return nil
        }
        
        print("GameplayViewModel.getCurrentPlayer: Returning player \(currentPlayer.displayName)")
        return currentPlayer
    }
    
    /// Handles card selection and question generation
    /// - Parameters:
    ///   - cardIndex: Selected card index
    ///   - category: Question category for the card
    public func handleCardSelection(cardIndex: Int, category: QuestionCategory) async {
        logger.info("Card selected at index \(cardIndex) with category \(category.rawValue)")
        
        guard let turnManager = turnManager else {
            setError(.gameNotInitialized("Game must be started before selecting cards"))
            return
        }
        
        guard turnManager.gameState.gamePhase == .playing else {
            setError(.invalidGamePhase("Cannot select cards outside of active gameplay"))
            return
        }
        
        isGeneratingQuestion = true
        hideTurnIndicator()
        
        do {
            // Assign question category to current turn
            try await turnManager.assignQuestionCategory(category)
            
            // Generate question for the category
            let question = try await turnManager.generateQuestionForCurrentTurn()
            
            // Update current question with animation
            await updateCurrentQuestion(question)
            
            // Coordinate with main content view model
            await mainContentViewModel?.selectCard(at: cardIndex)
            
            clearError()
            logger.info("Question generated successfully for category \(category.rawValue)")
            
        } catch {
            setError(.questionGenerationFailed("Failed to generate question: \(error.localizedDescription)"))
            logger.error("Failed to generate question: \(error.localizedDescription)")
            
            // Show turn indicator again on error
            await showCurrentPlayerTurn()
        }
        
        isGeneratingQuestion = false
    }
    
    /// Completes the current turn and advances to next player
    public func completeTurnAndAdvance() async {
        logger.info("Completing current turn and advancing to next player")
        
        guard let turnManager = turnManager else {
            setError(.gameNotInitialized("Game must be started before completing turns"))
            return
        }
        
        isTransitioningTurn = true
        
        do {
            // Mark current turn as answered
            try turnManager.markTurnAnswered()
            
            // Clear current question
            currentQuestion = nil
            questionRevealProgress = 0.0
            
            // Deselect all cards in main content
            await mainContentViewModel?.deselectAllCards()
            
            // Add transition delay for smooth animation
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Advance to next turn
            try await turnManager.nextTurn()
            
            // Refresh cards for new turn
            await refreshCardsForNewTurn()
            
            // Show new player turn indicator
            await showCurrentPlayerTurn()
            
            clearError()
            logger.info("Turn completed and advanced successfully")
            
        } catch {
            setError(.turnAdvanceFailed("Failed to advance turn: \(error.localizedDescription)"))
            logger.error("Failed to advance turn: \(error.localizedDescription)")
        }
        
        isTransitioningTurn = false
    }
    
    /// Ends the current game session
    public func endGame() async {
        logger.info("Ending current game session")
        
        guard let turnManager = turnManager else {
            logger.warning("Attempted to end game but no turn manager exists")
            return
        }
        
        do {
            try turnManager.completeGame()
            gameplayPhase = .gameComplete
            hideTurnIndicator()
            
            logger.info("Game ended successfully")
            
        } catch {
            setError(.gameCompletionFailed("Failed to end game: \(error.localizedDescription)"))
            logger.error("Failed to end game: \(error.localizedDescription)")
        }
    }
    
    /// Resets the entire game to player setup
    public func resetToPlayerSetup() async {
        logger.info("Resetting game to player setup")
        
        turnManager?.resetGame()
        turnManager = nil
        playerSetupData = nil
        currentQuestion = nil
        questionRevealProgress = 0.0
        gameplayPhase = .playerSetup
        showTurnIndicator = false
        
        // Reset main content view model
        await mainContentViewModel?.returnToModeSelection()
        
        clearError()
        logger.info("Game reset to player setup completed")
    }
    
    // MARK: - Current Game Information
    
    /// Gets the other player (not current turn)
    /// - Returns: Other player or nil if game not started
    public func getOtherPlayer() -> Player? {
        return turnManager?.getOtherPlayer()
    }
    
    /// Gets current turn statistics
    /// - Returns: Turn statistics or nil if game not started
    public func getTurnStatistics() -> TurnStatistics? {
        return turnManager?.getTurnStatistics()
    }
    
    /// Checks if the game is currently active
    /// - Returns: True if game is in active playing state
    public func isGameActive() -> Bool {
        return gameplayPhase == .activeGame && turnManager?.gameState.isGameActive == true
    }
    
    // MARK: - Private Methods
    
    /// Updates main content view model for active gameplay
    /// - Parameter mode: Selected conversation mode
    private func updateMainContentForGameplay(mode: ConversationMode) async {
        await mainContentViewModel?.selectMode(mode)
    }
    
    /// Shows turn indicator for current player
    private func showCurrentPlayerTurn() async {
        guard let currentPlayer = getCurrentPlayer() else { return }
        
        logger.debug("Showing turn indicator for player: \(currentPlayer.displayName)")
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            showTurnIndicator = true
        }
    }
    
    /// Hides the turn indicator
    private func hideTurnIndicator() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showTurnIndicator = false
        }
    }
    
    /// Updates current question with reveal animation
    /// - Parameter question: New question to display
    private func updateCurrentQuestion(_ question: String) async {
        currentQuestion = question
        
        // Animate question reveal
        await animateQuestionReveal()
    }
    
    /// Animates question reveal character by character
    private func animateQuestionReveal() async {
        guard let question = currentQuestion else { return }
        
        let characters = Array(question)
        let totalCharacters = characters.count
        let animationDuration: TimeInterval = 1.5
        let characterDelay = animationDuration / Double(totalCharacters)
        
        for i in 0..<totalCharacters {
            let progress = Double(i + 1) / Double(totalCharacters)
            
            withAnimation(.easeOut(duration: characterDelay)) {
                questionRevealProgress = progress
            }
            
            try? await Task.sleep(nanoseconds: UInt64(characterDelay * 0.8 * 1_000_000_000))
        }
    }
    
    /// Refreshes cards for new turn
    private func refreshCardsForNewTurn() async {
        guard let turnManager = turnManager else { return }
        
        // Get recommended categories based on conversation mode
        let categories = turnManager.getRecommendedCategories()
        
        // Update main content cards with new categories
        await mainContentViewModel?.refreshAllCards()
    }
    
    /// Sets an error state
    /// - Parameter error: Error to set
    private func setError(_ error: GameplayError) {
        gameplayError = error
        logger.error("Gameplay error: \(error.localizedDescription ?? "Unknown error")")
    }
    
    /// Clears the current error state
    private func clearError() {
        gameplayError = nil
    }
    
    /// Clears the current error
    public func clearGameplayError() {
        clearError()
    }
}

// MARK: - Gameplay Phase

/// Enumeration of gameplay phases
public enum GameplayPhase: String, CaseIterable {
    case playerSetup = "player_setup"
    case modeSelection = "mode_selection"
    case initializing = "initializing"
    case activeGame = "active_game"
    case gameComplete = "game_complete"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .playerSetup:
            return "Player Setup"
        case .modeSelection:
            return "Mode Selection"
        case .initializing:
            return "Starting Game"
        case .activeGame:
            return "Playing"
        case .gameComplete:
            return "Game Complete"
        }
    }
}

// MARK: - Gameplay Error

/// Errors that can occur during gameplay management
public enum GameplayError: LocalizedError, Equatable {
    case missingPlayerSetup(String)
    case gameInitializationFailed(String)
    case gameNotInitialized(String)
    case invalidGamePhase(String)
    case questionGenerationFailed(String)
    case turnAdvanceFailed(String)
    case gameCompletionFailed(String)
    case integrationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingPlayerSetup(let message):
            return "Missing Player Setup: \(message)"
        case .gameInitializationFailed(let message):
            return "Game Initialization Failed: \(message)"
        case .gameNotInitialized(let message):
            return "Game Not Initialized: \(message)"
        case .invalidGamePhase(let message):
            return "Invalid Game Phase: \(message)"
        case .questionGenerationFailed(let message):
            return "Question Generation Failed: \(message)"
        case .turnAdvanceFailed(let message):
            return "Turn Advance Failed: \(message)"
        case .gameCompletionFailed(let message):
            return "Game Completion Failed: \(message)"
        case .integrationError(let message):
            return "Integration Error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .missingPlayerSetup:
            return "Player information must be provided before starting the game"
        case .gameInitializationFailed:
            return "The game could not be properly initialized"
        case .gameNotInitialized:
            return "The game must be started before this action can be performed"
        case .invalidGamePhase:
            return "This action cannot be performed in the current game phase"
        case .questionGenerationFailed:
            return "A question could not be generated for the selected category"
        case .turnAdvanceFailed:
            return "The turn could not be advanced to the next player"
        case .gameCompletionFailed:
            return "The game could not be properly completed"
        case .integrationError:
            return "An error occurred while coordinating with other app components"
        }
    }
}

// MARK: - Extensions

extension GameplayViewModel {
    /// Creates a preview gameplay view model for testing and SwiftUI previews
    public static func preview(
        gameplayPhase: GameplayPhase = .playerSetup,
        withPlayers: Bool = false,
        withActiveGame: Bool = false
    ) -> GameplayViewModel {
        let viewModel = GameplayViewModel()
        viewModel.gameplayPhase = gameplayPhase
        
        if withPlayers {
            let player1 = Player.preview(name: "Alex", pronouns: .theyThem, playerNumber: 1)
            let player2 = Player.preview(name: "Jordan", pronouns: .sheHer, playerNumber: 2)
            viewModel.playerSetupData = PlayerSetupData(player1: player1, player2: player2)
        }
        
        if withActiveGame {
            let gameState = GameState.preview(gamePhase: .playing, conversationMode: .blindDate)
            viewModel.turnManager = TurnManager(gameState: gameState)
            viewModel.gameplayPhase = .activeGame
            viewModel.currentQuestion = "What's something you've always wanted to try but haven't had the chance to do yet?"
            viewModel.questionRevealProgress = 1.0
        }
        
        return viewModel
    }
}