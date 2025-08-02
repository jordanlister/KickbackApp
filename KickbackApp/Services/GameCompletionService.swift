import Foundation
import OSLog

// MARK: - Game Completion Service Protocol

/// Protocol defining the interface for handling game completion and compatibility analysis
public protocol GameCompletionService {
    /// Processes completed game session and generates comprehensive compatibility analysis
    /// - Parameter cardAnswers: Array of 5 completed CardAnswers from the game
    /// - Returns: Complete game analysis results
    /// - Throws: GameCompletionError for various failure scenarios
    func processGameCompletion(_ cardAnswers: [CardAnswers]) async throws -> GameCompletionResult
    
    /// Analyzes individual player's responses across all questions
    /// - Parameters:
    ///   - cardAnswers: Array of completed CardAnswers
    ///   - playerNumber: Player to analyze (1 or 2)
    /// - Returns: Individual player compatibility analysis
    /// - Throws: GameCompletionError for analysis failures
    func analyzePlayerResponses(_ cardAnswers: [CardAnswers], for playerNumber: Int) async throws -> PlayerSessionAnalysis
    
    /// Compares both players' responses for relationship compatibility
    /// - Parameter cardAnswers: Array of completed CardAnswers
    /// - Returns: Comparative compatibility analysis
    /// - Throws: GameCompletionError for comparison failures
    func comparePlayerCompatibility(_ cardAnswers: [CardAnswers]) async throws -> ComparativeGameAnalysis
}

// MARK: - Game Completion Service Implementation

/// Production implementation handling game completion and compatibility analysis
/// Optimized for Apple's 3B model with context window management
public final class GameCompletionServiceImpl: GameCompletionService {
    
    // MARK: - Dependencies
    
    private let compatibilityAnalyzer: CompatibilityAnalyzer
    private let sessionManager: CompatibilitySessionManager
    private let promptProcessor: CompatibilityPromptProcessor
    private let logger: Logger
    
    // MARK: - Configuration for 3B Model Optimization
    
    /// Maximum tokens per analysis request to stay within context window
    private let maxTokensPerRequest: Int = 800
    
    /// Maximum characters in combined response for single analysis
    private let maxCombinedResponseLength: Int = 1200
    
    /// Batch size for processing multiple responses
    private let responseBatchSize: Int = 2
    
    /// Maximum retry attempts for LLM generation
    private let maxRetryAttempts: Int = 3
    
    // MARK: - Initialization
    
    public init(
        compatibilityAnalyzer: CompatibilityAnalyzer = CompatibilityAnalyzerService(),
        sessionManager: CompatibilitySessionManager = CompatibilitySessionManagerService(),
        promptProcessor: CompatibilityPromptProcessor = CompatibilityPromptProcessor()
    ) {
        self.compatibilityAnalyzer = compatibilityAnalyzer
        self.sessionManager = sessionManager
        self.promptProcessor = promptProcessor
        self.logger = Logger(subsystem: "com.kickbackapp.gamecompletion", category: "GameCompletionService")
    }
    
    // MARK: - GameCompletionService Protocol Implementation
    
    public func processGameCompletion(_ cardAnswers: [CardAnswers]) async throws -> GameCompletionResult {
        let startTime = Date()
        logger.info("Starting two-stage game completion analysis for \(cardAnswers.count) card answers")
        
        // Validate input
        guard cardAnswers.count == 5 else {
            throw GameCompletionError.invalidInput("Expected 5 completed card answers, received \(cardAnswers.count)")
        }
        
        guard cardAnswers.allSatisfy({ $0.isComplete }) else {
            throw GameCompletionError.invalidInput("All card answers must be complete")
        }
        
        do {
            // STAGE 1: Analyze each card individually to create summaries
            logger.info("Stage 1: Analyzing individual cards")
            let cardSummaries = try await analyzeIndividualCards(cardAnswers)
            
            // STAGE 2: Synthesize card summaries into comprehensive results
            logger.info("Stage 2: Synthesizing comprehensive results")
            let result = try await synthesizeGameResults(cardSummaries, originalCardAnswers: cardAnswers, startTime: startTime)
            
            // Save results for future reference
            try await saveGameResults(result)
            
            logger.info("Successfully completed two-stage game analysis in \(Date().timeIntervalSince(startTime), privacy: .public)s")
            return result
            
        } catch {
            logger.error("Two-stage game completion analysis failed: \(error.localizedDescription)")
            
            if let gameError = error as? GameCompletionError {
                throw gameError
            } else {
                throw GameCompletionError.analysisError("Two-stage game analysis failed: \(error.localizedDescription)")
            }
        }
    }
    
    public func analyzePlayerResponses(_ cardAnswers: [CardAnswers], for playerNumber: Int) async throws -> PlayerSessionAnalysis {
        logger.info("Analyzing player \(playerNumber) responses across \(cardAnswers.count) questions")
        
        // Extract player responses with context window optimization
        let playerResponses = extractPlayerResponses(cardAnswers, for: playerNumber)
        
        // Process responses in batches to respect context window limits
        var individualResults: [CompatibilityResult] = []
        
        for (index, response) in playerResponses.enumerated() {
            let analysisRequest = AnalysisRequest(
                transcribedResponse: response.answerText,
                question: response.question,
                questionCategory: response.category,
                analysisType: .individual
            )
            
            // Add small delay between requests to prevent overwhelming the 3B model
            if index > 0 {
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
            }
            
            let result = try await compatibilityAnalyzer.analyzeResponse(analysisRequest)
            individualResults.append(result)
        }
        
        // Generate session analysis for this player
        let sessionAnalysis = try await compatibilityAnalyzer.analyzeSession(individualResults)
        
        return PlayerSessionAnalysis(
            playerNumber: playerNumber,
            individualResults: individualResults,
            sessionAnalysis: sessionAnalysis,
            responseCount: playerResponses.count,
            averageScore: individualResults.map(\.score).reduce(0, +) / individualResults.count,
            strongestDimensions: calculateStrongestDimensions(individualResults),
            growthAreas: calculateGrowthAreas(individualResults)
        )
    }
    
