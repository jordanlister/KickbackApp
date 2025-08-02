//
//  TwoStageAnalysisExample.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation

// MARK: - Two-Stage Analysis Example

/// Example demonstrating the new two-stage compatibility analysis system
/// Shows how the system processes 5 completed card answers efficiently
public class TwoStageAnalysisExample {
    
    // MARK: - Properties
    
    private let gameCompletionService: GameCompletionService
    
    // MARK: - Initialization
    
    public init() {
        self.gameCompletionService = GameCompletionServiceImpl()
    }
    
    // MARK: - Example Methods
    
    /// Demonstrates the complete two-stage analysis workflow
    public func runCompleteAnalysisExample() async {
        print("🚀 Starting Two-Stage Compatibility Analysis Example")
        print("=" * 60)
        
        do {
            // Step 1: Create sample completed card answers
            let cardAnswers = createSampleCardAnswers()
            print("✅ Created 5 sample card answers")
            printCardAnswersSummary(cardAnswers)
            
            // Step 2: Run the two-stage analysis
            print("\n🔄 Running two-stage compatibility analysis...")
            let startTime = Date()
            
            let gameResult = try await gameCompletionService.processGameCompletion(cardAnswers)
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Analysis completed in \(String(format: "%.2f", duration)) seconds")
            
            // Step 3: Display results
            printAnalysisResults(gameResult)
            
            // Step 4: Verify backwards compatibility
            print("\n🔍 Verifying backwards compatibility...")
            verifyBackwardsCompatibility(gameResult)
            
        } catch {
            print("❌ Analysis failed: \(error.localizedDescription)")
        }
    }
    
    /// Demonstrates individual card analysis (Stage 1)
    public func runStage1Example() async {
        print("🔬 Stage 1 Example: Individual Card Analysis")
        print("=" * 50)
        
        let sampleCard = createSampleCardAnswer(
            question: "What's something you've learned about yourself recently?",
            category: .personalGrowth,
            player1Answer: "I've learned that I'm more resilient than I thought. Going through challenges has shown me I can adapt and find solutions even when things seem impossible.",
            player2Answer: "I've discovered that I really value deep connections with people. Surface-level conversations don't satisfy me anymore - I crave meaningful discussions."
        )
        
        print("Question: \(sampleCard.question)")
        print("Category: \(sampleCard.category.displayName)")
        print("Player 1: \(sampleCard.player1Answer?.displaySummary ?? "No answer")")
        print("Player 2: \(sampleCard.player2Answer?.displaySummary ?? "No answer")")
        
        // In the actual system, Stage 1 would create a CardAnalysisSummary
        let mockSummary = CardAnalysisSummary.preview(
            questionText: sampleCard.question,
            questionCategory: sampleCard.category,
            compatibilityScore: 78
        )
        
        print("\n📊 Stage 1 Output (Card Analysis Summary):")
        print("Compatibility Score: \(mockSummary.cardCompatibilityScore)/100")
        print("Player 1 Score: \(mockSummary.player1Score)")
        print("Player 2 Score: \(mockSummary.player2Score)")
        print("Insights: \(mockSummary.compatibilityInsights)")
        print("Shows Alignment: \(mockSummary.showedAlignment ? "Yes" : "No")")
        print("Character Count: \(mockSummary.estimatedCharacterCount) chars")
    }
    
    /// Demonstrates the synthesis process (Stage 2)
    public func runStage2Example() {
        print("🧩 Stage 2 Example: Synthesis Analysis")
        print("=" * 50)
        
        // Create 5 sample card summaries
        let cardSummaries = createSampleCardSummaries()
        
        print("Input: 5 Card Analysis Summaries")
        for (index, summary) in cardSummaries.enumerated() {
            print("Card \(index + 1): Score \(summary.cardCompatibilityScore), \(summary.showedAlignment ? "Aligned" : "Contrasting")")
        }
        
        // Calculate total character count for context window verification
        let totalChars = cardSummaries.reduce(0) { $0 + $1.estimatedCharacterCount }
        print("\nTotal input size: \(totalChars) characters")
        
        if totalChars < 1500 {
            print("✅ Well within context window limits")
        } else {
            print("⚠️ Approaching context window limits")
        }
        
        // Show what Stage 2 synthesis would produce
        let averageCompatibility = cardSummaries.map { $0.cardCompatibilityScore }.reduce(0, +) / cardSummaries.count
        let alignedCards = cardSummaries.filter { $0.showedAlignment }.count
        
        print("\n📈 Stage 2 Output (Synthesis Results):")
        print("Overall Compatibility: \(averageCompatibility)/100")
        print("Aligned Cards: \(alignedCards)/5")
        print("Pattern: \(alignedCards >= 4 ? "Strong Alignment" : "Mixed Results")")
    }
    
