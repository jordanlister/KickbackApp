//
//  CardAnswerModel.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation

// MARK: - Card Answer Model

/// Represents a player's answer to a conversation question
/// Stores both audio transcription and metadata about the response
public struct PlayerAnswer: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for this answer
    public let id: UUID
    
    /// Player who provided this answer
    public let playerID: UUID
    
    /// Player number for easy reference
    public let playerNumber: Int
    
    /// The transcribed text of the answer
    public var answerText: String
    
    /// Timestamp when the answer was recorded
    public let recordedAt: Date
    
    /// Duration of the audio recording in seconds
    public var recordingDuration: TimeInterval
    
    /// Audio quality score (0.0 to 1.0)
    public var audioQuality: Float
    
    /// Optional metadata for future features
    public var metadata: [String: String]
    
    // MARK: - Initialization
    
    /// Creates a new player answer
    /// - Parameters:
    ///   - playerID: Unique identifier of the player
    ///   - playerNumber: Player number (1 or 2)
    ///   - answerText: Transcribed answer text
    ///   - recordingDuration: Duration of the recording
    ///   - audioQuality: Quality score of the audio
    ///   - metadata: Optional additional metadata
    public init(
        playerID: UUID,
        playerNumber: Int,
        answerText: String,
        recordingDuration: TimeInterval = 0.0,
        audioQuality: Float = 1.0,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.playerID = playerID
        self.playerNumber = playerNumber
        self.answerText = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.recordedAt = Date()
        self.recordingDuration = recordingDuration
        self.audioQuality = audioQuality
        self.metadata = metadata
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if the answer contains meaningful content
    public var hasContent: Bool {
        return !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns a summary of the answer for display
    public var displaySummary: String {
        let trimmed = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 100 {
            return trimmed
        }
        return String(trimmed.prefix(100)) + "..."
    }
    
    /// Returns formatted recording duration
    public var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Card Answer Collection

/// Represents all answers for a specific conversation card
/// Tracks both players' responses and completion state
public struct CardAnswers: Identifiable, Codable {
    
    // MARK: - Properties
    
    /// Unique identifier for this card's answer set
    public let id: UUID
    
    /// Question that was answered
    public let question: String
    
    /// Question category
    public let category: QuestionCategory
    
    /// Player 1's answer (if provided)
    public var player1Answer: PlayerAnswer?
    
    /// Player 2's answer (if provided)
    public var player2Answer: PlayerAnswer?
    
    /// Timestamp when the question was first presented
    public let questionPresentedAt: Date
    
    /// Timestamp when both players completed their answers
    public var completedAt: Date?
    
    /// Optional game session ID for tracking
    public var gameSessionID: UUID?
    
    // MARK: - Initialization
    
    /// Creates a new card answer collection
    /// - Parameters:
    ///   - question: The conversation question
    ///   - category: Question category
    ///   - gameSessionID: Optional game session identifier
    public init(
        question: String,
        category: QuestionCategory,
        gameSessionID: UUID? = nil
    ) {
        self.id = UUID()
        self.question = question
        self.category = category
        self.questionPresentedAt = Date()
        self.gameSessionID = gameSessionID
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if both players have provided answers
    public var isComplete: Bool {
        return player1Answer != nil && player2Answer != nil
    }
    
    /// Returns true if at least one player has answered
    public var hasAnyAnswers: Bool {
        return player1Answer != nil || player2Answer != nil
    }
    
    /// Returns the number of players who have answered
    public var answerCount: Int {
        var count = 0
        if player1Answer != nil { count += 1 }
        if player2Answer != nil { count += 1 }
        return count
    }
    
    /// Returns array of all answers for iteration
    public var allAnswers: [PlayerAnswer] {
        var answers: [PlayerAnswer] = []
        if let answer1 = player1Answer {
            answers.append(answer1)
        }
        if let answer2 = player2Answer {
            answers.append(answer2)
        }
        return answers
    }
    
    // MARK: - Methods
    
    /// Adds or updates an answer for a specific player
    /// - Parameter answer: The player's answer
    public mutating func setAnswer(_ answer: PlayerAnswer) {
        switch answer.playerNumber {
        case 1:
            player1Answer = answer
        case 2:
            player2Answer = answer
        default:
            print("Warning: Invalid player number \(answer.playerNumber) for answer")
        }
        
        // Mark as completed if both players have answered
        if isComplete && completedAt == nil {
            completedAt = Date()
        }
    }
    
    /// Gets answer for a specific player number
    /// - Parameter playerNumber: Player number (1 or 2)
    /// - Returns: Player's answer or nil
    public func getAnswer(for playerNumber: Int) -> PlayerAnswer? {
        switch playerNumber {
        case 1:
            return player1Answer
        case 2:
            return player2Answer
        default:
            return nil
        }
    }
    
    /// Removes answer for a specific player
    /// - Parameter playerNumber: Player number (1 or 2)
    public mutating func removeAnswer(for playerNumber: Int) {
        switch playerNumber {
        case 1:
            player1Answer = nil
        case 2:
            player2Answer = nil
        default:
            print("Warning: Invalid player number \(playerNumber) for answer removal")
        }
        
        // Clear completion timestamp if no longer complete
        if !isComplete {
            completedAt = nil
        }
    }
    
    /// Clears all answers
    public mutating func clearAllAnswers() {
        player1Answer = nil
        player2Answer = nil
        completedAt = nil
    }
}

// MARK: - Extensions

extension PlayerAnswer {
    /// Creates a preview player answer for testing and SwiftUI previews
    public static func preview(
        playerNumber: Int = 1,
        answerText: String = "This is a sample answer to demonstrate the conversation flow.",
        recordingDuration: TimeInterval = 15.5
    ) -> PlayerAnswer {
        return PlayerAnswer(
            playerID: UUID(),
            playerNumber: playerNumber,
            answerText: answerText,
            recordingDuration: recordingDuration,
            audioQuality: 0.95,
            metadata: ["preview": "true"]
        )
    }
}

extension CardAnswers {
    /// Creates a preview card answers collection for testing and SwiftUI previews
    public static func preview(
        question: String = "What's something you've learned about yourself recently?",
        category: QuestionCategory = .personalGrowth,
        hasPlayer1Answer: Bool = true,
        hasPlayer2Answer: Bool = false
    ) -> CardAnswers {
        var cardAnswers = CardAnswers(question: question, category: category)
        
        if hasPlayer1Answer {
            let answer1 = PlayerAnswer.preview(
                playerNumber: 1,
                answerText: "I've learned that I'm more resilient than I thought. Going through challenges has shown me I can adapt and find solutions even when things seem impossible."
            )
            cardAnswers.setAnswer(answer1)
        }
        
        if hasPlayer2Answer {
            let answer2 = PlayerAnswer.preview(
                playerNumber: 2,
                answerText: "I've discovered that I really value deep connections with people. Surface-level conversations don't satisfy me anymore - I crave meaningful discussions."
            )
            cardAnswers.setAnswer(answer2)
        }
        
        return cardAnswers
    }
}