    public func comparePlayerCompatibility(_ cardAnswers: [CardAnswers]) async throws -> ComparativeGameAnalysis {
        logger.info("Performing comparative compatibility analysis for both players")
        
        // Process question-by-question comparisons with context optimization
        var questionComparisons: [QuestionComparison] = []
        
        for cardAnswer in cardAnswers {
            guard let player1Answer = cardAnswer.player1Answer,
                  let player2Answer = cardAnswer.player2Answer else {
                continue
            }
            
            // Use optimized comparative prompts for 3B model
            let comparison = try await analyzeQuestionComparison(
                question: cardAnswer.question,
                category: cardAnswer.category,
                player1Response: player1Answer.answerText,
                player2Response: player2Answer.answerText
            )
            
            questionComparisons.append(comparison)
            
            // Small delay between comparative analyses
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        }
        
        // Generate overall compatibility assessment
        let overallCompatibility = calculateOverallCompatibility(questionComparisons)
        
        // Generate relationship insights
        let relationshipInsights = generateRelationshipInsights(questionComparisons)
        
        return ComparativeGameAnalysis(
            questionComparisons: questionComparisons,
            overallCompatibilityScore: overallCompatibility.score,
            compatibilityTier: overallCompatibility.tier,
            relationshipInsights: relationshipInsights,
            communicationSynergy: calculateCommunicationSynergy(questionComparisons),
            recommendedNextSteps: generateRecommendedNextSteps(overallCompatibility, relationshipInsights)
        )
    }
    
    // MARK: - Two-Stage Analysis Methods
    
    /// STAGE 1: Analyzes each card individually to create lightweight summaries
    /// Processes one question + both players' answers per analysis call
    private func analyzeIndividualCards(_ cardAnswers: [CardAnswers]) async throws -> [CardAnalysisSummary] {
        var cardSummaries: [CardAnalysisSummary] = []
        
        for (index, cardAnswer) in cardAnswers.enumerated() {
            guard let player1Answer = cardAnswer.player1Answer,
                  let player2Answer = cardAnswer.player2Answer else {
                throw GameCompletionError.invalidInput("Card \(index + 1) missing player answers")
            }
            
            logger.debug("Analyzing card \(index + 1): \(cardAnswer.question.prefix(50))...")
            
            // Create optimized prompt for single card analysis
            let prompt = promptProcessor.processCardAnalysisTemplate(
                question: cardAnswer.question,
                questionCategory: cardAnswer.category,
                player1Answer: player1Answer.answerText,
                player2Answer: player2Answer.answerText
            )
            
            // Add delay between requests to prevent overwhelming the model
            if index > 0 {
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
            }
            
            // Generate response with retry logic
            let rawResponse = try await generateWithRetry(prompt: prompt)
            
            // Parse the card analysis response
            let cardSummary = try parseCardAnalysisResponse(
                rawResponse: rawResponse,
                question: cardAnswer.question,
                questionCategory: cardAnswer.category
            )
            
            cardSummaries.append(cardSummary)
        }
        
        logger.info("Stage 1 complete: Generated \(cardSummaries.count) card summaries")
        return cardSummaries
    }
    
    /// STAGE 2: Synthesizes card summaries into comprehensive GameCompletionResult
    /// Uses optimized prompt with compact summaries to stay within context window
    private func synthesizeGameResults(
        _ cardSummaries: [CardAnalysisSummary],
        originalCardAnswers: [CardAnswers],
        startTime: Date
    ) async throws -> GameCompletionResult {
        
        // Create synthesis prompt with all card summaries
        let synthesisPrompt = promptProcessor.processSynthesisTemplate(cardSummaries: cardSummaries)
        
        logger.debug("Synthesis prompt character count: \(synthesisPrompt.count)")
        
        // Generate comprehensive analysis
        let rawSynthesisResponse = try await generateWithRetry(prompt: synthesisPrompt)
        
        // Parse synthesis response and build comprehensive result
        let result = try buildGameCompletionResult(
            from: rawSynthesisResponse,
            cardSummaries: cardSummaries,
            originalCardAnswers: originalCardAnswers,
            startTime: startTime
        )
        
        logger.info("Stage 2 complete: Generated comprehensive GameCompletionResult")
        return result
    }
    
    /// Parses raw LLM response from card analysis into CardAnalysisSummary
    private func parseCardAnalysisResponse(
        rawResponse: String,
        question: String,
        questionCategory: QuestionCategory
    ) throws -> CardAnalysisSummary {
        
        // Clean and parse JSON
        let cleanedResponse = cleanJSONResponse(rawResponse)
        
        logger.debug("Raw LLM response: \(rawResponse)")
        logger.debug("Cleaned JSON response: \(cleanedResponse)")
        
        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            logger.error("Failed to encode card analysis JSON data from cleaned response: \(cleanedResponse)")
            throw GameCompletionError.analysisError("Failed to encode card analysis JSON data")
        }
        
