import Foundation
import OSLog

// MARK: - Session Management Protocol

/// Protocol defining the interface for compatibility session management
/// Handles storage, retrieval, and analysis of compatibility results across sessions
public protocol CompatibilitySessionManager {
    /// Saves a compatibility analysis result
    /// - Parameter result: The compatibility result to save
    /// - Throws: SessionManagerError for storage failures
    func saveResult(_ result: CompatibilityResult) async throws
    
    /// Retrieves all results for a specific session
    /// - Parameter sessionId: The unique session identifier
    /// - Returns: Array of compatibility results for the session
    /// - Throws: SessionManagerError for retrieval failures
    func getSessionResults(_ sessionId: UUID) async throws -> [CompatibilityResult]
    
    /// Retrieves all results for a user across all sessions
    /// - Parameter userId: The unique user identifier (optional for single-user scenarios)
    /// - Returns: Array of all compatibility results for the user
    /// - Throws: SessionManagerError for retrieval failures
    func getAllResults(for userId: UUID?) async throws -> [CompatibilityResult]
    
    /// Creates a new compatibility session
    /// - Parameter userId: Optional user identifier
    /// - Returns: New session UUID
    /// - Throws: SessionManagerError for creation failures
    func createSession(for userId: UUID?) async throws -> UUID
    
    /// Analyzes session progress and generates insights
    /// - Parameter sessionId: The session to analyze
    /// - Returns: Session analysis with trends and insights
    /// - Throws: SessionManagerError for analysis failures
    func analyzeSession(_ sessionId: UUID) async throws -> SessionAnalysis
    
    /// Clears old results based on retention policy
    /// - Throws: SessionManagerError for cleanup failures
    func cleanupOldResults() async throws
}

// MARK: - Session Manager Implementation

/// Production implementation of CompatibilitySessionManager
/// Provides persistent storage and analysis of compatibility results
public final class CompatibilitySessionManagerService: CompatibilitySessionManager {
    
    // MARK: - Dependencies
    
    private let compatibilityAnalyzer: CompatibilityAnalyzer
    private let storage: CompatibilityStorage
    private let logger: Logger
    
    // MARK: - Configuration
    
    private let maxResultsPerSession: Int
    private let resultRetentionDays: Int
    
    // MARK: - State
    
    private var activeSessions: Set<UUID> = []
    private let sessionQueue = DispatchQueue(label: "com.kickbackapp.compatibility.session", qos: .userInitiated)
    
    // MARK: - Initialization
    
    /// Initializes the session manager with dependencies
    /// - Parameters:
    ///   - compatibilityAnalyzer: Analyzer for generating session insights
    ///   - storage: Storage provider for persistence
    ///   - maxResultsPerSession: Maximum results to store per session (default: 50)
    ///   - resultRetentionDays: Days to retain results (default: 90)
    public init(
        compatibilityAnalyzer: CompatibilityAnalyzer = CompatibilityAnalyzerService(),
        storage: CompatibilityStorage = CompatibilityStorageService(),
        maxResultsPerSession: Int = 50,
        resultRetentionDays: Int = 90
    ) {
        self.compatibilityAnalyzer = compatibilityAnalyzer
        self.storage = storage
        self.maxResultsPerSession = maxResultsPerSession
        self.resultRetentionDays = resultRetentionDays
        self.logger = Logger(subsystem: "com.kickbackapp.compatibility", category: "SessionManager")
    }
    
    // MARK: - CompatibilitySessionManager Protocol Implementation
    
    public func saveResult(_ result: CompatibilityResult) async throws {
        logger.info("Saving compatibility result: \(result.id)")
        
        do {
            try await storage.save(result)
            logger.debug("Successfully saved compatibility result")
        } catch {
            logger.error("Failed to save compatibility result: \(error.localizedDescription)")
            throw SessionManagerError.storageError("Failed to save result: \(error.localizedDescription)")
        }
    }
    
    public func getSessionResults(_ sessionId: UUID) async throws -> [CompatibilityResult] {
        logger.info("Retrieving results for session: \(sessionId)")
        
        do {
            let results = try await storage.getResultsForSession(sessionId)
            logger.debug("Retrieved \(results.count) results for session")
            return results.sorted { $0.createdAt < $1.createdAt }
        } catch {
            logger.error("Failed to retrieve session results: \(error.localizedDescription)")
            throw SessionManagerError.retrievalError("Failed to retrieve session results: \(error.localizedDescription)")
        }
    }
    
