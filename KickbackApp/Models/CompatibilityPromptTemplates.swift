import Foundation

// MARK: - Compatibility Analysis Prompt Templates

/// Protocol for compatibility analysis prompt template providers
public protocol CompatibilityPromptTemplateProvider {
    func template(for analysisType: AnalysisType) -> String
    func variables(for request: AnalysisRequest) -> [String: String]
}

/// Comprehensive prompt template system for compatibility analysis
/// Uses variable substitution to create contextually appropriate analysis prompts
public struct CompatibilityPromptTemplates: CompatibilityPromptTemplateProvider {
    
    public init() {}
    
    // MARK: - Template Variables
    
    /// Available template variables for substitution
    public enum TemplateVariable: String, CaseIterable {
        case question = "{{question}}"
        case response = "{{response}}"
        case questionCategory = "{{question_category}}"
        case responseLength = "{{response_length}}"
        case analysisType = "{{analysis_type}}"
        case userContext = "{{user_context}}"
        case focusAreas = "{{focus_areas}}"
        case detailLevel = "{{detail_level}}"
        case culturalContext = "{{cultural_context}}"
        case formatInstructions = "{{format_instructions}}"
        case seedInstruction = "{{seed_instruction}}"
    }
    
    // MARK: - Core Templates
    
    public func template(for analysisType: AnalysisType) -> String {
        switch analysisType {
        case .individual:
            return individualAnalysisTemplate
        case .comparative:
            return comparativeAnalysisTemplate
        case .sessionBased:
            return sessionBasedAnalysisTemplate
        case .categorySpecific:
            return categorySpecificAnalysisTemplate
        }
    }
    
    public func variables(for request: AnalysisRequest) -> [String: String] {
        var variables: [String: String] = [:]
        
        variables[TemplateVariable.question.rawValue] = request.question
        variables[TemplateVariable.response.rawValue] = request.transcribedResponse
        variables[TemplateVariable.questionCategory.rawValue] = request.questionCategory.displayName
        variables[TemplateVariable.responseLength.rawValue] = "\(request.transcribedResponse.count) characters"
        variables[TemplateVariable.analysisType.rawValue] = request.analysisType.displayName
        
        // User context
        if let context = request.userContext {
            variables[TemplateVariable.userContext.rawValue] = formatUserContext(context)
        } else {
            variables[TemplateVariable.userContext.rawValue] = "No specific user context provided"
        }
        
        // Focus areas
        if let preferences = request.userContext?.preferences {
            variables[TemplateVariable.focusAreas.rawValue] = formatFocusAreas(preferences.focusAreas)
            variables[TemplateVariable.detailLevel.rawValue] = preferences.detailLevel.displayName
            variables[TemplateVariable.culturalContext.rawValue] = preferences.culturalContext ?? "General cultural context"
        } else {
            variables[TemplateVariable.focusAreas.rawValue] = "All compatibility dimensions"
            variables[TemplateVariable.detailLevel.rawValue] = DetailLevel.medium.displayName
            variables[TemplateVariable.culturalContext.rawValue] = "General cultural context"
        }
        
        // Format instructions
        variables[TemplateVariable.formatInstructions.rawValue] = formatInstructions
        
        // Seed instruction for deterministic testing
        if let seed = request.seed {
            variables[TemplateVariable.seedInstruction.rawValue] = "Use deterministic analysis with seed: \(seed)"
        } else {
            variables[TemplateVariable.seedInstruction.rawValue] = ""
        }
        
        return variables
    }
    
    // MARK: - Individual Analysis Template
    
