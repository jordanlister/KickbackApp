//
//  CardAnalysisSummary.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation

// MARK: - Card Analysis Summary Model

/// Lightweight summary model for individual card analysis (Stage 1)
/// Designed to fit well within context window limits for the final aggregate analysis
public struct CardAnalysisSummary: Identifiable, Codable {
    
    // MARK: - Properties
    
    /// Unique identifier for this analysis summary
    public let id: UUID
    
    /// The question that was analyzed
    public let questionText: String
    
    /// Category of the question
    public let questionCategory: QuestionCategory
    
    /// Brief summary of Player 1's answer (max ~50 characters)
    public let player1AnswerSummary: String
    
    /// Brief summary of Player 2's answer (max ~50 characters)
    public let player2AnswerSummary: String
    
    /// Key compatibility insights from this specific card (max ~100 characters)
    public let compatibilityInsights: String
    
    /// Individual compatibility score for this card (0-100)
    public let cardCompatibilityScore: Int
    
    /// Player 1's individual score for this card (0-100)
    public let player1Score: Int
    
    /// Player 2's individual score for this card (0-100)
    public let player2Score: Int
    
    /// Dominant emotional tone detected in both responses
    public let overallTone: String
    
    /// Key dimension that stood out most in this card
    public let primaryDimension: String
    
    /// Whether this card showed alignment (true) or contrast (false)
    public let showedAlignment: Bool
    
    /// Timestamp when this summary was created
    public let createdAt: Date
    
    // MARK: - Initialization
    
    /// Creates a new card analysis summary
    /// - Parameters:
    ///   - questionText: The question that was analyzed
    ///   - questionCategory: Category of the question
    ///   - player1AnswerSummary: Brief summary of Player 1's answer
    ///   - player2AnswerSummary: Brief summary of Player 2's answer
    ///   - compatibilityInsights: Key compatibility insights from this card
    ///   - cardCompatibilityScore: Compatibility score for this card
    ///   - player1Score: Player 1's individual score
    ///   - player2Score: Player 2's individual score
    ///   - overallTone: Dominant emotional tone
    ///   - primaryDimension: Key dimension that stood out
    ///   - showedAlignment: Whether responses showed alignment
    public init(
        questionText: String,
        questionCategory: QuestionCategory,
        player1AnswerSummary: String,
        player2AnswerSummary: String,
        compatibilityInsights: String,
        cardCompatibilityScore: Int,
        player1Score: Int,
        player2Score: Int,
        overallTone: String,
        primaryDimension: String,
        showedAlignment: Bool
    ) {
        self.id = UUID()
        self.questionText = questionText
        self.questionCategory = questionCategory
        self.player1AnswerSummary = player1AnswerSummary.truncated(to: 50)
        self.player2AnswerSummary = player2AnswerSummary.truncated(to: 50)
        self.compatibilityInsights = compatibilityInsights.truncated(to: 100)
        self.cardCompatibilityScore = max(0, min(100, cardCompatibilityScore))
        self.player1Score = max(0, min(100, player1Score))
        self.player2Score = max(0, min(100, player2Score))
        self.overallTone = overallTone
        self.primaryDimension = primaryDimension
        self.showedAlignment = showedAlignment
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Returns the average individual score for both players
    public var averagePlayerScore: Int {
        return (player1Score + player2Score) / 2
    }
    
    /// Returns a very compact representation for context window optimization
    public var compactRepresentation: String {
        return "Q\(cardCompatibilityScore): \(compatibilityInsights.truncated(to: 40))"
    }
    
    /// Returns estimated character count for context window planning
    public var estimatedCharacterCount: Int {
        return compactRepresentation.count
    }
}

// MARK: - Supporting Models for Card Analysis

/// Response structure for individual card analysis JSON parsing
public struct CardAnalysisResponse: Codable {
    public let player1Summary: String
    public let player2Summary: String
    public let compatibilityInsights: String
    public let compatibilityScore: Int
    public let player1Score: Int
    public let player2Score: Int
    public let overallTone: String
    public let primaryDimension: String
    public let showedAlignment: Bool
    
    public init(
        player1Summary: String,
        player2Summary: String,
        compatibilityInsights: String,
        compatibilityScore: Int,
        player1Score: Int,
        player2Score: Int,
        overallTone: String,
        primaryDimension: String,
        showedAlignment: Bool
    ) {
        self.player1Summary = player1Summary
        self.player2Summary = player2Summary
        self.compatibilityInsights = compatibilityInsights
        self.compatibilityScore = compatibilityScore
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.overallTone = overallTone
        self.primaryDimension = primaryDimension
        self.showedAlignment = showedAlignment
    }
}

// MARK: - Extensions

extension String {
    /// Truncates string to specified length with ellipsis if needed
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length - 3)) + "..."
    }
}

extension CardAnalysisSummary {
    /// Creates a preview card analysis summary for testing and SwiftUI previews
    public static func preview(
        questionText: String = "What's something you've learned about yourself recently?",
        questionCategory: QuestionCategory = .personalGrowth,
        compatibilityScore: Int = 78
    ) -> CardAnalysisSummary {
        return CardAnalysisSummary(
            questionText: questionText,
            questionCategory: questionCategory,
            player1AnswerSummary: "Learned I'm more resilient than I thought",
            player2AnswerSummary: "Value deep connections over surface talks",
            compatibilityInsights: "Both show strong self-awareness and growth mindset",
            cardCompatibilityScore: compatibilityScore,
            player1Score: 82,
            player2Score: 74,
            overallTone: "Reflective",
            primaryDimension: "Emotional Intelligence",
            showedAlignment: true
        )
    }
}