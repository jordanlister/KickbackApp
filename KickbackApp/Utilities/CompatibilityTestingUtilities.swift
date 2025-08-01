import Foundation

// MARK: - Testing Utilities for Compatibility Analysis

/// Comprehensive testing utilities for compatibility analysis with deterministic results
/// Provides mock implementations, test data, and verification helpers
public struct CompatibilityTestingUtilities {
    
    // MARK: - Mock Data Generators
    
    /// Generates mock compatibility results for testing
    /// - Parameters:
    ///   - seed: Seed for deterministic generation
    ///   - category: Question category for the result
    ///   - baseScore: Base score to modify (default: 75)
    /// - Returns: Mock compatibility result
    public static func generateMockResult(
        seed: UInt64 = 12345,
        category: QuestionCategory = .earlyDating,
        baseScore: Int = 75
    ) -> CompatibilityResult {
        // Use seed for deterministic random generation
        var generator = SeededRandomGenerator(seed: seed)
        
        // Generate dimensions with some variance
        let dimensions = CompatibilityDimensions(
            emotionalOpenness: max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            clarity: max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            empathy: max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            vulnerability: max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            communicationStyle: max(0, min(100, baseScore + generator.nextInt(in: -15...15)))
        )
        
        // Generate insights based on dimensions
        let insights = generateMockInsights(dimensions: dimensions, generator: &generator)
        
        // Create metadata
        let metadata = AnalysisMetadata(
            promptUsed: "Mock analysis prompt for testing",
            rawLLMResponse: "Mock LLM response",
            processingDuration: 1.2 + generator.nextDouble() * 0.8,
            analysisType: .individual,
            questionCategory: category,
            responseLength: 120 + generator.nextInt(in: -30...80),
            seed: seed
        )
        
        return CompatibilityResult(
            score: dimensions.averageScore,
            summary: generateMockSummary(score: dimensions.averageScore, generator: &generator),
            tone: generateMockTone(generator: &generator),
            dimensions: dimensions,
            insights: insights,
            analysisMetadata: metadata
        )
    }
    
