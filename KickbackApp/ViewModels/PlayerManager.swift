//
//  PlayerManager.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation
import SwiftUI
import OSLog

/// Validation state for player data
public enum PlayerValidationState: Equatable {
    case pending
    case valid
    case invalid(String)
    
    /// Returns true if validation passed
    public var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .pending, .invalid:
            return false
        }
    }
    
    /// Returns error message if validation failed
    public var errorMessage: String? {
        switch self {
        case .invalid(let message):
            return message
        case .pending, .valid:
            return nil
        }
    }
    
    /// Returns display text for current state
    public var displayText: String {
        switch self {
        case .pending:
            return "Enter player information"
        case .valid:
            return "✓ Ready to play"
        case .invalid(let message):
            return "⚠ \(message)"
        }
    }
    
    /// Returns appropriate color for UI display
    public var statusColor: Color {
        switch self {
        case .pending:
            return .secondary
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }
    
    /// Returns appropriate icon for UI display
    public var statusIcon: String {
        switch self {
        case .pending:
            return "circle"
        case .valid:
            return "checkmark.circle.fill"
        case .invalid:
            return "exclamationmark.circle.fill"
        }
    }
}

/// Manages player creation, validation, and persistence
/// Provides centralized player data management with validation and storage capabilities
@MainActor
public final class PlayerManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current player setup state
    @Published public var player1Name: String = ""
    @Published public var player1Pronouns: PlayerPronouns = .theyThem
    @Published public var player2Name: String = ""
    @Published public var player2Pronouns: PlayerPronouns = .theyThem
    
    /// Validation states
    @Published public private(set) var player1PlayerValidationState: PlayerValidationState = .pending
    @Published public private(set) var player2PlayerValidationState: PlayerValidationState = .pending
    
    /// Overall setup state
    @Published public private(set) var isSetupComplete: Bool = false
    @Published public private(set) var isValidating: Bool = false
    
    /// Error state
    @Published public private(set) var validationError: PlayerManagerError?
    
    // MARK: - Configuration
    
    private let logger: Logger
    
    /// Auto-validation delay to avoid validating on every keystroke
    private let validationDelay: TimeInterval = 0.5
    
    /// Validation timers
    private var player1ValidationTimer: Timer?
    private var player2ValidationTimer: Timer?
    
    // MARK: - Persistence (optional)
    
    /// UserDefaults key for last used player names
    private let lastPlayer1NameKey = "lastPlayer1Name"
    private let lastPlayer2NameKey = "lastPlayer2Name"
    private let lastPlayer1PronounsKey = "lastPlayer1Pronouns"
    private let lastPlayer2PronounsKey = "lastPlayer2Pronouns"
    
    // MARK: - Initialization
    
    /// Initializes player manager and loads any previous data
    public init() {
        self.logger = Logger(subsystem: "com.kickbackapp.gameplay", category: "PlayerManager")
        loadPreviousPlayerData()
        setupValidationObservers()
    }
    
    // MARK: - Public Methods
    
    /// Updates player 1 name with validation
    /// - Parameter name: New name for player 1
    public func updatePlayer1Name(_ name: String) {
        player1Name = name
        scheduleValidation(for: .player1)
        updateSetupState()
        savePlayerData()
    }
    
    /// Updates player 1 pronouns
    /// - Parameter pronouns: New pronouns for player 1
    public func updatePlayer1Pronouns(_ pronouns: PlayerPronouns) {
        player1Pronouns = pronouns
        validatePlayer1()
        updateSetupState()
        savePlayerData()
    }
    
    /// Updates player 2 name with validation
    /// - Parameter name: New name for player 2
    public func updatePlayer2Name(_ name: String) {
        player2Name = name
        scheduleValidation(for: .player2)
        updateSetupState()
        savePlayerData()
    }
    
    /// Updates player 2 pronouns
    /// - Parameter pronouns: New pronouns for player 2
    public func updatePlayer2Pronouns(_ pronouns: PlayerPronouns) {
        player2Pronouns = pronouns
        validatePlayer2()
        updateSetupState()
        savePlayerData()
    }
    
    /// Creates validated player objects
    /// - Returns: PlayerSetupData with validated players
    /// - Throws: PlayerManagerError for validation failures
    public func createValidatedPlayers() throws -> PlayerSetupData {
        logger.info("Creating validated players")
        
        // Validate both players
        validateAllPlayers()
        
        guard player1PlayerValidationState == .valid else {
            throw PlayerManagerError.player1Invalid(player1PlayerValidationState.errorMessage ?? "Player 1 data is invalid")
        }
        
        guard player2PlayerValidationState == .valid else {
            throw PlayerManagerError.player2Invalid(player2PlayerValidationState.errorMessage ?? "Player 2 data is invalid")
        }
        
        // Check for duplicate names
        let trimmedName1 = player1Name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName2 = player2Name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName1.lowercased() == trimmedName2.lowercased() {
            throw PlayerManagerError.duplicateNames("Players cannot have the same name")
        }
        
        // Create player objects
        let player1 = Player(
            name: trimmedName1,
            pronouns: player1Pronouns,
            playerNumber: 1,
            metadata: ["createdBy": "PlayerManager"]
        )
        
        let player2 = Player(
            name: trimmedName2,
            pronouns: player2Pronouns,
            playerNumber: 2,
            metadata: ["createdBy": "PlayerManager"]
        )
        
        clearError()
        logger.info("Players created successfully: \(player1.displayName), \(player2.displayName)")
        
        return PlayerSetupData(player1: player1, player2: player2)
    }
    
    /// Resets all player data
    public func resetPlayerData() {
        logger.info("Resetting all player data")
        
        player1Name = ""
        player1Pronouns = .theyThem
        player2Name = ""
        player2Pronouns = .theyThem
        
        player1PlayerValidationState = .pending
        player2PlayerValidationState = .pending
        isSetupComplete = false
        
        clearError()
        clearSavedData()
    }
    
    /// Loads sample data for testing
    public func loadSampleData() {
        logger.info("Loading sample player data")
        
        player1Name = "Alex"
        player1Pronouns = .theyThem
        player2Name = "Jordan"
        player2Pronouns = .sheHer
        
        validateAllPlayers()
        updateSetupState()
    }
    
    /// Gets available pronoun options
    /// - Returns: Array of all pronoun options
    public func getAvailablePronouns() -> [PlayerPronouns] {
        return PlayerPronouns.allCases
    }
    
    /// Validates a specific player's data
    /// - Parameter playerNumber: Player number (1 or 2)
    /// - Returns: Validation state
    public func validatePlayer(_ playerNumber: Int) -> PlayerValidationState {
        switch playerNumber {
        case 1:
            validatePlayer1()
            return player1PlayerValidationState
        case 2:
            validatePlayer2()
            return player2PlayerValidationState
        default:
            return .invalid("Invalid player number")
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up observers for automatic validation
    private func setupValidationObservers() {
        // Initial validation
        validateAllPlayers()
        updateSetupState()
    }
    
    /// Schedules delayed validation to avoid validating on every keystroke
    /// - Parameter player: Which player to validate
    private func scheduleValidation(for player: PlayerIdentifier) {
        switch player {
        case .player1:
            player1ValidationTimer?.invalidate()
            player1ValidationTimer = Timer.scheduledTimer(withTimeInterval: validationDelay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.validatePlayer1()
                }
            }
        case .player2:
            player2ValidationTimer?.invalidate()
            player2ValidationTimer = Timer.scheduledTimer(withTimeInterval: validationDelay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.validatePlayer2()
                }
            }
        }
    }
    
    /// Validates player 1 data
    private func validatePlayer1() {
        let nameValidation = PlayerValidator.validateName(player1Name)
        
        switch nameValidation {
        case .valid:
            player1PlayerValidationState = .valid
        case .invalid(let message):
            player1PlayerValidationState = .invalid(message)
        }
        
        updateSetupState()
    }
    
    /// Validates player 2 data
    private func validatePlayer2() {
        let nameValidation = PlayerValidator.validateName(player2Name)
        
        switch nameValidation {
        case .valid:
            player2PlayerValidationState = .valid
        case .invalid(let message):
            player2PlayerValidationState = .invalid(message)
        }
        
        updateSetupState()
    }
    
    /// Validates all players
    private func validateAllPlayers() {
        validatePlayer1()
        validatePlayer2()
    }
    
    /// Updates overall setup completion state
    private func updateSetupState() {
        let bothPlayersValid = player1PlayerValidationState == .valid && player2PlayerValidationState == .valid
        let noduplicateNames = !player1Name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .isEmpty && player1Name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() !=
            player2Name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        isSetupComplete = bothPlayersValid && noduplicateNames
    }
    
    /// Loads previous player data from UserDefaults
    private func loadPreviousPlayerData() {
        if let savedName1 = UserDefaults.standard.string(forKey: lastPlayer1NameKey) {
            player1Name = savedName1
        }
        
        if let savedName2 = UserDefaults.standard.string(forKey: lastPlayer2NameKey) {
            player2Name = savedName2
        }
        
        if let savedPronouns1 = UserDefaults.standard.string(forKey: lastPlayer1PronounsKey),
           let pronouns1 = PlayerPronouns(rawValue: savedPronouns1) {
            player1Pronouns = pronouns1
        }
        
        if let savedPronouns2 = UserDefaults.standard.string(forKey: lastPlayer2PronounsKey),
           let pronouns2 = PlayerPronouns(rawValue: savedPronouns2) {
            player2Pronouns = pronouns2
        }
        
        logger.debug("Loaded previous player data from UserDefaults")
    }
    
    /// Saves current player data to UserDefaults
    private func savePlayerData() {
        UserDefaults.standard.set(player1Name, forKey: lastPlayer1NameKey)
        UserDefaults.standard.set(player2Name, forKey: lastPlayer2NameKey)
        UserDefaults.standard.set(player1Pronouns.rawValue, forKey: lastPlayer1PronounsKey)
        UserDefaults.standard.set(player2Pronouns.rawValue, forKey: lastPlayer2PronounsKey)
    }
    
    /// Clears saved player data from UserDefaults
    private func clearSavedData() {
        UserDefaults.standard.removeObject(forKey: lastPlayer1NameKey)
        UserDefaults.standard.removeObject(forKey: lastPlayer2NameKey)
        UserDefaults.standard.removeObject(forKey: lastPlayer1PronounsKey)
        UserDefaults.standard.removeObject(forKey: lastPlayer2PronounsKey)
    }
    
    /// Sets an error state
    /// - Parameter error: Error to set
    private func setError(_ error: PlayerManagerError) {
        validationError = error
        logger.error("Player manager error: \(error.localizedDescription)")
    }
    
    /// Clears the current error state
    private func clearError() {
        validationError = nil
    }
    
    /// Clears the current error
    public func clearValidationError() {
        clearError()
    }
    
    // MARK: - Cleanup
    
    deinit {
        player1ValidationTimer?.invalidate()
        player2ValidationTimer?.invalidate()
    }
}