    public func getAllResults(for userId: UUID?) async throws -> [CompatibilityResult] {
        logger.info("Retrieving all results for user: \(userId?.uuidString ?? "anonymous")")
        
        do {
            let results = try await storage.getAllResults(for: userId)
            logger.debug("Retrieved \(results.count) total results")
            return results.sorted { $0.createdAt < $1.createdAt }
        } catch {
            logger.error("Failed to retrieve all results: \(error.localizedDescription)")
            throw SessionManagerError.retrievalError("Failed to retrieve all results: \(error.localizedDescription)")
        }
    }
    
    public func createSession(for userId: UUID?) async throws -> UUID {
        let sessionId = UUID()
        logger.info("Creating new session: \(sessionId) for user: \(userId?.uuidString ?? "anonymous")")
        
        do {
            try await storage.createSession(sessionId, userId: userId)
            
            await withCheckedContinuation { continuation in
                sessionQueue.async {
                    self.activeSessions.insert(sessionId)
                    continuation.resume()
                }
            }
            
            logger.debug("Successfully created session")
            return sessionId
            
        } catch {
            logger.error("Failed to create session: \(error.localizedDescription)")
            throw SessionManagerError.sessionCreationError("Failed to create session: \(error.localizedDescription)")
        }
    }
    
    public func analyzeSession(_ sessionId: UUID) async throws -> SessionAnalysis {
        logger.info("Analyzing session: \(sessionId)")
        
        do {
            let results = try await getSessionResults(sessionId)
            
            guard !results.isEmpty else {
                throw SessionManagerError.analysisError("Cannot analyze empty session")
            }
            
            let sessionAnalysis = try await compatibilityAnalyzer.analyzeSession(results)
            
            // Save the session analysis
            try await storage.saveSessionAnalysis(sessionAnalysis)
            
            logger.info("Successfully analyzed session with \(results.count) results")
            return sessionAnalysis
            
        } catch {
            logger.error("Failed to analyze session: \(error.localizedDescription)")
            
            if let sessionError = error as? SessionManagerError {
                throw sessionError
            } else {
                throw SessionManagerError.analysisError("Session analysis failed: \(error.localizedDescription)")
            }
        }
    }
    
    public func cleanupOldResults() async throws {
        logger.info("Starting cleanup of old results")
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -resultRetentionDays, to: Date()) ?? Date.distantPast
        
        do {
            let deletedCount = try await storage.deleteResultsOlderThan(cutoffDate)
            logger.info("Cleaned up \(deletedCount) old results")
        } catch {
            logger.error("Failed to cleanup old results: \(error.localizedDescription)")
            throw SessionManagerError.cleanupError("Failed to cleanup old results: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Additional Public Methods
    
    /// Gets recent compatibility results for quick access
    /// - Parameter limit: Maximum number of results to return (default: 10)
    /// - Returns: Most recent compatibility results
    public func getRecentResults(limit: Int = 10) async throws -> [CompatibilityResult] {
        logger.info("Retrieving \(limit) most recent results")
        
        do {
            let results = try await storage.getRecentResults(limit: limit)
            logger.debug("Retrieved \(results.count) recent results")
            return results
        } catch {
            logger.error("Failed to retrieve recent results: \(error.localizedDescription)")
            throw SessionManagerError.retrievalError("Failed to retrieve recent results: \(error.localizedDescription)")
        }
    }
    
    /// Gets compatibility results by category for analysis
    /// - Parameter category: The question category to filter by
    /// - Returns: Results for the specified category
    public func getResultsByCategory(_ category: QuestionCategory) async throws -> [CompatibilityResult] {
        logger.info("Retrieving results for category: \(category.rawValue)")
        
        do {
            let results = try await storage.getResultsByCategory(category)
            logger.debug("Retrieved \(results.count) results for category")
            return results
        } catch {
            logger.error("Failed to retrieve results by category: \(error.localizedDescription)")
            throw SessionManagerError.retrievalError("Failed to retrieve results by category: \(error.localizedDescription)")
        }
    }
    
    /// Checks if a session is still active
    /// - Parameter sessionId: The session to check
    /// - Returns: True if the session is active
    public func isSessionActive(_ sessionId: UUID) async -> Bool {
        return await withCheckedContinuation { continuation in
            sessionQueue.async {
                continuation.resume(returning: self.activeSessions.contains(sessionId))
            }
        }
    }
    
    /// Ends an active session
    /// - Parameter sessionId: The session to end
    public func endSession(_ sessionId: UUID) async {
        logger.info("Ending session: \(sessionId)")
        
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                self.activeSessions.remove(sessionId)
                continuation.resume()
            }
        }
    }
    
