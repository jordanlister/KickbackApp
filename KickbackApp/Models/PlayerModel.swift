//
//  PlayerModel.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation

// MARK: - Player Data Model

/// Represents a player in the turn-based gameplay system
/// Contains all necessary player information for game management
public struct Player: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the player
    public let id: UUID
    
    /// Player's display name
    public var name: String
    
    /// Player's pronouns for proper UI display
    public var pronouns: PlayerPronouns
    
    /// Player number (1 or 2) for turn order management
    public let playerNumber: Int
    
    /// Timestamp when player was created
    public let createdAt: Date
    
    /// Optional metadata for future extensibility
    public var metadata: [String: String]
    
    // MARK: - Initialization
    
    /// Creates a new player with the specified information
    /// - Parameters:
    ///   - name: Player's display name
    ///   - pronouns: Player's pronouns
    ///   - playerNumber: Player number (1 or 2)
    ///   - metadata: Optional additional metadata
    public init(
        name: String,
        pronouns: PlayerPronouns,
        playerNumber: Int,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pronouns = pronouns
        self.playerNumber = playerNumber
        self.createdAt = Date()
        self.metadata = metadata
    }
    
    // MARK: - Computed Properties
    
    /// Returns a sanitized version of the player name for display
    public var displayName: String {
        return name.isEmpty ? "Player \(playerNumber)" : name
    }
    
    /// Returns formatted pronouns for UI display
    public var displayPronouns: String {
        return pronouns.displayString
    }
    
    /// Returns true if the player information is valid
    public var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               playerNumber >= 1 && playerNumber <= 2
    }
    
    // MARK: - Methods
    
    /// Updates the player's name
    /// - Parameter newName: The new name to set
    public mutating func updateName(_ newName: String) {
        self.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Updates the player's pronouns
    /// - Parameter newPronouns: The new pronouns to set
    public mutating func updatePronouns(_ newPronouns: PlayerPronouns) {
        self.pronouns = newPronouns
    }
    
    /// Adds or updates metadata
    /// - Parameters:
    ///   - key: Metadata key
    ///   - value: Metadata value
    public mutating func setMetadata(key: String, value: String) {
        metadata[key] = value
    }
    
    /// Gets metadata value for a key
    /// - Parameter key: Metadata key
    /// - Returns: Metadata value or nil
    public func getMetadata(key: String) -> String? {
        return metadata[key]
    }
}

// MARK: - Player Pronouns

/// Enumeration for player pronouns with comprehensive options
public enum PlayerPronouns: String, CaseIterable, Codable {
    case heHim = "he_him"
    case sheHer = "she_her"
    case theyThem = "they_them"
    case other = "other"
    
    /// Human-readable display string for pronouns
    public var displayString: String {
        switch self {
        case .heHim:
            return "He/Him"
        case .sheHer:
            return "She/Her"
        case .theyThem:
            return "They/Them"
        case .other:
            return "Other"
        }
    }
    
    /// Abbreviated display for compact UI spaces
    public var shortDisplayString: String {
        switch self {
        case .heHim:
            return "He/Him"
        case .sheHer:
            return "She/Her"
        case .theyThem:
            return "They/Them"
        case .other:
            return "Other"
        }
    }
    
    /// Subject pronoun for sentence construction
    public var subjectPronoun: String {
        switch self {
        case .heHim:
            return "he"
        case .sheHer:
            return "she"
        case .theyThem:
            return "they"
        case .other:
            return "they" // Default to they for inclusive language
        }
    }
    
    /// Object pronoun for sentence construction
    public var objectPronoun: String {
        switch self {
        case .heHim:
            return "him"
        case .sheHer:
            return "her"
        case .theyThem:
            return "them"
        case .other:
            return "them" // Default to them for inclusive language
        }
    }
    
    /// Possessive pronoun for sentence construction
    public var possessivePronoun: String {
        switch self {
        case .heHim:
            return "his"
        case .sheHer:
            return "her"
        case .theyThem:
            return "their"
        case .other:
            return "their" // Default to their for inclusive language
        }
    }
}

// MARK: - Player Validation

/// Utility for validating player data
public struct PlayerValidator {
    
    /// Validates a player name
    /// - Parameter name: Name to validate
    /// - Returns: Validation result with error message if invalid
    public static func validateName(_ name: String) -> PlayerModelValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid("Name cannot be empty")
        }
        
        if trimmedName.count < 2 {
            return .invalid("Name must be at least 2 characters")
        }
        
        if trimmedName.count > 50 {
            return .invalid("Name cannot exceed 50 characters")
        }
        
        // Check for inappropriate characters
        let allowedCharacterSet = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "'-"))
        
        if !trimmedName.unicodeScalars.allSatisfy(allowedCharacterSet.contains) {
            return .invalid("Name contains invalid characters")
        }
        
        return .valid
    }
    
    /// Validates player number
    /// - Parameter playerNumber: Player number to validate
    /// - Returns: Validation result with error message if invalid
    public static func validatePlayerNumber(_ playerNumber: Int) -> PlayerModelValidationResult {
        if playerNumber < 1 || playerNumber > 2 {
            return .invalid("Player number must be 1 or 2")
        }
        return .valid
    }
    
    /// Validates complete player data
    /// - Parameter player: Player to validate
    /// - Returns: Validation result with error message if invalid
    public static func validatePlayer(_ player: Player) -> PlayerModelValidationResult {
        let nameValidation = validateName(player.name)
        if case .invalid(let message) = nameValidation {
            return .invalid(message)
        }
        
        let numberValidation = validatePlayerNumber(player.playerNumber)
        if case .invalid(let message) = numberValidation {
            return .invalid(message)
        }
        
        return .valid
    }
}

// MARK: - Validation Result

/// Result type for validation operations
public enum PlayerModelValidationResult {
    case valid
    case invalid(String)
    
    /// Returns true if validation passed
    public var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    /// Returns error message if validation failed
    public var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Extensions

extension Player {
    /// Creates a preview player for testing and SwiftUI previews
    public static func preview(
        name: String = "Alex",
        pronouns: PlayerPronouns = .theyThem,
        playerNumber: Int = 1
    ) -> Player {
        return Player(
            name: name,
            pronouns: pronouns,
            playerNumber: playerNumber,
            metadata: ["preview": "true"]
        )
    }
}

// MARK: - Legacy Support

/// Bridge for existing PlayerSetupView compatibility
public struct PlayerSetupData {
    public let player1: Player
    public let player2: Player
    
    public init(player1: Player, player2: Player) {
        self.player1 = player1
        self.player2 = player2
    }
    
    /// Creates PlayerSetupData from legacy string-based data
    public static func fromLegacyData(
        player1Name: String,
        player1Gender: String,
        player2Name: String,
        player2Gender: String
    ) -> PlayerSetupData {
        let player1Pronouns = PlayerPronouns.fromGenderString(player1Gender)
        let player2Pronouns = PlayerPronouns.fromGenderString(player2Gender)
        
        let player1 = Player(name: player1Name, pronouns: player1Pronouns, playerNumber: 1)
        let player2 = Player(name: player2Name, pronouns: player2Pronouns, playerNumber: 2)
        
        return PlayerSetupData(player1: player1, player2: player2)
    }
}

extension PlayerPronouns {
    /// Converts legacy gender string to pronouns
    fileprivate static func fromGenderString(_ genderString: String) -> PlayerPronouns {
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