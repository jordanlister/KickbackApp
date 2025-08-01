import XCTest
@testable import KickbackApp

// MARK: - Mock LLM Service

final class MockLLMService: LLMService {
    var shouldFail = false
    var responseDelay: TimeInterval = 0
    var mockResponse = "What's the most adventurous thing you've ever done together?"
    var callCount = 0
    var lastPrompt: String = ""
    
    override func generateResponse(for prompt: String) async throws -> String {
        callCount += 1
        lastPrompt = prompt
        
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        if shouldFail {
            throw LLMServiceError.inferenceError("Mock inference error")
        }
        
        return mockResponse
    }
}

// MARK: - Question Engine Tests

final class QuestionEngineTests: XCTestCase {
    
    var mockLLMService: MockLLMService!
    var questionEngine: QuestionEngineService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockLLMService = MockLLMService()
        questionEngine = QuestionEngineService(
            llmService: mockLLMService,
            maxRetryAttempts: 1,
            requestTimeout: 1.0
        )
    }
    
    override func tearDownWithError() throws {
        mockLLMService = nil
        questionEngine = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Generation Tests
    
    func testGenerateQuestionBasic() async throws {
        // Given
        let category = QuestionCategory.firstDate
        mockLLMService.mockResponse = "What's your idea of a perfect weekend?"
        
        // When
        let question = try await questionEngine.generateQuestion(for: category)
        
        // Then
        XCTAssertEqual(question, "What's your idea of a perfect weekend?")
        XCTAssertEqual(mockLLMService.callCount, 1)
        XCTAssertTrue(mockLLMService.lastPrompt.contains("first_date"))
    }
    
    func testGenerateQuestionWithConfiguration() async throws {
        // Given
        let config = QuestionConfiguration(
            category: .deepCouple,
            tone: .intimate,
            customComplexity: .profound,
            previousTopics: ["dreams", "fears"]
        )
        mockLLMService.mockResponse = "What's something about me that you've discovered recently that surprised you?"
        
        // When
        let result = try await questionEngine.generateQuestion(with: config)
        
        // Then
        XCTAssertEqual(result.question, "What's something about me that you've discovered recently that surprised you?")
        XCTAssertEqual(result.category, .deepCouple)
        XCTAssertEqual(result.configuration.effectiveTone, .intimate)
        XCTAssertTrue(mockLLMService.lastPrompt.contains("dreams, fears"))
        XCTAssertTrue(mockLLMService.lastPrompt.contains("Intimate & Connected"))
    }
    
    // MARK: - Error Handling Tests
    
    func testLLMServiceError() async {
        // Given
        mockLLMService.shouldFail = true
        
        // When/Then
        do {
            _ = try await questionEngine.generateQuestion(for: .blindDate)
            XCTFail("Expected error to be thrown")
        } catch let error as QuestionEngineError {
            if case .llmServiceError = error {
                // Expected error type
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTimeoutHandling() async {
        // Given
        mockLLMService.responseDelay = 2.0 // Longer than 1.0s timeout
        
        // When/Then
        do {
            _ = try await questionEngine.generateQuestion(for: .firstDate)
            XCTFail("Expected timeout error")
        } catch let error as QuestionEngineError {
            if case .timeout = error {
                // Expected timeout error
            } else {
                XCTFail("Expected timeout error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRetryLogic() async throws {
        // Given
        mockLLMService.shouldFail = true
        let retryEngine = QuestionEngineService(
            llmService: mockLLMService,
            maxRetryAttempts: 2,
            requestTimeout: 1.0
        )
        
        // When
        do {
            _ = try await retryEngine.generateQuestion(for: .firstDate)
            XCTFail("Expected error after retries")
        } catch {
            // Then
            XCTAssertEqual(mockLLMService.callCount, 3) // 1 initial + 2 retries
        }
    }
    
    // MARK: - Response Processing Tests
    
    func testResponseProcessing() async throws {
        // Given - Various messy responses
        let testCases: [(input: String, expected: String)] = [
            ("**What's your favorite memory together?**", "What's your favorite memory together?"),
            ("\"How do you show love?\"", "How do you show love?"),
            ("# Question\nWhat makes you feel most connected to me?", "What makes you feel most connected to me?"),
            ("Here's a question: What's your biggest dream", "What's your biggest dream?"),
            ("what's your love language?", "What's your love language?"),
            ("What's your   biggest    fear   ?", "What's your biggest fear?")
        ]
        
        // When/Then
        for (input, expected) in testCases {
            mockLLMService.mockResponse = input
            let question = try await questionEngine.generateQuestion(for: .firstDate)
            XCTAssertEqual(question, expected, "Failed for input: '\(input)'")
        }
    }
    
    func testInvalidResponseHandling() async {
        // Given - Invalid responses
        let invalidResponses = [
            "", // Empty
            "   ", // Whitespace only
            "This is not a question", // No question mark
            "What", // Too short
            "What " + String(repeating: "very ", times: 50) + "long question?" // Too long
        ]
        
        // When/Then
        for response in invalidResponses {
            mockLLMService.mockResponse = response
            
            do {
                _ = try await questionEngine.generateQuestion(for: .firstDate)
                XCTFail("Expected error for invalid response: '\(response)'")
            } catch let error as QuestionEngineError {
                if case .invalidResponse = error {
                    // Expected
                } else {
                    XCTFail("Expected invalidResponse error for '\(response)', got: \(error)")
                }
            } catch {
                XCTFail("Unexpected error type for '\(response)': \(error)")
            }
        }
    }
}

// MARK: - Question Models Tests

final class QuestionModelsTests: XCTestCase {
    
    func testQuestionCategoryProperties() {
        // Test display names
        XCTAssertEqual(QuestionCategory.blindDate.displayName, "Blind Date")
        XCTAssertEqual(QuestionCategory.deepCouple.displayName, "Deep Couple")
        
        // Test relationship stages
        XCTAssertEqual(QuestionCategory.blindDate.relationshipStage, .meeting)
        XCTAssertEqual(QuestionCategory.deepCouple.relationshipStage, .serious)
        
        // Test complexity levels
        XCTAssertEqual(QuestionCategory.blindDate.complexityLevel, .light)
        XCTAssertEqual(QuestionCategory.deepCouple.complexityLevel, .deep)
    }
    
    func testQuestionConfiguration() {
        // Given
        let config = QuestionConfiguration(
            category: .firstDate,
            tone: .playful,
            customComplexity: .medium,
            previousTopics: ["hobbies", "work"]
        )
        
        // Then
        XCTAssertEqual(config.effectiveComplexity, .medium)
        XCTAssertEqual(config.effectiveTone, .playful)
        XCTAssertEqual(config.previousTopics, ["hobbies", "work"])
    }
    
    func testDefaultToneSelection() {
        // Test default tone selection for various categories
        let configs = [
            QuestionConfiguration(category: .blindDate),
            QuestionConfiguration(category: .funAndPlayful),
            QuestionConfiguration(category: .intimacyBuilding),
            QuestionConfiguration(category: .vulnerabilitySharing)
        ]
        
        XCTAssertEqual(configs[0].effectiveTone, .curious)
        XCTAssertEqual(configs[1].effectiveTone, .playful)
        XCTAssertEqual(configs[2].effectiveTone, .intimate)
        XCTAssertEqual(configs[3].effectiveTone, .vulnerable)
    }
}

// MARK: - Prompt Templates Tests

final class PromptTemplatesTests: XCTestCase {
    
    var promptTemplates: QuestionPromptTemplates!
    var promptProcessor: PromptProcessor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        promptTemplates = QuestionPromptTemplates()
        promptProcessor = PromptProcessor(templateProvider: promptTemplates)
    }
    
    func testTemplateVariableSubstitution() {
        // Given
        let config = QuestionConfiguration(
            category: .firstDate,
            tone: .thoughtful,
            customComplexity: .medium,
            relationshipDuration: 86400 * 7, // 1 week
            previousTopics: ["work", "family"],
            contextualHints: ["both love hiking"]
        )
        
        // When
        let processedPrompt = promptProcessor.processTemplate(for: config)
        
        // Then
        XCTAssertTrue(processedPrompt.contains("First Date"))
        XCTAssertTrue(processedPrompt.contains("Thoughtful & Considerate"))
        XCTAssertTrue(processedPrompt.contains("Moderate Depth"))
        XCTAssertTrue(processedPrompt.contains("1 week"))
        XCTAssertTrue(processedPrompt.contains("work, family"))
        XCTAssertTrue(processedPrompt.contains("both love hiking"))
        XCTAssertFalse(processedPrompt.contains("{{")) // No unsubstituted variables
    }
    
    func testAllCategoryTemplates() {
        // Ensure all categories have templates
        for category in QuestionCategory.allCases {
            let template = promptTemplates.template(for: category)
            XCTAssertFalse(template.isEmpty, "Template missing for category: \(category)")
            XCTAssertTrue(template.contains("{{category}}"), "Template should contain category variable for: \(category)")
        }
    }
    
    func testPromptCleaning() {
        // Given
        let config = QuestionConfiguration(category: .blindDate)
        
        // When
        let processedPrompt = promptProcessor.processTemplate(for: config)
        
        // Then
        XCTAssertFalse(processedPrompt.contains("\n\n\n")) // No excessive newlines
        XCTAssertEqual(processedPrompt, processedPrompt.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - Response Processor Tests

final class ResponseProcessorTests: XCTestCase {
    
    var processor: ResponseProcessor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        processor = ResponseProcessor()
    }
    
    func testMarkdownRemoval() throws {
        let testCases: [(input: String, expected: String)] = [
            ("**What's your favorite color?**", "What's your favorite color?"),
            ("*How do you relax?*", "How do you relax?"),
            ("`What` makes you happy?", "What makes you happy?"),
            ("# What's your dream?", "What's your dream?"),
            ("\"What do you value most?\"", "What do you value most?")
        ]
        
        for (input, expected) in testCases {
            let result = try processor.processResponse(input)
            XCTAssertEqual(result, expected, "Failed for input: '\(input)'")
        }
    }
    
    func testQuestionExtraction() throws {
        let multilineInput = """
        Here's a thoughtful question for you:
        
        What's the most meaningful conversation you've ever had?
        
        This question helps explore deep connections.
        """
        
        let result = try processor.processResponse(multilineInput)
        XCTAssertEqual(result, "What's the most meaningful conversation you've ever had?")
    }
    
    func testCapitalizationAndPunctuation() throws {
        let testCases: [(input: String, expected: String)] = [
            ("what's your favorite book", "What's your favorite book?"),
            ("What's   your   biggest   dream   ?", "What's your biggest dream?"),
            ("WHAT DO YOU LOVE MOST?", "WHAT DO YOU LOVE MOST?"), // Preserve if already uppercase
        ]
        
        for (input, expected) in testCases {
            let result = try processor.processResponse(input)
            XCTAssertEqual(result, expected, "Failed for input: '\(input)'")
        }
    }
    
    func testSanitizationTracking() throws {
        let input = "**What's   your   favorite   memory?**"
        let _ = try processor.processResponse(input)
        
        XCTAssertTrue(processor.lastSanitizationSteps.contains("removed_markdown"))
        XCTAssertTrue(processor.lastSanitizationSteps.contains("normalized_punctuation"))
        XCTAssertTrue(processor.lastSanitizationSteps.contains("normalized_capitalization"))
    }
}

// MARK: - Integration Tests

final class QuestionEngineIntegrationTests: XCTestCase {
    
    func testEndToEndGeneration() async throws {
        // Given
        let mockLLM = MockLLMService()
        let engine = QuestionEngineService(llmService: mockLLM)
        
        mockLLM.mockResponse = "**What's the most adventurous thing you want to do together?**"
        
        // When
        let result = try await engine.generateQuestion(with: QuestionConfiguration(
            category: .futureVisions,
            tone: .exploratory,
            previousTopics: ["travel", "goals"]
        ))
        
        // Then
        XCTAssertEqual(result.question, "What's the most adventurous thing you want to do together?")
        XCTAssertEqual(result.category, .futureVisions)
        XCTAssertTrue(result.processingMetadata.sanitizationApplied.contains("removed_markdown"))
        XCTAssertGreaterThan(result.processingMetadata.processingDuration, 0)
        XCTAssertTrue(mockLLM.lastPrompt.contains("travel, goals"))
    }
    
    func testConcurrentGeneration() async throws {
        // Given
        let mockLLM = MockLLMService()
        let engine = QuestionEngineService(llmService: mockLLM)
        
        mockLLM.mockResponse = "What brings you the most joy?"
        
        // When - Generate multiple questions concurrently
        async let question1 = engine.generateQuestion(for: .personalGrowth)
        async let question2 = engine.generateQuestion(for: .funAndPlayful)
        async let question3 = engine.generateQuestion(for: .valuesAlignment)
        
        let results = try await [question1, question2, question3]
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(mockLLM.callCount, 3)
        for result in results {
            XCTAssertEqual(result, "What brings you the most joy?")
        }
    }
}