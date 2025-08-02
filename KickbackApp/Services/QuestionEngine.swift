import Foundation
import OSLog

// MARK: - Question Engine Protocol

/// Protocol defining the interface for question generation services
/// Enables dependency injection and testing with mock implementations
public protocol QuestionEngine {
    /// Generates a conversation question for the specified category
    /// - Parameter category: The type of question to generate
    /// - Returns: A thoughtful, contextually appropriate question
    /// - Throws: QuestionEngineError for various failure scenarios
    func generateQuestion(for category: QuestionCategory) async throws -> String
    
    /// Generates a conversation question with detailed configuration
    /// - Parameter configuration: Detailed configuration including category, tone, and context
    /// - Returns: A question result with metadata
    /// - Throws: QuestionEngineError for various failure scenarios
    func generateQuestion(with configuration: QuestionConfiguration) async throws -> QuestionResult
    
    /// Manually resets the context window for memory management
    func resetContext() async
}

// MARK: - Question Engine Service Implementation

/// Production implementation of QuestionEngine using on-device LLM
/// Integrates with LLMService to generate contextually appropriate conversation questions
/// without any hardcoded fallbacks - all content comes from the language model
public final class QuestionEngineService: QuestionEngine {
    
    // MARK: - Dependencies
    
    private let llmService: LLMService
    private let promptProcessor: PromptProcessor
    private var responseProcessor: ResponseProcessor
    private let logger: Logger
    
    // MARK: - Configuration
    
    private let maxRetryAttempts: Int
    private let requestTimeout: TimeInterval
    
    // MARK: - Context Management
    
    private let maxQuestionsBeforeReset: Int = 6 // Reset after 6 questions to manage context window
    private let contextActor = ContextActor()
    
    // MARK: - Initialization
    
    /// Initializes the QuestionEngine with dependencies
    /// - Parameters:
    ///   - llmService: Service for LLM inference (defaults to shared instance)
    ///   - promptProcessor: Processor for template substitution (defaults to standard processor)
    ///   - responseProcessor: Processor for cleaning LLM responses (defaults to standard processor)
    ///   - maxRetryAttempts: Maximum retry attempts for failed requests (default: 2)
    ///   - requestTimeout: Timeout for individual requests (default: 30 seconds)
    public init(
        llmService: LLMService = .shared,
        promptProcessor: PromptProcessor = PromptProcessor(),
        responseProcessor: ResponseProcessor = ResponseProcessor(),
        maxRetryAttempts: Int = 2,
        requestTimeout: TimeInterval = 30.0
    ) {
        self.llmService = llmService
        self.promptProcessor = promptProcessor
        self.responseProcessor = responseProcessor
        self.maxRetryAttempts = maxRetryAttempts
        self.requestTimeout = requestTimeout
        self.logger = Logger(subsystem: "com.kickbackapp.questionengine", category: "QuestionGeneration")
    }
    
    // MARK: - QuestionEngine Protocol Implementation
    
    public func generateQuestion(for category: QuestionCategory) async throws -> String {
        let configuration = QuestionConfiguration(category: category)
        let result = try await generateQuestion(with: configuration)
        return result.question
    }
    