    private var individualAnalysisTemplate: String {
        """
        You are an expert relationship compatibility analyst specializing in evaluating emotional intelligence, communication patterns, and interpersonal dynamics from conversational responses.

        Your task is to analyze the following transcribed response to a relationship question and generate meaningful compatibility insights using a structured approach.

        QUESTION ASKED:
        "{{question}}"

        CATEGORY: {{question_category}}

        USER'S TRANSCRIBED RESPONSE:
        "{{response}}"

        ANALYSIS CONTEXT:
        - Response Length: {{response_length}}
        - Analysis Type: {{analysis_type}}
        - Detail Level: {{detail_level}}
        - Focus Areas: {{focus_areas}}
        - Cultural Context: {{cultural_context}}
        - User Context: {{user_context}}

        {{seed_instruction}}

        ANALYSIS FRAMEWORK:
        Evaluate the response across these five key dimensions (0-100 scale):

        1. EMOTIONAL OPENNESS (0-100): Willingness to share feelings and emotional experiences
        2. CLARITY (0-100): Clear, articulate self-expression and communication
        3. EMPATHY (0-100): Understanding and consideration of others' perspectives
        4. VULNERABILITY (0-100): Authentic self-disclosure and genuine openness
        5. COMMUNICATION STYLE (0-100): How effectively they express themselves

        SCORING METHODOLOGY:
        - 90-100: Exceptional emotional intelligence and relationship readiness
        - 80-89: Strong compatibility indicators with mature communication
        - 70-79: Good relationship potential with some growth areas
        - 60-69: Moderate compatibility with notable development needs
        - 50-59: Basic compatibility with significant growth opportunities
        - Below 50: Limited relationship readiness requiring substantial development

        QUALITY STANDARDS:
        - Ground all insights in actual response content - never fabricate
        - Provide emotionally intelligent feedback that feels insightful and constructive
        - Avoid superficial judgments or quiz-like assessments
        - Focus on genuine relationship compatibility factors, not personality stereotypes
        - Maintain a thoughtful, non-judgmental tone

        REQUIRED OUTPUT FORMAT:
        You must respond with a valid JSON object containing exactly these fields:

        {
            "score": <integer 0-100>,
            "summary": "<2-3 sentence natural language summary>",
            "tone": "<detected emotional tone in 1-2 words>",
            "dimensions": {
                "emotionalOpenness": <integer 0-100>,
                "clarity": <integer 0-100>,
                "empathy": <integer 0-100>,
                "vulnerability": <integer 0-100>,
                "communicationStyle": <integer 0-100>
            },
            "insights": [
                {
                    "type": "<strength|growth_area|communication_pattern|emotional_intelligence|relationship_readiness|compatibility>",
                    "title": "<brief insight title>",
                    "description": "<1-2 sentence description>",
                    "confidence": "<low|medium|high|very_high>",
                    "relatedDimension": "<dimension name or null>"
                }
            ]
        }

        Provide 2-4 insights that are specific, actionable, and grounded in the actual response content.

        {{format_instructions}}
        """
    }
    
    // MARK: - Comparative Analysis Template
    
    private var comparativeAnalysisTemplate: String {
        """
        You are an expert relationship compatibility analyst specializing in comparing two individuals' responses to relationship questions to assess their compatibility potential.

        Your task is to analyze compatibility between two users based on their responses to the same question.

        QUESTION ASKED:
        "{{question}}"

        CATEGORY: {{question_category}}

        USER 1 RESPONSE:
        "{{response}}"

        USER 2 RESPONSE:
        "{{response_2}}"

        ANALYSIS CONTEXT:
        - Analysis Type: {{analysis_type}}
        - Detail Level: {{detail_level}}
        - Focus Areas: {{focus_areas}}
        - Cultural Context: {{cultural_context}}

        {{seed_instruction}}

        COMPARATIVE ANALYSIS FRAMEWORK:
        1. Analyze each response individually using the five dimensions
        2. Compare communication styles and emotional approaches
        3. Identify areas of alignment, complementarity, and potential challenges
        4. Assess overall relationship compatibility potential

        ALIGNMENT TYPES:
        - COMPLEMENT: Different but complementary strengths
        - HARMONY: Similar levels and approaches
        - CONTRAST: Significant differences requiring navigation
        - BALANCE: One strong, one developing (can be positive)

        REQUIRED OUTPUT FORMAT:
        You must respond with a valid JSON object for comparative analysis.

        {{format_instructions}}
        """
    }
    
    // MARK: - Session-Based Analysis Template
    
    private var sessionBasedAnalysisTemplate: String {
        """
        You are an expert relationship compatibility analyst specializing in analyzing patterns across multiple responses in a single session.

        Your task is to identify trends, consistency patterns, and overall relationship readiness based on multiple question responses.

        SESSION RESPONSES:
        {{response}}

        ANALYSIS CONTEXT:
        - Analysis Type: {{analysis_type}}
        - Detail Level: {{detail_level}}
        - Focus Areas: {{focus_areas}}
        - Cultural Context: {{cultural_context}}

        {{seed_instruction}}

        SESSION ANALYSIS FRAMEWORK:
        1. Identify consistency patterns across responses
        2. Track dimension progression throughout the session
        3. Note developing confidence and openness
        4. Assess overall relationship readiness trajectory
        5. Provide session-level insights and recommendations

        {{format_instructions}}
        """
    }
    
