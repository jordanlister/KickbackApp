import Foundation

// MARK: - Question Category Definitions

/// Comprehensive categories for relationship-focused conversation questions
/// Each category targets specific relationship stages and conversation depths
public enum QuestionCategory: String, CaseIterable, Codable {
    case blindDate = "blind_date"
    case firstDate = "first_date"
    case earlyDating = "early_dating"
    case deepCouple = "deep_couple"
    case longTermRelationship = "long_term_relationship"
    case conflictResolution = "conflict_resolution"
    case loveLanguageDiscovery = "love_language_discovery"
    case intimacyBuilding = "intimacy_building"
    case futureVisions = "future_visions"
    case personalGrowth = "personal_growth"
    case vulnerabilitySharing = "vulnerability_sharing"
    case funAndPlayful = "fun_and_playful"
    case valuesAlignment = "values_alignment"
    case emotionalIntelligence = "emotional_intelligence"
    case lifeTransitions = "life_transitions"
    
    /// Human-readable display name for the category
    public var displayName: String {
        switch self {
        case .blindDate:
            return "Blind Date"
        case .firstDate:
            return "First Date"
        case .earlyDating:
            return "Early Dating"
        case .deepCouple:
            return "Deep Couple"
        case .longTermRelationship:
            return "Long-term Relationship"
        case .conflictResolution:
            return "Conflict Resolution"
        case .loveLanguageDiscovery:
            return "Love Language Discovery"
        case .intimacyBuilding:
            return "Intimacy Building"
        case .futureVisions:
            return "Future Visions"
        case .personalGrowth:
            return "Personal Growth"
        case .vulnerabilitySharing:
            return "Vulnerability Sharing"
        case .funAndPlayful:
            return "Fun & Playful"
        case .valuesAlignment:
            return "Values Alignment"
        case .emotionalIntelligence:
            return "Emotional Intelligence"
        case .lifeTransitions:
            return "Life Transitions"
        }
    }
    
    /// Recommended relationship stage for this category
    public var relationshipStage: RelationshipStage {
        switch self {
        case .blindDate, .firstDate:
            return .meeting
        case .earlyDating, .funAndPlayful:
            return .dating
        case .deepCouple, .intimacyBuilding, .vulnerabilitySharing:
            return .serious
        case .longTermRelationship, .futureVisions, .lifeTransitions:
            return .committed
        case .conflictResolution, .loveLanguageDiscovery, .valuesAlignment, .emotionalIntelligence, .personalGrowth:
            return .any
        }
    }
    
    /// Emotional complexity level of questions in this category
    public var complexityLevel: ComplexityLevel {
        switch self {
        case .blindDate, .firstDate, .funAndPlayful:
            return .light
        case .earlyDating, .personalGrowth, .loveLanguageDiscovery:
            return .medium
        case .deepCouple, .intimacyBuilding, .vulnerabilitySharing, .conflictResolution, .valuesAlignment, .emotionalIntelligence:
            return .deep
        case .longTermRelationship, .futureVisions, .lifeTransitions:
            return .profound
        }
    }
}

// MARK: - Supporting Enums

/// Relationship stage indicators for context-appropriate question generation
public enum RelationshipStage: String, CaseIterable, Codable {
    case meeting = "meeting"
    case dating = "dating"
    case serious = "serious"
    case committed = "committed"
    case any = "any"
    
    public var displayName: String {
        switch self {
        case .meeting:
            return "First Meeting"
        case .dating:
            return "Dating"
        case .serious:
            return "Serious Relationship"
        case .committed:
            return "Committed Partnership"
        case .any:
            return "Any Stage"
        }
    }
}

/// Complexity levels for question depth and emotional intensity
public enum ComplexityLevel: String, CaseIterable, Codable {
    case light = "light"
    case medium = "medium"
    case deep = "deep"
    case profound = "profound"
    