    public func generateQuestion(with configuration: QuestionConfiguration) async throws -> QuestionResult {
        let startTime = Date()
        
        logger.info("Starting question generation for category: \(configuration.category.rawValue)")
        
        // Check if we need to reset the context window
        let currentCount = await contextActor.getCurrentCount()
        
        if currentCount >= maxQuestionsBeforeReset {
            logger.info("Context window approaching limit (\(currentCount)/\(self.maxQuestionsBeforeReset)). Resetting session...")
            await resetContextWindow()
        }
        
        do {
            // Process the prompt template
            let prompt = promptProcessor.processTemplate(for: configuration)
            logger.debug("Generated prompt: \(prompt, privacy: .private)")
            
            // Generate response with retry logic
            let rawResponse = try await generateWithRetry(prompt: prompt)
            logger.debug("Raw LLM response: \(rawResponse, privacy: .private)")
            
            // Process and sanitize the response
            let processedQuestion = try responseProcessor.processResponse(rawResponse)
            logger.info("Successfully generated question: \(processedQuestion, privacy: .private)")
            
            // Create processing metadata
            let processingDuration = Date().timeIntervalSince(startTime)
            let metadata = ProcessingMetadata(
                promptUsed: prompt,
                rawLLMResponse: rawResponse,
                processingDuration: processingDuration,
                sanitizationApplied: responseProcessor.lastSanitizationSteps
            )
            
            // Return complete result
            let result = QuestionResult(
                question: processedQuestion,
                category: configuration.category,
                configuration: configuration,
                generatedAt: startTime,
                processingMetadata: metadata
            )
            
            // Increment question counter for context management
            let totalQuestions = await contextActor.incrementCount()
            
            logger.info("Question generation completed successfully in \(processingDuration, privacy: .public)s (Total: \(totalQuestions))")
            return result
            
        } catch {
            let processingDuration = Date().timeIntervalSince(startTime)
            logger.error("Question generation failed after \(processingDuration, privacy: .public)s: \(error.localizedDescription)")
            
            // Check if this is a context window error and reset if needed
            if error.localizedDescription.contains("Exceeded model context window size") || 
               error.localizedDescription.contains("context window") {
                logger.warning("Context window exceeded - forcing reset for next generation")
                await resetContextWindow()
            }
            
            // Re-throw as QuestionEngineError if not already
            if let questionError = error as? QuestionEngineError {
                throw questionError
            } else {
                throw QuestionEngineError.generationFailed("Question generation failed: \(error.localizedDescription)")
            }
        }
    }
    
    public func resetContext() async {
        await resetContextWindow()
    }
    
    // MARK: - Private Methods
    
    /// Resets the context window to prevent memory overflow
    private func resetContextWindow() async {
        logger.info("Resetting LLM context window to manage memory")
        
        // Reset the LLM session to clear context
        llmService.resetSession()
        
        // Reset our question counter
        await contextActor.resetCount()
        
        logger.info("Context window reset completed")
    }
    