    // MARK: - Category-Specific Analysis Template
    
    private var categorySpecificAnalysisTemplate: String {
        """
        You are an expert relationship compatibility analyst specializing in category-specific relationship dynamics.

        Your task is to provide analysis tailored to the specific relationship category and stage.

        QUESTION ASKED:
        "{{question}}"

        CATEGORY: {{question_category}}

        USER'S RESPONSE:
        "{{response}}"

        ANALYSIS CONTEXT:
        - Analysis Type: {{analysis_type}}
        - Detail Level: {{detail_level}}
        - Focus Areas: {{focus_areas}}
        - Cultural Context: {{cultural_context}}
        - User Context: {{user_context}}

        {{seed_instruction}}

        CATEGORY-SPECIFIC CONSIDERATIONS:
        {{category_guidance}}

        Focus your analysis on aspects most relevant to the {{question_category}} category, while maintaining the core five-dimension framework.

        {{format_instructions}}
        """
    }
    
    // MARK: - Helper Methods
    
    private func formatUserContext(_ context: UserContext) -> String {
        var contextParts: [String] = []
        
        if let age = context.age {
            contextParts.append("Age: \(age)")
        }
        
        if let stage = context.relationshipStage {
            contextParts.append("Relationship Stage: \(stage.displayName)")
        }
        
        if !context.previousAnalyses.isEmpty {
            contextParts.append("Previous Analyses: \(context.previousAnalyses.count)")
        }
        
        return contextParts.isEmpty ? "No specific context" : contextParts.joined(separator: ", ")
    }
    
    private func formatFocusAreas(_ focusAreas: [InsightType]) -> String {
        return focusAreas.map { $0.displayName }.joined(separator: ", ")
    }
    
    private func categoryGuidance(for category: QuestionCategory) -> String {
        switch category {
        case .blindDate, .firstDate:
            return """
            - Focus on initial impression and openness to connection
            - Assess comfort with sharing appropriate personal information
            - Evaluate social skills and conversation ability
            - Consider respect for boundaries and mutual interest
            """
            
        case .earlyDating:
            return """
            - Evaluate emotional availability and dating readiness
            - Assess communication of interests and values
            - Look for signs of emotional maturity
            - Consider ability to balance sharing with listening
            """
            
        case .deepCouple, .intimacyBuilding:
            return """
            - Focus on emotional depth and vulnerability capacity
            - Assess ability to share intimate thoughts and feelings
            - Evaluate empathy and emotional responsiveness
            - Consider trust-building and authentic connection
            """
            
        case .longTermRelationship:
            return """
            - Evaluate commitment and future-oriented thinking
            - Assess ability to navigate relationship challenges
            - Look for signs of mature partnership perspective
            - Consider growth mindset and adaptability
            """
            
        case .conflictResolution:
            return """
            - Focus on emotional regulation and conflict navigation
            - Assess empathy and perspective-taking ability
            - Evaluate communication during disagreement
            - Consider problem-solving approach and fairness
            """
            
        case .emotionalIntelligence:
            return """
            - Evaluate self-awareness and emotional vocabulary
            - Assess understanding of emotional dynamics
            - Look for empathy and emotional responsiveness
            - Consider emotional regulation and expression
            """
            
        default:
            return """
            - Apply general compatibility analysis principles
            - Focus on communication clarity and emotional openness
            - Assess relationship readiness appropriate to the category
            - Consider overall emotional intelligence and maturity
            """
        }
    }
    
    private var formatInstructions: String {
        """
        OUTPUT REQUIREMENTS:
        - Respond ONLY with valid JSON - no additional text before or after
        - Ensure all scores are integers between 0-100
        - Base all insights on actual response content
        - Provide specific, actionable feedback
        - Maintain professional, supportive tone
        - Include 2-4 insights minimum
        - Ensure JSON is properly formatted and complete
        """
    }
}

// MARK: - Template Processing for Compatibility Analysis

/// Utility class for processing compatibility analysis prompt templates
public struct CompatibilityPromptProcessor {
    private let templateProvider: CompatibilityPromptTemplateProvider
    
    public init() {
        self.init(templateProvider: CompatibilityPromptTemplates())
    }
    
    public init(templateProvider: CompatibilityPromptTemplateProvider) {
        self.templateProvider = templateProvider
    }
    