    /// Gets session statistics
    /// - Parameter sessionId: The session to get stats for
    /// - Returns: Session statistics
    public func getSessionStatistics(_ sessionId: UUID) async throws -> SessionStatistics {
        logger.info("Getting statistics for session: \(sessionId)")
        
        do {
            let results = try await getSessionResults(sessionId)
            return calculateSessionStatistics(results)
        } catch {
            logger.error("Failed to get session statistics: \(error.localizedDescription)")
            throw SessionManagerError.analysisError("Failed to get session statistics: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Calculates statistics for a session
    private func calculateSessionStatistics(_ results: [CompatibilityResult]) -> SessionStatistics {
        guard !results.isEmpty else {
            return SessionStatistics(
                totalResponses: 0,
                averageScore: 0,
                scoreRange: (min: 0, max: 0),
                categoryBreakdown: [:],
                timeSpent: 0,
                improvementTrend: 0
            )
        }
        
        let scores = results.map { $0.score }
        let averageScore = scores.reduce(0, +) / scores.count
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 0
        
        // Calculate category breakdown
        var categoryBreakdown: [QuestionCategory: Int] = [:]
        for result in results {
            let category = result.analysisMetadata.questionCategory
            categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1
        }
        
        // Calculate time spent
        let timeSpent = results.last?.createdAt.timeIntervalSince(results.first?.createdAt ?? Date()) ?? 0
        
        // Calculate improvement trend
        let improvementTrend = scores.count > 1 ? scores.last! - scores.first! : 0
        
        return SessionStatistics(
            totalResponses: results.count,
            averageScore: averageScore,
            scoreRange: (min: minScore, max: maxScore),
            categoryBreakdown: categoryBreakdown,
            timeSpent: timeSpent,
            improvementTrend: improvementTrend
        )
    }
}

// MARK: - Session Statistics

/// Statistics for a compatibility session
public struct SessionStatistics {
    public let totalResponses: Int
    public let averageScore: Int
    public let scoreRange: (min: Int, max: Int)
    public let categoryBreakdown: [QuestionCategory: Int]
    public let timeSpent: TimeInterval
    public let improvementTrend: Int
    
    public init(
        totalResponses: Int,
        averageScore: Int,
        scoreRange: (min: Int, max: Int),
        categoryBreakdown: [QuestionCategory: Int],
        timeSpent: TimeInterval,
        improvementTrend: Int
    ) {
        self.totalResponses = totalResponses
        self.averageScore = averageScore
        self.scoreRange = scoreRange
        self.categoryBreakdown = categoryBreakdown
        self.timeSpent = timeSpent
        self.improvementTrend = improvementTrend
    }
}

// MARK: - Storage Protocol

/// Protocol for compatibility result storage
public protocol CompatibilityStorage {
    func save(_ result: CompatibilityResult) async throws
    func getResultsForSession(_ sessionId: UUID) async throws -> [CompatibilityResult]
    func getAllResults(for userId: UUID?) async throws -> [CompatibilityResult]
    func createSession(_ sessionId: UUID, userId: UUID?) async throws
    func saveSessionAnalysis(_ analysis: SessionAnalysis) async throws
    func deleteResultsOlderThan(_ date: Date) async throws -> Int
    func getRecentResults(limit: Int) async throws -> [CompatibilityResult]
    func getResultsByCategory(_ category: QuestionCategory) async throws -> [CompatibilityResult]
}

// MARK: - In-Memory Storage Implementation

/// In-memory storage implementation for compatibility results
/// Suitable for development and testing, but data is not persisted across app launches
public final class CompatibilityStorageService: CompatibilityStorage {
    
    private var results: [CompatibilityResult] = []
    private var sessions: [UUID: UUID?] = [:]  // sessionId -> userId
    private var sessionAnalyses: [SessionAnalysis] = []
    private let storageQueue = DispatchQueue(label: "com.kickbackapp.compatibility.storage", qos: .userInitiated)
    
    public init() {}
    
    public func save(_ result: CompatibilityResult) async throws {
        await withCheckedContinuation { continuation in
            storageQueue.async {
                self.results.append(result)
                continuation.resume()
            }
        }
    }
    
    public func getResultsForSession(_ sessionId: UUID) async throws -> [CompatibilityResult] {
        return await withCheckedContinuation { continuation in
            storageQueue.async {
                // For this simple implementation, we'll use a property on CompatibilityResult
                // In practice, you'd store the sessionId relationship
                let sessionResults = self.results.filter { _ in
                    // For now, return all results - in practice you'd filter by sessionId
                    true
                }
                continuation.resume(returning: sessionResults)
            }
        }
    }
    
    public func getAllResults(for userId: UUID?) async throws -> [CompatibilityResult] {
        return await withCheckedContinuation { continuation in
            storageQueue.async {
                // For single-user scenarios, return all results
                continuation.resume(returning: self.results)
            }
        }
    }
    
    public func createSession(_ sessionId: UUID, userId: UUID?) async throws {
        await withCheckedContinuation { continuation in
            storageQueue.async {
                self.sessions[sessionId] = userId
                continuation.resume()
            }
        }
    }
    
    public func saveSessionAnalysis(_ analysis: SessionAnalysis) async throws {
        await withCheckedContinuation { continuation in
            storageQueue.async {
                self.sessionAnalyses.append(analysis)
                continuation.resume()
            }
        }
    }
    
    public func deleteResultsOlderThan(_ date: Date) async throws -> Int {
        return await withCheckedContinuation { continuation in
            storageQueue.async {
                let initialCount = self.results.count
                self.results.removeAll { $0.createdAt < date }
                let deletedCount = initialCount - self.results.count
                continuation.resume(returning: deletedCount)
            }
        }
    }
    
    public func getRecentResults(limit: Int) async throws -> [CompatibilityResult] {
        return await withCheckedContinuation { continuation in
            storageQueue.async {
                let recentResults = Array(self.results.suffix(limit))
                continuation.resume(returning: recentResults)
            }
        }
    }
    
    public func getResultsByCategory(_ category: QuestionCategory) async throws -> [CompatibilityResult] {
        return await withCheckedContinuation { continuation in
            storageQueue.async {
                let categoryResults = self.results.filter { $0.analysisMetadata.questionCategory == category }
                continuation.resume(returning: categoryResults)
            }
        }
    }
}

// MARK: - Error Types

/// Errors that can occur during session management
public enum SessionManagerError: LocalizedError {
    case storageError(String)
    case retrievalError(String)
    case sessionCreationError(String)
    case analysisError(String)
    case cleanupError(String)
    case sessionNotFound(UUID)
    case invalidSession(String)
    
    public var errorDescription: String? {
        switch self {
        case .storageError(let message):
            return "Storage Error: \(message)"
        case .retrievalError(let message):
            return "Retrieval Error: \(message)"
        case .sessionCreationError(let message):
            return "Session Creation Error: \(message)"
        case .analysisError(let message):
            return "Analysis Error: \(message)"
        case .cleanupError(let message):
            return "Cleanup Error: \(message)"
        case .sessionNotFound(let sessionId):
            return "Session not found: \(sessionId)"
        case .invalidSession(let message):
            return "Invalid Session: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .storageError:
            return "Failed to store compatibility result"
        case .retrievalError:
            return "Failed to retrieve compatibility results"
        case .sessionCreationError:
            return "Failed to create compatibility session"
        case .analysisError:
            return "Failed to analyze session data"
        case .cleanupError:
            return "Failed to cleanup old results"
        case .sessionNotFound:
            return "The specified session could not be found"
        case .invalidSession:
            return "The session is invalid or corrupted"
        }
    }
}