    /// Generates LLM response with retry logic for handling transient failures
    private func generateWithRetry(prompt: String) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...(maxRetryAttempts + 1) {
            do {
                logger.debug("Attempt \(attempt) of \(self.maxRetryAttempts + 1) for LLM generation")
                
                let response = try await withTimeout(seconds: requestTimeout) { [self] in
                    try await llmService.generateResponse(for: prompt)
                }
                
                return response
                
            } catch {
                lastError = error
                logger.warning("Attempt \(attempt) failed: \(error.localizedDescription)")
                
                // For context window errors, reset immediately and retry without delay
                if error.localizedDescription.contains("Exceeded model context window size") || 
                   error.localizedDescription.contains("context window") {
                    logger.warning("Context window error detected - resetting session before retry")
                    llmService.resetSession()
                    await contextActor.resetCount()
                }
                
                // Don't retry on the last attempt
                if attempt <= maxRetryAttempts {
                    // For context window errors, retry immediately. Otherwise use exponential backoff
                    if error.localizedDescription.contains("context window") {
                        logger.debug("Retrying immediately after context reset")
                    } else {
                        let delay = min(pow(2.0, Double(attempt - 1)), 8.0) + Double.random(in: 0...1)
                        logger.debug("Retrying after \(delay, privacy: .public)s delay")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
            }
        }
        
        // All attempts failed
        if let llmError = lastError as? LLMServiceError {
            throw QuestionEngineError.llmServiceError(llmError)
        } else {
            throw QuestionEngineError.generationFailed("Failed after \(self.maxRetryAttempts + 1) attempts: \(lastError?.localizedDescription ?? "Unknown error")")
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
                throw QuestionEngineError.timeout("Operation timed out after \(seconds) seconds")
            }
            
            guard let result = try await group.next() else {
                throw QuestionEngineError.timeout("Timeout task group failed")
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Response Processor

/// Handles cleaning and sanitizing raw LLM responses into usable questions
public struct ResponseProcessor {
    
    /// Tracks sanitization steps applied during processing
    public private(set) var lastSanitizationSteps: [String] = []
    
    public init() {}
    
    /// Processes raw LLM response into a clean, usable question
    /// - Parameter rawResponse: The raw text from the LLM
    /// - Returns: A clean, properly formatted question
    /// - Throws: QuestionEngineError.invalidResponse for unusable responses
    public mutating func processResponse(_ rawResponse: String) throws -> String {
        lastSanitizationSteps.removeAll()
        
        guard !rawResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw QuestionEngineError.invalidResponse("Empty response from LLM")
        }
        
        var processedResponse = rawResponse
        
        // Step 1: Basic cleanup
        processedResponse = processedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        lastSanitizationSteps.append("trimmed_whitespace")
        
        // Step 2: Remove markdown formatting
        processedResponse = removeMarkdownFormatting(processedResponse)
        if processedResponse != rawResponse.trimmingCharacters(in: .whitespacesAndNewlines) {
            lastSanitizationSteps.append("removed_markdown")
        }
        
        // Step 3: Extract the actual question
        processedResponse = extractQuestion(from: processedResponse)
        lastSanitizationSteps.append("extracted_question")
        
        // Step 4: Normalize punctuation and capitalization
        processedResponse = normalizePunctuation(processedResponse)
        lastSanitizationSteps.append("normalized_punctuation")
        
        processedResponse = normalizeCapitalization(processedResponse)
        lastSanitizationSteps.append("normalized_capitalization")
        
        // Step 5: Validate final result
        try validateQuestion(processedResponse)
        
        return processedResponse
    }
    
    // MARK: - Processing Steps
    
    private func removeMarkdownFormatting(_ text: String) -> String {
        var cleaned = text
        
        // Remove markdown headers
        cleaned = cleaned.replacingOccurrences(of: #"^#{1,6}\s*"#, with: "", options: .regularExpression)
        
        // Remove bold/italic formatting
        cleaned = cleaned.replacingOccurrences(of: #"\*{1,2}([^*]+)\*{1,2}"#, with: "$1", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"_{1,2}([^_]+)_{1,2}"#, with: "$1", options: .regularExpression)
        
        // Remove code blocks and inline code
        cleaned = cleaned.replacingOccurrences(of: #"```[^`]*```"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        
        // Remove quote markers
        let lines = cleaned.components(separatedBy: .newlines)
        let cleanedLines = lines.map { line in
            line.replacingOccurrences(of: #"^>\s*"#, with: "", options: .regularExpression)
        }
        cleaned = cleanedLines.joined(separator: "\n")
        
        // Clean up quotation marks around the entire response
        cleaned = cleaned.replacingOccurrences(of: #"^["""](.+)["""]$"#, with: "$1", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractQuestion(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Look for the first line that appears to be a question
        for line in lines {
            if isValidQuestion(line) {
                return line
            }
        }
        
        // If no clear question found, try to find the most question-like line
        let questionLines = lines.filter { $0.contains("?") }
        if let firstQuestion = questionLines.first {
            return firstQuestion
        }
        
        // As a last resort, return the first substantial line
        return lines.first ?? text
    }
    
    private func normalizePunctuation(_ text: String) -> String {
        var normalized = text
        
        // Ensure proper spacing around punctuation
        normalized = normalized.replacingOccurrences(of: #"\s*\?\s*"#, with: "?", options: .regularExpression)
        
        // Fix multiple punctuation marks
        normalized = normalized.replacingOccurrences(of: #"\?{2,}"#, with: "?", options: .regularExpression)
        
        // Ensure question ends with question mark
        if !normalized.hasSuffix("?") {
            normalized += "?"
        }
        
        // Clean up extra spaces
        normalized = normalized.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func normalizeCapitalization(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        // Capitalize first letter
        let firstChar = String(text.prefix(1)).uppercased()
        let remainder = String(text.dropFirst())
        
        return firstChar + remainder
    }
    
    private func isValidQuestion(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must not be empty and should end with question mark
        guard !trimmed.isEmpty, trimmed.hasSuffix("?") else { return false }
        
        // Should have reasonable length (not too short or too long)
        let wordCount = trimmed.components(separatedBy: .whitespacesAndNewlines).count
        guard wordCount >= 3 && wordCount <= 50 else { return false }
        
        // Should contain typical question patterns
        let lowercased = trimmed.lowercased()
        let questionWords = ["what", "how", "why", "when", "where", "who", "which", "would", "could", "should", "do", "does", "did", "have", "has", "had", "is", "are", "was", "were", "will", "can", "might", "may"]
        
        return questionWords.contains { lowercased.hasPrefix($0 + " ") }
    }
    
    private func validateQuestion(_ question: String) throws {
        guard !question.isEmpty else {
            throw QuestionEngineError.invalidResponse("Processed question is empty")
        }
        
        guard question.hasSuffix("?") else {
            throw QuestionEngineError.invalidResponse("Question does not end with question mark")
        }
        
        let wordCount = question.components(separatedBy: .whitespacesAndNewlines).count
        guard wordCount >= 3 else {
            throw QuestionEngineError.invalidResponse("Question is too short")
        }
        
        guard wordCount <= 50 else {
            throw QuestionEngineError.invalidResponse("Question is too long")
        }
        
        // Check for generic or low-quality questions
        let lowercased = question.lowercased()
        let genericPhrases = ["tell me about", "what do you think", "how do you feel", "what's your favorite"]
        
        for phrase in genericPhrases {
            if lowercased.contains(phrase) {
                throw QuestionEngineError.invalidResponse("Question appears to be too generic")
            }
        }
    }
}

// MARK: - Error Types

/// Comprehensive error types for question generation failures
public enum QuestionEngineError: LocalizedError, Equatable {
    case llmServiceError(LLMServiceError)
    case invalidResponse(String)
    case generationFailed(String)
    case timeout(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .llmServiceError(let llmError):
            return "LLM Service Error: \(llmError.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .generationFailed(let message):
            return "Generation Failed: \(message)"
        case .timeout(let message):
            return "Timeout: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .llmServiceError:
            return "The language model service encountered an error"
        case .invalidResponse:
            return "The generated response could not be processed into a valid question"
        case .generationFailed:
            return "Question generation failed due to an internal error"
        case .timeout:
            return "The operation took too long to complete"
        case .configurationError:
            return "The question configuration is invalid"
        }
    }
    
    public static func == (lhs: QuestionEngineError, rhs: QuestionEngineError) -> Bool {
        switch (lhs, rhs) {
        case (.llmServiceError(let lError), .llmServiceError(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        case (.invalidResponse(let lMessage), .invalidResponse(let rMessage)):
            return lMessage == rMessage
        case (.generationFailed(let lMessage), .generationFailed(let rMessage)):
            return lMessage == rMessage
        case (.timeout(let lMessage), .timeout(let rMessage)):
            return lMessage == rMessage
        case (.configurationError(let lMessage), .configurationError(let rMessage)):
            return lMessage == rMessage
        default:
            return false
        }
    }
}

// MARK: - Context Management Actor

/// Actor for thread-safe context management in async environments
private actor ContextActor {
    private var count: Int = 0
    
    func getCurrentCount() -> Int {
        return count
    }
    
    func incrementCount() -> Int {
        count += 1
        return count
    }
    
    func resetCount() {
        count = 0
    }
}