// MARK: - Supporting Types

/// Player identifier for internal use
private enum PlayerIdentifier {
    case player1
    case player2
}

// MARK: - Player Manager Error

/// Errors that can occur during player management
public enum PlayerManagerError: LocalizedError, Equatable {
    case player1Invalid(String)
    case player2Invalid(String)
    case duplicateNames(String)
    case validationFailed(String)
    case persistenceError(String)
    
    public var errorDescription: String? {
        switch self {
        case .player1Invalid(let message):
            return "Player 1 Invalid: \(message)"
        case .player2Invalid(let message):
            return "Player 2 Invalid: \(message)"
        case .duplicateNames(let message):
            return "Duplicate Names: \(message)"
        case .validationFailed(let message):
            return "Validation Failed: \(message)"
        case .persistenceError(let message):
            return "Persistence Error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .player1Invalid:
            return "Player 1 information is incomplete or invalid"
        case .player2Invalid:
            return "Player 2 information is incomplete or invalid"
        case .duplicateNames:
            return "Both players cannot have the same name"
        case .validationFailed:
            return "Player data validation failed"
        case .persistenceError:
            return "Player data could not be saved or loaded"
        }
    }
}

// MARK: - Extensions

extension PlayerManager {
    /// Creates a preview player manager for testing and SwiftUI previews
    public static func preview(
        withValidPlayers: Bool = false,
        withPartialData: Bool = false
    ) -> PlayerManager {
        let manager = PlayerManager()
        
        if withValidPlayers {
            manager.player1Name = "Alex"
            manager.player1Pronouns = .theyThem
            manager.player2Name = "Jordan"
            manager.player2Pronouns = .sheHer
            manager.validateAllPlayers()
            manager.updateSetupState()
        } else if withPartialData {
            manager.player1Name = "Al"
            manager.player1Pronouns = .heHim
            manager.player2Name = ""
            manager.player2Pronouns = .sheHer
            manager.validateAllPlayers()
            manager.updateSetupState()
        }
        
        return manager
    }
}