    // MARK: - Helper Methods
    
    /// Creates 5 sample completed card answers for testing
    private func createSampleCardAnswers() -> [CardAnswers] {
        return [
            createSampleCardAnswer(
                question: "What's something you've learned about yourself recently?",
                category: .personalGrowth,
                player1Answer: "I've learned that I'm more resilient than I thought. Going through challenges has shown me I can adapt and find solutions even when things seem impossible.",
                player2Answer: "I've discovered that I really value deep connections with people. Surface-level conversations don't satisfy me anymore - I crave meaningful discussions."
            ),
            createSampleCardAnswer(
                question: "How do you typically handle disagreements in relationships?",
                category: .conflictResolution,
                player1Answer: "I try to listen first and understand the other person's perspective before sharing my own. I believe most conflicts come from misunderstandings.",
                player2Answer: "I used to avoid conflict, but I've learned that addressing issues directly but kindly leads to better outcomes. Communication is key."
            ),
            createSampleCardAnswer(
                question: "What does emotional intimacy mean to you?",
                category: .intimacyBuilding,
                player1Answer: "It's being able to share your true self without fear of judgment. It's feeling safe to be vulnerable and knowing the other person accepts you completely.",
                player2Answer: "Emotional intimacy is when you can sit in comfortable silence or share your deepest fears and feel understood. It's beyond physical - it's soul-deep connection."
            ),
            createSampleCardAnswer(
                question: "Where do you see yourself in five years?",
                category: .futureVisions,
                player1Answer: "I hope to be in a stable, loving relationship, maybe thinking about starting a family. I want to feel settled and content with someone who shares my values.",
                player2Answer: "I see myself growing both personally and professionally, ideally with a partner who challenges me to be better. Travel and new experiences are important to me."
            ),
            createSampleCardAnswer(
                question: "What's one thing that always makes you laugh?",
                category: .funAndPlayful,
                player1Answer: "My friends always make me laugh with their terrible dad jokes. I love silly humor and people who don't take themselves too seriously.",
                player2Answer: "I crack up at observational comedy and witty banter. I love when someone can find humor in everyday situations - it shows intelligence and positivity."
            )
        ]
    }
    
    /// Creates a single sample card answer
    private func createSampleCardAnswer(
        question: String,
        category: QuestionCategory,
        player1Answer: String,
        player2Answer: String
    ) -> CardAnswers {
        var cardAnswer = CardAnswers(question: question, category: category)
        
        let answer1 = PlayerAnswer(
            playerID: UUID(),
            playerNumber: 1,
            answerText: player1Answer,
            recordingDuration: Double.random(in: 15...45),
            audioQuality: Float.random(in: 0.85...1.0)
        )
        
        let answer2 = PlayerAnswer(
            playerID: UUID(),
            playerNumber: 2,
            answerText: player2Answer,
            recordingDuration: Double.random(in: 15...45),
            audioQuality: Float.random(in: 0.85...1.0)
        )
        
        cardAnswer.setAnswer(answer1)
        cardAnswer.setAnswer(answer2)
        
        return cardAnswer
    }
    
    /// Creates sample card summaries for Stage 2 testing
    private func createSampleCardSummaries() -> [CardAnalysisSummary] {
        return [
            CardAnalysisSummary.preview(
                questionText: "What's something you've learned about yourself recently?",
                questionCategory: .personalGrowth,
                compatibilityScore: 78
            ),
            CardAnalysisSummary(
                questionText: "How do you typically handle disagreements?",
                questionCategory: .conflictResolution,
                player1AnswerSummary: "Listens first, seeks understanding",
                player2AnswerSummary: "Direct but kind communication",
                compatibilityInsights: "Both value respectful communication",
                cardCompatibilityScore: 82,
                player1Score: 79,
                player2Score: 85,
                overallTone: "Constructive",
                primaryDimension: "Communication Style",
                showedAlignment: true
            ),
            CardAnalysisSummary(
                questionText: "What does emotional intimacy mean to you?",
                questionCategory: .intimacyBuilding,
                player1AnswerSummary: "Safe vulnerability without judgment",
                player2AnswerSummary: "Soul-deep connection and understanding",
                compatibilityInsights: "Deep understanding of emotional intimacy",
                cardCompatibilityScore: 91,
                player1Score: 88,
                player2Score: 94,
                overallTone: "Intimate",
                primaryDimension: "Vulnerability",
                showedAlignment: true
            ),
            CardAnalysisSummary(
                questionText: "Where do you see yourself in five years?",
                questionCategory: .futureVisions,
                player1AnswerSummary: "Stable relationship, maybe family",
                player2AnswerSummary: "Growth with challenging partner",
                compatibilityInsights: "Both want committed partnership",
                cardCompatibilityScore: 73,
                player1Score: 76,
                player2Score: 70,
                overallTone: "Hopeful",
                primaryDimension: "Future Planning",
                showedAlignment: false
            ),
            CardAnalysisSummary(
                questionText: "What's one thing that always makes you laugh?",
                questionCategory: .funAndPlayful,
                player1AnswerSummary: "Dad jokes and silly humor",
                player2AnswerSummary: "Observational comedy and wit",
                compatibilityInsights: "Different but compatible humor styles",
                cardCompatibilityScore: 69,
                player1Score: 71,
                player2Score: 67,
                overallTone: "Playful",
                primaryDimension: "Communication Style",
                showedAlignment: false
            )
        ]
    }
    