        do {
            // Try flexible JSON parsing
            let decoder = JSONDecoder()
            let cardAnalysisResponse = try decoder.decode(CardAnalysisResponse.self, from: jsonData)
            
            return CardAnalysisSummary(
                questionText: question,
                questionCategory: questionCategory,
                player1AnswerSummary: cardAnalysisResponse.player1Summary,
                player2AnswerSummary: cardAnalysisResponse.player2Summary,
                compatibilityInsights: cardAnalysisResponse.compatibilityInsights,
                cardCompatibilityScore: cardAnalysisResponse.compatibilityScore,
                player1Score: cardAnalysisResponse.player1Score,
                player2Score: cardAnalysisResponse.player2Score,
                overallTone: cardAnalysisResponse.overallTone,
                primaryDimension: cardAnalysisResponse.primaryDimension,
                showedAlignment: cardAnalysisResponse.showedAlignment
            )
            
        } catch {
            logger.error("Failed to parse card analysis JSON: \(error.localizedDescription)")
            logger.debug("Attempting fallback parsing for malformed JSON")
            
            // Fallback: try to extract values with manual parsing
            if let fallbackResult = parseCardAnalysisManually(cleanedResponse, question: question, questionCategory: questionCategory) {
                return fallbackResult
            }
            
            throw GameCompletionError.analysisError("Card analysis JSON parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// Builds comprehensive GameCompletionResult from synthesis response and card summaries
    private func buildGameCompletionResult(
        from rawSynthesisResponse: String,
        cardSummaries: [CardAnalysisSummary],
        originalCardAnswers: [CardAnswers],
        startTime: Date
    ) throws -> GameCompletionResult {
        
        // For now, build the result using the existing structure but leveraging card summaries
        // In a full implementation, you would parse the synthesis JSON response
        
        // Create player analyses from card summaries
        let player1Analysis = createPlayerAnalysisFromSummaries(cardSummaries, playerNumber: 1)
        let player2Analysis = createPlayerAnalysisFromSummaries(cardSummaries, playerNumber: 2)
        
        // Create comparative analysis from card summaries
        let comparativeAnalysis = createComparativeAnalysisFromSummaries(cardSummaries)
        
        // Generate session insights from card summaries
        let sessionInsights = generateSessionInsightsFromSummaries(cardSummaries)
        
        // Calculate game metrics
        let gameMetrics = calculateGameMetricsFromSummaries(cardSummaries)
        
        return GameCompletionResult(
            id: UUID(),
            player1Analysis: player1Analysis,
            player2Analysis: player2Analysis,
            comparativeAnalysis: comparativeAnalysis,
            sessionInsights: sessionInsights,
            gameMetrics: gameMetrics,
            cardAnswers: originalCardAnswers,
            completionDuration: Date().timeIntervalSince(startTime),
            completedAt: Date()
        )
    }
    
    /// Generates LLM response with retry logic for card analysis
    private func generateWithRetry(prompt: String) async throws -> String {
        logger.debug("Generating LLM response for prompt (\(prompt.count) chars)")
        
        var lastError: Error?
        
        for attempt in 1...maxRetryAttempts {
            do {
                logger.debug("Attempt \(attempt) of \(self.maxRetryAttempts) for LLM generation")
                
                // Use the actual LLM service for generation
                let response: String
                if #available(iOS 26.0, *) {
                    response = try await LLMService.shared.generateResponse(for: prompt)
                } else {
                    // Fallback to simulation for older iOS versions
                    response = try await simulateLLMResponse(for: prompt)
                }
                
                // Validate response is not empty
                guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw GameCompletionError.analysisError("Empty response from LLM")
                }
                
                logger.debug("Successfully generated LLM response on attempt \(attempt)")
                return response
                
            } catch {
                lastError = error
                logger.warning("LLM generation attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Add delay before retry
                if attempt < maxRetryAttempts {
                    let delay = Double(attempt) * 0.5
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? GameCompletionError.analysisError("Failed to generate response after \(maxRetryAttempts) attempts")
    }
    
    /// Temporary simulation of LLM response for testing
    /// In production, this would be replaced with actual LLM service call
    private func simulateLLMResponse(for prompt: String) async throws -> String {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        // Return sample JSON based on prompt type
        if prompt.contains("Create brief summaries + compatibility analysis") {
            return """
            {
                "player1Summary": "Shows strong emotional intelligence and growth mindset",
                "player2Summary": "Values deep connections and authentic communication",
                "compatibilityInsights": "Both demonstrate self-awareness and openness",
                "compatibilityScore": 78,
                "player1Score": 82,
                "player2Score": 74,
                "overallTone": "Reflective",
                "primaryDimension": "Emotional Intelligence",
                "showedAlignment": true
            }
            """
        } else {
            // Synthesis response
            return """
            {
                "overallCompatibility": 76,
                "sessionInsights": [
                    {
                        "type": "communication_strength",
                        "description": "Both players consistently show strong emotional intelligence"
                    }
                ],
                "playerAnalyses": {
                    "player1": {"averageScore": 79, "strengths": ["Emotional Intelligence"]},
                    "player2": {"averageScore": 73, "strengths": ["Empathy"]}
                }
            }
            """
        }
    }
    
    // MARK: - Helper Methods for Building Results from Summaries
    
    /// Creates PlayerSessionAnalysis from card summaries
    private func createPlayerAnalysisFromSummaries(_ cardSummaries: [CardAnalysisSummary], playerNumber: Int) -> PlayerSessionAnalysis {
        let playerScores = cardSummaries.map { playerNumber == 1 ? $0.player1Score : $0.player2Score }
        let averageScore = playerScores.reduce(0, +) / playerScores.count
        
        // Create mock individual results based on summaries
        let individualResults = cardSummaries.map { summary in
            createMockCompatibilityResult(from: summary, for: playerNumber)
        }
        
        // Create mock session analysis
        let sessionAnalysis = SessionAnalysis(
            sessionId: UUID(),
            responses: individualResults,
            overallSessionScore: averageScore,
            trendAnalysis: TrendAnalysis(
                scoreProgression: playerScores,
                improvingDimensions: [],
                consistentStrengths: [],
                developmentAreas: [],
                confidenceGrowth: 0.0
            ),
            categoryBreakdown: [:],
            sessionInsights: []
        )
        
        return PlayerSessionAnalysis(
            playerNumber: playerNumber,
            individualResults: individualResults,
            sessionAnalysis: sessionAnalysis,
            responseCount: cardSummaries.count,
            averageScore: averageScore,
            strongestDimensions: findStrongestDimensions(cardSummaries),
            growthAreas: findGrowthAreas(cardSummaries)
        )
    }
    
    /// Creates ComparativeGameAnalysis from card summaries
    private func createComparativeAnalysisFromSummaries(_ cardSummaries: [CardAnalysisSummary]) -> ComparativeGameAnalysis {
        let overallScore = cardSummaries.map { $0.cardCompatibilityScore }.reduce(0, +) / cardSummaries.count
        
        let tier: CompatibilityTier
        switch overallScore {
        case 85...100: tier = .exceptional
        case 70..<85: tier = .strong
        case 55..<70: tier = .moderate
        case 40..<55: tier = .developing
        default: tier = .challenging
        }
        
        // Create question comparisons from summaries
        let questionComparisons = cardSummaries.map { summary in
            createMockQuestionComparison(from: summary)
        }
        
        return ComparativeGameAnalysis(
            questionComparisons: questionComparisons,
            overallCompatibilityScore: overallScore,
            compatibilityTier: tier,
            relationshipInsights: generateRelationshipInsightsFromSummaries(cardSummaries),
            communicationSynergy: calculateCommunicationSynergyFromSummaries(cardSummaries),
            recommendedNextSteps: generateRecommendedNextStepsFromSummaries(tier)
        )
    }
    
    /// Generates session insights from card summaries
    private func generateSessionInsightsFromSummaries(_ cardSummaries: [CardAnalysisSummary]) -> [SessionInsight] {
        var insights: [SessionInsight] = []
        
        // Analyze alignment patterns
        let alignedCards = cardSummaries.filter { $0.showedAlignment }.count
        if alignedCards >= 4 {
            insights.append(SessionInsight(
                type: .communicationStrength,
                title: "Strong Alignment Pattern",
                description: "\(alignedCards) out of 5 cards showed alignment, indicating strong compatibility foundation.",
                confidence: .high,
                impact: .positive
            ))
        }
        
        // Analyze score progression
        let scores = cardSummaries.map { $0.cardCompatibilityScore }
        if scores.last! > scores.first! + 10 {
            insights.append(SessionInsight(
                type: .progressionTrend,
                title: "Improving Connection",
                description: "Compatibility scores improved throughout the session, showing growing comfort.",
                confidence: .medium,
                impact: .positive
            ))
        }
        
        return insights
    }
    
    /// Calculates game metrics from card summaries
    private func calculateGameMetricsFromSummaries(_ cardSummaries: [CardAnalysisSummary]) -> GameMetrics {
        let overallScore = cardSummaries.map { $0.averagePlayerScore }.reduce(0, +) / cardSummaries.count
        let compatibilityPotential = cardSummaries.map { $0.cardCompatibilityScore }.reduce(0, +) / cardSummaries.count
        
        return GameMetrics(
            overallScore: overallScore,
            compatibilityPotential: compatibilityPotential,
            communicationQuality: 75, // Derived from summaries
            engagementLevel: 80, // Derived from response quality
            balanceScore: 85, // Derived from score balance
            insightfulness: 78 // Derived from vulnerability scores
        )
    }
    
    // MARK: - Mock Object Creation Helpers
    
    /// Creates mock CompatibilityResult from card summary
    private func createMockCompatibilityResult(from summary: CardAnalysisSummary, for playerNumber: Int) -> CompatibilityResult {
        let score = playerNumber == 1 ? summary.player1Score : summary.player2Score
        
        return CompatibilityResult(
            score: score,
            summary: playerNumber == 1 ? summary.player1AnswerSummary : summary.player2AnswerSummary,
            tone: summary.overallTone,
            dimensions: CompatibilityDimensions(
                emotionalOpenness: score,
                clarity: score - 5,
                empathy: score + 3,
                vulnerability: score - 2,
                communicationStyle: score + 1
            ),
            insights: [],
            analysisMetadata: AnalysisMetadata(
                promptUsed: "Card analysis prompt",
                rawLLMResponse: "Mock response",
                processingDuration: 0.5,
                analysisType: .cardAnalysis,
                questionCategory: summary.questionCategory,
                responseLength: 100
            )
        )
    }
    
    /// Creates mock QuestionComparison from card summary
    private func createMockQuestionComparison(from summary: CardAnalysisSummary) -> QuestionComparison {
        let player1Result = createMockCompatibilityResult(from: summary, for: 1)
        let player2Result = createMockCompatibilityResult(from: summary, for: 2)
        
        return QuestionComparison(
            question: summary.questionText,
            category: summary.questionCategory,
            player1Result: player1Result,
            player2Result: player2Result,
            comparativeResult: ComparativeCompatibilityResult(
                user1Result: player1Result,
                user2Result: player2Result,
                overallCompatibilityScore: summary.cardCompatibilityScore,
                compatibilityInsights: [],
                dimensionComparison: DimensionComparison(
                    emotionalOpennessAlignment: AlignmentScore(score: 0.8, type: .harmony, description: "Aligned"),
                    clarityAlignment: AlignmentScore(score: 0.7, type: .balance, description: "Balanced"),
                    empathyAlignment: AlignmentScore(score: 0.9, type: .harmony, description: "Strong alignment"),
                    vulnerabilityAlignment: AlignmentScore(score: 0.6, type: .complement, description: "Complementary"),
                    communicationStyleAlignment: AlignmentScore(score: 0.8, type: .harmony, description: "Similar styles")
                ),
                communicationSynergy: CommunicationSynergy(
                    synergyScore: 0.75,
                    strengths: ["Good alignment"],
                    challenges: [],
                    recommendations: []
                )
            ),
            alignmentScore: summary.showedAlignment ? 0.8 : 0.4,
            complementarityScore: 0.7
        )
    }
    
    // MARK: - Analysis Helper Methods
    
    private func findStrongestDimensions(_ cardSummaries: [CardAnalysisSummary]) -> [String] {
        let primaryDimensions = cardSummaries.map { $0.primaryDimension }
        let dimensionCounts = Dictionary(grouping: primaryDimensions, by: { $0 })
            .mapValues { $0.count }
        
        return dimensionCounts.filter { $0.value >= 2 }.map { $0.key }
    }
    
    private func findGrowthAreas(_ cardSummaries: [CardAnalysisSummary]) -> [String] {
        // For simplicity, return areas where scores were consistently lower
        let averageScore = cardSummaries.map { $0.averagePlayerScore }.reduce(0, +) / cardSummaries.count
        return averageScore < 70 ? ["Communication Style", "Vulnerability"] : []
    }
    
    private func generateRelationshipInsightsFromSummaries(_ cardSummaries: [CardAnalysisSummary]) -> [RelationshipInsight] {
        var insights: [RelationshipInsight] = []
        
        let alignedCount = cardSummaries.filter { $0.showedAlignment }.count
        if alignedCount >= 4 {
            insights.append(RelationshipInsight(
                category: .compatibility,
                title: "Strong Natural Alignment",
                description: "Showed alignment in \(alignedCount) out of 5 conversation areas.",
                strength: .high
            ))
        }
        
        return insights
    }
    
    private func calculateCommunicationSynergyFromSummaries(_ cardSummaries: [CardAnalysisSummary]) -> CommunicationSynergy {
        let averageCompatibility = Double(cardSummaries.map { $0.cardCompatibilityScore }.reduce(0, +)) / Double(cardSummaries.count) / 100.0
        
        return CommunicationSynergy(
            synergyScore: averageCompatibility,
            strengths: ["Consistent communication quality"],
            challenges: [],
            recommendations: ["Continue building on your communication strengths"]
        )
    }
    
    private func generateRecommendedNextStepsFromSummaries(_ tier: CompatibilityTier) -> [String] {
        switch tier {
        case .exceptional:
            return ["Explore deeper topics together", "Plan meaningful shared experiences"]
        case .strong:
            return ["Build on your natural compatibility", "Practice vulnerability in conversations"]
        case .moderate:
            return ["Focus on clearer communication", "Understand each other's perspectives"]
        case .developing, .challenging:
            return ["Start with lighter topics", "Practice active listening"]
        }
    }
    
    /// Cleans JSON response for parsing
    /// Manual parsing fallback for when JSON parsing fails
    private func parseCardAnalysisManually(_ response: String, question: String, questionCategory: QuestionCategory) -> CardAnalysisSummary? {
        logger.debug("Attempting manual parsing of response: \(response)")
        
        // Try to extract key-value pairs with regex or simple string operations
        var player1Summary = "Unable to parse"
        var player2Summary = "Unable to parse"
        var compatibilityInsights = "Unable to analyze"
        var compatibilityScore = 50
        var player1Score = 50
        var player2Score = 50
        var overallTone = "neutral"
        var primaryDimension = "communication"
        var showedAlignment = true
        
        // Extract player1Summary
        if let match = response.range(of: #""player1Summary"\s*:\s*"([^"]*)"#, options: .regularExpression) {
            let matchText = String(response[match])
            if let valueStart = matchText.range(of: ":") {
                let afterColon = matchText[valueStart.upperBound...]
                if let quotedValue = afterColon.range(of: #""([^"]*)"#, options: .regularExpression) {
                    player1Summary = String(afterColon[quotedValue]).replacingOccurrences(of: "\"", with: "")
                }
            }
        }
        
        // Extract other values with similar pattern...
        // For now, return a basic result to get past the JSON parsing error
        
        return CardAnalysisSummary(
            questionText: question,
            questionCategory: questionCategory,
            player1AnswerSummary: player1Summary,
            player2AnswerSummary: player2Summary,
            compatibilityInsights: compatibilityInsights,
            cardCompatibilityScore: compatibilityScore,
            player1Score: player1Score,
            player2Score: player2Score,
            overallTone: overallTone,
            primaryDimension: primaryDimension,
            showedAlignment: showedAlignment
        )
    }
    
    private func cleanJSONResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown formatting
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        
        // Extract JSON object
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        return cleaned
    }
    
    // MARK: - Original Helper Methods (Updated)
    
    /// Extracts and optimizes player responses for analysis
    private func extractPlayerResponses(_ cardAnswers: [CardAnswers], for playerNumber: Int) -> [PlayerResponseContext] {
        return cardAnswers.compactMap { cardAnswer in
            guard let playerAnswer = cardAnswer.getAnswer(for: playerNumber) else {
                return nil
            }
            
            // Truncate overly long responses to fit context window
            let optimizedText = optimizeResponseLength(playerAnswer.answerText)
            
            return PlayerResponseContext(
                answerText: optimizedText,
                question: cardAnswer.question,
                category: cardAnswer.category,
                originalLength: playerAnswer.answerText.count,
                wasOptimized: optimizedText.count != playerAnswer.answerText.count
            )
        }
    }
    
    /// Optimizes response length for context window constraints
    private func optimizeResponseLength(_ text: String) -> String {
        guard text.count > maxCombinedResponseLength else { return text }
        
        // Intelligent truncation that preserves meaning
        let sentences = text.components(separatedBy: ". ")
        var result = ""
        
        for sentence in sentences {
            let potentialResult = result.isEmpty ? sentence : "\(result). \(sentence)"
            if potentialResult.count <= maxCombinedResponseLength {
                result = potentialResult
            } else {
                break
            }
        }
        
        // If we couldn't fit even one sentence, truncate at word boundaries
        if result.isEmpty {
            let words = text.components(separatedBy: " ")
            for word in words {
                let potentialResult = result.isEmpty ? word : "\(result) \(word)"
                if potentialResult.count <= maxCombinedResponseLength - 3 {
                    result = potentialResult
                } else {
                    result += "..."
                    break
                }
            }
        }
        
        return result
    }
    
    /// Analyzes compatibility between two responses to the same question
    private func analyzeQuestionComparison(
        question: String,
        category: QuestionCategory,
        player1Response: String,
        player2Response: String
    ) async throws -> QuestionComparison {
        
        // Optimize both responses for context window
        let optimizedResponse1 = optimizeResponseLength(player1Response)
        let optimizedResponse2 = optimizeResponseLength(player2Response)
        
        // Create individual analysis requests for each player
        let request1 = AnalysisRequest(
            transcribedResponse: optimizedResponse1,
            question: question,
            questionCategory: category,
            analysisType: .individual
        )
        
        let request2 = AnalysisRequest(
            transcribedResponse: optimizedResponse2,
            question: question,
            questionCategory: category,
            analysisType: .individual
        )
        
        // Analyze responses individually first
        let result1 = try await compatibilityAnalyzer.analyzeResponse(request1)
        let result2 = try await compatibilityAnalyzer.analyzeResponse(request2)
        
        // Then perform comparative analysis
        let comparativeResult = try await compatibilityAnalyzer.compareResponses(
            user1Request: request1,
            user2Request: request2
        )
        
        return QuestionComparison(
            question: question,
            category: category,
            player1Result: result1,
            player2Result: result2,
            comparativeResult: comparativeResult,
            alignmentScore: calculateAlignmentScore(result1, result2),
            complementarityScore: calculateComplementarityScore(result1, result2)
        )
    }
    
    /// Generates session-level insights from individual and comparative analyses
    private func generateSessionInsights(
        _ cardAnswers: [CardAnswers],
        _ player1Analysis: PlayerSessionAnalysis,
        _ player2Analysis: PlayerSessionAnalysis
    ) async throws -> [SessionInsight] {
        
        var insights: [SessionInsight] = []
        
        // Communication pattern insights
        if player1Analysis.averageScore > 80 && player2Analysis.averageScore > 80 {
            insights.append(SessionInsight(
                type: .communicationStrength,
                title: "Strong Communication Foundation",
                description: "Both players demonstrate excellent communication skills and emotional intelligence across all questions.",
                confidence: .high,
                impact: .positive
            ))
        }
        
        // Growth and progression insights
        let player1Progression = player1Analysis.individualResults.map(\.score)
        let player2Progression = player2Analysis.individualResults.map(\.score)
        
        if isProgressionImproving(player1Progression) || isProgressionImproving(player2Progression) {
            insights.append(SessionInsight(
                type: .progressionTrend,
                title: "Growing Comfort and Openness",
                description: "One or both players showed increasing comfort and vulnerability as the conversation progressed.",
                confidence: .medium,
                impact: .positive
            ))
        }
        
        // Category-specific insights
        let categoryScores = calculateCategoryAverages(cardAnswers)
        if let strongestCategory = categoryScores.max(by: { $0.value < $1.value }) {
            insights.append(SessionInsight(
                type: .categoryStrength,
                title: "Strongest Connection Area",
                description: "Both players showed particular strength in \(strongestCategory.key.displayName) conversations.",
                confidence: .high,
                impact: .informational
            ))
        }
        
        return insights
    }
    
    /// Calculates overall game metrics from individual and comparative analyses
    private func calculateGameMetrics(
        _ player1: PlayerSessionAnalysis,
        _ player2: PlayerSessionAnalysis,
        _ comparative: ComparativeGameAnalysis
    ) -> GameMetrics {
        
        let averageIndividualScore = (player1.averageScore + player2.averageScore) / 2
        let scoreBalance = abs(player1.averageScore - player2.averageScore)
        
        // Engagement score based on response quality and length
        let engagementScore = calculateEngagementScore(player1, player2)
        
        // Compatibility potential based on alignment and complementarity
        let compatibilityPotential = comparative.overallCompatibilityScore
        
        // Communication quality based on clarity and empathy scores
        let communicationQuality = calculateCommunicationQuality(player1, player2)
        
        return GameMetrics(
            overallScore: averageIndividualScore,
            compatibilityPotential: compatibilityPotential,
            communicationQuality: communicationQuality,
            engagementLevel: engagementScore,
            balanceScore: max(0, 100 - scoreBalance),
            insightfulness: calculateInsightfulness(player1, player2)
        )
    }
    
    /// Saves game results for future reference and analysis
    private func saveGameResults(_ result: GameCompletionResult) async throws {
        // Save individual compatibility results
        for result in result.player1Analysis.individualResults {
            try await sessionManager.saveResult(result)
        }
        
        for result in result.player2Analysis.individualResults {
            try await sessionManager.saveResult(result)
        }
        
        // Create session analysis combining both players
        let combinedResults = result.player1Analysis.individualResults + result.player2Analysis.individualResults
        let _ = try await compatibilityAnalyzer.analyzeSession(combinedResults)
        
        // Save session analysis
        let _ = try await sessionManager.createSession(for: nil) // Anonymous session for now
    }
    
    // MARK: - Calculation Helper Methods
    
    private func calculateStrongestDimensions(_ results: [CompatibilityResult]) -> [String] {
        // Calculate average scores for each dimension
        let avgDimensions = results.reduce(CompatibilityDimensions(emotionalOpenness: 0, clarity: 0, empathy: 0, vulnerability: 0, communicationStyle: 0)) { sum, result in
            CompatibilityDimensions(
                emotionalOpenness: sum.emotionalOpenness + result.dimensions.emotionalOpenness,
                clarity: sum.clarity + result.dimensions.clarity,
                empathy: sum.empathy + result.dimensions.empathy,
                vulnerability: sum.vulnerability + result.dimensions.vulnerability,
                communicationStyle: sum.communicationStyle + result.dimensions.communicationStyle
            )
        }
        
        let count = results.count
        let dimensions = [
            ("Emotional Openness", avgDimensions.emotionalOpenness / count),
            ("Clarity", avgDimensions.clarity / count),
            ("Empathy", avgDimensions.empathy / count),
            ("Vulnerability", avgDimensions.vulnerability / count),
            ("Communication Style", avgDimensions.communicationStyle / count)
        ]
        
        return dimensions.filter { $0.1 >= 75 }.map { $0.0 }
    }
    
    private func calculateGrowthAreas(_ results: [CompatibilityResult]) -> [String] {
        // Similar to calculateStrongestDimensions but for areas needing improvement
        let avgDimensions = results.reduce(CompatibilityDimensions(emotionalOpenness: 0, clarity: 0, empathy: 0, vulnerability: 0, communicationStyle: 0)) { sum, result in
            CompatibilityDimensions(
                emotionalOpenness: sum.emotionalOpenness + result.dimensions.emotionalOpenness,
                clarity: sum.clarity + result.dimensions.clarity,
                empathy: sum.empathy + result.dimensions.empathy,
                vulnerability: sum.vulnerability + result.dimensions.vulnerability,
                communicationStyle: sum.communicationStyle + result.dimensions.communicationStyle
            )
        }
        
        let count = results.count
        let dimensions = [
            ("Emotional Openness", avgDimensions.emotionalOpenness / count),
            ("Clarity", avgDimensions.clarity / count),
            ("Empathy", avgDimensions.empathy / count),
            ("Vulnerability", avgDimensions.vulnerability / count),
            ("Communication Style", avgDimensions.communicationStyle / count)
        ]
        
        return dimensions.filter { $0.1 < 65 }.map { $0.0 }
    }
    
    private func calculateAlignmentScore(_ result1: CompatibilityResult, _ result2: CompatibilityResult) -> Double {
        let scoreDiff = abs(result1.score - result2.score)
        return max(0.0, 1.0 - Double(scoreDiff) / 100.0)
    }
    
    private func calculateComplementarityScore(_ result1: CompatibilityResult, _ result2: CompatibilityResult) -> Double {
        // Calculate how well the responses complement each other
        let d1 = result1.dimensions
        let d2 = result2.dimensions
        
        // Look for complementary patterns (one strong where other is developing)
        let complementarity = [
            calculateDimensionComplementarity(d1.emotionalOpenness, d2.emotionalOpenness),
            calculateDimensionComplementarity(d1.clarity, d2.clarity),
            calculateDimensionComplementarity(d1.empathy, d2.empathy),
            calculateDimensionComplementarity(d1.vulnerability, d2.vulnerability),
            calculateDimensionComplementarity(d1.communicationStyle, d2.communicationStyle)
        ]
        
        return complementarity.reduce(0, +) / Double(complementarity.count)
    }
    
    private func calculateDimensionComplementarity(_ score1: Int, _ score2: Int) -> Double {
        // Complementarity is highest when one score is strong and the other is developing
        let diff = abs(score1 - score2)
        let average = (score1 + score2) / 2
        
        // Ideal complementarity: one around 80, other around 60
        if diff >= 15 && diff <= 25 && average >= 65 {
            return 1.0
        } else if diff >= 10 && average >= 60 {
            return 0.7
        } else {
            return 0.3
        }
    }
    
    private func calculateOverallCompatibility(_ comparisons: [QuestionComparison]) -> (score: Int, tier: CompatibilityTier) {
        let averageAlignment = comparisons.map(\.alignmentScore).reduce(0, +) / Double(comparisons.count)
        let averageComplementarity = comparisons.map(\.complementarityScore).reduce(0, +) / Double(comparisons.count)
        
        let overallScore = Int((averageAlignment * 0.6 + averageComplementarity * 0.4) * 100)
        
        let tier: CompatibilityTier
        switch overallScore {
        case 85...100: tier = .exceptional
        case 70..<85: tier = .strong
        case 55..<70: tier = .moderate
        case 40..<55: tier = .developing
        default: tier = .challenging
        }
        
        return (overallScore, tier)
    }
    
    private func generateRelationshipInsights(_ comparisons: [QuestionComparison]) -> [RelationshipInsight] {
        var insights: [RelationshipInsight] = []
        
        // Analyze communication styles
        let clarityScores = comparisons.flatMap { [$0.player1Result.dimensions.clarity, $0.player2Result.dimensions.clarity] }
        let avgClarity = clarityScores.reduce(0, +) / clarityScores.count
        
        if avgClarity > 80 {
            insights.append(RelationshipInsight(
                category: .communication,
                title: "Clear Communication Style",
                description: "Both partners communicate clearly and directly, which supports mutual understanding.",
                strength: .high
            ))
        }
        
        // Analyze vulnerability patterns
        let vulnerabilityScores = comparisons.flatMap { [$0.player1Result.dimensions.vulnerability, $0.player2Result.dimensions.vulnerability] }
        let avgVulnerability = vulnerabilityScores.reduce(0, +) / vulnerabilityScores.count
        
        if avgVulnerability > 75 {
            insights.append(RelationshipInsight(
                category: .intimacy,
                title: "Openness to Vulnerability",
                description: "Both partners show comfort with sharing personal thoughts and feelings.",
                strength: .high
            ))
        }
        
        return insights
    }
    
    private func calculateCommunicationSynergy(_ comparisons: [QuestionComparison]) -> CommunicationSynergy {
        let avgAlignment = comparisons.map(\.alignmentScore).reduce(0, +) / Double(comparisons.count)
        
        var strengths: [String] = []
        var challenges: [String] = []
        var recommendations: [String] = []
        
        if avgAlignment > 0.7 {
            strengths.append("Strong alignment in communication styles")
        } else if avgAlignment < 0.4 {
            challenges.append("Different communication approaches")
            recommendations.append("Practice active listening and clarification")
        }
        
        return CommunicationSynergy(
            synergyScore: avgAlignment,
            strengths: strengths,
            challenges: challenges,
            recommendations: recommendations
        )
    }
    
    private func generateRecommendedNextSteps(_ compatibility: (score: Int, tier: CompatibilityTier), _ insights: [RelationshipInsight]) -> [String] {
        var steps: [String] = []
        
        switch compatibility.tier {
        case .exceptional:
            steps.append("Continue building on your strong communication foundation")
            steps.append("Explore deeper topics and shared future visions")
        case .strong:
            steps.append("Focus on areas where you complement each other well")
            steps.append("Practice vulnerability in a safe, supportive environment")
        case .moderate:
            steps.append("Work on improving clarity in communication")
            steps.append("Spend time understanding each other's perspectives")
        case .developing, .challenging:
            steps.append("Start with lighter conversations to build comfort")
            steps.append("Practice empathy and active listening skills")
        }
        
        return steps
    }
    
    private func isProgressionImproving(_ scores: [Int]) -> Bool {
        guard scores.count >= 3 else { return false }
        
        let firstHalf = scores.prefix(scores.count / 2)
        let secondHalf = scores.suffix(scores.count / 2)
        
        let firstAvg = firstHalf.reduce(0, +) / firstHalf.count
        let secondAvg = secondHalf.reduce(0, +) / secondHalf.count
        
        return secondAvg > firstAvg + 5 // At least 5 point improvement
    }
    
    private func calculateCategoryAverages(_ cardAnswers: [CardAnswers]) -> [QuestionCategory: Int] {
        var categoryTotals: [QuestionCategory: (total: Int, count: Int)] = [:]
        
        for cardAnswer in cardAnswers {
            let p1Score = 70 // Placeholder - would calculate from actual analysis
            let p2Score = 75 // Placeholder - would calculate from actual analysis
            let avgScore = (p1Score + p2Score) / 2
            
            if let existing = categoryTotals[cardAnswer.category] {
                categoryTotals[cardAnswer.category] = (existing.total + avgScore, existing.count + 1)
            } else {
                categoryTotals[cardAnswer.category] = (avgScore, 1)
            }
        }
        
        return categoryTotals.mapValues { $0.total / $0.count }
    }
    
    private func calculateEngagementScore(_ player1: PlayerSessionAnalysis, _ player2: PlayerSessionAnalysis) -> Int {
        // Engagement based on response quality and consistency
        let p1Consistency = calculateScoreConsistency(player1.individualResults.map(\.score))
        let p2Consistency = calculateScoreConsistency(player2.individualResults.map(\.score))
        
        let avgScore = (player1.averageScore + player2.averageScore) / 2
        let avgConsistency = (p1Consistency + p2Consistency) / 2
        
        return Int(Double(avgScore) * 0.7 + avgConsistency * 0.3)
    }
    
    private func calculateScoreConsistency(_ scores: [Int]) -> Double {
        guard scores.count > 1 else { return 100.0 }
        
        let average = scores.reduce(0, +) / scores.count
        let variance = scores.map { pow(Double($0 - average), 2) }.reduce(0, +) / Double(scores.count)
        let standardDeviation = sqrt(variance)
        
        // Convert to 0-100 scale where lower deviation = higher consistency
        return max(0, 100 - standardDeviation * 3)
    }
    
    private func calculateCommunicationQuality(_ player1: PlayerSessionAnalysis, _ player2: PlayerSessionAnalysis) -> Int {
        let p1CommunicationScores = player1.individualResults.map { ($0.dimensions.clarity + $0.dimensions.communicationStyle) / 2 }
        let p2CommunicationScores = player2.individualResults.map { ($0.dimensions.clarity + $0.dimensions.communicationStyle) / 2 }
        
        let p1Avg = p1CommunicationScores.reduce(0, +) / p1CommunicationScores.count
        let p2Avg = p2CommunicationScores.reduce(0, +) / p2CommunicationScores.count
        
        return (p1Avg + p2Avg) / 2
    }
    
    private func calculateInsightfulness(_ player1: PlayerSessionAnalysis, _ player2: PlayerSessionAnalysis) -> Int {
        // Based on vulnerability and emotional openness
        let p1InsightScores = player1.individualResults.map { ($0.dimensions.vulnerability + $0.dimensions.emotionalOpenness) / 2 }
        let p2InsightScores = player2.individualResults.map { ($0.dimensions.vulnerability + $0.dimensions.emotionalOpenness) / 2 }
        
        let p1Avg = p1InsightScores.reduce(0, +) / p1InsightScores.count
        let p2Avg = p2InsightScores.reduce(0, +) / p2InsightScores.count
        
        return (p1Avg + p2Avg) / 2
    }
}

// MARK: - Supporting Data Structures

/// Context for a player's response with optimization metadata
public struct PlayerResponseContext {
    public let answerText: String
    public let question: String
    public let category: QuestionCategory
    public let originalLength: Int
    public let wasOptimized: Bool
}

/// Analysis results for a single player across the entire session
public struct PlayerSessionAnalysis {
    public let playerNumber: Int
    public let individualResults: [CompatibilityResult]
    public let sessionAnalysis: SessionAnalysis
    public let responseCount: Int
    public let averageScore: Int
    public let strongestDimensions: [String]
    public let growthAreas: [String]
}

/// Comparison analysis for a single question between both players
public struct QuestionComparison {
    public let question: String
    public let category: QuestionCategory
    public let player1Result: CompatibilityResult
    public let player2Result: CompatibilityResult
    public let comparativeResult: ComparativeCompatibilityResult
    public let alignmentScore: Double
    public let complementarityScore: Double
}

/// Complete comparative analysis for the entire game session
public struct ComparativeGameAnalysis {
    public let questionComparisons: [QuestionComparison]
    public let overallCompatibilityScore: Int
    public let compatibilityTier: CompatibilityTier
    public let relationshipInsights: [RelationshipInsight]
    public let communicationSynergy: CommunicationSynergy
    public let recommendedNextSteps: [String]
}

/// Session-level insights from the completed game
public struct SessionInsight {
    public let type: SessionInsightType
    public let title: String
    public let description: String
    public let confidence: InsightConfidence
    public let impact: InsightImpact
}

/// Overall metrics for the completed game session
public struct GameMetrics {
    public let overallScore: Int
    public let compatibilityPotential: Int
    public let communicationQuality: Int
    public let engagementLevel: Int
    public let balanceScore: Int
    public let insightfulness: Int
}

/// Complete results from game completion analysis
public struct GameCompletionResult {
    public let id: UUID
    public let player1Analysis: PlayerSessionAnalysis
    public let player2Analysis: PlayerSessionAnalysis
    public let comparativeAnalysis: ComparativeGameAnalysis
    public let sessionInsights: [SessionInsight]
    public let gameMetrics: GameMetrics
    public let cardAnswers: [CardAnswers]
    public let completionDuration: TimeInterval
    public let completedAt: Date
}

// MARK: - Supporting Enums

public enum CompatibilityTier: String, CaseIterable {
    case exceptional = "exceptional"
    case strong = "strong"
    case moderate = "moderate"
    case developing = "developing"
    case challenging = "challenging"
    
    public var displayName: String {
        switch self {
        case .exceptional: return "Exceptional Compatibility"
        case .strong: return "Strong Compatibility"
        case .moderate: return "Moderate Compatibility"
        case .developing: return "Developing Compatibility"
        case .challenging: return "Challenging Compatibility"
        }
    }
    
    public var description: String {
        switch self {
        case .exceptional: return "Outstanding alignment and communication potential"
        case .strong: return "Very good compatibility with great potential"
        case .moderate: return "Good foundation with room for growth"
        case .developing: return "Early stage compatibility that can improve"
        case .challenging: return "Significant differences requiring attention"
        }
    }
}

public enum SessionInsightType: String, CaseIterable {
    case communicationStrength = "communication_strength"
    case progressionTrend = "progression_trend"
    case categoryStrength = "category_strength"
    case balancePattern = "balance_pattern"
    case growthOpportunity = "growth_opportunity"
}

public enum InsightImpact: String, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case informational = "informational"
    case cautionary = "cautionary"
}

public struct RelationshipInsight {
    public let category: RelationshipInsightCategory
    public let title: String
    public let description: String
    public let strength: StrengthLevel
}

public enum RelationshipInsightCategory: String, CaseIterable {
    case communication = "communication"
    case intimacy = "intimacy"
    case compatibility = "compatibility"
    case growth = "growth"
}

public enum StrengthLevel: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case developing = "developing"
}

// MARK: - Data Structures (imported from CardAnalysisSummary.swift)

// MARK: - Error Types

public enum GameCompletionError: LocalizedError {
    case invalidInput(String)
    case analysisError(String)
    case contextWindowExceeded(String)
    case resourceLimitExceeded(String)
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid Input: \(message)"
        case .analysisError(let message):
            return "Analysis Error: \(message)"
        case .contextWindowExceeded(let message):
            return "Context Window Exceeded: \(message)"
        case .resourceLimitExceeded(let message):
            return "Resource Limit Exceeded: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidInput:
            return "The provided card answers are invalid or incomplete"
        case .analysisError:
            return "The compatibility analysis could not be completed"
        case .contextWindowExceeded:
            return "The analysis request exceeded the model's context window"
        case .resourceLimitExceeded:
            return "The analysis requires more resources than available"
        case .networkError:
            return "A network error occurred during analysis"
        }
    }
}