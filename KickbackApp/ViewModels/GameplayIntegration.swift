//
//  GameplayIntegration.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation
import SwiftUI
import OSLog

/// Integration bridge between the existing MainContentViewModel and new turn-based gameplay system
/// Provides seamless integration while maintaining backward compatibility
@MainActor
public final class GameplayIntegration: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether turn-based mode is enabled
    @Published public var isTurnBasedModeEnabled: Bool = false
    
    /// Current gameplay view model (when turn-based mode is active)
    @Published public private(set) var gameplayViewModel: GameplayViewModel?
    
    /// Player manager for setup
    @Published public private(set) var playerManager: PlayerManager?
    
    /// Integration state
    @Published public private(set) var integrationState: IntegrationState = .singlePlayer
    
    // MARK: - Dependencies
    
    private weak var mainContentViewModel: MainContentViewModel?
    private let logger: Logger
    
    // MARK: - Initialization
    
    /// Initializes gameplay integration
    /// - Parameter mainContentViewModel: Main content view model to integrate with
    public init(mainContentViewModel: MainContentViewModel? = nil) {
        self.mainContentViewModel = mainContentViewModel
        self.logger = Logger(subsystem: "com.kickbackapp.integration", category: "GameplayIntegration")
    }
    
    // MARK: - Mode Management
    
    /// Enables turn-based gameplay mode
    public func enableTurnBasedMode() {
        logger.info("Enabling turn-based gameplay mode")
        
        guard !isTurnBasedModeEnabled else {
            logger.warning("Turn-based mode already enabled")
            return
        }
        
        // Create player manager and gameplay view model
        playerManager = PlayerManager()
        gameplayViewModel = GameplayViewModel(mainContentViewModel: mainContentViewModel)
        
        // Update state
        isTurnBasedModeEnabled = true
        integrationState = .playerSetup
        
        logger.info("Turn-based mode enabled successfully")
    }
    
    /// Enables turn-based gameplay mode with existing player data
    /// - Parameter existingPlayerManager: PlayerManager with setup data
    public func enableTurnBasedMode(with existingPlayerManager: PlayerManager) {
        logger.info("Enabling turn-based gameplay mode with existing player data")
        
        guard !isTurnBasedModeEnabled else {
            logger.warning("Turn-based mode already enabled")
            return
        }
        
        // Use existing player manager with setup data
        self.playerManager = existingPlayerManager
        gameplayViewModel = GameplayViewModel(mainContentViewModel: mainContentViewModel)
        
        // Initialize gameplay with player data
        if let gameplayViewModel = gameplayViewModel {
            do {
                let playerSetupData = try existingPlayerManager.createValidatedPlayers()
                gameplayViewModel.completePlayerSetup(with: playerSetupData)
                
                // Auto-start the game with default mode for immediate play
                Task {
                    await gameplayViewModel.selectModeAndStartGame(.blindDate)
                }
            } catch {
                logger.error("Failed to initialize game with player data: \(error.localizedDescription)")
            }
        }
        
        // Update state
        isTurnBasedModeEnabled = true
        integrationState = .activeGame
        
        logger.info("Turn-based mode enabled with player data successfully")
    }
    
    /// Disables turn-based gameplay mode and returns to single-player
    public func disableTurnBasedMode() {
        logger.info("Disabling turn-based gameplay mode")
        
        guard isTurnBasedModeEnabled else {
            logger.warning("Turn-based mode already disabled")
            return
        }
        
        // Reset gameplay components
        gameplayViewModel = nil
        playerManager = nil
        
        // Update state
        isTurnBasedModeEnabled = false
        integrationState = .singlePlayer
        
        // Reset main content view model to single-player state
        Task {
            await mainContentViewModel?.returnToModeSelection()
        }
        
        logger.info("Turn-based mode disabled successfully")
    }
    
    /// Toggles between single-player and turn-based modes
    public func toggleGameplayMode() {
        if isTurnBasedModeEnabled {
            disableTurnBasedMode()
        } else {
            enableTurnBasedMode()
        }
    }
    
    // MARK: - Integration State Management
    
    /// Updates integration state
    /// - Parameter newState: New integration state
    public func updateIntegrationState(_ newState: IntegrationState) {
        logger.info("Integration state changing from \(self.integrationState.rawValue) to \(newState.rawValue)")
        integrationState = newState
    }
    
    /// Handles player setup completion
    /// - Parameter setupData: Completed player setup data
    public func handlePlayerSetupComplete(with setupData: PlayerSetupData) {
        logger.info("Player setup completed")
        
        gameplayViewModel?.completePlayerSetup(with: setupData)
        integrationState = .modeSelection
    }
    
    /// Handles mode selection and game start
    /// - Parameter mode: Selected conversation mode
    public func handleModeSelectionAndStart(_ mode: ConversationMode) async {
        logger.info("Mode selected: \(mode.rawValue)")
        
        integrationState = .gameInitializing
        
        await gameplayViewModel?.selectModeAndStartGame(mode)
        
        if gameplayViewModel?.isGameActive() == true {
            integrationState = .activeGame
        } else {
            integrationState = .error
        }
    }
    
    /// Handles card selection in turn-based mode
    /// - Parameters:
    ///   - cardIndex: Selected card index
    ///   - category: Question category
    public func handleTurnBasedCardSelection(cardIndex: Int, category: QuestionCategory) async {
        guard isTurnBasedModeEnabled,
              let gameplayViewModel = gameplayViewModel else {
            logger.warning("Turn-based card selection called but mode not enabled")
            return
        }
        
        await gameplayViewModel.handleCardSelection(cardIndex: cardIndex, category: category)
    }
    
    /// Handles turn completion and advancement
    public func handleTurnCompletion() async {
        guard isTurnBasedModeEnabled,
              let gameplayViewModel = gameplayViewModel else {
            logger.warning("Turn completion called but mode not enabled")
            return
        }
        
        await gameplayViewModel.completeTurnAndAdvance()
    }
    
    /// Handles game end
    public func handleGameEnd() async {
        guard isTurnBasedModeEnabled,
              let gameplayViewModel = gameplayViewModel else {
            logger.warning("Game end called but mode not enabled")
            return
        }
        
        await gameplayViewModel.endGame()
        integrationState = .gameComplete
    }
    
    /// Resets to player setup
    public func resetToPlayerSetup() async {
        guard isTurnBasedModeEnabled else { return }
        
        await gameplayViewModel?.resetToPlayerSetup()
        integrationState = .playerSetup
        
        // Reset player manager
        playerManager?.resetPlayerData()
    }
    
    // MARK: - Convenience Methods
    
    /// Gets current player in turn-based mode
    /// - Returns: Current player or nil
    public func getCurrentPlayer() -> Player? {
        print("GameplayIntegration.getCurrentPlayer: isTurnBasedModeEnabled=\(isTurnBasedModeEnabled)")
        guard isTurnBasedModeEnabled else { 
            print("GameplayIntegration.getCurrentPlayer: Turn-based mode not enabled, returning nil")
            return nil 
        }
        
        let player = gameplayViewModel?.getCurrentPlayer()
        print("GameplayIntegration.getCurrentPlayer: gameplayViewModel player=\(player?.displayName ?? "nil")")
        return player
    }
    
    /// Gets turn statistics
    /// - Returns: Turn statistics or nil
    public func getTurnStatistics() -> TurnStatistics? {
        guard isTurnBasedModeEnabled else { return nil }
        return gameplayViewModel?.getTurnStatistics()
    }
    
    /// Checks if it's currently a specific player's turn
    /// - Parameter player: Player to check
    /// - Returns: True if it's the player's turn
    public func isPlayerTurn(_ player: Player) -> Bool {
        guard isTurnBasedModeEnabled,
              let gameplayViewModel = gameplayViewModel else { return false }
        
        return gameplayViewModel.getCurrentPlayer()?.id == player.id
    }
    
    /// Gets display text for current game state
    /// - Returns: Current state description
    public func getCurrentStateDescription() -> String {
        switch integrationState {
        case .singlePlayer:
            return "Single Player Mode"
        case .playerSetup:
            return "Player Setup"
        case .modeSelection:
            return "Select Conversation Mode"
        case .gameInitializing:
            return "Starting Game..."
        case .activeGame:
            if let currentPlayer = getCurrentPlayer() {
                return "\(currentPlayer.displayName)'s Turn"
            } else {
                return "Active Game"
            }
        case .gameComplete:
            return "Game Complete"
        case .error:
            return "Error"
        }
    }
}

