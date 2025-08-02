//
//  CardViewModel.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import Foundation
import SwiftUI

/// ViewModel for managing individual conversation card state and behavior
/// Handles question loading, animation states, and user interactions
@MainActor
public final class CardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current question displayed on this card
    @Published var question: String = ""
    
    /// Category of the current question
    @Published var category: QuestionCategory = .firstDate
    
    /// Loading state for question generation
    @Published var isLoading: Bool = false
    
    /// Error state for failed question generation
    @Published var errorMessage: String?
    
    /// Whether this card is currently flipped up (expanded state)
    @Published var isFlipped: Bool = false
    
    /// Unique identifier for this card
    let id = UUID()
    
    // MARK: - Dependencies
    
    private let questionEngine: QuestionEngine
    
    // MARK: - Animation Properties
    
    /// Tracks if this card is currently animating to prevent gesture conflicts
    @Published var isAnimating: Bool = false
    
    /// Character-by-character reveal progress for AI-style text generation effect
    @Published var revealProgress: Double = 0.0
    
    /// Displayed portion of question during reveal animation
    @Published var displayedQuestion: String = ""
    
    // MARK: - Voice Recording Properties
    
    /// Audio transcriber for voice input functionality
    @Published var audioTranscriber: AudioTranscriber = AudioTranscriber()
    
    /// User's voice answer to the current question
    @Published var voiceAnswer: String = ""
    
    /// Whether the card is currently in voice input mode
    @Published var isVoiceInputMode: Bool = false
    
    /// Whether voice permissions have been requested and granted
    @Published var voicePermissionsGranted: Bool = false
    
    // MARK: - Answer Management Properties
    
    /// Collection of answers for this card from both players
    @Published var cardAnswers: CardAnswers?
    
    /// Current player answering (from gameplay integration)
    @Published var currentPlayer: Player?
    
    /// Whether this card has been completed (both players answered)
    @Published var isCardComplete: Bool = false
    
    /// Animation state for card completion
    @Published var isCompletingCard: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes CardViewModel with dependency injection for testing
    /// - Parameter questionEngine: Service for generating questions (defaults to real AI service)
    init(questionEngine: QuestionEngine = QuestionEngineService()) {
        self.questionEngine = questionEngine
    }
    
    // MARK: - Public Methods
    
    /// Sets the card to loading state immediately for UI feedback
    func setLoadingState(for category: QuestionCategory) {
        self.category = category
        isLoading = true
        errorMessage = nil
        displayedQuestion = ""
        revealProgress = 0.0
    }
    
    /// Loads a new question for the specified category with smooth animation
    /// - Parameter category: The question category to generate
    func loadQuestion(for category: QuestionCategory) async {
        // If not already loading, set up the loading state
        if !isLoading {
            setLoadingState(for: category)
        }
        
        do {
            let newQuestion = try await questionEngine.generateQuestion(for: category)
            
            // Update question and start reveal animation
            question = newQuestion
            await startQuestionRevealAnimation()
            
            // Notify that question is ready
            onQuestionLoaded?()
            
        } catch {
            errorMessage = error.localizedDescription
            question = "Unable to load question. Please try again."
            displayedQuestion = question
        }
        
        isLoading = false
    }
    
    /// Flips the card to expanded state with smooth animation
    func flipUp() {
        guard !isAnimating else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            isFlipped = true
        }
    }
    
    /// Flips the card back to collapsed state
    func flipDown() {
        guard !isAnimating else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0)) {
            isFlipped = false
        }
    }
    
    /// Resets card to initial state for reuse
    func reset() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlipped = false
            revealProgress = 0.0
            displayedQuestion = ""
            errorMessage = nil
            voiceAnswer = ""
            isVoiceInputMode = false
        }
    }
    
    // MARK: - Voice Recording Methods
    
    /// Starts voice recording for answering the current question
    func startVoiceRecording() async {
        guard !question.isEmpty else { return }
        
        // Since permissions are granted in onboarding, assume they're available
        voicePermissionsGranted = true
        
        do {
            isVoiceInputMode = true
            try await audioTranscriber.startRecording()
        } catch {
            errorMessage = error.localizedDescription
            isVoiceInputMode = false
        }
    }
    
    /// Stops voice recording and processes the transcription
    func stopVoiceRecording() async {
        guard isVoiceInputMode else { return }
        
        let transcription = await audioTranscriber.stopRecording()
        voiceAnswer = transcription
        isVoiceInputMode = false
        
        // If we got a valid transcription, keep the card flipped
        if !transcription.isEmpty {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFlipped = true
            }
        }
    }
    
    /// Toggles voice input mode
    func toggleVoiceInput() async {
        if isVoiceInputMode {
            await stopVoiceRecording()
        } else {
            await startVoiceRecording()
        }
    }
    
    /// Clears the current voice answer
    func clearVoiceAnswer() {
        withAnimation(.easeInOut(duration: 0.2)) {
            voiceAnswer = ""
        }
    }
    
    // MARK: - Answer Management Methods
    
    /// Initializes answer collection for this card
    /// - Parameters:
    ///   - currentPlayer: The player who will answer first
    ///   - gameSessionID: Optional game session identifier
    func initializeAnswerCollection(currentPlayer: Player, gameSessionID: UUID? = nil) {
        self.currentPlayer = currentPlayer
        
        // Create answer collection if not exists
        if cardAnswers == nil && !question.isEmpty {
            cardAnswers = CardAnswers(
                question: question,
                category: category,
                gameSessionID: gameSessionID
            )
        }
    }
    
    /// Records the current player's answer from voice input
    /// - Returns: True if answer was recorded successfully
    @discardableResult
    func recordCurrentPlayerAnswer() async -> Bool {
        guard let player = currentPlayer,
              let answers = cardAnswers,
              !voiceAnswer.isEmpty else {
            return false
        }
        
        // Create player answer from voice input
        let playerAnswer = PlayerAnswer(
            playerID: player.id,
            playerNumber: player.playerNumber,
            answerText: voiceAnswer,
            recordingDuration: audioTranscriber.recordingDuration,
            audioQuality: audioTranscriber.audioLevel
        )
        
        print("Recording answer for player \(player.playerNumber) (\(player.displayName)): \(voiceAnswer)")
        
        // Add answer to collection
        var updatedAnswers = answers
        updatedAnswers.setAnswer(playerAnswer)
        cardAnswers = updatedAnswers
        
        print("After recording: Player1 answered? \(updatedAnswers.player1Answer != nil), Player2 answered? \(updatedAnswers.player2Answer != nil)")
        print("Complete? \(updatedAnswers.isComplete)")
        
        // Clear current voice answer
        voiceAnswer = ""
        
        // Check if we need to switch to the other player
        if !updatedAnswers.isComplete {
            switchToOtherPlayer()
        } else {
            // Both players have answered, trigger completion
            checkCardCompletion()
        }
        
        return true
    }
    
    /// Switches to the other player for their turn to answer
    private func switchToOtherPlayer() {
        // Notify parent view that player needs to switch
        onPlayerNeedsToSwitch?()
        print("Ready for next player to answer")
    }
    
    /// Sets the current player (called by parent view)
    func setCurrentPlayer(_ player: Player) {
        currentPlayer = player
        print("Current answering player: \(player.displayName)")
    }
    
    /// Checks if both players have answered and triggers completion flow
    private func checkCardCompletion() {
        guard let answers = cardAnswers else { return }
        
        isCardComplete = answers.isComplete
        
        if isCardComplete {
            triggerCardCompletion()
        }
    }
    
    /// Triggers the card completion animation and cleanup
    private func triggerCardCompletion() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            isCompletingCard = true
        }
        
        // Notify completion after animation
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            await MainActor.run {
                onCardCompleted?()
            }
        }
    }
    
    /// Callback for when card is completed (set by parent view model)
    var onCardCompleted: (() -> Void)?
    
    /// Callback for when player needs to switch (set by parent view model)
    var onPlayerNeedsToSwitch: (() -> Void)?
    
    /// Callback for when question is loaded (set by parent view model)
    var onQuestionLoaded: (() -> Void)?
    
    /// Gets answer for a specific player
    /// - Parameter playerNumber: Player number (1 or 2)
    /// - Returns: Player's answer or nil
    func getPlayerAnswer(for playerNumber: Int) -> PlayerAnswer? {
        return cardAnswers?.getAnswer(for: playerNumber)
    }
    
    /// Checks if a specific player has answered
    /// - Parameter playerNumber: Player number (1 or 2)
    /// - Returns: True if player has answered
    func hasPlayerAnswered(_ playerNumber: Int) -> Bool {
        return getPlayerAnswer(for: playerNumber) != nil
    }
    
    /// Gets the waiting player (who hasn't answered yet)
    /// - Returns: Player number of waiting player, or nil if both have answered
    func getWaitingPlayerNumber() -> Int? {
        guard let answers = cardAnswers else { return nil }
        
        if answers.player1Answer == nil { return 1 }
        if answers.player2Answer == nil { return 2 }
        return nil // Both have answered
    }
    
    // MARK: - Private Methods
    
    /// Creates character-by-character reveal animation for AI-style text generation
    private func startQuestionRevealAnimation() async {
        guard !question.isEmpty else { return }
        
        let characters = Array(question)
        let totalCharacters = characters.count
        let animationDuration: TimeInterval = 1.5
        let characterDelay = animationDuration / Double(totalCharacters)
        
        for i in 0..<totalCharacters {
            let progress = Double(i + 1) / Double(totalCharacters)
            
            await MainActor.run {
                withAnimation(.easeOut(duration: characterDelay)) {
                    revealProgress = progress
                    displayedQuestion = String(characters[0...i])
                }
            }
            
            // Add small delay between characters for smooth reveal effect
            try? await Task.sleep(nanoseconds: UInt64(characterDelay * 0.8 * 1_000_000_000))
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension CardViewModel {
    /// Creates a preview CardViewModel for SwiftUI previews
    static func preview(
        question: String = "What's something you've learned about yourself in the past year?",
        category: QuestionCategory = .personalGrowth,
        isFlipped: Bool = false,
        isLoading: Bool = false
    ) -> CardViewModel {
        let viewModel = CardViewModel()
        viewModel.question = question
        viewModel.displayedQuestion = isLoading ? "" : question
        viewModel.category = category
        viewModel.isFlipped = isFlipped
        viewModel.isLoading = isLoading
        viewModel.revealProgress = isLoading ? 0.0 : 1.0
        return viewModel
    }
}
#endif