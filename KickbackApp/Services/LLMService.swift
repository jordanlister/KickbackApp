import Foundation
import OSLog

// Import Foundation Models when available in iOS 26 SDK
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - iOS 26 LLM Service

/// Production LLMService for iOS 26 - ready for Foundation Models framework
/// Provides on-device language model inference through Apple Intelligence
@available(iOS 26.0, *)
public final class LLMService {
    
    // MARK: - Singleton
    public static let shared = LLMService()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.kickbackapp.llm", category: "FoundationModels")
    #if canImport(FoundationModels)
    private var currentSession: LanguageModelSession?
    private var isSessionBusy = false
    #endif
    private let sessionQueue = DispatchQueue(label: "com.kickbackapp.llm.session", qos: .userInitiated)
    private let sessionLock = NSLock()
    
    // MARK: - Configuration
    private let maxRetries = 3
    private let requestTimeout: TimeInterval = 30.0
    private let maxTokens = 150
    
    // MARK: - Initialization
    private init() {
        logger.info("Initializing Foundation Models LLMService")
        checkModelAvailability()
    }
    
    // MARK: - Public Interface
    
    /// Generates a response using Apple's on-device language model
    /// - Parameter prompt: The input prompt for generation
    /// - Returns: Generated response text
    /// - Throws: LLMServiceError for various failure scenarios
    public func generateResponse(for prompt: String) async throws -> String {
        logger.info("Starting response generation for prompt length: \(prompt.count)")
        
        // Validate prompt
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMServiceError.invalidInput("Prompt cannot be empty")
        }
        
        guard prompt.count <= 2000 else {
            throw LLMServiceError.invalidInput("Prompt too long (max 2000 characters)")
        }
        
        // Check model availability
        try checkModelReadiness()
        
        // Generate with retry logic
        for attempt in 1...maxRetries {
            do {
                logger.debug("Generation attempt \(attempt)/\(self.maxRetries)")
                
                let response = try await withTimeout(seconds: requestTimeout) {
                    try await self.performGeneration(prompt: prompt)
                }
                
                logger.info("Successfully generated response with \(response.count) characters")
                return response
                
            } catch {
                logger.warning("Attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Handle safety guardrails specifically
                if error.localizedDescription.contains("Safety guardrails") || error.localizedDescription.contains("unsafe") {
                    logger.info("Safety guardrails triggered - using simplified prompt")
                    // For safety issues, we could try a more conservative prompt
                    if attempt < maxRetries {
                        continue // Retry with existing logic
                    }
                }
                
                if attempt == maxRetries {
                    logger.error("All generation attempts failed")
                    throw error
                }
                
                // Exponential backoff
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw LLMServiceError.generationFailed("Unexpected retry loop exit")
    }
    
    // MARK: - Private Methods
    
    /// Performs the actual generation using Foundation Models
    #if canImport(FoundationModels)
    private func performGeneration(prompt: String) async throws -> String {
        // Acquire session lock to prevent concurrent requests
        sessionLock.lock()
        defer { sessionLock.unlock() }
        
        // Check if session is busy
        if isSessionBusy {
            logger.warning("Session busy, waiting...")
            // Wait a moment and retry
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        // Get or create session
        let session = try await getLanguageModelSession()
        
        // Mark session as busy
        isSessionBusy = true
        defer { isSessionBusy = false }
        
        // Create request with optimal prompt formatting
        let formattedPrompt = formatPromptForGeneration(prompt)
        
        // Generate response
        let response = try await session.respond(to: formattedPrompt)
        
        // Process and validate response
        let processedResponse = processResponse(response.content)
        
        guard !processedResponse.isEmpty else {
            throw LLMServiceError.invalidResponse("Empty response from model")
        }
        
        return processedResponse
    }
    #else
    private func performGeneration(prompt: String) async throws -> String {
        throw LLMServiceError.deviceNotSupported("Foundation Models framework not available")
    }
    #endif
    
    /// Gets or creates a language model session
    #if canImport(FoundationModels)
    private func getLanguageModelSession() async throws -> LanguageModelSession {
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    if let existingSession = self.currentSession {
                        continuation.resume(returning: existingSession)
                    } else {
                        let newSession = LanguageModelSession()
                        self.currentSession = newSession
                        continuation.resume(returning: newSession)
                    }
                }
            }
        }
    }
    #else
    private func getLanguageModelSession() async throws -> Never {
        throw LLMServiceError.deviceNotSupported("Foundation Models framework not available")
    }
    #endif
    
    /// Checks if the language model is ready for use
    private func checkModelReadiness() throws {
        #if canImport(FoundationModels)
        let availability = SystemLanguageModel.default.availability
        
        switch availability {
        case .available:
            logger.debug("Foundation Models available and ready")
            return
            
        case .unavailable(let reason):
            let errorMessage: String
            let serviceError: LLMServiceError
            
            switch reason {
            case .appleIntelligenceNotEnabled:
                errorMessage = "Apple Intelligence is not enabled. Please enable it in Settings > Apple Intelligence & Siri."
                serviceError = .setupRequired(errorMessage)
                
            case .deviceNotEligible:
                errorMessage = "This device is not eligible for Apple Intelligence. Requires iPhone 15 Pro or later, iPad with M1 or later, or Mac with Apple Silicon."
                serviceError = .deviceNotSupported(errorMessage)
                
            case .modelNotReady:
                errorMessage = "The language model is downloading or not ready. Please try again in a few minutes."
                serviceError = .modelNotReady(errorMessage)
                
            @unknown default:
                errorMessage = "Language model is unavailable for an unknown reason."
                serviceError = .serviceUnavailable(errorMessage)
            }
            
            logger.error("Model availability check failed: \(errorMessage)")
            throw serviceError
        }
        #else
        // Foundation Models not available - provide helpful error
        throw LLMServiceError.deviceNotSupported("Foundation Models framework not available in this iOS version")
        #endif
    }
    