// MARK: - Integration State

/// Enumeration of possible integration states
public enum IntegrationState: String, CaseIterable {
    case singlePlayer = "single_player"
    case playerSetup = "player_setup"
    case modeSelection = "mode_selection"
    case gameInitializing = "game_initializing"
    case activeGame = "active_game"
    case gameComplete = "game_complete"
    case error = "error"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .singlePlayer:
            return "Single Player"
        case .playerSetup:
            return "Player Setup"
        case .modeSelection:
            return "Mode Selection"
        case .gameInitializing:
            return "Starting Game"
        case .activeGame:
            return "Playing"
        case .gameComplete:
            return "Game Complete"
        case .error:
            return "Error"
        }
    }
    
    /// Whether the state represents active gameplay
    public var isActiveGameplay: Bool {
        return self == .activeGame
    }
    
    /// Whether the state represents setup phases
    public var isSetupPhase: Bool {
        return [.playerSetup, .modeSelection, .gameInitializing].contains(self)
    }
}

// MARK: - Extensions

extension GameplayIntegration {
    /// Creates a preview integration for testing and SwiftUI previews
    public static func preview(
        integrationState: IntegrationState = .singlePlayer,
        isTurnBasedEnabled: Bool = false
    ) -> GameplayIntegration {
        let integration = GameplayIntegration()
        integration.integrationState = integrationState
        integration.isTurnBasedModeEnabled = isTurnBasedEnabled
        
        if isTurnBasedEnabled {
            integration.playerManager = PlayerManager.preview(withValidPlayers: true)
            integration.gameplayViewModel = GameplayViewModel.preview(
                gameplayPhase: .activeGame,
                withPlayers: true,
                withActiveGame: true
            )
        }
        
        return integration
    }
}