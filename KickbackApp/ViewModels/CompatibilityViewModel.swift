import Foundation
import SwiftUI
import OSLog

// MARK: - Compatibility View Model

/// View model for managing compatibility analysis UI state and operations
/// Integrates with CompatibilityAnalyzer and SessionManager to provide seamless user experience
@MainActor
public final class CompatibilityViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current analysis state
    @Published var analysisState: AnalysisState = .idle
    
    /// Current compatibility result being displayed
    @Published var currentResult: CompatibilityResult?
    
    /// Most recent analysis results
    @Published var recentResults: [CompatibilityResult] = []
    
    /// Session analysis if available
    @Published var sessionAnalysis: SessionAnalysis?
    
    /// Current error state
    @Published var currentError: CompatibilityAnalysisError?
    
    /// Analysis progress (0.0 to 1.0)
    @Published var analysisProgress: Double = 0.0
    
    /// Whether to show detailed insights
    @Published var showDetailedInsights: Bool = false
    
    /// Selected insight for detailed view
    @Published var selectedInsight: CompatibilityInsight?
    
    /// Current session ID
    @Published var currentSessionId: UUID?
    
    /// Session statistics
    @Published var sessionStatistics: SessionStatistics?
    
    // MARK: - Dependencies
    
    private let compatibilityAnalyzer: CompatibilityAnalyzer
    private let sessionManager: CompatibilitySessionManager
    private let logger: Logger
    
    // MARK: - Configuration
    
    private let maxRecentResults: Int
    private let autoSaveResults: Bool
    
    // MARK: - Initialization
    
    /// Initializes the view model with dependencies
    /// - Parameters:
    ///   - compatibilityAnalyzer: Service for performing compatibility analysis
    ///   - sessionManager: Service for managing analysis sessions
    ///   - maxRecentResults: Maximum number of recent results to keep (default: 20)
    ///   - autoSaveResults: Whether to automatically save results (default: true)
    public init(
        compatibilityAnalyzer: CompatibilityAnalyzer = CompatibilityAnalyzerService(),
        sessionManager: CompatibilitySessionManager = CompatibilitySessionManagerService(),
        maxRecentResults: Int = 20,
        autoSaveResults: Bool = true
    ) {
        self.compatibilityAnalyzer = compatibilityAnalyzer
        self.sessionManager = sessionManager
        self.maxRecentResults = maxRecentResults
        self.autoSaveResults = autoSaveResults
        self.logger = Logger(subsystem: "com.kickbackapp.compatibility", category: "ViewModel")
        
        // Load recent results on initialization
        Task {
            await loadRecentResults()
        }
    }
    
    // MARK: - Public Methods
    
    /// Analyzes a transcribed response
    /// - Parameters:
    ///   - response: The transcribed response text
    ///   - question: The question that was asked
    ///   - category: The question category
    ///   - userContext: Optional user context for personalization
    ///   - seed: Optional seed for deterministic testing
    public func analyzeResponse(
        _ response: String,
        question: String,
        category: QuestionCategory,
        userContext: UserContext? = nil,
        seed: UInt64? = nil
    ) async {
        logger.info("Starting response analysis for category: \(category.rawValue)")
        
        // Clear previous error
        currentError = nil
        analysisState = .analyzing
        analysisProgress = 0.1
        
        do {
            // Create analysis request
            let request = AnalysisRequest(
                transcribedResponse: response,
                question: question,
                questionCategory: category,
                userContext: userContext,
                analysisType: .individual,
                seed: seed
            )
            
            analysisProgress = 0.3
            
            // Perform analysis
            let result = try await compatibilityAnalyzer.analyzeResponse(request)
            
            analysisProgress = 0.8
            
            // Save result if auto-save is enabled
            if autoSaveResults {
                try await sessionManager.saveResult(result)
            }
            
            analysisProgress = 1.0
            
            // Update UI state
            currentResult = result
            analysisState = .completed
            
            // Add to recent results
            await addToRecentResults(result)
            
            logger.info("Successfully completed response analysis")
            
        } catch {
            logger.error("Response analysis failed: \(error.localizedDescription)")
            
            currentError = error as? CompatibilityAnalysisError ?? .processingError(error.localizedDescription)
            analysisState = .error
            analysisProgress = 0.0
        }
    }
    
    /// Compares two responses for compatibility
    /// - Parameters:
    ///   - response1: First user's response
    ///   - response2: Second user's response
    ///   - question: The question both users answered
    ///   - category: The question category
    public func compareResponses(
        response1: String,
        response2: String,
        question: String,
        category: QuestionCategory
    ) async {
        logger.info("Starting comparative analysis")
        
        currentError = nil
        analysisState = .analyzing
        analysisProgress = 0.1
        
        do {
            // Create analysis requests
            let request1 = AnalysisRequest(
                transcribedResponse: response1,
                question: question,
                questionCategory: category,
                analysisType: .comparative
            )
            
            let request2 = AnalysisRequest(
                transcribedResponse: response2,
                question: question,
                questionCategory: category,
                analysisType: .comparative
            )
            
            analysisProgress = 0.5
            
            // Perform comparative analysis
            let comparativeResult = try await compatibilityAnalyzer.compareResponses(
                user1Request: request1,
                user2Request: request2
            )
            
            analysisProgress = 1.0
            analysisState = .completed
            
            // For comparative results, we could store differently or show in a different view
            // For now, we'll show the first user's individual result
            currentResult = comparativeResult.user1Result
            
            logger.info("Successfully completed comparative analysis")
            
        } catch {
            logger.error("Comparative analysis failed: \(error.localizedDescription)")
            
            currentError = error as? CompatibilityAnalysisError ?? .processingError(error.localizedDescription)
            analysisState = .error
            analysisProgress = 0.0
        }
    }
    
    /// Starts a new compatibility session
    /// - Parameter userId: Optional user identifier
    public func startNewSession(for userId: UUID? = nil) async {
        logger.info("Starting new compatibility session")
        
        do {
            let sessionId = try await sessionManager.createSession(for: userId)
            currentSessionId = sessionId
            
            // Clear previous results
            currentResult = nil
            sessionAnalysis = nil
            sessionStatistics = nil
            
            logger.info("Successfully started session: \(sessionId)")
            
        } catch {
            logger.error("Failed to start session: \(error.localizedDescription)")
            currentError = .processingError("Failed to start new session: \(error.localizedDescription)")
        }
    }
    
    /// Analyzes the current session
    public func analyzeCurrentSession() async {
        guard let sessionId = currentSessionId else {
            logger.warning("No active session to analyze")
            currentError = .configurationError("No active session")
            return
        }
        
        logger.info("Analyzing current session: \(sessionId)")
        
        do {
            let analysis = try await sessionManager.analyzeSession(sessionId)
            sessionAnalysis = analysis
            
            // Update session statistics
            sessionStatistics = try await sessionManager.getSessionStatistics(sessionId)
            
            logger.info("Successfully analyzed session")
            
        } catch {
            logger.error("Session analysis failed: \(error.localizedDescription)")
            currentError = .analysisError("Session analysis failed: \(error.localizedDescription)")
        }
    }
    
    /// Loads recent compatibility results
    public func loadRecentResults() async {
        logger.info("Loading recent results")
        
        do {
            let results = try await sessionManager.getRecentResults(limit: maxRecentResults)
            recentResults = results
            
            logger.debug("Loaded \(results.count) recent results")
            
        } catch {
            logger.error("Failed to load recent results: \(error.localizedDescription)")
            // Don't set error for this, as it's not critical
        }
    }
    
    /// Clears the current result and resets state
    public func clearCurrentResult() {
        logger.info("Clearing current result")
        
        currentResult = nil
        currentError = nil
        analysisState = .idle
        analysisProgress = 0.0
        selectedInsight = nil
    }
    
    /// Retries the last analysis
    public func retryAnalysis() async {
        guard analysisState == .error else {
            logger.warning("Cannot retry - no failed analysis")
            return
        }
        
        // For now, we'll just clear the error state
        // In practice, you'd store the last request and retry it
        currentError = nil
        analysisState = .idle
        analysisProgress = 0.0
    }
    
    /// Shows detailed view for a specific insight
    /// - Parameter insight: The insight to show details for
    public func showInsightDetails(_ insight: CompatibilityInsight) {
        selectedInsight = insight
        showDetailedInsights = true
    }
    
    /// Hides detailed insight view
    public func hideInsightDetails() {
        selectedInsight = nil
        showDetailedInsights = false
    }
    
    /// Gets results for a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Results for the specified category
    public func getResultsForCategory(_ category: QuestionCategory) async -> [CompatibilityResult] {
        do {
            return try await sessionManager.getResultsByCategory(category)
        } catch {
            logger.error("Failed to get results for category: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Ends the current session
    public func endCurrentSession() async {
        guard let sessionId = currentSessionId else {
            return
        }
        
        logger.info("Ending current session: \(sessionId)")
        
        await sessionManager.endSession(sessionId)
        currentSessionId = nil
        sessionAnalysis = nil
        sessionStatistics = nil
    }
    
    // MARK: - Private Methods
    
    /// Adds a result to recent results list
    private func addToRecentResults(_ result: CompatibilityResult) async {
        // Add to beginning of list
        recentResults.insert(result, at: 0)
        
        // Trim to max size
        if recentResults.count > maxRecentResults {
            recentResults = Array(recentResults.prefix(maxRecentResults))
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether analysis is currently in progress
    public var isAnalyzing: Bool {
        analysisState == .analyzing
    }
    
    /// Whether there's a current error
    public var hasError: Bool {
        currentError != nil
    }
    
    /// Whether there's a current result to display
    public var hasResult: Bool {
        currentResult != nil
    }
    
    /// Whether there's an active session
    public var hasActiveSession: Bool {
        currentSessionId != nil
    }
    
    /// Formatted analysis progress text
    public var progressText: String {
        switch analysisState {
        case .idle:
            return "Ready to analyze"
        case .analyzing:
            let percentage = Int(analysisProgress * 100)
            return "Analyzing... \(percentage)%"
        case .completed:
            return "Analysis complete"
        case .error:
            return "Analysis failed"
        }
    }
    
    /// Current result's score as a formatted string
    public var formattedScore: String {
        guard let result = currentResult else { return "—" }
        return "\(result.score)"
    }
    
    /// Current result's score category
    public var scoreCategory: String {
        guard let result = currentResult else { return "" }
        
        switch result.score {
        case 90...100:
            return "Exceptional"
        case 80..<90:
            return "Strong"
        case 70..<80:
            return "Good"
        case 60..<70:
            return "Moderate"
        case 50..<60:
            return "Basic"
        default:
            return "Developing"
        }
    }
    
    /// Color for the current score
    public var scoreColor: Color {
        guard let result = currentResult else { return .gray }
        
        switch result.score {
        case 80...100:
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Analysis State

/// Current state of compatibility analysis
public enum AnalysisState {
    case idle
    case analyzing
    case completed
    case error
}

// MARK: - Extensions for UI Helpers

extension CompatibilityViewModel {
    
    /// Gets icon name for an insight type
    /// - Parameter type: The insight type
    /// - Returns: SF Symbol name for the insight type
    public func iconName(for type: InsightType) -> String {
        switch type {
        case .strength:
            return "star.fill"
        case .growthArea:
            return "arrow.up.circle"
        case .communicationPattern:
            return "message.circle"
        case .emotionalIntelligence:
            return "heart.circle"
        case .relationshipReadiness:
            return "person.2.circle"
        case .compatibility:
            return "heart.text.square"
        }
    }
    
    /// Gets color for an insight confidence level
    /// - Parameter confidence: The confidence level
    /// - Returns: Color for the confidence level
    public func color(for confidence: InsightConfidence) -> Color {
        switch confidence {
        case .low:
            return .gray
        case .medium:
            return .orange
        case .high:
            return .blue
        case .veryHigh:
            return .green
        }
    }
    
    /// Gets formatted text for a dimension score
    /// - Parameters:
    ///   - score: The dimension score (0-100)
    ///   - dimensionName: Name of the dimension
    /// - Returns: Formatted text description
    public func formattedDimensionText(_ score: Int, dimensionName: String) -> String {
        let level = dimensionLevel(for: score)
        return "\(dimensionName): \(level) (\(score))"
    }
    
    /// Gets level description for a dimension score
    /// - Parameter score: The dimension score (0-100)
    /// - Returns: Level description
    private func dimensionLevel(for score: Int) -> String {
        switch score {
        case 85...100:
            return "Excellent"
        case 70..<85:
            return "Strong"
        case 55..<70:
            return "Good"
        case 40..<55:
            return "Developing"
        default:
            return "Needs Growth"
        }
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension CompatibilityViewModel {
    /// Creates a view model with mock data for SwiftUI previews
    static func mockViewModel() -> CompatibilityViewModel {
        let viewModel = CompatibilityViewModel()
        
        // Mock current result
        let mockDimensions = CompatibilityDimensions(
            emotionalOpenness: 78,
            clarity: 85,
            empathy: 72,
            vulnerability: 68,
            communicationStyle: 82
        )
        
        let mockInsights = [
            CompatibilityInsight(
                type: .strength,
                title: "Clear Communication",
                description: "You express yourself clearly and directly, making it easy for others to understand your thoughts and feelings.",
                confidence: .high,
                relatedDimension: "Clarity"
            ),
            CompatibilityInsight(
                type: .growthArea,
                title: "Emotional Vulnerability",
                description: "Consider sharing more personal experiences and feelings to deepen emotional connections.",
                confidence: .medium,
                relatedDimension: "Vulnerability"
            )
        ]
        
        let mockMetadata = AnalysisMetadata(
            promptUsed: "Mock prompt",
            rawLLMResponse: "Mock LLM response",
            processingDuration: 1.5,
            analysisType: .individual,
            questionCategory: .earlyDating,
            responseLength: 150
        )
        
        viewModel.currentResult = CompatibilityResult(
            score: 77,
            summary: "You demonstrate strong communication skills with good emotional awareness. Focus on increasing vulnerability to deepen connections.",
            tone: "Thoughtful",
            dimensions: mockDimensions,
            insights: mockInsights,
            analysisMetadata: mockMetadata
        )
        
        viewModel.analysisState = .completed
        
        return viewModel
    }
}