    /// Generates multiple mock results for session testing
    /// - Parameters:
    ///   - count: Number of results to generate
    ///   - baseSeed: Base seed for deterministic generation
    ///   - categories: Categories to cycle through
    /// - Returns: Array of mock results
    public static func generateMockSession(
        count: Int = 5,
        baseSeed: UInt64 = 12345,
        categories: [QuestionCategory] = [.earlyDating, .personalGrowth, .emotionalIntelligence]
    ) -> [CompatibilityResult] {
        var results: [CompatibilityResult] = []
        
        for i in 0..<count {
            let seed = baseSeed + UInt64(i * 1000)
            let category = categories[i % categories.count]
            let baseScore = 60 + (i * 5) // Progressive improvement
            
            var result = generateMockResult(seed: seed, category: category, baseScore: baseScore)
            
            // Adjust creation time for chronological order
            let createdAt = Date().addingTimeInterval(-Double(count - i) * 300) // 5 minutes apart
            result = CompatibilityResult(
                id: result.id,
                score: result.score,
                summary: result.summary,
                tone: result.tone,
                dimensions: result.dimensions,
                insights: result.insights,
                analysisMetadata: result.analysisMetadata,
                createdAt: createdAt
            )
            
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Mock Analysis Responses
    
    /// Generates mock LLM analysis response in expected JSON format
    /// - Parameters:
    ///   - seed: Seed for deterministic generation
    ///   - baseScore: Base score for the analysis
    /// - Returns: Mock JSON response string
    public static func generateMockLLMResponse(seed: UInt64 = 12345, baseScore: Int = 75) -> String {
        var generator = SeededRandomGenerator(seed: seed)
        
        let dimensions = [
            "emotionalOpenness": max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            "clarity": max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            "empathy": max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            "vulnerability": max(0, min(100, baseScore + generator.nextInt(in: -15...15))),
            "communicationStyle": max(0, min(100, baseScore + generator.nextInt(in: -15...15)))
        ]
        
        let averageScore = dimensions.values.reduce(0, +) / dimensions.count
        
        let mockResponse = """
        {
            "score": \(averageScore),
            "summary": "\(generateMockSummary(score: averageScore, generator: &generator))",
            "tone": "\(generateMockTone(generator: &generator))",
            "dimensions": {
                "emotionalOpenness": \(dimensions["emotionalOpenness"]!),
                "clarity": \(dimensions["clarity"]!),
                "empathy": \(dimensions["empathy"]!),
                "vulnerability": \(dimensions["vulnerability"]!),
                "communicationStyle": \(dimensions["communicationStyle"]!)
            },
            "insights": [
                {
                    "type": "strength",
                    "title": "Clear Expression",
                    "description": "You communicate your thoughts and feelings clearly and effectively.",
                    "confidence": "high",
                    "relatedDimension": "Clarity"
                },
                {
                    "type": "growth_area",
                    "title": "Emotional Depth",
                    "description": "Consider sharing deeper emotional experiences to enhance connection.",
                    "confidence": "medium",
                    "relatedDimension": "Vulnerability"
                }
            ]
        }
        """
        
        return mockResponse
    }
    
    // MARK: - Test Scenarios
    
    /// Predefined test scenarios for consistent testing
    public enum TestScenario {
        case highCompatibility
        case lowCompatibility
        case mixedResults
        case growthFocused
        case strengthsFocused
        
        var baseScore: Int {
            switch self {
            case .highCompatibility: return 85
            case .lowCompatibility: return 35
            case .mixedResults: return 65
            case .growthFocused: return 55
            case .strengthsFocused: return 80
            }
        }
        
        var seed: UInt64 {
            switch self {
            case .highCompatibility: return 11111
            case .lowCompatibility: return 22222
            case .mixedResults: return 33333
            case .growthFocused: return 44444
            case .strengthsFocused: return 55555
            }
        }
    }
    
    /// Generates result for a specific test scenario
    /// - Parameter scenario: The test scenario
    /// - Returns: Mock result for the scenario
    public static func generateScenarioResult(_ scenario: TestScenario) -> CompatibilityResult {
        return generateMockResult(seed: scenario.seed, baseScore: scenario.baseScore)
    }
    
    // MARK: - Verification Helpers
    
    /// Verifies that a compatibility result meets basic validation criteria
    /// - Parameter result: The result to validate
    /// - Returns: Validation result with any issues found
    public static func validateResult(_ result: CompatibilityResult) -> ValidationResult {
        var issues: [String] = []
        
        // Score validation
        if result.score < 0 || result.score > 100 {
            issues.append("Score \(result.score) is outside valid range (0-100)")
        }
        
        // Dimensions validation
        let dimensions = result.dimensions
        if dimensions.emotionalOpenness < 0 || dimensions.emotionalOpenness > 100 {
            issues.append("Emotional openness dimension out of range")
        }
        if dimensions.clarity < 0 || dimensions.clarity > 100 {
            issues.append("Clarity dimension out of range")
        }
        if dimensions.empathy < 0 || dimensions.empathy > 100 {
            issues.append("Empathy dimension out of range")
        }
        if dimensions.vulnerability < 0 || dimensions.vulnerability > 100 {
            issues.append("Vulnerability dimension out of range")
        }
        if dimensions.communicationStyle < 0 || dimensions.communicationStyle > 100 {
            issues.append("Communication style dimension out of range")
        }
        
        // Summary validation
        if result.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Summary is empty")
        }
        
        // Insights validation
        if result.insights.isEmpty {
            issues.append("No insights provided")
        }
        
        for insight in result.insights {
            if insight.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append("Insight has empty title")
            }
            if insight.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append("Insight has empty description")
            }
        }
        
        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    /// Compares two results for consistency in deterministic testing
    /// - Parameters:
    ///   - result1: First result
    ///   - result2: Second result
    /// - Returns: Comparison result
    public static func compareResults(_ result1: CompatibilityResult, _ result2: CompatibilityResult) -> ComparisonResult {
        var differences: [String] = []
        
        if result1.score != result2.score {
            differences.append("Scores differ: \(result1.score) vs \(result2.score)")
        }
        
        if result1.dimensions.emotionalOpenness != result2.dimensions.emotionalOpenness {
            differences.append("Emotional openness differs: \(result1.dimensions.emotionalOpenness) vs \(result2.dimensions.emotionalOpenness)")
        }
        
        if result1.dimensions.clarity != result2.dimensions.clarity {
            differences.append("Clarity differs: \(result1.dimensions.clarity) vs \(result2.dimensions.clarity)")
        }
        
        if result1.insights.count != result2.insights.count {
            differences.append("Insight counts differ: \(result1.insights.count) vs \(result2.insights.count)")
        }
        
        return ComparisonResult(isIdentical: differences.isEmpty, differences: differences)
    }
    
