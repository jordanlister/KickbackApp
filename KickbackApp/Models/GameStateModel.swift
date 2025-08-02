//
//  GameStateModel.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation
import Observation

// MARK: - Game State Model

/// Represents the complete state of a turn-based game session
/// Manages players, turn progression, and game phases
@Observable
public final class GameState {
    
    // MARK: - Properties
    
    /// Unique identifier for this game session
    public let gameID: UUID
    
    /// Players participating in the game
    public private(set) var players: [Player]
    
    /// Current game phase
    public private(set) var gamePhase: GamePhase
    
    /// Selected conversation mode
    public var conversationMode: ConversationMode?
    
    /// Current turn information
    public private(set) var currentTurn: TurnState
    
    /// Turn counter and round tracking
    public private(set) var turnCounter: Int
    
    /// Round counter (each round = both players have had a turn)
    public private(set) var roundCounter: Int
    
    /// Game session timestamp
    public let createdAt: Date
    
    /// Last activity timestamp
    public var lastActivity: Date
    
    /// Game session metadata
    public var metadata: [String: String]
    
    // MARK: - Initialization
    
    /// Creates a new game state with the specified players
    /// - Parameters:
    ///   - player1: First player
    ///   - player2: Second player
    ///   - conversationMode: Optional conversation mode
    public init(
        player1: Player,
        player2: Player,
        conversationMode: ConversationMode? = nil
    ) {
        self.gameID = UUID()
        self.players = [player1, player2]
        self.gamePhase = .setup
        self.conversationMode = conversationMode
        self.currentTurn = TurnState(
            currentPlayerIndex: 0,
            turnStartTime: Date(),
            questionCategory: nil,
            hasAnswered: false
        )
        self.turnCounter = 0
        self.roundCounter = 0
        self.createdAt = Date()
        self.lastActivity = Date()
        self.metadata = [:]
    }
    
    // MARK: - Computed Properties
    
    /// Current player whose turn it is
    public var currentPlayer: Player {
        return players[currentTurn.currentPlayerIndex]
    }
    
    /// Other player (not current turn)
    public var otherPlayer: Player {
        let otherIndex = (currentTurn.currentPlayerIndex + 1) % players.count
        return players[otherIndex]
    }
    
    /// True if game is in active playing state
    public var isGameActive: Bool {
        return gamePhase == .playing
    }
    
    /// True if game has been completed
    public var isGameComplete: Bool {
        return gamePhase == .complete
    }
    
    /// True if setup phase is complete
    public var isSetupComplete: Bool {
        return gamePhase != .setup
    }
    
    /// Total number of completed turns by both players
    public var totalCompletedTurns: Int {
        return turnCounter
    }
    
    /// Number of questions asked this round
    public var questionsThisRound: Int {
        return turnCounter - (roundCounter * players.count)
    }
    
    // MARK: - Game State Management
    
    /// Starts the game after setup completion
    /// - Throws: GameStateError for invalid state transitions
    public func startGame() throws {
        guard gamePhase == .setup else {
            throw GameStateError.invalidPhaseTransition("Cannot start game from \(gamePhase) phase")
        }
        
        guard let _ = conversationMode else {
            throw GameStateError.missingConversationMode("Conversation mode must be selected before starting")
        }
        
        guard players.allSatisfy({ $0.isValid }) else {
            throw GameStateError.invalidPlayerData("All players must have valid data")
        }
        
        gamePhase = .playing
        currentTurn = TurnState(
            currentPlayerIndex: 0,
            turnStartTime: Date(),
            questionCategory: nil,
            hasAnswered: false
        )
        turnCounter = 0
        roundCounter = 0
        updateLastActivity()
    }
    
    /// Advances to the next turn
    /// - Throws: GameStateError for invalid state
    public func nextTurn() throws {
        guard gamePhase == .playing else {
            throw GameStateError.invalidPhaseTransition("Cannot advance turn in \(gamePhase) phase")
        }
        
        // Increment turn counter
        turnCounter += 1
        
        // Calculate next player index
        let nextPlayerIndex = (currentTurn.currentPlayerIndex + 1) % players.count
        
        // If we've cycled through all players, increment round counter
        if nextPlayerIndex == 0 && turnCounter > 0 {
            roundCounter += 1
        }
        
        // Create new turn state
        currentTurn = TurnState(
            currentPlayerIndex: nextPlayerIndex,
            turnStartTime: Date(),
            questionCategory: nil,
            hasAnswered: false
        )
        
        updateLastActivity()
    }
    
    /// Sets the question category for the current turn
    /// - Parameter category: Question category to set
    /// - Throws: GameStateError for invalid state
    public func setQuestionCategory(_ category: QuestionCategory) throws {
        guard gamePhase == .playing else {
            throw GameStateError.invalidPhaseTransition("Cannot set question category in \(gamePhase) phase")
        }
        
        currentTurn.questionCategory = category
        updateLastActivity()
    }
    
    /// Marks the current turn as answered
    /// - Throws: GameStateError for invalid state
    public func markTurnAnswered() throws {
        guard gamePhase == .playing else {
            throw GameStateError.invalidPhaseTransition("Cannot mark turn answered in \(gamePhase) phase")
        }
        
        guard !currentTurn.hasAnswered else {
            throw GameStateError.turnAlreadyAnswered("Current turn has already been answered")
        }
        
        currentTurn.hasAnswered = true
        updateLastActivity()
    }
    
