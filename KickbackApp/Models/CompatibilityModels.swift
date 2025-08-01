import Foundation

// MARK: - Core Compatibility Analysis Models

/// Comprehensive result of compatibility analysis for a single response
public struct CompatibilityResult: Codable, Identifiable {
    public let id: UUID
    public let score: Int  // 0-100 compatibility score
    public let summary: String  // Natural language summary of insights
    public let tone: String  // Overall emotional tone detected
    public let dimensions: CompatibilityDimensions  // Detailed scoring across key areas
    public let insights: [CompatibilityInsight]  // Specific insights and observations
    public let analysisMetadata: AnalysisMetadata  // Processing information
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        score: Int,
        summary: String,
        tone: String,
        dimensions: CompatibilityDimensions,
        insights: [CompatibilityInsight],
        analysisMetadata: AnalysisMetadata,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.score = score
        self.summary = summary
        self.tone = tone
        self.dimensions = dimensions
        self.insights = insights
        self.analysisMetadata = analysisMetadata
        self.createdAt = createdAt
    }
}

/// Five key dimensions of compatibility analysis
public struct CompatibilityDimensions: Codable {
    public let emotionalOpenness: Int  // 0-100: Willingness to share feelings
    public let clarity: Int  // 0-100: Clear self-expression
    public let empathy: Int  // 0-100: Understanding others' perspectives
    public let vulnerability: Int  // 0-100: Authentic self-disclosure
    public let communicationStyle: Int  // 0-100: How effectively they express themselves
    
    public init(
        emotionalOpenness: Int,
        clarity: Int,
        empathy: Int,
        vulnerability: Int,
        communicationStyle: Int
    ) {
        self.emotionalOpenness = emotionalOpenness
        self.clarity = clarity
        self.empathy = empathy
        self.vulnerability = vulnerability
        self.communicationStyle = communicationStyle
    }
    
    /// Computed average score across all dimensions
    public var averageScore: Int {
        return (emotionalOpenness + clarity + empathy + vulnerability + communicationStyle) / 5
    }
    
    /// Returns the strongest dimension
    public var strongestDimension: (name: String, score: Int) {
        let dimensions = [
            ("Emotional Openness", emotionalOpenness),
            ("Clarity", clarity),
            ("Empathy", empathy),
            ("Vulnerability", vulnerability),
            ("Communication Style", communicationStyle)
        ]
        return dimensions.max { $0.1 < $1.1 } ?? ("", 0)
    }
    
    /// Returns the dimension needing most growth
    public var growthArea: (name: String, score: Int) {
        let dimensions = [
            ("Emotional Openness", emotionalOpenness),
            ("Clarity", clarity),
            ("Empathy", empathy),
            ("Vulnerability", vulnerability),
            ("Communication Style", communicationStyle)
        ]
        return dimensions.min { $0.1 < $1.1 } ?? ("", 0)
    }
}

/// Specific insight about communication patterns or relationship readiness
public struct CompatibilityInsight: Codable, Identifiable {
    public let id: UUID
    public let type: InsightType
    public let title: String
    public let description: String
    public let confidence: InsightConfidence
    public let relatedDimension: String?
    
    public init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        description: String,
        confidence: InsightConfidence,
        relatedDimension: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.relatedDimension = relatedDimension
    }
}

/// Types of insights that can be generated
public enum InsightType: String, Codable, CaseIterable {
    case strength = "strength"
    case growthArea = "growth_area"
    case communicationPattern = "communication_pattern"
    case emotionalIntelligence = "emotional_intelligence"
    case relationshipReadiness = "relationship_readiness"
    case compatibility = "compatibility"
    
    public var displayName: String {
        switch self {
        case .strength:
            return "Strength"
        case .growthArea:
            return "Growth Area"
        case .communicationPattern:
            return "Communication Pattern"
        case .emotionalIntelligence:
            return "Emotional Intelligence"
        case .relationshipReadiness:
            return "Relationship Readiness"
        case .compatibility:
            return "Compatibility"
        }
    }
}

/// Confidence level for insights
public enum InsightConfidence: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
    
    public var displayName: String {
        switch self {
        case .low:
            return "Low Confidence"
        case .medium:
            return "Medium Confidence"
        case .high:
            return "High Confidence"
        case .veryHigh:
            return "Very High Confidence"
        }
    }
    
    public var numericValue: Double {
        switch self {
        case .low:
            return 0.25
        case .medium:
            return 0.5
        case .high:
            return 0.75
        case .veryHigh:
            return 1.0
        }
    }
}

/// Metadata about the analysis process
public struct AnalysisMetadata: Codable {
    public let promptUsed: String
    public let rawLLMResponse: String
    public let processingDuration: TimeInterval
    public let modelVersion: String
    public let analysisType: AnalysisType
    public let questionCategory: QuestionCategory
    public let responseLength: Int
    public let seed: UInt64?  // For deterministic testing
    
