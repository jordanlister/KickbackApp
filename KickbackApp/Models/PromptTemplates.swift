import Foundation

// MARK: - Prompt Template System

/// Protocol for prompt template providers
public protocol PromptTemplateProvider {
    func template(for category: QuestionCategory) -> String
    func variables(for configuration: QuestionConfiguration) -> [String: String]
}

/// Comprehensive prompt template system for generating relationship questions
/// Uses variable substitution to create contextually appropriate prompts
public struct QuestionPromptTemplates: PromptTemplateProvider {
    
    public init() {}
    
    // MARK: - Template Variables
    
    /// Available template variables for substitution
    public enum TemplateVariable: String, CaseIterable {
        case category = "{{category}}"
        case relationshipStage = "{{relationship_stage}}"
        case tone = "{{tone}}"
        case complexity = "{{complexity}}"
        case duration = "{{duration}}"
        case previousTopics = "{{previous_topics}}"
        case contextualHints = "{{contextual_hints}}"
        case avoidanceGuidance = "{{avoidance_guidance}}"
        case formatInstructions = "{{format_instructions}}"
    }
    
    // MARK: - Core Templates
    
    public func template(for category: QuestionCategory) -> String {
        switch category {
        case .blindDate:
            return blindDateTemplate
        case .firstDate:
            return firstDateTemplate
        case .earlyDating:
            return earlyDatingTemplate
        case .deepCouple:
            return deepCoupleTemplate
        case .longTermRelationship:
            return longTermRelationshipTemplate
        case .conflictResolution:
            return conflictResolutionTemplate
        case .loveLanguageDiscovery:
            return loveLanguageDiscoveryTemplate
        case .intimacyBuilding:
            return intimacyBuildingTemplate
        case .futureVisions:
            return futureVisionsTemplate
        case .personalGrowth:
            return personalGrowthTemplate
        case .vulnerabilitySharing:
            return vulnerabilitySharingTemplate
        case .funAndPlayful:
            return funAndPlayfulTemplate
        case .valuesAlignment:
            return valuesAlignmentTemplate
        case .emotionalIntelligence:
            return emotionalIntelligenceTemplate
        case .lifeTransitions:
            return lifeTransitionsTemplate
        }
    }
    
    public func variables(for configuration: QuestionConfiguration) -> [String: String] {
        var variables: [String: String] = [:]
        
        variables[TemplateVariable.category.rawValue] = configuration.category.displayName
        variables[TemplateVariable.relationshipStage.rawValue] = configuration.category.relationshipStage.displayName
        variables[TemplateVariable.tone.rawValue] = configuration.effectiveTone.displayName
        variables[TemplateVariable.complexity.rawValue] = configuration.effectiveComplexity.displayName
        
        // Duration context
        if let duration = configuration.relationshipDuration {
            variables[TemplateVariable.duration.rawValue] = formatDuration(duration)
        } else {
            variables[TemplateVariable.duration.rawValue] = "unspecified duration"
        }
        
        // Previous topics to avoid repetition
        if !configuration.previousTopics.isEmpty {
            variables[TemplateVariable.previousTopics.rawValue] = "Avoid these previously covered topics: " + configuration.previousTopics.joined(separator: ", ")
        } else {
            variables[TemplateVariable.previousTopics.rawValue] = ""
        }
        
        // Contextual hints for personalization
        if !configuration.contextualHints.isEmpty {
            variables[TemplateVariable.contextualHints.rawValue] = "Consider these contextual hints: " + configuration.contextualHints.joined(separator: ", ")
        } else {
            variables[TemplateVariable.contextualHints.rawValue] = ""
        }
        
        // Avoidance guidance
        variables[TemplateVariable.avoidanceGuidance.rawValue] = avoidanceGuidance(for: configuration.category)
        
        // Format instructions
        variables[TemplateVariable.formatInstructions.rawValue] = formatInstructions
        
        return variables
    }
    
    // MARK: - Individual Templates
    
