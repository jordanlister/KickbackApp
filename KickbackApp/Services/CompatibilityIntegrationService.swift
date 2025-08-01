import Foundation
import OSLog

// MARK: - Integration Service for Compatibility Analysis

/// Service that integrates compatibility analysis with existing QuestionEngine and AudioTranscriber
/// Provides seamless workflow from question generation to analysis results
@MainActor
public final class CompatibilityIntegrationService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current workflow state
    @Published var workflowState: WorkflowState = .idle
    
    /// Current question being processed
    @Published var currentQuestion: QuestionResult?
    
    /// Current transcription result
    @Published var currentTranscription: String = ""
    
    /// Current compatibility analysis
    @Published var currentAnalysis: CompatibilityResult?
    
    /// Integration errors
    @Published var integrationError: IntegrationError?
    
    /// Progress through the workflow (0.0 to 1.0)
    @Published var workflowProgress: Double = 0.0
    
    // MARK: - Dependencies
    
    private let questionEngine: QuestionEngine
    private let audioTranscriber: AudioTranscriber?
    private let compatibilityAnalyzer: CompatibilityAnalyzer
    private let sessionManager: CompatibilitySessionManager
    private let logger: Logger
    
    // MARK: - Configuration
    
    private let autoAnalyze: Bool
    private let saveResults: Bool
    
    // MARK: - Initialization
    
    /// Initializes the integration service with dependencies
    /// - Parameters:
    ///   - questionEngine: Service for generating questions
    ///   - audioTranscriber: Service for transcribing audio responses
    ///   - compatibilityAnalyzer: Service for analyzing compatibility
    ///   - sessionManager: Service for managing analysis sessions
    ///   - autoAnalyze: Whether to automatically analyze after transcription (default: true)
    ///   - saveResults: Whether to automatically save results (default: true)
    public init(
        questionEngine: QuestionEngine = QuestionEngineService(),
        audioTranscriber: AudioTranscriber? = nil,
        compatibilityAnalyzer: CompatibilityAnalyzer = CompatibilityAnalyzerService(),
        sessionManager: CompatibilitySessionManager = CompatibilitySessionManagerService(),
        autoAnalyze: Bool = true,
        saveResults: Bool = true
    ) {
        self.questionEngine = questionEngine
        self.audioTranscriber = audioTranscriber
        self.compatibilityAnalyzer = compatibilityAnalyzer
        self.sessionManager = sessionManager
        self.autoAnalyze = autoAnalyze
        self.saveResults = saveResults
        self.logger = Logger(subsystem: "com.kickbackapp.compatibility", category: "Integration")
    }
    
    // MARK: - Workflow Methods
    
    /// Starts a complete compatibility analysis workflow
    /// - Parameters:
    ///   - category: Question category to generate
    ///   - userContext: Optional user context for personalization
    public func startCompatibilityWorkflow(
        for category: QuestionCategory,
        userContext: UserContext? = nil
    ) async {
        logger.info("Starting compatibility workflow for category: \(category.rawValue)")
        
        workflowState = .generatingQuestion
        workflowProgress = 0.1
        integrationError = nil
        
        do {
            // Step 1: Generate question
            let questionText = try await questionEngine.generateQuestion(for: category)
            let questionResult = QuestionResult(
                question: questionText,
                category: category,
                configuration: QuestionConfiguration(category: category),
                processingMetadata: ProcessingMetadata(
                    promptUsed: "Integration Service Generated",
                    rawLLMResponse: questionText,
                    processingDuration: 0.0
                )
            )
            currentQuestion = questionResult
            workflowProgress = 0.2
            
            logger.info("Generated question: \(questionText, privacy: .private)")
            
            // Step 2: Wait for user to provide response (handled externally)
            workflowState = .waitingForResponse
            workflowProgress = 0.3
            
        } catch {
            logger.error("Failed to generate question: \(error.localizedDescription)")
            integrationError = .questionGenerationFailed(error)
            workflowState = .error
            workflowProgress = 0.0
        }
    }
    
    /// Starts audio recording for response capture
    public func startRecording() async {
        guard workflowState == .waitingForResponse else {
            logger.warning("Cannot start recording - workflow not in correct state")
            return
        }
        
        logger.info("Starting audio recording")
        workflowState = .recording
        workflowProgress = 0.4
        
        guard let audioTranscriber = audioTranscriber else {
            logger.error("AudioTranscriber not available")
            integrationError = .recordingFailed(NSError(domain: "AudioTranscriber", code: -1, userInfo: [NSLocalizedDescriptionKey: "AudioTranscriber not initialized"]))
            workflowState = .error
            return
        }
        
        do {
            try await audioTranscriber.startRecording()
            logger.info("Audio recording started successfully")
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            integrationError = .recordingFailed(error)
            workflowState = .error
        }
    }
    
    /// Stops audio recording and processes the transcription
    public func stopRecordingAndProcess() async {
        guard workflowState == .recording else {
            logger.warning("Cannot stop recording - not currently recording")
            return
        }
        
        logger.info("Stopping audio recording and processing")
        workflowState = .transcribing
        workflowProgress = 0.6
        
        guard let audioTranscriber = audioTranscriber else {
            logger.error("AudioTranscriber not available for stopping recording")
            integrationError = .recordingFailed(NSError(domain: "AudioTranscriber", code: -1, userInfo: [NSLocalizedDescriptionKey: "AudioTranscriber not initialized"]))
            workflowState = .error
            return
        }
        
        do {
            // Stop recording and get transcription
            let transcription = await audioTranscriber.stopRecording()
            currentTranscription = transcription
            
            logger.info("Transcription completed: \(transcription, privacy: .private)")
            workflowProgress = 0.7
            
            // Validate transcription
            guard !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw IntegrationError.emptyTranscription
            }
            
            // Auto-analyze if enabled
            if autoAnalyze {
                await performCompatibilityAnalysis()
            } else {
                workflowState = .transcriptionComplete
                workflowProgress = 0.8
            }
            
        } catch {
            logger.error("Failed to process transcription: \(error.localizedDescription)")
            integrationError = error as? IntegrationError ?? .transcriptionFailed(error)
            workflowState = .error
        }
    }
    
    /// Performs compatibility analysis on the current transcription
    public func performCompatibilityAnalysis() async {
        guard let question = currentQuestion else {
            logger.error("No question available for analysis")
            integrationError = .missingData("No question available")
            workflowState = .error
            return
        }
        
        guard !currentTranscription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.error("No transcription available for analysis")
            integrationError = .missingData("No transcription available")
            workflowState = .error
            return
        }
        
        logger.info("Starting compatibility analysis")
        workflowState = .analyzing
        workflowProgress = 0.8
        
        do {
            // Create analysis request
            let request = AnalysisRequest(
                transcribedResponse: currentTranscription,
                question: question.question,
                questionCategory: question.category,
                userContext: nil, // Could be enhanced to include user context
                analysisType: .individual
            )
            
            // Perform analysis
            let result = try await compatibilityAnalyzer.analyzeResponse(request)
            currentAnalysis = result
            
            logger.info("Compatibility analysis completed with score: \(result.score)")
            workflowProgress = 0.9
            
            // Save result if enabled
            if saveResults {
                try await sessionManager.saveResult(result)
                logger.info("Analysis result saved")
            }
            
            workflowState = .complete
            workflowProgress = 1.0
            
        } catch {
            logger.error("Compatibility analysis failed: \(error.localizedDescription)")
            integrationError = .analysisFailed(error)
            workflowState = .error
            workflowProgress = 0.8
        }
    }
    
    /// Resets the workflow to start fresh
    public func resetWorkflow() {
        logger.info("Resetting compatibility workflow")
        
        workflowState = .idle
        workflowProgress = 0.0
        currentQuestion = nil
        currentTranscription = ""
        currentAnalysis = nil
        integrationError = nil
    }
    
    /// Retries the current step if there was an error
    public func retryCurrentStep() async {
        guard workflowState == .error else {
            logger.warning("Cannot retry - workflow not in error state")
            return
        }
        
        integrationError = nil
        
        // Determine what step to retry based on current state
        if currentQuestion == nil {
            // Retry question generation - would need category stored
            logger.info("Would retry question generation (category needed)")
        } else if currentTranscription.isEmpty {
            // Retry transcription
            await stopRecordingAndProcess()
        } else if currentAnalysis == nil {
            // Retry analysis
            await performCompatibilityAnalysis()
        }
    }
    
    // MARK: - Integration Helpers
    
    /// Processes a pre-recorded audio file for compatibility analysis
    /// - Parameters:
    ///   - audioURL: URL to the audio file
    ///   - question: The question that was asked
    ///   - category: The question category
    public func processAudioFile(
        _ audioURL: URL,
        question: String,
        category: QuestionCategory
    ) async {
        logger.info("Processing audio file for compatibility analysis")
        
        workflowState = .transcribing
        workflowProgress = 0.5
        integrationError = nil
        
        // Create mock question result
        let questionResult = QuestionResult(
            question: question,
            category: category,
            configuration: QuestionConfiguration(category: category),
            processingMetadata: ProcessingMetadata(
                promptUsed: "Direct question input",
                rawLLMResponse: "N/A",
                processingDuration: 0
            )
        )
        currentQuestion = questionResult
        
        // In a real implementation, you would process the audio file here
        // For now, we'll simulate with a placeholder
        currentTranscription = "Simulated transcription from audio file"
        workflowProgress = 0.7
        
        if autoAnalyze {
            await performCompatibilityAnalysis()
        } else {
            workflowState = .transcriptionComplete
        }
    }
    
    /// Processes a text response directly (bypassing audio)
    /// - Parameters:
    ///   - response: The text response
    ///   - question: The question that was asked
    ///   - category: The question category
    public func processTextResponse(
        _ response: String,
        question: String,
        category: QuestionCategory
    ) async {
        logger.info("Processing text response for compatibility analysis")
        
        workflowState = .transcribing
        workflowProgress = 0.5
        integrationError = nil
        
        // Create mock question result
        let questionResult = QuestionResult(
            question: question,
            category: category,
            configuration: QuestionConfiguration(category: category),
            processingMetadata: ProcessingMetadata(
                promptUsed: "Direct question input",
                rawLLMResponse: "N/A",
                processingDuration: 0
            )
        )
        currentQuestion = questionResult
        currentTranscription = response
        workflowProgress = 0.7
        
        if autoAnalyze {
            await performCompatibilityAnalysis()
        } else {
            workflowState = .transcriptionComplete
        }
    }
    
    /// Gets the current workflow status as a user-friendly string
    public var workflowStatusText: String {
        switch workflowState {
        case .idle:
            return "Ready to start"
        case .generatingQuestion:
            return "Generating question..."
        case .waitingForResponse:
            return "Tap to record your response"
        case .recording:
            return "Recording... (tap to stop)"
        case .transcribing:
            return "Processing your response..."
        case .transcriptionComplete:
            return "Ready for analysis"
        case .analyzing:
            return "Analyzing compatibility..."
        case .complete:
            return "Analysis complete!"
        case .error:
            return "Error occurred"
        }
    }
    
    /// Whether the workflow can be advanced to the next step
    public var canAdvanceWorkflow: Bool {
        switch workflowState {
        case .waitingForResponse:
            return true // Can start recording
        case .recording:
            return true // Can stop recording
        case .transcriptionComplete:
            return true // Can start analysis
        default:
            return false
        }
    }
    
    /// Whether the current step can be retried
    public var canRetry: Bool {
        workflowState == .error
    }
}