    /// Completes the game session
    /// - Throws: GameStateError for invalid state
    public func completeGame() throws {
        guard gamePhase == .playing else {
            throw GameStateError.invalidPhaseTransition("Cannot complete game from \(gamePhase) phase")
        }
        
        gamePhase = .complete
        updateLastActivity()
    }
    
    /// Resets the game to setup phase
    public func resetGame() {
        gamePhase = .setup
        conversationMode = nil
        currentTurn = TurnState(
            currentPlayerIndex: 0,
            turnStartTime: Date(),
            questionCategory: nil,
            hasAnswered: false
        )
        turnCounter = 0
        roundCounter = 0
        updateLastActivity()
    }
    
    /// Updates player information
    /// - Parameters:
    ///   - playerIndex: Index of player to update (0 or 1)
    ///   - updatedPlayer: New player data
    /// - Throws: GameStateError for invalid player index
    public func updatePlayer(at playerIndex: Int, with updatedPlayer: Player) throws {
        guard playerIndex >= 0 && playerIndex < players.count else {
            throw GameStateError.invalidPlayerIndex("Player index \(playerIndex) out of range")
        }
        
        players[playerIndex] = updatedPlayer
        updateLastActivity()
    }
    
    /// Sets conversation mode
    /// - Parameter mode: Conversation mode to set
    public func setConversationMode(_ mode: ConversationMode) {
        conversationMode = mode
        updateLastActivity()
    }
    
    /// Sets metadata value
    /// - Parameters:
    ///   - key: Metadata key
    ///   - value: Metadata value
    public func setMetadata(key: String, value: String) {
        metadata[key] = value
        updateLastActivity()
    }
    
    /// Gets metadata value
    /// - Parameter key: Metadata key
    /// - Returns: Metadata value or nil
    public func getMetadata(key: String) -> String? {
        return metadata[key]
    }
    
    // MARK: - Private Methods
    
    /// Updates the last activity timestamp
    private func updateLastActivity() {
        lastActivity = Date()
    }
}

// MARK: - Turn State

/// Represents the state of a single turn
public struct TurnState: Codable {
    /// Index of current player (0 or 1)
    public var currentPlayerIndex: Int
    
    /// When this turn started
    public let turnStartTime: Date
    
    /// Question category for this turn (set when card is selected)
    public var questionCategory: QuestionCategory?
    
    /// Whether the current player has answered the question
    public var hasAnswered: Bool
    
    /// Duration of this turn
    public var turnDuration: TimeInterval {
        return Date().timeIntervalSince(turnStartTime)
    }
    
    /// True if this turn has a question assigned
    public var hasQuestion: Bool {
        return questionCategory != nil
    }
}

// MARK: - Game Phase

/// Enumeration of possible game phases
public enum GamePhase: String, CaseIterable, Codable {
    case setup = "setup"
    case playing = "playing"
    case complete = "complete"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .setup:
            return "Setup"
        case .playing:
            return "Playing"
        case .complete:
            return "Complete"
        }
    }
    
    /// Description of what happens in this phase
    public var description: String {
        switch self {
        case .setup:
            return "Players enter their information and select conversation mode"
        case .playing:
            return "Players take turns answering conversation questions"
        case .complete:
            return "Game session has ended"
        }
    }
}

// MARK: - Game State Error

/// Errors that can occur during game state management
public enum GameStateError: LocalizedError, Equatable {
    case invalidPhaseTransition(String)
    case missingConversationMode(String)
    case invalidPlayerData(String)
    case invalidPlayerIndex(String)
    case turnAlreadyAnswered(String)
    case gameNotStarted(String)
    case gameAlreadyComplete(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPhaseTransition(let message):
            return "Invalid Phase Transition: \(message)"
        case .missingConversationMode(let message):
            return "Missing Conversation Mode: \(message)"
        case .invalidPlayerData(let message):
            return "Invalid Player Data: \(message)"
        case .invalidPlayerIndex(let message):
            return "Invalid Player Index: \(message)"
        case .turnAlreadyAnswered(let message):
            return "Turn Already Answered: \(message)"
        case .gameNotStarted(let message):
            return "Game Not Started: \(message)"
        case .gameAlreadyComplete(let message):
            return "Game Already Complete: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidPhaseTransition:
            return "The requested action cannot be performed in the current game phase"
        case .missingConversationMode:
            return "A conversation mode must be selected before proceeding"
        case .invalidPlayerData:
            return "Player information is incomplete or invalid"
        case .invalidPlayerIndex:
            return "The specified player does not exist"
        case .turnAlreadyAnswered:
            return "The current turn has already been completed"
        case .gameNotStarted:
            return "The game must be started before this action can be performed"
        case .gameAlreadyComplete:
            return "This action cannot be performed on a completed game"
        }
    }
}

// MARK: - Extensions

extension GameState {
    /// Creates a preview game state for testing and SwiftUI previews
    public static func preview(
        gamePhase: GamePhase = .setup,
        conversationMode: ConversationMode? = .blindDate,
        currentPlayerIndex: Int = 0,
        turnCounter: Int = 0
    ) -> GameState {
        let player1 = Player.preview(name: "Alex", pronouns: .theyThem, playerNumber: 1)
        let player2 = Player.preview(name: "Jordan", pronouns: .sheHer, playerNumber: 2)
        
        let gameState = GameState(
            player1: player1,
            player2: player2,
            conversationMode: conversationMode
        )
        
        // Set desired state for preview
        gameState.gamePhase = gamePhase
        if gamePhase == .playing {
            gameState.currentTurn.currentPlayerIndex = currentPlayerIndex
            gameState.turnCounter = turnCounter
            gameState.roundCounter = turnCounter / 2
        }
        
        return gameState
    }
}