    public init(
        promptUsed: String,
        rawLLMResponse: String,
        processingDuration: TimeInterval,
        modelVersion: String = "OpenELM-3B",
        analysisType: AnalysisType,
        questionCategory: QuestionCategory,
        responseLength: Int,
        seed: UInt64? = nil
    ) {
        self.promptUsed = promptUsed
        self.rawLLMResponse = rawLLMResponse
        self.processingDuration = processingDuration
        self.modelVersion = modelVersion
        self.analysisType = analysisType
        self.questionCategory = questionCategory
        self.responseLength = responseLength
        self.seed = seed
    }
}

/// Types of compatibility analysis
public enum AnalysisType: String, Codable, CaseIterable {
    case individual = "individual"
    case comparative = "comparative"
    case sessionBased = "session_based"
    case categorySpecific = "category_specific"
    
    public var displayName: String {
        switch self {
        case .individual:
            return "Individual Response Analysis"
        case .comparative:
            return "Compatibility Comparison"
        case .sessionBased:
            return "Session Insights"
        case .categorySpecific:
            return "Category-Specific Analysis"
        }
    }
}

// MARK: - Analysis Request Models

/// Request for analyzing a single transcribed response
public struct AnalysisRequest {
    public let transcribedResponse: String
    public let question: String
    public let questionCategory: QuestionCategory
    public let userContext: UserContext?
    public let analysisType: AnalysisType
    public let seed: UInt64?  // For deterministic testing
    
    public init(
        transcribedResponse: String,
        question: String,
        questionCategory: QuestionCategory,
        userContext: UserContext? = nil,
        analysisType: AnalysisType = .individual,
        seed: UInt64? = nil
    ) {
        self.transcribedResponse = transcribedResponse
        self.question = question
        self.questionCategory = questionCategory
        self.userContext = userContext
        self.analysisType = analysisType
        self.seed = seed
    }
}

/// User context for personalized analysis
public struct UserContext: Codable {
    public let age: Int?
    public let relationshipStage: RelationshipStage?
    public let previousAnalyses: [UUID]
    public let preferences: AnalysisPreferences?
    
    public init(
        age: Int? = nil,
        relationshipStage: RelationshipStage? = nil,
        previousAnalyses: [UUID] = [],
        preferences: AnalysisPreferences? = nil
    ) {
        self.age = age
        self.relationshipStage = relationshipStage
        self.previousAnalyses = previousAnalyses
        self.preferences = preferences
    }
}

/// Analysis preferences for customizing insights
public struct AnalysisPreferences: Codable {
    public let focusAreas: [InsightType]
    public let detailLevel: DetailLevel
    public let includeGrowthSuggestions: Bool
    public let culturalContext: String?
    
    public init(
        focusAreas: [InsightType] = InsightType.allCases,
        detailLevel: DetailLevel = .medium,
        includeGrowthSuggestions: Bool = true,
        culturalContext: String? = nil
    ) {
        self.focusAreas = focusAreas
        self.detailLevel = detailLevel
        self.includeGrowthSuggestions = includeGrowthSuggestions
        self.culturalContext = culturalContext
    }
}

/// Level of detail for analysis results
public enum DetailLevel: String, Codable, CaseIterable {
    case minimal = "minimal"
    case medium = "medium"
    case comprehensive = "comprehensive"
    
    public var displayName: String {
        switch self {
        case .minimal:
            return "Quick Overview"
        case .medium:
            return "Standard Analysis"
        case .comprehensive:
            return "Detailed Insights"
        }
    }
}

// MARK: - Comparative Analysis Models

/// Result of comparing two users' compatibility
public struct ComparativeCompatibilityResult: Codable, Identifiable {
    public let id: UUID
    public let user1Result: CompatibilityResult
    public let user2Result: CompatibilityResult
    public let overallCompatibilityScore: Int  // 0-100
    public let compatibilityInsights: [CompatibilityInsight]
    public let dimensionComparison: DimensionComparison
    public let communicationSynergy: CommunicationSynergy
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        user1Result: CompatibilityResult,
        user2Result: CompatibilityResult,
        overallCompatibilityScore: Int,
        compatibilityInsights: [CompatibilityInsight],
        dimensionComparison: DimensionComparison,
        communicationSynergy: CommunicationSynergy,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.user1Result = user1Result
        self.user2Result = user2Result
        self.overallCompatibilityScore = overallCompatibilityScore
        self.compatibilityInsights = compatibilityInsights
        self.dimensionComparison = dimensionComparison
        self.communicationSynergy = communicationSynergy
        self.createdAt = createdAt
    }
}

/// Comparison of compatibility dimensions between two users
public struct DimensionComparison: Codable {
    public let emotionalOpennessAlignment: AlignmentScore
    public let clarityAlignment: AlignmentScore
    public let empathyAlignment: AlignmentScore
    public let vulnerabilityAlignment: AlignmentScore
    public let communicationStyleAlignment: AlignmentScore
    
