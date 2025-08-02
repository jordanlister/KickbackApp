//
//  TurnManager.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation
import OSLog

// MARK: - Turn Manager

/// Manages turn rotation, question assignment, and turn-based game logic
/// Provides thread-safe operations for turn management in a two-player game
@MainActor
public final class TurnManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current game state
    @Published public private(set) var gameState: GameState
    
    /// Loading state for turn transitions
    @Published public private(set) var isTransitioningTurn: Bool = false
    
    /// Error state for turn management operations
    @Published public private(set) var turnError: TurnManagerError?
    
    // MARK: - Dependencies
    
    private let questionEngine: QuestionEngine
    private let logger: Logger
    
    // MARK: - Configuration
    
    /// Maximum turn duration before auto-advancing (in seconds)
    public let maxTurnDuration: TimeInterval = 300 // 5 minutes
    
    /// Auto-advance timer
    private var turnTimer: Timer?
    
    // MARK: - Initialization
    
    /// Creates a turn manager with the specified game state
    /// - Parameters:
    ///   - gameState: Initial game state
    ///   - questionEngine: Service for generating questions
    public init(
        gameState: GameState,
        questionEngine: QuestionEngine = QuestionEngineService()
    ) {
        self.gameState = gameState
        self.questionEngine = questionEngine
        self.logger = Logger(subsystem: "com.kickbackapp.gameplay", category: "TurnManager")
    }
    
    // MARK: - Turn Management
    
    /// Starts the game and begins the first turn
    /// - Throws: TurnManagerError for invalid operations
    public func startGame() throws {
        logger.info("Starting game with \(self.gameState.players.count) players")
        
        do {
            try gameState.startGame()
            startTurnTimer()
            clearError()
            logger.info("Game started successfully. Current player: \(self.gameState.currentPlayer.displayName)")
        } catch {
            let turnError = TurnManagerError.gameStartFailed("Failed to start game: \(error.localizedDescription)")
            setError(turnError)
            logger.error("Failed to start game: \(error.localizedDescription)")
            throw turnError
        }
    }
    
    /// Advances to the next player's turn
    /// - Throws: TurnManagerError for invalid operations
    public func nextTurn() async throws {
        logger.info("Advancing to next turn from player \(self.gameState.currentPlayer.displayName)")
        
        guard !isTransitioningTurn else {
            throw TurnManagerError.turnTransitionInProgress("Turn transition already in progress")
        }
        
        isTransitioningTurn = true
        stopTurnTimer()
        
        do {
            try gameState.nextTurn()
            startTurnTimer()
            clearError()
            
            logger.info("Advanced to turn \(self.gameState.turnCounter). Current player: \(self.gameState.currentPlayer.displayName)")
            
            // Add small delay for smooth animation
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
        } catch {
            let turnError = TurnManagerError.turnAdvanceFailed("Failed to advance turn: \(error.localizedDescription)")
            setError(turnError)
            logger.error("Failed to advance turn: \(error.localizedDescription)")
            throw turnError
        }
        
        isTransitioningTurn = false
    }
    
    /// Assigns a question category to the current turn
    /// - Parameter category: Question category to assign
    /// - Throws: TurnManagerError for invalid operations
    public func assignQuestionCategory(_ category: QuestionCategory) async throws {
        logger.info("Assigning question category \(category.rawValue) to current turn")
        
        do {
            try gameState.setQuestionCategory(category)
            clearError()
            logger.info("Question category assigned successfully")
        } catch {
            let turnError = TurnManagerError.questionAssignmentFailed("Failed to assign question: \(error.localizedDescription)")
            setError(turnError)
            logger.error("Failed to assign question category: \(error.localizedDescription)")
            throw turnError
        }
    }
    
    /// Generates a question for the current turn
    /// - Returns: Generated question string
    /// - Throws: TurnManagerError for invalid operations
    public func generateQuestionForCurrentTurn() async throws -> String {
        guard let category = gameState.currentTurn.questionCategory else {
            throw TurnManagerError.missingQuestionCategory("No question category assigned to current turn")
        }
        
        logger.info("Generating question for category \(category.rawValue)")
        
        do {
            let question = try await questionEngine.generateQuestion(for: category)
            clearError()
            logger.info("Question generated successfully")
            return question
        } catch {
            let turnError = TurnManagerError.questionGenerationFailed("Failed to generate question: \(error.localizedDescription)")
            setError(turnError)
            logger.error("Failed to generate question: \(error.localizedDescription)")
            throw turnError
        }
    }
    
    /// Marks the current turn as answered and ready for next turn
    /// - Throws: TurnManagerError for invalid operations
    public func markTurnAnswered() throws {
        logger.info("Marking current turn as answered")
        
        do {
            try gameState.markTurnAnswered()
            clearError()
            logger.info("Turn marked as answered successfully")
        } catch {
            let turnError = TurnManagerError.turnCompletionFailed("Failed to mark turn answered: \(error.localizedDescription)")
            setError(turnError)
            logger.error("Failed to mark turn answered: \(error.localizedDescription)")
            throw turnError
        }
    }
    
    /// Completes the current game session
    /// - Throws: TurnManagerError for invalid operations
    public func completeGame() throws {
        logger.info("Completing game session")
        
        stopTurnTimer()
        
        do {
            try gameState.completeGame()
            clearError()
            logger.info("Game completed successfully")
        } catch {
            let turnError = TurnManagerError.gameCompletionFailed("Failed to complete game: \(error.localizedDescription)")
            setError(turnError)
            logger.error("Failed to complete game: \(error.localizedDescription)")
            throw turnError
        }
    }
    
    /// Resets the game to initial state
    public func resetGame() {
        logger.info("Resetting game to initial state")
        
        stopTurnTimer()
        gameState.resetGame()
        isTransitioningTurn = false
        clearError()
        
        logger.info("Game reset completed")
    }
    
    // MARK: - Turn Information
    
    /// Gets the current player
    /// - Returns: Current player
    public func getCurrentPlayer() -> Player {
        return gameState.currentPlayer
    }
    
    /// Gets the other player (not current turn)
    /// - Returns: Other player
    public func getOtherPlayer() -> Player {
        return gameState.otherPlayer
    }
    
    /// Checks if it's a specific player's turn
    /// - Parameter player: Player to check
    /// - Returns: True if it's the player's turn
    public func isPlayerTurn(_ player: Player) -> Bool {
        return gameState.currentPlayer.id == player.id
    }
    
    /// Gets turn statistics
    /// - Returns: Turn statistics information
    public func getTurnStatistics() -> TurnStatistics {
        return TurnStatistics(
            totalTurns: gameState.totalCompletedTurns,
            currentRound: gameState.roundCounter + 1,
            questionsThisRound: gameState.questionsThisRound,
            currentTurnDuration: gameState.currentTurn.turnDuration,
            gameStartTime: gameState.createdAt
        )
    }
    
    // MARK: - Question Category Selection
    
    /// Gets recommended question categories based on conversation mode
    /// - Returns: Array of recommended categories
    public func getRecommendedCategories() -> [QuestionCategory] {
        guard let mode = gameState.conversationMode else {
            return QuestionCategory.allCases.shuffled().prefix(3).map { $0 }
        }
        
        var categories = mode.preferredCategories.shuffled()
        
        // Ensure we have at least 3 categories
        while categories.count < 3 {
            let additionalCategories = QuestionCategory.allCases.filter { !categories.contains($0) }
            categories.append(contentsOf: additionalCategories.shuffled())
        }
        
        return Array(categories.prefix(3))
    }
    
    /// Gets random question categories avoiding recent duplicates
    /// - Parameter count: Number of categories to return
    /// - Returns: Array of random categories
    public func getRandomCategories(count: Int = 3) -> [QuestionCategory] {
        // For now, return random categories
        // Future enhancement: track recent categories to avoid duplicates
        return QuestionCategory.allCases.shuffled().prefix(count).map { $0 }
    }
    
    // MARK: - Timer Management
    
    /// Starts the turn timer for automatic turn advancement
    private func startTurnTimer() {
        stopTurnTimer()
        
        turnTimer = Timer.scheduledTimer(withTimeInterval: maxTurnDuration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleTurnTimeout()
            }
        }
    }
    
    /// Stops the turn timer
    private func stopTurnTimer() {
        turnTimer?.invalidate()
        turnTimer = nil
    }
    
    /// Handles turn timeout by automatically advancing
    private func handleTurnTimeout() async {
        logger.warning("Turn timeout occurred for player \(self.gameState.currentPlayer.displayName)")
        
        // Mark turn as answered (timeout) and advance
        do {
            if !gameState.currentTurn.hasAnswered {
                try gameState.markTurnAnswered()
            }
            try await nextTurn()
            
            // Set timeout metadata
            gameState.setMetadata(key: "lastTurnTimedOut", value: "true")
            
        } catch {
            logger.error("Failed to handle turn timeout: \(error.localizedDescription)")
            setError(TurnManagerError.turnTimeoutFailed("Failed to handle turn timeout: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Error Management
    
    /// Sets an error state
    /// - Parameter error: Error to set
    private func setError(_ error: TurnManagerError) {
        turnError = error
    }
    
    /// Clears the current error state
    private func clearError() {
        turnError = nil
    }
    
    /// Clears the current error
    public func clearTurnError() {
        clearError()
    }
    
    // MARK: - Cleanup
    
    deinit {
        turnTimer?.invalidate()
        turnTimer = nil
    }
}

// MARK: - Turn Statistics

/// Statistics and information about turn progression
public struct TurnStatistics {
    /// Total number of completed turns
    public let totalTurns: Int
    
    /// Current round number (1-based)
    public let currentRound: Int
    
    /// Number of questions asked this round
    public let questionsThisRound: Int
    
    /// Duration of current turn
    public let currentTurnDuration: TimeInterval
    
    /// When the game started
    public let gameStartTime: Date
    
    /// Total game duration
    public var gameDuration: TimeInterval {
        return Date().timeIntervalSince(gameStartTime)
    }
    
    /// Average turn duration (if any turns completed)
    public var averageTurnDuration: TimeInterval? {
        guard totalTurns > 0 else { return nil }
        return gameDuration / Double(totalTurns)
    }
}

// MARK: - Turn Manager Error

/// Errors that can occur during turn management
public enum TurnManagerError: LocalizedError, Equatable {
    case gameStartFailed(String)
    case turnTransitionInProgress(String)
    case turnAdvanceFailed(String)
    case questionAssignmentFailed(String)
    case questionGenerationFailed(String)
    case missingQuestionCategory(String)
    case turnCompletionFailed(String)
    case gameCompletionFailed(String)
    case turnTimeoutFailed(String)
    case invalidGameState(String)
    
    public var errorDescription: String? {
        switch self {
        case .gameStartFailed(let message):
            return "Game Start Failed: \(message)"
        case .turnTransitionInProgress(let message):
            return "Turn Transition In Progress: \(message)"
        case .turnAdvanceFailed(let message):
            return "Turn Advance Failed: \(message)"
        case .questionAssignmentFailed(let message):
            return "Question Assignment Failed: \(message)"
        case .questionGenerationFailed(let message):
            return "Question Generation Failed: \(message)"
        case .missingQuestionCategory(let message):
            return "Missing Question Category: \(message)"
        case .turnCompletionFailed(let message):
            return "Turn Completion Failed: \(message)"
        case .gameCompletionFailed(let message):
            return "Game Completion Failed: \(message)"
        case .turnTimeoutFailed(let message):
            return "Turn Timeout Failed: \(message)"
        case .invalidGameState(let message):
            return "Invalid Game State: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .gameStartFailed:
            return "The game could not be started due to invalid setup"
        case .turnTransitionInProgress:
            return "A turn transition is already in progress"
        case .turnAdvanceFailed:
            return "The turn could not be advanced to the next player"
        case .questionAssignmentFailed:
            return "The question category could not be assigned"
        case .questionGenerationFailed:
            return "A question could not be generated"
        case .missingQuestionCategory:
            return "No question category has been assigned"
        case .turnCompletionFailed:
            return "The turn could not be marked as completed"
        case .gameCompletionFailed:
            return "The game could not be completed"
        case .turnTimeoutFailed:
            return "The turn timeout could not be handled"
        case .invalidGameState:
            return "The game is in an invalid state"
        }
    }
}

// MARK: - Extensions

extension TurnManager {
    /// Creates a preview turn manager for testing and SwiftUI previews
    public static func preview(
        gamePhase: GamePhase = .playing,
        currentPlayerIndex: Int = 0,
        turnCounter: Int = 2
    ) -> TurnManager {
        let gameState = GameState.preview(
            gamePhase: gamePhase,
            conversationMode: .blindDate,
            currentPlayerIndex: currentPlayerIndex,
            turnCounter: turnCounter
        )
        
        return TurnManager(gameState: gameState)
    }
}