    private var blindDateTemplate: String {
        """
        You are an expert relationship coach helping people connect on their first meeting. Generate a thoughtful conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create a question that helps people discover compatibility and shared interests
        - Keep it appropriate for people who are just meeting
        - Focus on positive, engaging topics that reveal personality
        - Avoid overly personal or intimate subjects
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var firstDateTemplate: String {
        """
        You are an expert relationship coach helping couples navigate their first formal date. Generate a meaningful conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create a question that deepens understanding while maintaining appropriate boundaries
        - Focus on values, interests, and life perspectives
        - Encourage storytelling and sharing experiences
        - Balance curiosity with respect for privacy
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var earlyDatingTemplate: String {
        """
        You are an expert relationship coach guiding couples in the early dating phase. Generate an engaging conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that explore compatibility and build emotional connection
        - Focus on understanding each other's perspectives and experiences
        - Encourage vulnerability within appropriate boundaries
        - Help identify shared values and complementary differences
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var deepCoupleTemplate: String {
        """
        You are an expert relationship coach helping established couples deepen their connection. Generate a profound conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that explore deep emotional territories and intimate thoughts
        - Focus on understanding each other's inner worlds and evolving perspectives
        - Encourage vulnerability, empathy, and emotional intimacy
        - Help partners discover new facets of each other
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var longTermRelationshipTemplate: String {
        """
        You are an expert relationship coach supporting long-term partners in maintaining connection and growth. Generate a meaningful conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that reignite curiosity and rediscover each other
        - Focus on growth, change, and evolving dreams
        - Address the depth that comes with sustained partnership
        - Help partners see each other with fresh eyes
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var conflictResolutionTemplate: String {
        """
        You are an expert relationship coach helping couples navigate disagreements constructively. Generate a supportive conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that promote understanding and empathy
        - Focus on perspective-sharing and finding common ground
        - Encourage respectful dialogue about differences
        - Help partners understand each other's needs and triggers
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var loveLanguageDiscoveryTemplate: String {
        """
        You are an expert relationship coach helping couples understand how they give and receive love. Generate an insightful conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that explore how partners express and interpret love
        - Focus on understanding different ways of showing care and affection
        - Help identify what makes each person feel most loved and appreciated
        - Encourage discovery of both giving and receiving preferences
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var intimacyBuildingTemplate: String {
        """
        You are an expert relationship coach helping couples build deeper emotional and physical intimacy. Generate a tender conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that foster emotional and physical closeness
        - Focus on desires, boundaries, and intimate connection
        - Encourage vulnerability and trust-building
        - Help partners communicate their needs and fantasies appropriately
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var futureVisionsTemplate: String {
        """
        You are an expert relationship coach helping couples align their dreams and future plans. Generate a forward-thinking conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that explore shared dreams and individual aspirations
        - Focus on life goals, values, and vision alignment
        - Encourage discussion of both practical and aspirational futures
        - Help partners understand each other's priorities and timeline
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var personalGrowthTemplate: String {
        """
        You are an expert relationship coach helping individuals and couples pursue personal development together. Generate a growth-oriented conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that encourage self-reflection and growth
        - Focus on personal development, learning, and evolution
        - Help partners support each other's individual journeys
        - Encourage sharing of insights and growth experiences
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var vulnerabilitySharingTemplate: String {
        """
        You are an expert relationship coach helping couples share vulnerable parts of themselves safely. Generate a compassionate conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that invite appropriate vulnerability and openness
        - Focus on creating safe spaces for sharing fears, hopes, and struggles
        - Encourage empathy and non-judgmental listening
        - Help partners build trust through authentic sharing
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var funAndPlayfulTemplate: String {
        """
        You are an expert relationship coach helping couples maintain joy and playfulness in their connection. Generate a fun, engaging conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that spark laughter, creativity, and lighthearted connection
        - Focus on imagination, humor, and shared enjoyment
        - Encourage playful exploration of preferences and fantasies
        - Help partners rediscover their sense of fun together
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var valuesAlignmentTemplate: String {
        """
        You are an expert relationship coach helping couples explore their core values and beliefs. Generate a meaningful conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that explore fundamental beliefs and principles
        - Focus on understanding what matters most to each person
        - Encourage respectful discussion of differences and similarities
        - Help partners find common ground while respecting individuality
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var emotionalIntelligenceTemplate: String {
        """
        You are an expert relationship coach helping couples develop emotional awareness and intelligence. Generate an insightful conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that enhance emotional awareness and understanding
        - Focus on feelings, emotional patterns, and triggers
        - Encourage empathy and emotional validation
        - Help partners develop better emotional communication skills
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    private var lifeTransitionsTemplate: String {
        """
        You are an expert relationship coach helping couples navigate major life changes together. Generate a supportive conversation question for a {{category}} scenario.
        
        Context:
        - Relationship Stage: {{relationship_stage}}
        - Desired Tone: {{tone}}
        - Complexity Level: {{complexity}}
        - Duration Context: {{duration}}
        
        {{previous_topics}}
        {{contextual_hints}}
        
        Guidelines:
        - Create questions that address adaptation and change
        - Focus on how transitions affect the relationship
        - Encourage mutual support during challenging times
        - Help partners navigate uncertainty and growth together
        {{avoidance_guidance}}
        
        {{format_instructions}}
        """
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let days = Int(duration / 86400)
        let months = days / 30
        let years = months / 12
        
        if years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else {
            return "new relationship"
        }
    }
    
    private func avoidanceGuidance(for category: QuestionCategory) -> String {
        let commonAvoidance = "- Avoid generic, cliché, or overly obvious questions\n- Don't ask questions that can be answered with simple yes/no responses\n- Avoid topics that might be triggering or inappropriate for the relationship stage"
        
        switch category {
        case .blindDate, .firstDate:
            return commonAvoidance + "\n- Avoid deeply personal or intimate topics\n- Don't ask about past relationships or sexual history"
        case .conflictResolution:
            return commonAvoidance + "\n- Avoid blame-focused or accusatory language\n- Don't suggest taking sides in disagreements"
        case .intimacyBuilding:
            return commonAvoidance + "\n- Ensure questions are appropriate for the relationship stage\n- Respect boundaries around physical and emotional intimacy"
        default:
            return commonAvoidance
        }
    }
    
    private var formatInstructions: String {
        """
        Format Requirements:
        - Generate exactly ONE thoughtful, open-ended question
        - Ensure the question is clear, engaging, and appropriate for the context
        - Make it conversational and natural, not clinical or therapeutic
        - End with a question mark
        - Keep it concise but meaningful (1-2 sentences maximum)
        - Avoid using quotation marks around the question
        """
    }
}

// MARK: - Template Processing

/// Utility class for processing prompt templates with variable substitution
public struct PromptProcessor {
    private let templateProvider: PromptTemplateProvider
    
    public init() {
        self.init(templateProvider: QuestionPromptTemplates())
    }
    
    public init(templateProvider: PromptTemplateProvider) {
        self.templateProvider = templateProvider
    }
    
    /// Processes a template by substituting variables with actual values
    public func processTemplate(for configuration: QuestionConfiguration) -> String {
        let template = templateProvider.template(for: configuration.category)
        let variables = templateProvider.variables(for: configuration)
        
        var processedTemplate = template
        
        // Substitute all variables
        for (variable, value) in variables {
            processedTemplate = processedTemplate.replacingOccurrences(of: variable, with: value)
        }
        
        // Clean up any remaining empty variable placeholders
        processedTemplate = cleanupTemplate(processedTemplate)
        
        return processedTemplate
    }
    
    private func cleanupTemplate(_ template: String) -> String {
        // Remove lines that contain only whitespace after variable substitution
        let lines = template.components(separatedBy: .newlines)
        let cleanedLines = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : line
        }
        
        // Join lines and clean up excessive whitespace
        return cleanedLines
            .joined(separator: "\n")
            .replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}