    public init(
        emotionalOpennessAlignment: AlignmentScore,
        clarityAlignment: AlignmentScore,
        empathyAlignment: AlignmentScore,
        vulnerabilityAlignment: AlignmentScore,
        communicationStyleAlignment: AlignmentScore
    ) {
        self.emotionalOpennessAlignment = emotionalOpennessAlignment
        self.clarityAlignment = clarityAlignment
        self.empathyAlignment = empathyAlignment
        self.vulnerabilityAlignment = vulnerabilityAlignment
        self.communicationStyleAlignment = communicationStyleAlignment
    }
    
    /// Average alignment across all dimensions
    public var overallAlignment: Double {
        let alignments = [
            emotionalOpennessAlignment.score,
            clarityAlignment.score,
            empathyAlignment.score,
            vulnerabilityAlignment.score,
            communicationStyleAlignment.score
        ]
        return alignments.reduce(0, +) / Double(alignments.count)
    }
}

/// Alignment score between two users on a specific dimension
public struct AlignmentScore: Codable {
    public let score: Double  // 0.0 - 1.0
    public let type: AlignmentType
    public let description: String
    
    public init(score: Double, type: AlignmentType, description: String) {
        self.score = score
        self.type = type
        self.description = description
    }
}

/// Types of alignment between users
public enum AlignmentType: String, Codable, CaseIterable {
    case complement = "complement"  // Different but complementary
    case harmony = "harmony"        // Similar levels
    case contrast = "contrast"      // Significant differences
    case balance = "balance"        // One strong, one developing
    
    public var displayName: String {
        switch self {
        case .complement:
            return "Complementary"
        case .harmony:
            return "Harmonious"
        case .contrast:
            return "Contrasting"
        case .balance:
            return "Balanced"
        }
    }
}

/// Analysis of communication synergy between users
public struct CommunicationSynergy: Codable {
    public let synergyScore: Double  // 0.0 - 1.0
    public let strengths: [String]
    public let challenges: [String]
    public let recommendations: [String]
    
    public init(
        synergyScore: Double,
        strengths: [String],
        challenges: [String],
        recommendations: [String]
    ) {
        self.synergyScore = synergyScore
        self.strengths = strengths
        self.challenges = challenges
        self.recommendations = recommendations
    }
}

// MARK: - Session Analysis Models

/// Analysis results for a complete question session
public struct SessionAnalysis: Codable, Identifiable {
    public let id: UUID
    public let sessionId: UUID
    public let responses: [CompatibilityResult]
    public let overallSessionScore: Int
    public let trendAnalysis: TrendAnalysis
    public let categoryBreakdown: [QuestionCategory: Int]
    public let sessionInsights: [CompatibilityInsight]
    public let completedAt: Date
    
    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        responses: [CompatibilityResult],
        overallSessionScore: Int,
        trendAnalysis: TrendAnalysis,
        categoryBreakdown: [QuestionCategory: Int],
        sessionInsights: [CompatibilityInsight],
        completedAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.responses = responses
        self.overallSessionScore = overallSessionScore
        self.trendAnalysis = trendAnalysis
        self.categoryBreakdown = categoryBreakdown
        self.sessionInsights = sessionInsights
        self.completedAt = completedAt
    }
}

/// Analysis of trends across multiple responses in a session
public struct TrendAnalysis: Codable {
    public let scoreProgression: [Int]
    public let improvingDimensions: [String]
    public let consistentStrengths: [String]
    public let developmentAreas: [String]
    public let confidenceGrowth: Double
    
    public init(
        scoreProgression: [Int],
        improvingDimensions: [String],
        consistentStrengths: [String],
        developmentAreas: [String],
        confidenceGrowth: Double
    ) {
        self.scoreProgression = scoreProgression
        self.improvingDimensions = improvingDimensions
        self.consistentStrengths = consistentStrengths
        self.developmentAreas = developmentAreas
        self.confidenceGrowth = confidenceGrowth
    }
}

// MARK: - Error Types

/// Errors that can occur during compatibility analysis
public enum CompatibilityAnalysisError: LocalizedError {
    case invalidResponse(String)
    case analysisTimeout(String)
    case llmServiceError(LLMServiceError)
    case insufficientData(String)
    case processingError(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .analysisTimeout(let message):
            return "Analysis Timeout: \(message)"
        case .llmServiceError(let llmError):
            return "LLM Service Error: \(llmError.localizedDescription)"
        case .insufficientData(let message):
            return "Insufficient Data: \(message)"
        case .processingError(let message):
            return "Processing Error: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidResponse:
            return "The response could not be analyzed for compatibility insights"
        case .analysisTimeout:
            return "The analysis took too long to complete"
        case .llmServiceError:
            return "The language model service encountered an error"
        case .insufficientData:
            return "Not enough data to perform meaningful analysis"
        case .processingError:
            return "An error occurred while processing the analysis"
        case .configurationError:
            return "The analysis configuration is invalid"
        }
    }
}