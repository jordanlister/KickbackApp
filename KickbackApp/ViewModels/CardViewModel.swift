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
    
    // MARK: - Initialization
    
    /// Initializes CardViewModel with dependency injection for testing
    /// - Parameter questionEngine: Service for generating questions (defaults to shared instance)
    init(questionEngine: QuestionEngine = QuestionEngineService()) {
        self.questionEngine = questionEngine
    }
    
    // MARK: - Public Methods
    
    /// Loads a new question for the specified category with smooth animation
    /// - Parameter category: The question category to generate
    func loadQuestion(for category: QuestionCategory) async {
        guard !isLoading else { return }
        
        self.category = category
        isLoading = true
        errorMessage = nil
        
        // Reset reveal animation state
        revealProgress = 0.0
        displayedQuestion = ""
        
        do {
            let newQuestion = try await questionEngine.generateQuestion(for: category)
            
            // Update question and start reveal animation
            question = newQuestion
            await startQuestionRevealAnimation()
            
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
        
        // Request permissions if not already granted
        if !voicePermissionsGranted {
            voicePermissionsGranted = await audioTranscriber.requestPermissions()
            guard voicePermissionsGranted else { return }
        }
        
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
    /// Creates a mock CardViewModel for SwiftUI previews
    static func mock(
        question: String = "What's something you've learned about yourself in the past year?",
        category: QuestionCategory = .personalGrowth,
        isFlipped: Bool = false,
        isLoading: Bool = false
    ) -> CardViewModel {
        let viewModel = CardViewModel(questionEngine: MockQuestionEngine())
        viewModel.question = question
        viewModel.displayedQuestion = isLoading ? "" : question
        viewModel.category = category
        viewModel.isFlipped = isFlipped
        viewModel.isLoading = isLoading
        viewModel.revealProgress = isLoading ? 0.0 : 1.0
        return viewModel
    }
}

/// Mock QuestionEngine for previews and testing
private class MockQuestionEngine: QuestionEngine {
    func generateQuestion(for category: QuestionCategory) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mockQuestions: [QuestionCategory: [String]] = [
            .firstDate: [
                "What's something that always makes you laugh?",
                "If you could travel anywhere right now, where would you go?",
                "What's your favorite way to spend a weekend?"
            ],
            .personalGrowth: [
                "What's something you've learned about yourself in the past year?",
                "What habit would you most like to develop?",
                "What's a fear you've overcome recently?"
            ],
            .deepCouple: [
                "What's something you appreciate about our relationship that you rarely mention?",
                "How do you prefer to be comforted when you're feeling down?",
                "What's a dream you have that you've never shared with me?"
            ]
        ]
        
        let questions = mockQuestions[category] ?? ["What's on your mind today?"]
        return questions.randomElement() ?? "What's on your mind today?"
    }
    
    func generateQuestion(with configuration: QuestionConfiguration) async throws -> QuestionResult {
        let question = try await generateQuestion(for: configuration.category)
        let metadata = ProcessingMetadata(
            promptUsed: "Mock prompt",
            rawLLMResponse: question,
            processingDuration: 1.0
        )
        
        return QuestionResult(
            question: question,
            category: configuration.category,
            configuration: configuration,
            processingMetadata: metadata
        )
    }
}
#endif