import Foundation
import OSLog

// MARK: - Compatibility Analyzer Protocol

/// Protocol defining the interface for compatibility analysis services
/// Enables dependency injection and testing with mock implementations
public protocol CompatibilityAnalyzer {
    /// Analyzes a single transcribed response for compatibility insights
    /// - Parameter request: The analysis request containing response and context
    /// - Returns: Detailed compatibility analysis result
    /// - Throws: CompatibilityAnalysisError for various failure scenarios
    func analyzeResponse(_ request: AnalysisRequest) async throws -> CompatibilityResult
    
    /// Compares two users' responses for compatibility assessment
    /// - Parameters:
    ///   - user1Request: First user's analysis request
    ///   - user2Request: Second user's analysis request
    /// - Returns: Comparative compatibility analysis result
    /// - Throws: CompatibilityAnalysisError for various failure scenarios
    func compareResponses(
        user1Request: AnalysisRequest,
        user2Request: AnalysisRequest
    ) async throws -> ComparativeCompatibilityResult
    
    /// Analyzes patterns across multiple responses in a session
    /// - Parameter responses: Array of compatibility results from the session
    /// - Returns: Session-level analysis with trends and insights
    /// - Throws: CompatibilityAnalysisError for various failure scenarios
    func analyzeSession(_ responses: [CompatibilityResult]) async throws -> SessionAnalysis
}

// MARK: - Compatibility Analyzer Service Implementation

/// Production implementation of CompatibilityAnalyzer using on-device LLM
/// Integrates with LLMService to generate meaningful compatibility insights
/// without any network calls - all analysis happens locally
public final class CompatibilityAnalyzerService: CompatibilityAnalyzer {
    
    // MARK: - Dependencies
    
    private let llmService: LLMService
    private let promptProcessor: CompatibilityPromptProcessor
    private let responseProcessor: CompatibilityResponseProcessor
    private let logger: Logger
    
    // MARK: - Configuration
    
    private let maxRetryAttempts: Int
    private let requestTimeout: TimeInterval
    private let maxResponseLength: Int
    
    // MARK: - Initialization
    
    /// Initializes the CompatibilityAnalyzer with dependencies
    /// - Parameters:
    ///   - llmService: Service for LLM inference (defaults to shared instance)
    ///   - promptProcessor: Processor for template substitution (defaults to standard processor)
    ///   - responseProcessor: Processor for cleaning LLM responses (defaults to standard processor)
    ///   - maxRetryAttempts: Maximum retry attempts for failed requests (default: 2)
    ///   - requestTimeout: Timeout for individual requests (default: 45 seconds)
    ///   - maxResponseLength: Maximum response length to analyze (default: 1000 characters)
    public init(
        llmService: LLMService = .shared,
        promptProcessor: CompatibilityPromptProcessor = CompatibilityPromptProcessor(),
        responseProcessor: CompatibilityResponseProcessor = CompatibilityResponseProcessor(),
        maxRetryAttempts: Int = 2,
        requestTimeout: TimeInterval = 45.0,
        maxResponseLength: Int = 1000
    ) {
        self.llmService = llmService
        self.promptProcessor = promptProcessor
        self.responseProcessor = responseProcessor
        self.maxRetryAttempts = maxRetryAttempts
        self.requestTimeout = requestTimeout
        self.maxResponseLength = maxResponseLength
        self.logger = Logger(subsystem: "com.kickbackapp.compatibility", category: "CompatibilityAnalysis")
    }
    
    // MARK: - CompatibilityAnalyzer Protocol Implementation
    
    public func analyzeResponse(_ request: AnalysisRequest) async throws -> CompatibilityResult {
        let startTime = Date()
        
        logger.info("Starting compatibility analysis for category: \(request.questionCategory.rawValue)")
        
        do {
            // Validate input
            try validateAnalysisRequest(request)
            
            // Process the prompt template
            let prompt = promptProcessor.processTemplate(for: request)
            logger.debug("Generated analysis prompt: \(prompt, privacy: .private)")
            
            // Generate response with retry logic
            let rawResponse = try await generateWithRetry(prompt: prompt, seed: request.seed)
            logger.debug("Raw LLM response: \(rawResponse, privacy: .private)")
            
            // Process and parse the response
            let analysisResult = try responseProcessor.processResponse(
                rawResponse,
                for: request,
                processingDuration: Date().timeIntervalSince(startTime)
            )
            
            logger.info("Successfully completed compatibility analysis in \(Date().timeIntervalSince(startTime), privacy: .public)s")
            return analysisResult
            
        } catch {
            let processingDuration = Date().timeIntervalSince(startTime)
            logger.error("Compatibility analysis failed after \(processingDuration, privacy: .public)s: \(error.localizedDescription)")
            
            // Re-throw as CompatibilityAnalysisError if not already
            if let compatibilityError = error as? CompatibilityAnalysisError {
                throw compatibilityError
            } else {
                throw CompatibilityAnalysisError.processingError("Analysis failed: \(error.localizedDescription)")
            }
        }
    }
    