// MARK: - Legacy Support

extension PlayerManager {
    /// Converts to legacy string-based format for existing views
    /// - Returns: Tuple with legacy string format
    public func toLegacyFormat() -> (player1Name: String, player1Gender: String, player2Name: String, player2Gender: String) {
        return (
            player1Name: player1Name,
            player1Gender: player1Pronouns.displayString,
            player2Name: player2Name,
            player2Gender: player2Pronouns.displayString
        )
    }
    
    /// Updates from legacy string-based format
    /// - Parameters:
    ///   - player1Name: Player 1 name
    ///   - player1Gender: Player 1 gender string
    ///   - player2Name: Player 2 name
    ///   - player2Gender: Player 2 gender string
    public func updateFromLegacyFormat(
        player1Name: String,
        player1Gender: String,
        player2Name: String,
        player2Gender: String
    ) {
        self.player1Name = player1Name
        self.player1Pronouns = PlayerPronouns.fromGenderString(player1Gender)
        self.player2Name = player2Name
        self.player2Pronouns = PlayerPronouns.fromGenderString(player2Gender)
        
        validateAllPlayers()
        updateSetupState()
    }
}

// MARK: - Private Extensions

private extension PlayerPronouns {
    /// Converts legacy gender string to pronouns
    static func fromGenderString(_ genderString: String) -> PlayerPronouns {
        switch genderString.lowercased() {
        case "he/him", "he", "him":
            return .heHim
        case "she/her", "she", "her":
            return .sheHer
        case "they/them", "they", "them":
            return .theyThem
        default:
            return .other
        }
    }
}