    /// Initial availability check and logging
    private func checkModelAvailability() {
        #if canImport(FoundationModels)
        let availability = SystemLanguageModel.default.availability
        
        switch availability {
        case .available:
            logger.info("✅ Foundation Models ready for inference")
            
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                logger.warning("⚠️ Apple Intelligence not enabled - user setup required")
            case .deviceNotEligible:
                logger.error("❌ Device not eligible for Apple Intelligence")
            case .modelNotReady:
                logger.info("⏳ Model downloading - will be ready soon")
            @unknown default:
                logger.warning("⚠️ Unknown availability issue")
            }
        }
        #else
        logger.info("Foundation Models framework not available - using fallback")
        #endif
    }
    
    /// Formats prompt for optimal generation results
    private func formatPromptForGeneration(_ prompt: String) -> String {
        // Safety-optimized prompt structure for Foundation Models
        let instruction = "Create a positive, constructive conversation question for couples. Focus on building understanding and connection. Generate only the question with proper punctuation."
        
        return """
        \(instruction)
        
        Context: \(prompt)
        
        Generate a thoughtful question:
        """
    }
    
    /// Processes and cleans the model response
    private func processResponse(_ rawResponse: String) -> String {
        var processed = rawResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any instruction repetition
        if processed.hasPrefix("Question:") {
            processed = String(processed.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Ensure proper question formatting
        if !processed.hasSuffix("?") && !processed.isEmpty {
            processed += "?"
        }
        
        // Basic cleanup
        processed = processed.replacingOccurrences(of: "\\n", with: " ")
        processed = processed.replacingOccurrences(of: "  ", with: " ")
        
        return processed
    }
    
    /// Adds timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw LLMServiceError.timeout("Operation timed out after \(seconds) seconds")
            }
            
            guard let result = try await group.next() else {
                throw LLMServiceError.timeout("Task group failed")
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Resets the session (useful for memory management)
    public func resetSession() {
        #if canImport(FoundationModels)
        sessionQueue.async {
            self.currentSession = nil
            self.logger.debug("Language model session reset")
        }
        #else
        logger.debug("Session reset not available - Foundation Models framework not imported")
        #endif
    }
}

// MARK: - Error Types

/// Comprehensive error types for LLM service operations
public enum LLMServiceError: LocalizedError, Equatable {
    case deviceNotSupported(String)
    case setupRequired(String)
    case modelNotReady(String)
    case serviceUnavailable(String)
    case sessionCreationFailed(String)
    case invalidInput(String)
    case invalidResponse(String)
    case generationFailed(String)
    case timeout(String)
    case memoryError(String)
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotSupported(let message):
            return "Device Not Supported: \(message)"
        case .setupRequired(let message):
            return "Setup Required: \(message)"
        case .modelNotReady(let message):
            return "Model Not Ready: \(message)"
        case .serviceUnavailable(let message):
            return "Service Unavailable: \(message)"
        case .sessionCreationFailed(let message):
            return "Session Creation Failed: \(message)"
        case .invalidInput(let message):
            return "Invalid Input: \(message)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .generationFailed(let message):
            return "Generation Failed: \(message)"
        case .timeout(let message):
            return "Timeout: \(message)"
        case .memoryError(let message):
            return "Memory Error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .deviceNotSupported:
            return "The device does not support Apple Intelligence"
        case .setupRequired:
            return "Apple Intelligence needs to be enabled in Settings"
        case .modelNotReady:
            return "The language model is still downloading or initializing"
        case .serviceUnavailable:
            return "The language model service is temporarily unavailable"
        case .sessionCreationFailed:
            return "Failed to create a language model session"
        case .invalidInput:
            return "The input prompt is invalid or malformed"
        case .invalidResponse:
            return "The model response could not be processed"
        case .generationFailed:
            return "Text generation failed due to an internal error"
        case .timeout:
            return "The operation took too long to complete"
        case .memoryError:
            return "Insufficient memory to complete the operation"
        }
    }
    
    public static func == (lhs: LLMServiceError, rhs: LLMServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.deviceNotSupported(let lMsg), .deviceNotSupported(let rMsg)):
            return lMsg == rMsg
        case (.setupRequired(let lMsg), .setupRequired(let rMsg)):
            return lMsg == rMsg
        case (.modelNotReady(let lMsg), .modelNotReady(let rMsg)):
            return lMsg == rMsg
        case (.serviceUnavailable(let lMsg), .serviceUnavailable(let rMsg)):
            return lMsg == rMsg
        case (.sessionCreationFailed(let lMsg), .sessionCreationFailed(let rMsg)):
            return lMsg == rMsg
        case (.invalidInput(let lMsg), .invalidInput(let rMsg)):
            return lMsg == rMsg
        case (.invalidResponse(let lMsg), .invalidResponse(let rMsg)):
            return lMsg == rMsg
        case (.generationFailed(let lMsg), .generationFailed(let rMsg)):
            return lMsg == rMsg
        case (.timeout(let lMsg), .timeout(let rMsg)):
            return lMsg == rMsg
        case (.memoryError(let lMsg), .memoryError(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - Fallback for iOS < 26

/// Fallback implementation for devices that don't support Foundation Models
@available(iOS, deprecated: 26.0, message: "Use Foundation Models implementation")
public class FallbackLLMService {
    
    public static let shared = FallbackLLMService()
    
    private init() {}
    
    public func generateResponse(for prompt: String) async throws -> String {
        // Provide helpful error for older iOS versions
        throw LLMServiceError.deviceNotSupported("Foundation Models requires iOS 26.0 or later with Apple Intelligence support")
    }
}