    public func compareResponses(
        user1Request: AnalysisRequest,
        user2Request: AnalysisRequest
    ) async throws -> ComparativeCompatibilityResult {
        let startTime = Date()
        
        logger.info("Starting comparative compatibility analysis")
        
        do {
            // Validate that both requests are for the same question
            guard user1Request.question == user2Request.question else {
                throw CompatibilityAnalysisError.configurationError("Users must be answering the same question for comparison")
            }
            
            // Analyze both responses individually first
            let user1Result = try await analyzeResponse(user1Request)
            let user2Result = try await analyzeResponse(user2Request)
            
            // Generate comparative analysis prompt
            let comparativePrompt = promptProcessor.processComparativeTemplate(
                question: user1Request.question,
                response1: user1Request.transcribedResponse,
                response2: user2Request.transcribedResponse,
                questionCategory: user1Request.questionCategory,
                seed: user1Request.seed ?? user2Request.seed
            )
            
            // Generate comparative analysis
            let rawComparativeResponse = try await generateWithRetry(prompt: comparativePrompt, seed: user1Request.seed)
            
            // Process comparative result
            let comparativeResult = try responseProcessor.processComparativeResponse(
                rawComparativeResponse,
                user1Result: user1Result,
                user2Result: user2Result
            )
            
            logger.info("Successfully completed comparative analysis in \(Date().timeIntervalSince(startTime), privacy: .public)s")
            return comparativeResult
            
        } catch {
            let processingDuration = Date().timeIntervalSince(startTime)
            logger.error("Comparative analysis failed after \(processingDuration, privacy: .public)s: \(error.localizedDescription)")
            
            if let compatibilityError = error as? CompatibilityAnalysisError {
                throw compatibilityError
            } else {
                throw CompatibilityAnalysisError.processingError("Comparative analysis failed: \(error.localizedDescription)")
            }
        }
    }
    