    public var displayName: String {
        switch self {
        case .light:
            return "Light & Easy"
        case .medium:
            return "Moderate Depth"
        case .deep:
            return "Deep & Meaningful"
        case .profound:
            return "Profound & Transformative"
        }
    }
}

/// Tone variations for question delivery and style
public enum QuestionTone: String, CaseIterable, Codable {
    case curious = "curious"
    case playful = "playful"
    case thoughtful = "thoughtful"
    case vulnerable = "vulnerable"
    case supportive = "supportive"
    case exploratory = "exploratory"
    case intimate = "intimate"
    case reflective = "reflective"
    
    public var displayName: String {
        switch self {
        case .curious:
            return "Curious & Inquisitive"
        case .playful:
            return "Playful & Light"
        case .thoughtful:
            return "Thoughtful & Considerate"
        case .vulnerable:
            return "Vulnerable & Open"
        case .supportive:
            return "Supportive & Caring"
        case .exploratory:
            return "Exploratory & Discovery-focused"
        case .intimate:
            return "Intimate & Connected"
        case .reflective:
            return "Reflective & Introspective"
        }
    }
}

// MARK: - Question Configuration

/// Configuration object for customizing question generation
public struct QuestionConfiguration {
    public let category: QuestionCategory
    public let tone: QuestionTone?
    public let customComplexity: ComplexityLevel?
    public let relationshipDuration: TimeInterval?
    public let previousTopics: [String]
    public let contextualHints: [String]
    
    public init(
        category: QuestionCategory,
        tone: QuestionTone? = nil,
        customComplexity: ComplexityLevel? = nil,
        relationshipDuration: TimeInterval? = nil,
        previousTopics: [String] = [],
        contextualHints: [String] = []
    ) {
        self.category = category
        self.tone = tone
        self.customComplexity = customComplexity
        self.relationshipDuration = relationshipDuration
        self.previousTopics = previousTopics
        self.contextualHints = contextualHints
    }
    
    /// Computed property for effective complexity level
    public var effectiveComplexity: ComplexityLevel {
        return customComplexity ?? category.complexityLevel
    }
    
    /// Computed property for effective tone
    public var effectiveTone: QuestionTone {
        return tone ?? defaultToneForCategory()
    }
    
    private func defaultToneForCategory() -> QuestionTone {
        switch category {
        case .blindDate, .firstDate:
            return .curious
        case .funAndPlayful:
            return .playful
        case .deepCouple, .intimacyBuilding:
            return .intimate
        case .vulnerabilitySharing:
            return .vulnerable
        case .conflictResolution:
            return .supportive
        case .personalGrowth, .emotionalIntelligence:
            return .reflective
        default:
            return .thoughtful
        }
    }
}

// MARK: - Question Result

/// Result container for generated questions with metadata
public struct QuestionResult {
    public let question: String
    public let category: QuestionCategory
    public let configuration: QuestionConfiguration
    public let generatedAt: Date
    public let processingMetadata: ProcessingMetadata
    
    public init(
        question: String,
        category: QuestionCategory,
        configuration: QuestionConfiguration,
        generatedAt: Date = Date(),
        processingMetadata: ProcessingMetadata
    ) {
        self.question = question
        self.category = category
        self.configuration = configuration
        self.generatedAt = generatedAt
        self.processingMetadata = processingMetadata
    }
}

/// Metadata about the question generation process
public struct ProcessingMetadata {
    public let promptUsed: String
    public let rawLLMResponse: String
    public let processingDuration: TimeInterval
    public let sanitizationApplied: [String]
    
    public init(
        promptUsed: String,
        rawLLMResponse: String,
        processingDuration: TimeInterval,
        sanitizationApplied: [String] = []
    ) {
        self.promptUsed = promptUsed
        self.rawLLMResponse = rawLLMResponse
        self.processingDuration = processingDuration
        self.sanitizationApplied = sanitizationApplied
    }
}