    // MARK: - Performance Testing Helpers
    
    /// Measures analysis performance
    /// - Parameter operation: The operation to measure
    /// - Returns: Performance metrics
    public static func measurePerformance<T>(_ operation: () async throws -> T) async -> PerformanceMetrics {
        let startTime = Date()
        let startMemory = getMemoryUsage()
        
        do {
            _ = try await operation()
            let endTime = Date()
            let endMemory = getMemoryUsage()
            
            return PerformanceMetrics(
                executionTime: endTime.timeIntervalSince(startTime),
                memoryDelta: endMemory - startMemory,
                success: true,
                error: nil
            )
        } catch {
            let endTime = Date()
            return PerformanceMetrics(
                executionTime: endTime.timeIntervalSince(startTime),
                memoryDelta: 0,
                success: false,
                error: error
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    private static func generateMockInsights(
        dimensions: CompatibilityDimensions,
        generator: inout SeededRandomGenerator
    ) -> [CompatibilityInsight] {
        var insights: [CompatibilityInsight] = []
        
        // Generate strength insight for highest dimension
        let strongest = dimensions.strongestDimension
        insights.append(CompatibilityInsight(
            type: .strength,
            title: "Strong \(strongest.name)",
            description: "Your \(strongest.name.lowercased()) is a notable strength in relationship communication.",
            confidence: strongest.score > 80 ? .high : .medium,
            relatedDimension: strongest.name
        ))
        
        // Generate growth insight for lowest dimension
        let growth = dimensions.growthArea
        if growth.score < 70 {
            insights.append(CompatibilityInsight(
                type: .growthArea,
                title: "Develop \(growth.name)",
                description: "Focus on improving your \(growth.name.lowercased()) to enhance relationship connections.",
                confidence: .medium,
                relatedDimension: growth.name
            ))
        }
        
        // Generate additional insights based on patterns
        if generator.nextInt(in: 0...1) == 1 {
            insights.append(CompatibilityInsight(
                type: .communicationPattern,
                title: "Communication Style",
                description: "Your communication approach shows consistent patterns that support relationship building.",
                confidence: .medium
            ))
        }
        
        return insights
    }
    
    private static func generateMockSummary(score: Int, generator: inout SeededRandomGenerator) -> String {
        let summaries = [
            "You demonstrate strong relationship communication skills with good emotional awareness.",
            "Your communication style shows maturity and thoughtfulness in relationship contexts.",
            "You exhibit balanced emotional intelligence with clear areas for continued growth.",
            "Your responses indicate healthy relationship readiness with room for development."
        ]
        
        let index = generator.nextInt(in: 0..<summaries.count)
        return summaries[index]
    }
    
    private static func generateMockTone(generator: inout SeededRandomGenerator) -> String {
        let tones = ["Thoughtful", "Confident", "Reflective", "Open", "Sincere", "Considerate"]
        let index = generator.nextInt(in: 0..<tones.count)
        return tones[index]
    }
    
    private static func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - Mock Implementations for Testing

/// Mock compatibility analyzer for testing
public class MockCompatibilityAnalyzer: CompatibilityAnalyzer {
    private let shouldFail: Bool
    private let delay: TimeInterval
    private let seed: UInt64
    
    public init(shouldFail: Bool = false, delay: TimeInterval = 0.1, seed: UInt64 = 12345) {
        self.shouldFail = shouldFail
        self.delay = delay
        self.seed = seed
    }
    
    public func analyzeResponse(_ request: AnalysisRequest) async throws -> CompatibilityResult {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldFail {
            throw CompatibilityAnalysisError.processingError("Mock analysis failure")
        }
        
        // Use seed from request if available, otherwise use instance seed
        let effectiveSeed = request.seed ?? seed
        return CompatibilityTestingUtilities.generateMockResult(seed: effectiveSeed)
    }
    
    public func compareResponses(
        user1Request: AnalysisRequest,
        user2Request: AnalysisRequest
    ) async throws -> ComparativeCompatibilityResult {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldFail {
            throw CompatibilityAnalysisError.processingError("Mock comparative analysis failure")
        }
        
        let result1 = try await analyzeResponse(user1Request)
        let result2 = try await analyzeResponse(user2Request)
        
        // Create mock comparative result
        let overallScore = (result1.score + result2.score) / 2
        let dimensionComparison = DimensionComparison(
            emotionalOpennessAlignment: AlignmentScore(score: 0.8, type: .harmony, description: "Similar levels"),
            clarityAlignment: AlignmentScore(score: 0.7, type: .complement, description: "Complementary"),
            empathyAlignment: AlignmentScore(score: 0.9, type: .harmony, description: "Very similar"),
            vulnerabilityAlignment: AlignmentScore(score: 0.6, type: .balance, description: "Balanced"),
            communicationStyleAlignment: AlignmentScore(score: 0.8, type: .harmony, description: "Compatible")
        )
        
        let synergy = CommunicationSynergy(
            synergyScore: 0.8,
            strengths: ["Clear communication", "Good empathy"],
            challenges: ["Different vulnerability levels"],
            recommendations: ["Practice sharing more personal experiences"]
        )
        
        return ComparativeCompatibilityResult(
            user1Result: result1,
            user2Result: result2,
            overallCompatibilityScore: overallScore,
            compatibilityInsights: [],
            dimensionComparison: dimensionComparison,
            communicationSynergy: synergy
        )
    }
    
    public func analyzeSession(_ responses: [CompatibilityResult]) async throws -> SessionAnalysis {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldFail {
            throw CompatibilityAnalysisError.processingError("Mock session analysis failure")
        }
        
        let scores = responses.map { $0.score }
        let overallScore = scores.reduce(0, +) / scores.count
        
        let trendAnalysis = TrendAnalysis(
            scoreProgression: scores,
            improvingDimensions: ["Clarity", "Empathy"],
            consistentStrengths: ["Communication Style"],
            developmentAreas: ["Vulnerability"],
            confidenceGrowth: 0.2
        )
        
        return SessionAnalysis(
            sessionId: UUID(),
            responses: responses,
            overallSessionScore: overallScore,
            trendAnalysis: trendAnalysis,
            categoryBreakdown: [:],
            sessionInsights: []
        )
    }
}

// MARK: - Seeded Random Generator

/// Deterministic random number generator for testing
public struct SeededRandomGenerator {
    private var state: UInt64
    
    public init(seed: UInt64) {
        self.state = seed
    }
    
    public mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
    
    public mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let value = next()
        let rangeSize = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(value % rangeSize)
    }
    
    public mutating func nextDouble() -> Double {
        return Double(next()) / Double(UInt64.max)
    }
}

// MARK: - Testing Result Types

/// Result of compatibility analysis validation
public struct ValidationResult {
    public let isValid: Bool
    public let issues: [String]
    
    public init(isValid: Bool, issues: [String]) {
        self.isValid = isValid
        self.issues = issues
    }
}

/// Result of comparing two compatibility results
public struct ComparisonResult {
    public let isIdentical: Bool
    public let differences: [String]
    
    public init(isIdentical: Bool, differences: [String]) {
        self.isIdentical = isIdentical
        self.differences = differences
    }
}

/// Performance metrics for analysis operations
public struct PerformanceMetrics {
    public let executionTime: TimeInterval
    public let memoryDelta: UInt64
    public let success: Bool
    public let error: Error?
    
    public init(executionTime: TimeInterval, memoryDelta: UInt64, success: Bool, error: Error?) {
        self.executionTime = executionTime
        self.memoryDelta = memoryDelta
        self.success = success
        self.error = error
    }
}