    public func analyzeSession(_ responses: [CompatibilityResult]) async throws -> SessionAnalysis {
        let startTime = Date()
        
        logger.info("Starting session analysis for \(responses.count) responses")
        
        guard !responses.isEmpty else {
            throw CompatibilityAnalysisError.insufficientData("Cannot analyze empty session")
        }
        
        guard responses.count >= 2 else {
            throw CompatibilityAnalysisError.insufficientData("Session analysis requires at least 2 responses")
        }
        
        do {
            // Calculate trend analysis
            let trendAnalysis = calculateTrendAnalysis(responses)
            
            // Calculate category breakdown
            let categoryBreakdown = calculateCategoryBreakdown(responses)
            
            // Calculate overall session score
            let overallScore = responses.map { $0.score }.reduce(0, +) / responses.count
            
            // Generate session insights
            let sessionInsights = generateSessionInsights(responses, trendAnalysis: trendAnalysis)
            
            let sessionAnalysis = SessionAnalysis(
                sessionId: UUID(), // In practice, this would be provided
                responses: responses,
                overallSessionScore: overallScore,
                trendAnalysis: trendAnalysis,
                categoryBreakdown: categoryBreakdown,
                sessionInsights: sessionInsights
            )
            
            logger.info("Successfully completed session analysis in \(Date().timeIntervalSince(startTime), privacy: .public)s")
            return sessionAnalysis
            
        } catch {
            logger.error("Session analysis failed: \(error.localizedDescription)")
            throw CompatibilityAnalysisError.processingError("Session analysis failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Validates an analysis request for required data
    private func validateAnalysisRequest(_ request: AnalysisRequest) throws {
        guard !request.transcribedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CompatibilityAnalysisError.invalidResponse("Response cannot be empty")
        }
        
        guard request.transcribedResponse.count <= maxResponseLength else {
            throw CompatibilityAnalysisError.invalidResponse("Response too long (max \(maxResponseLength) characters)")
        }
        
        guard !request.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CompatibilityAnalysisError.configurationError("Question cannot be empty")
        }
        
        // Check for minimum meaningful response length
        let wordCount = request.transcribedResponse.components(separatedBy: .whitespacesAndNewlines).count
        guard wordCount >= 3 else {
            throw CompatibilityAnalysisError.insufficientData("Response too short for meaningful analysis")
        }
    }
    
    /// Generates LLM response with retry logic and optional seed for deterministic results
    private func generateWithRetry(prompt: String, seed: UInt64? = nil) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...(maxRetryAttempts + 1) {
            do {
                logger.debug("Attempt \(attempt) of \(self.maxRetryAttempts + 1) for LLM generation")
                
                let response = try await withTimeout(seconds: requestTimeout) { [self] in
                    // If seed is provided, we could set it here for deterministic results
                    // For now, we'll pass it through in the prompt
                    try await llmService.generateResponse(for: prompt)
                }
                
                return response
                
            } catch {
                lastError = error
                logger.warning("Attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Don't retry on the last attempt
                if attempt <= maxRetryAttempts {
                    // Exponential backoff with jitter
                    let delay = min(pow(2.0, Double(attempt - 1)), 8.0) + Double.random(in: 0...1)
                    logger.debug("Retrying after \(delay, privacy: .public)s delay")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // All attempts failed
        if let llmError = lastError as? LLMServiceError {
            throw CompatibilityAnalysisError.llmServiceError(llmError)
        } else {
            throw CompatibilityAnalysisError.processingError("Failed after \(self.maxRetryAttempts + 1) attempts: \(lastError?.localizedDescription ?? "Unknown error")")
        }
    }
    
    /// Adds timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CompatibilityAnalysisError.analysisTimeout("Analysis timed out after \(seconds) seconds")
            }
            
            guard let result = try await group.next() else {
                throw CompatibilityAnalysisError.analysisTimeout("Timeout task group failed")
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Calculates trend analysis across session responses
    private func calculateTrendAnalysis(_ responses: [CompatibilityResult]) -> TrendAnalysis {
        let scores = responses.map { $0.score }
        let scoreProgression = scores
        
        // Calculate improving dimensions by comparing first and last responses
        let firstDimensions = responses.first?.dimensions
        let lastDimensions = responses.last?.dimensions
        
        var improvingDimensions: [String] = []
        if let first = firstDimensions, let last = lastDimensions {
            if last.emotionalOpenness > first.emotionalOpenness { improvingDimensions.append("Emotional Openness") }
            if last.clarity > first.clarity { improvingDimensions.append("Clarity") }
            if last.empathy > first.empathy { improvingDimensions.append("Empathy") }
            if last.vulnerability > first.vulnerability { improvingDimensions.append("Vulnerability") }
            if last.communicationStyle > first.communicationStyle { improvingDimensions.append("Communication Style") }
        }
        
        // Find consistent strengths (high scores across multiple responses)
        let avgDimensions = calculateAverageDimensions(responses)
        var consistentStrengths: [String] = []
        if avgDimensions.emotionalOpenness >= 75 { consistentStrengths.append("Emotional Openness") }
        if avgDimensions.clarity >= 75 { consistentStrengths.append("Clarity") }
        if avgDimensions.empathy >= 75 { consistentStrengths.append("Empathy") }
        if avgDimensions.vulnerability >= 75 { consistentStrengths.append("Vulnerability") }
        if avgDimensions.communicationStyle >= 75 { consistentStrengths.append("Communication Style") }
        
        // Find development areas (low scores needing improvement)
        var developmentAreas: [String] = []
        if avgDimensions.emotionalOpenness < 60 { developmentAreas.append("Emotional Openness") }
        if avgDimensions.clarity < 60 { developmentAreas.append("Clarity") }
        if avgDimensions.empathy < 60 { developmentAreas.append("Empathy") }
        if avgDimensions.vulnerability < 60 { developmentAreas.append("Vulnerability") }
        if avgDimensions.communicationStyle < 60 { developmentAreas.append("Communication Style") }
        
        // Calculate confidence growth (based on score progression)
        let confidenceGrowth = scores.count > 1 ? Double(scores.last! - scores.first!) / 100.0 : 0.0
        
        return TrendAnalysis(
            scoreProgression: scoreProgression,
            improvingDimensions: improvingDimensions,
            consistentStrengths: consistentStrengths,
            developmentAreas: developmentAreas,
            confidenceGrowth: confidenceGrowth
        )
    }
    
    /// Calculates average dimensions across all responses
    private func calculateAverageDimensions(_ responses: [CompatibilityResult]) -> CompatibilityDimensions {
        let count = responses.count
        let sumDimensions = responses.reduce(CompatibilityDimensions(emotionalOpenness: 0, clarity: 0, empathy: 0, vulnerability: 0, communicationStyle: 0)) { sum, result in
            CompatibilityDimensions(
                emotionalOpenness: sum.emotionalOpenness + result.dimensions.emotionalOpenness,
                clarity: sum.clarity + result.dimensions.clarity,
                empathy: sum.empathy + result.dimensions.empathy,
                vulnerability: sum.vulnerability + result.dimensions.vulnerability,
                communicationStyle: sum.communicationStyle + result.dimensions.communicationStyle
            )
        }
        
        return CompatibilityDimensions(
            emotionalOpenness: sumDimensions.emotionalOpenness / count,
            clarity: sumDimensions.clarity / count,
            empathy: sumDimensions.empathy / count,
            vulnerability: sumDimensions.vulnerability / count,
            communicationStyle: sumDimensions.communicationStyle / count
        )
    }
    
    /// Calculates breakdown of scores by question category
    private func calculateCategoryBreakdown(_ responses: [CompatibilityResult]) -> [QuestionCategory: Int] {
        var breakdown: [QuestionCategory: (total: Int, count: Int)] = [:]
        
        for response in responses {
            let category = response.analysisMetadata.questionCategory
            if let existing = breakdown[category] {
                breakdown[category] = (existing.total + response.score, existing.count + 1)
            } else {
                breakdown[category] = (response.score, 1)
            }
        }
        
        return breakdown.mapValues { $0.total / $0.count }
    }
    
    /// Generates session-level insights based on response patterns
    private func generateSessionInsights(_ responses: [CompatibilityResult], trendAnalysis: TrendAnalysis) -> [CompatibilityInsight] {
        var insights: [CompatibilityInsight] = []
        
        // Insight about score progression
        if !trendAnalysis.scoreProgression.isEmpty {
            let firstScore = trendAnalysis.scoreProgression.first!
            let lastScore = trendAnalysis.scoreProgression.last!
            let improvement = lastScore - firstScore
            
            if improvement > 10 {
                insights.append(CompatibilityInsight(
                    type: .relationshipReadiness,
                    title: "Growing Confidence",
                    description: "Your compatibility scores improved by \(improvement) points throughout the session, showing increasing comfort and openness.",
                    confidence: .high
                ))
            } else if improvement < -10 {
                insights.append(CompatibilityInsight(
                    type: .growthArea,
                    title: "Consistency Challenge",
                    description: "Your scores varied significantly during the session. Consider what factors might affect your response consistency.",
                    confidence: .medium
                ))
            }
        }
        
        // Insight about consistent strengths
        if !trendAnalysis.consistentStrengths.isEmpty {
            insights.append(CompatibilityInsight(
                type: .strength,
                title: "Reliable Strengths",
                description: "You consistently demonstrate strong \(trendAnalysis.consistentStrengths.joined(separator: " and ")) across different question types.",
                confidence: .veryHigh
            ))
        }
        
        // Insight about development areas
        if !trendAnalysis.developmentAreas.isEmpty {
            insights.append(CompatibilityInsight(
                type: .growthArea,
                title: "Growth Opportunities",
                description: "Focus on developing your \(trendAnalysis.developmentAreas.joined(separator: " and ")) to enhance your relationship communication.",
                confidence: .high
            ))
        }
        
        return insights
    }
}

// MARK: - Response Processor

/// Handles processing and parsing raw LLM responses into CompatibilityResult objects
public struct CompatibilityResponseProcessor {
    
    public init() {}
    
    /// Processes raw LLM response into a CompatibilityResult
    /// - Parameters:
    ///   - rawResponse: The raw JSON text from the LLM
    ///   - request: The original analysis request
    ///   - processingDuration: Time taken for analysis
    /// - Returns: Parsed and validated CompatibilityResult
    /// - Throws: CompatibilityAnalysisError for parsing failures
    public func processResponse(
        _ rawResponse: String,
        for request: AnalysisRequest,
        processingDuration: TimeInterval
    ) throws -> CompatibilityResult {
        // Clean and prepare JSON
        let cleanedResponse = cleanJSONResponse(rawResponse)
        
        // Parse JSON
        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            throw CompatibilityAnalysisError.processingError("Failed to encode JSON data")
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            guard let json = jsonObject else {
                throw CompatibilityAnalysisError.processingError("Invalid JSON structure")
            }
            
            // Parse required fields
            guard let score = json["score"] as? Int,
                  let summary = json["summary"] as? String,
                  let tone = json["tone"] as? String,
                  let dimensionsDict = json["dimensions"] as? [String: Any],
                  let insightsArray = json["insights"] as? [[String: Any]] else {
                throw CompatibilityAnalysisError.processingError("Missing required JSON fields")
            }
            
            // Validate score range
            let validatedScore = max(0, min(100, score))
            
            // Parse dimensions
            let dimensions = try parseDimensions(dimensionsDict)
            
            // Parse insights
            let insights = try parseInsights(insightsArray)
            
            // Create metadata
            let metadata = AnalysisMetadata(
                promptUsed: "", // Would be filled by the analyzer
                rawLLMResponse: rawResponse,
                processingDuration: processingDuration,
                analysisType: request.analysisType,
                questionCategory: request.questionCategory,
                responseLength: request.transcribedResponse.count,
                seed: request.seed
            )
            
            return CompatibilityResult(
                score: validatedScore,
                summary: summary,
                tone: tone,
                dimensions: dimensions,
                insights: insights,
                analysisMetadata: metadata
            )
            
        } catch {
            throw CompatibilityAnalysisError.processingError("JSON parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// Processes comparative analysis response
    public func processComparativeResponse(
        _ rawResponse: String,
        user1Result: CompatibilityResult,
        user2Result: CompatibilityResult
    ) throws -> ComparativeCompatibilityResult {
        // For now, create a basic comparative result
        // In practice, this would parse the LLM's comparative analysis JSON
        
        let overallScore = (user1Result.score + user2Result.score) / 2
        
        // Calculate dimension comparisons
        let dimensionComparison = calculateDimensionComparison(
            user1: user1Result.dimensions,
            user2: user2Result.dimensions
        )
        
        // Generate compatibility insights
        let compatibilityInsights = generateCompatibilityInsights(user1Result, user2Result)
        
        // Calculate communication synergy
        let communicationSynergy = calculateCommunicationSynergy(user1Result, user2Result)
        
        return ComparativeCompatibilityResult(
            user1Result: user1Result,
            user2Result: user2Result,
            overallCompatibilityScore: overallScore,
            compatibilityInsights: compatibilityInsights,
            dimensionComparison: dimensionComparison,
            communicationSynergy: communicationSynergy
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func cleanJSONResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any markdown code block formatting
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        
        // Find the JSON object bounds
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        return cleaned
    }
    
    private func parseDimensions(_ dict: [String: Any]) throws -> CompatibilityDimensions {
        guard let emotionalOpenness = dict["emotionalOpenness"] as? Int,
              let clarity = dict["clarity"] as? Int,
              let empathy = dict["empathy"] as? Int,
              let vulnerability = dict["vulnerability"] as? Int,
              let communicationStyle = dict["communicationStyle"] as? Int else {
            throw CompatibilityAnalysisError.processingError("Invalid dimensions format")
        }
        
        // Validate ranges
        return CompatibilityDimensions(
            emotionalOpenness: max(0, min(100, emotionalOpenness)),
            clarity: max(0, min(100, clarity)),
            empathy: max(0, min(100, empathy)),
            vulnerability: max(0, min(100, vulnerability)),
            communicationStyle: max(0, min(100, communicationStyle))
        )
    }
    
    private func parseInsights(_ array: [[String: Any]]) throws -> [CompatibilityInsight] {
        return try array.map { insightDict in
            guard let typeString = insightDict["type"] as? String,
                  let type = InsightType(rawValue: typeString),
                  let title = insightDict["title"] as? String,
                  let description = insightDict["description"] as? String,
                  let confidenceString = insightDict["confidence"] as? String,
                  let confidence = InsightConfidence(rawValue: confidenceString) else {
                throw CompatibilityAnalysisError.processingError("Invalid insight format")
            }
            
            let relatedDimension = insightDict["relatedDimension"] as? String
            
            return CompatibilityInsight(
                type: type,
                title: title,
                description: description,
                confidence: confidence,
                relatedDimension: relatedDimension
            )
        }
    }
    
    private func calculateDimensionComparison(
        user1: CompatibilityDimensions,
        user2: CompatibilityDimensions
    ) -> DimensionComparison {
        return DimensionComparison(
            emotionalOpennessAlignment: calculateAlignment(user1.emotionalOpenness, user2.emotionalOpenness),
            clarityAlignment: calculateAlignment(user1.clarity, user2.clarity),
            empathyAlignment: calculateAlignment(user1.empathy, user2.empathy),
            vulnerabilityAlignment: calculateAlignment(user1.vulnerability, user2.vulnerability),
            communicationStyleAlignment: calculateAlignment(user1.communicationStyle, user2.communicationStyle)
        )
    }
    
    private func calculateAlignment(_ score1: Int, _ score2: Int) -> AlignmentScore {
        let difference = abs(score1 - score2)
        let average = (score1 + score2) / 2
        
        let alignmentScore: Double
        let alignmentType: AlignmentType
        let description: String
        
        if difference <= 10 {
            alignmentScore = 1.0 - (Double(difference) / 20.0)
            alignmentType = .harmony
            description = "Very similar levels creating harmony"
        } else if difference <= 20 {
            alignmentScore = 0.8 - (Double(difference - 10) / 30.0)
            alignmentType = .balance
            description = "Complementary levels that can balance each other"
        } else if difference <= 30 {
            alignmentScore = 0.6 - (Double(difference - 20) / 40.0)
            alignmentType = .complement
            description = "Different approaches that could complement"
        } else {
            alignmentScore = 0.3
            alignmentType = .contrast
            description = "Significant differences requiring attention"
        }
        
        return AlignmentScore(
            score: alignmentScore,
            type: alignmentType,
            description: description
        )
    }
    
    private func generateCompatibilityInsights(
        _ user1: CompatibilityResult,
        _ user2: CompatibilityResult
    ) -> [CompatibilityInsight] {
        var insights: [CompatibilityInsight] = []
        
        // Compare overall scores
        let scoreDifference = abs(user1.score - user2.score)
        if scoreDifference <= 10 {
            insights.append(CompatibilityInsight(
                type: .compatibility,
                title: "Strong Overall Compatibility",
                description: "Both users show similar relationship readiness levels, indicating good compatibility potential.",
                confidence: .high
            ))
        } else if scoreDifference > 25 {
            insights.append(CompatibilityInsight(
                type: .compatibility,
                title: "Different Readiness Levels",
                description: "Significant difference in relationship readiness suggests need for open communication about expectations.",
                confidence: .medium
            ))
        }
        
        return insights
    }
    
    private func calculateCommunicationSynergy(
        _ user1: CompatibilityResult,
        _ user2: CompatibilityResult
    ) -> CommunicationSynergy {
        let avgScore = Double(user1.score + user2.score) / 200.0 // Normalize to 0-1
        
        var strengths: [String] = []
        var challenges: [String] = []
        var recommendations: [String] = []
        
        // Analyze communication strengths
        if user1.dimensions.clarity >= 75 && user2.dimensions.clarity >= 75 {
            strengths.append("Both communicate clearly and effectively")
        }
        
        if user1.dimensions.empathy >= 75 && user2.dimensions.empathy >= 75 {
            strengths.append("Strong mutual empathy and understanding")
        }
        
        // Identify potential challenges
        if abs(user1.dimensions.vulnerability - user2.dimensions.vulnerability) > 25 {
            challenges.append("Different comfort levels with vulnerability")
            recommendations.append("Practice gradual vulnerability sharing together")
        }
        
        if user1.dimensions.emotionalOpenness < 60 || user2.dimensions.emotionalOpenness < 60 {
            challenges.append("One or both partners may struggle with emotional expression")
            recommendations.append("Create safe spaces for emotional sharing")
        }
        
        return CommunicationSynergy(
            synergyScore: avgScore,
            strengths: strengths,
            challenges: challenges,
            recommendations: recommendations
        )
    }
}