    /// Prints a summary of the card answers
    private func printCardAnswersSummary(_ cardAnswers: [CardAnswers]) {
        print("\nCard Answers Summary:")
        for (index, card) in cardAnswers.enumerated() {
            print("Card \(index + 1): \(card.category.displayName)")
            print("  Q: \(card.question.prefix(50))...")
            print("  Player 1: \(card.player1Answer?.displaySummary.prefix(40) ?? "No answer")...")
            print("  Player 2: \(card.player2Answer?.displaySummary.prefix(40) ?? "No answer")...")
            print("")
        }
    }
    
    /// Prints the analysis results
    private func printAnalysisResults(_ result: GameCompletionResult) {
        print("\n📊 Game Completion Analysis Results")
        print("=" * 50)
        
        // Overall metrics
        print("Overall Metrics:")
        print("  Overall Score: \(result.gameMetrics.overallScore)/100")
        print("  Compatibility Potential: \(result.gameMetrics.compatibilityPotential)/100")
        print("  Communication Quality: \(result.gameMetrics.communicationQuality)/100")
        print("  Engagement Level: \(result.gameMetrics.engagementLevel)/100")
        
        // Player analyses
        print("\nPlayer 1 Analysis:")
        print("  Average Score: \(result.player1Analysis.averageScore)/100")
        print("  Strongest Dimensions: \(result.player1Analysis.strongestDimensions.joined(separator: ", "))")
        print("  Growth Areas: \(result.player1Analysis.growthAreas.joined(separator: ", "))")
        
        print("\nPlayer 2 Analysis:")
        print("  Average Score: \(result.player2Analysis.averageScore)/100")
        print("  Strongest Dimensions: \(result.player2Analysis.strongestDimensions.joined(separator: ", "))")
        print("  Growth Areas: \(result.player2Analysis.growthAreas.joined(separator: ", "))")
        
        // Comparative analysis
        print("\nComparative Analysis:")
        print("  Compatibility Score: \(result.comparativeAnalysis.overallCompatibilityScore)/100")
        print("  Compatibility Tier: \(result.comparativeAnalysis.compatibilityTier.displayName)")
        print("  Question Comparisons: \(result.comparativeAnalysis.questionComparisons.count)")
        
        // Session insights
        print("\nSession Insights:")
        for insight in result.sessionInsights {
            print("  • \(insight.title): \(insight.description)")
        }
        
        // Processing info
        print("\nProcessing Info:")
        print("  Duration: \(String(format: "%.2f", result.completionDuration)) seconds")
        print("  Completed At: \(result.completedAt)")
    }
    
    /// Verifies that the result maintains backwards compatibility
    private func verifyBackwardsCompatibility(_ result: GameCompletionResult) {
        var isCompatible = true
        var issues: [String] = []
        
        // Check that all expected properties exist
        if result.player1Analysis.individualResults.isEmpty {
            issues.append("Player 1 individual results are missing")
            isCompatible = false
        }
        
        if result.player2Analysis.individualResults.isEmpty {
            issues.append("Player 2 individual results are missing")
            isCompatible = false
        }
        
        if result.comparativeAnalysis.questionComparisons.count != 5 {
            issues.append("Expected 5 question comparisons, got \(result.comparativeAnalysis.questionComparisons.count)")
            isCompatible = false
        }
        
        if result.sessionInsights.isEmpty {
            issues.append("Session insights are missing")
            isCompatible = false
        }
        
        // Check score ranges
        if result.gameMetrics.overallScore < 0 || result.gameMetrics.overallScore > 100 {
            issues.append("Overall score out of range: \(result.gameMetrics.overallScore)")
            isCompatible = false
        }
        
        if isCompatible {
            print("✅ Backwards compatibility verified - all expected properties present")
        } else {
            print("❌ Backwards compatibility issues found:")
            for issue in issues {
                print("  • \(issue)")
            }
        }
    }
}

// MARK: - String Extension

private extension String {
    /// Repeats a string n times
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}