    /// Processes a template by substituting variables with actual values
    public func processTemplate(for request: AnalysisRequest) -> String {
        let template = templateProvider.template(for: request.analysisType)
        let variables = templateProvider.variables(for: request)
        
        var processedTemplate = template
        
        // Substitute all variables
        for (variable, value) in variables {
            processedTemplate = processedTemplate.replacingOccurrences(of: variable, with: value)
        }
        
        // Add category-specific guidance if needed
        if request.analysisType == .categorySpecific {
            let guidance = categoryGuidance(for: request.questionCategory)
            processedTemplate = processedTemplate.replacingOccurrences(of: "{{category_guidance}}", with: guidance)
        }
        
        // Clean up any remaining placeholders
        processedTemplate = cleanupTemplate(processedTemplate)
        
        return processedTemplate
    }
    
    /// Processes template for comparative analysis with two responses
    public func processComparativeTemplate(
        question: String,
        response1: String,
        response2: String,
        questionCategory: QuestionCategory,
        seed: UInt64? = nil
    ) -> String {
        var template = templateProvider.template(for: .comparative)
        
        // Substitute variables
        template = template.replacingOccurrences(of: "{{question}}", with: question)
        template = template.replacingOccurrences(of: "{{response}}", with: response1)
        template = template.replacingOccurrences(of: "{{response_2}}", with: response2)
        template = template.replacingOccurrences(of: "{{question_category}}", with: questionCategory.displayName)
        template = template.replacingOccurrences(of: "{{analysis_type}}", with: AnalysisType.comparative.displayName)
        template = template.replacingOccurrences(of: "{{detail_level}}", with: DetailLevel.medium.displayName)
        template = template.replacingOccurrences(of: "{{focus_areas}}", with: "All compatibility dimensions")
        template = template.replacingOccurrences(of: "{{cultural_context}}", with: "General cultural context")
        
        if let seed = seed {
            template = template.replacingOccurrences(of: "{{seed_instruction}}", with: "Use deterministic analysis with seed: \(seed)")
        } else {
            template = template.replacingOccurrences(of: "{{seed_instruction}}", with: "")
        }
        
        let formatInstructions = """
        OUTPUT REQUIREMENTS:
        - Respond ONLY with valid JSON for comparative analysis
        - Include individual analysis for both users
        - Provide overall compatibility assessment
        - Include alignment analysis for each dimension
        - Base all insights on actual response content
        """
        
        template = template.replacingOccurrences(of: "{{format_instructions}}", with: formatInstructions)
        
        return cleanupTemplate(template)
    }
    
    private func categoryGuidance(for category: QuestionCategory) -> String {
        let templates = CompatibilityPromptTemplates()
        return templates.categoryGuidance(for: category)
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

// MARK: - Extensions for Template Support

extension CompatibilityPromptTemplates {
    func categoryGuidance(for category: QuestionCategory) -> String {
        switch category {
        case .blindDate, .firstDate:
            return """
            - Focus on initial impression and openness to connection
            - Assess comfort with sharing appropriate personal information
            - Evaluate social skills and conversation ability
            - Consider respect for boundaries and mutual interest
            """
            
        case .earlyDating:
            return """
            - Evaluate emotional availability and dating readiness
            - Assess communication of interests and values
            - Look for signs of emotional maturity
            - Consider ability to balance sharing with listening
            """
            
        case .deepCouple, .intimacyBuilding:
            return """
            - Focus on emotional depth and vulnerability capacity
            - Assess ability to share intimate thoughts and feelings
            - Evaluate empathy and emotional responsiveness
            - Consider trust-building and authentic connection
            """
            
        case .longTermRelationship:
            return """
            - Evaluate commitment and future-oriented thinking
            - Assess ability to navigate relationship challenges
            - Look for signs of mature partnership perspective
            - Consider growth mindset and adaptability
            """
            
        case .conflictResolution:
            return """
            - Focus on emotional regulation and conflict navigation
            - Assess empathy and perspective-taking ability
            - Evaluate communication during disagreement
            - Consider problem-solving approach and fairness
            """
            
        case .emotionalIntelligence:
            return """
            - Evaluate self-awareness and emotional vocabulary
            - Assess understanding of emotional dynamics
            - Look for empathy and emotional responsiveness
            - Consider emotional regulation and expression
            """
            
        default:
            return """
            - Apply general compatibility analysis principles
            - Focus on communication clarity and emotional openness
            - Assess relationship readiness appropriate to the category
            - Consider overall emotional intelligence and maturity
            """
        }
    }
}