// MARK: - Workflow State

/// States of the compatibility analysis workflow
public enum WorkflowState {
    case idle
    case generatingQuestion
    case waitingForResponse
    case recording
    case transcribing
    case transcriptionComplete
    case analyzing
    case complete
    case error
}

// MARK: - Integration Errors

/// Errors that can occur during workflow integration
public enum IntegrationError: LocalizedError {
    case questionGenerationFailed(Error)
    case recordingFailed(Error)
    case transcriptionFailed(Error)
    case emptyTranscription
    case analysisFailed(Error)
    case missingData(String)
    case workflowError(String)
    
    public var errorDescription: String? {
        switch self {
        case .questionGenerationFailed(let error):
            return "Failed to generate question: \(error.localizedDescription)"
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .emptyTranscription:
            return "No speech was detected in the recording"
        case .analysisFailed(let error):
            return "Analysis failed: \(error.localizedDescription)"
        case .missingData(let description):
            return "Missing required data: \(description)"
        case .workflowError(let description):
            return "Workflow error: \(description)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .questionGenerationFailed:
            return "Please try generating a new question or check your connection"
        case .recordingFailed:
            return "Check microphone permissions and try recording again"
        case .transcriptionFailed:
            return "Ensure you speak clearly and try recording again"
        case .emptyTranscription:
            return "Please record again and speak more clearly"
        case .analysisFailed:
            return "Try the analysis again or restart the workflow"
        case .missingData:
            return "Please complete all previous steps before continuing"
        case .workflowError:
            return "Reset the workflow and try again"
        }
    }
}

