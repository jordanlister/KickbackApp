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
        case .cardAnalysis:
            return cardAnalysisTemplate
        case .synthesis:
            return synthesisTemplate
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
        Analyze this relationship response:

        Q: "{{question}}"
        A: "{{response}}"

        Rate 0-100 for: emotional openness, clarity, empathy, vulnerability, communication style. 
        Score based on relationship readiness: 90-100=exceptional, 80-89=strong, 70-79=good, 60-69=moderate, 50-59=basic, <50=limited.

        Return only JSON:
        {
            "score": <0-100>,
            "summary": "<brief 2-sentence summary>",
            "tone": "<1-2 words>",
            "dimensions": {
                "emotionalOpenness": <0-100>,
                "clarity": <0-100>,
                "empathy": <0-100>,
                "vulnerability": <0-100>,
                "communicationStyle": <0-100>
            },
            "insights": [
                {
                    "type": "strength",
                    "title": "Brief insight title",
                    "description": "One sentence description based on response content.",
                    "confidence": "high",
                    "relatedDimension": "emotionalOpenness"
                }
            ]
        }
        
        Provide 2-3 insights based on actual response content.
        """
    }
    
    // MARK: - Comparative Analysis Template
    
    private var comparativeAnalysisTemplate: String {
        """
        Compare these responses to: "{{question}}"

        User 1: "{{response}}"
        User 2: "{{response_2}}"

        Analyze compatibility. Return JSON:
        {
            "overallCompatibility": <0-100>,
            "alignmentType": "harmony",
            "summary": "<brief compatibility assessment>",
            "insights": [
                {
                    "type": "compatibility", 
                    "description": "One sentence compatibility insight.",
                    "confidence": "high"
                }
            ]
        }
        """
    }
    
    // MARK: - Session-Based Analysis Template
    
    private var sessionBasedAnalysisTemplate: String {
        """
        Analyze session patterns from responses:
        {{response}}

        Identify trends, consistency, growth. Return JSON:
        {
            "overallScore": <0-100>,
            "trendAnalysis": {
                "improvingAreas": ["<areas>"],
                "consistentStrengths": ["<strengths>"],
                "developmentNeeds": ["<needs>"]
            },
            "sessionInsights": [
                {
                    "type": "growth|strength|pattern",
                    "description": "<1 sentence>",
                    "confidence": "low|medium|high"
                }
            ]
        }
        """
    }
    
    // MARK: - Category-Specific Analysis Template
    
    private var categorySpecificAnalysisTemplate: String {
        """
        Analyze {{question_category}} response:

        Q: "{{question}}"
        A: "{{response}}"

        Category focus: {{category_guidance}}

        Rate 0-100 for emotional openness, clarity, empathy, vulnerability, communication style.

        Return JSON:
        {
            "score": <0-100>,
            "summary": "<brief assessment>",
            "tone": "<1-2 words>",
            "dimensions": {
                "emotionalOpenness": <0-100>,
                "clarity": <0-100>,
                "empathy": <0-100>,
                "vulnerability": <0-100>,
                "communicationStyle": <0-100>
            },
            "insights": [
                {
                    "type": "strength",
                    "title": "Brief insight title", 
                    "description": "One sentence description.",
                    "confidence": "high"
                }
            ]
        }
        """
    }
    
    // MARK: - Card Analysis Template (Stage 1 - Individual Card)
    
    /// Very short template for analyzing a single card with both players' answers
    /// Optimized to stay under 800 characters to prevent context window issues
    private var cardAnalysisTemplate: String {
        """
        Q: "{{question}}"
        P1: "{{player1_answer}}"
        P2: "{{player2_answer}}"

        Return JSON only:
        {
            "player1Summary": "brief summary",
            "player2Summary": "brief summary", 
            "compatibilityInsights": "key insight",
            "compatibilityScore": 75,
            "player1Score": 80,
            "player2Score": 70,
            "overallTone": "positive",
            "primaryDimension": "clarity",
            "showedAlignment": true
        }
        """
    }
    
    // MARK: - Synthesis Template (Stage 2 - Aggregate Analysis)
    
    /// Template for synthesizing multiple card summaries into final game results
    /// Takes 5 CardAnalysisSummary compact representations as input
    private var synthesisTemplate: String {
        """
        Cards: {{card_summaries}}

        Analyze compatibility patterns. Return JSON:
        {
            "overallScore": 75,
            "insights": ["pattern1", "pattern2"],
            "recommendation": "brief advice"
        }
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
    
    internal func categoryGuidance(for category: QuestionCategory) -> String {
        switch category {
        case .blindDate, .firstDate:
            return "Focus on openness, social comfort, boundary respect"
            
        case .earlyDating:
            return "Assess emotional availability, maturity, value communication"
            
        case .deepCouple, .intimacyBuilding:
            return "Evaluate depth, vulnerability, trust-building capacity"
            
        case .longTermRelationship:
            return "Look for commitment, challenge navigation, partnership mindset"
            
        case .conflictResolution:
            return "Assess emotional regulation, empathy, problem-solving approach"
            
        case .emotionalIntelligence:
            return "Evaluate self-awareness, emotional vocabulary, regulation"
            
        default:
            return "General compatibility: clarity, openness, relationship readiness"
        }
    }
    
    private var formatInstructions: String {
        """
        Return only valid JSON. Base insights on actual content. Scores 0-100.
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
            let guidance = (templateProvider as? CompatibilityPromptTemplates)?.categoryGuidance(for: request.questionCategory) ?? ""
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
        
        let formatInstructions = "Return only valid JSON."
        
        template = template.replacingOccurrences(of: "{{format_instructions}}", with: formatInstructions)
        
        return cleanupTemplate(template)
    }
    
    /// Processes template for card analysis with both players' answers (Stage 1)
    public func processCardAnalysisTemplate(
        question: String,
        questionCategory: QuestionCategory,
        player1Answer: String,
        player2Answer: String
    ) -> String {
        var template = templateProvider.template(for: .cardAnalysis)
        
        // Optimize answer lengths for context window
        let optimizedPlayer1 = optimizeAnswerForContext(player1Answer)
        let optimizedPlayer2 = optimizeAnswerForContext(player2Answer)
        
        // Substitute variables
        template = template.replacingOccurrences(of: "{{question}}", with: question.truncated(to: 100))
        template = template.replacingOccurrences(of: "{{player1_answer}}", with: optimizedPlayer1)
        template = template.replacingOccurrences(of: "{{player2_answer}}", with: optimizedPlayer2)
        template = template.replacingOccurrences(of: "{{question_category}}", with: questionCategory.displayName)
        
        return cleanupTemplate(template)
    }
    
    /// Processes template for synthesis analysis with card summaries (Stage 2)
    public func processSynthesisTemplate(cardSummaries: [CardAnalysisSummary]) -> String {
        var template = templateProvider.template(for: .synthesis)
        
        // Create compact representations of all card summaries
        let summariesText = cardSummaries.enumerated().map { index, summary in
            "Card \(index + 1): \(summary.compactRepresentation)"
        }.joined(separator: "\n\n")
        
        // Substitute the summaries
        template = template.replacingOccurrences(of: "{{card_summaries}}", with: summariesText)
        
        return cleanupTemplate(template)
    }
    
    /// Optimizes answer text for context window constraints
    private func optimizeAnswerForContext(_ answer: String, maxLength: Int = 200) -> String {
        if answer.count <= maxLength {
            return answer
        }
        
        // Try to truncate at sentence boundaries
        let sentences = answer.components(separatedBy: ". ")
        var result = ""
        
        for sentence in sentences {
            let potential = result.isEmpty ? sentence : "\(result). \(sentence)"
            if potential.count <= maxLength - 3 {
                result = potential
            } else {
                break
            }
        }
        
        // If no sentences fit, truncate at word boundaries
        if result.isEmpty {
            let words = answer.components(separatedBy: " ")
            for word in words {
                let potential = result.isEmpty ? word : "\(result) \(word)"
                if potential.count <= maxLength - 3 {
                    result = potential
                } else {
                    break
                }
            }
        }
        
        return result.isEmpty ? answer.truncated(to: maxLength) : "\(result)..."
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

// MARK: - String Extension (imported from CardAnalysisSummary.swift)