// MARK: - Convenience Extensions

extension CompatibilityIntegrationService {
    
    /// Quick method to generate and ask a random question
    /// - Parameter categories: Categories to choose from (defaults to common dating categories)
    public func generateRandomQuestion(
        from categories: [QuestionCategory] = [.earlyDating, .personalGrowth, .emotionalIntelligence, .funAndPlayful]
    ) async {
        let randomCategory = categories.randomElement() ?? .earlyDating
        await startCompatibilityWorkflow(for: randomCategory)
    }
    
    /// Convenience method for quick text-based analysis
    /// - Parameters:
    ///   - response: User's text response
    ///   - category: Question category (defaults to .earlyDating)
    public func quickTextAnalysis(
        response: String,
        category: QuestionCategory = .earlyDating
    ) async {
        let genericQuestion = "How do you approach building connections with new people?"
        await processTextResponse(response, question: genericQuestion, category: category)
    }
}

// MARK: - Integration with Existing ViewModels

extension CompatibilityIntegrationService {
    
    /// Creates a compatible analysis request from current workflow state
    /// - Returns: Analysis request if workflow state is valid
    public func createAnalysisRequest() -> AnalysisRequest? {
        guard let question = currentQuestion,
              !currentTranscription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        return AnalysisRequest(
            transcribedResponse: currentTranscription,
            question: question.question,
            questionCategory: question.category,
            userContext: nil,
            analysisType: .individual
        )
    }
    
    /// Integrates with existing CompatibilityViewModel
    /// - Parameter viewModel: The view model to update
    public func updateViewModel(_ viewModel: CompatibilityViewModel) {
        if let analysis = currentAnalysis {
            viewModel.currentResult = analysis
            viewModel.analysisState = .completed
        } else if workflowState == .analyzing {
            viewModel.analysisState = .analyzing
            viewModel.analysisProgress = workflowProgress
        } else if let error = integrationError {
            viewModel.currentError = .processingError(error.localizedDescription)
            viewModel.analysisState = .error
        }
    }
}