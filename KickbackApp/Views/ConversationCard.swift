//
//  ConversationCard.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Individual conversation card with smooth flip animations and text reveal effects
/// Designed for 60fps performance with optimized animations and minimal redraws
struct ConversationCard: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: CardViewModel
    let cardIndex: Int
    
    /// Card dimensions and layout constants
    private let cardHeight: CGFloat = 200
    private let expandedCardHeight: CGFloat = 320
    private let cardPadding: CGFloat = 20
    private let cornerRadius: CGFloat = 16
    
    /// Animation constants tuned for 60fps performance
    private let flipDuration: Double = 0.6
    private let scaleFactor: CGFloat = 0.95
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Card background with subtle gradient
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cardBackgroundGradient)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: viewModel.isFlipped ? 20 : 8,
                    x: 0,
                    y: viewModel.isFlipped ? 10 : 4
                )
            
            // Card content
            VStack(spacing: 16) {
                // Category indicator
                categoryHeader
                
                // Question content area
                questionContent
                
                // Voice input section when card is flipped
                if viewModel.isFlipped && !viewModel.isLoading && viewModel.errorMessage == nil {
                    voiceInputSection
                }
                
                Spacer(minLength: 0)
            }
            .padding(cardPadding)
        }
        .frame(height: viewModel.isFlipped ? expandedCardHeight : cardHeight)
        .scaleEffect(viewModel.isFlipped ? 1.05 : 1.0)
        .rotation3DEffect(
            .degrees(viewModel.isFlipped ? 0 : 0),
            axis: (x: 1, y: 0, z: 0)
        )
        .animation(
            .spring(response: flipDuration, dampingFraction: 0.8, blendDuration: 0),
            value: viewModel.isFlipped
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityAction(.default) {
            // Default tap action for accessibility
        }
        .accessibilityScrollAction { edge in
            // Handle scroll actions for accessibility
            return .handled
        }
    }
    
    // MARK: - Subviews
    
    /// Category header with animated appearance
    @ViewBuilder
    private var categoryHeader: some View {
        HStack {
            Text(viewModel.category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(categoryColor)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: categoryColor))
            }
        }
        .opacity(viewModel.isFlipped ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isFlipped)
    }
    
    /// Main question content with text reveal animation
    @ViewBuilder
    private var questionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                loadingContent
            } else if let errorMessage = viewModel.errorMessage {
                errorContent(errorMessage)
            } else {
                questionText
            }
        }
    }
    
    /// Loading state content
    @ViewBuilder
    private var loadingContent: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
                .redacted(reason: .placeholder)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
                .frame(width: .random(in: 120...200))
                .redacted(reason: .placeholder)
        }
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isLoading)
    }
    
    /// Error state content
    @ViewBuilder
    private func errorContent(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Unable to load question")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Tap to try again")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
    }
    
    /// Question text with character-by-character reveal animation
    @ViewBuilder
    private var questionText: some View {
        Text(viewModel.displayedQuestion)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(viewModel.isFlipped ? nil : 3)
            .animation(.none, value: viewModel.displayedQuestion) // Disable automatic animation
            .opacity(viewModel.displayedQuestion.isEmpty ? 0.0 : 1.0)
            .animation(.easeIn(duration: 0.2), value: viewModel.displayedQuestion.isEmpty)
    }
    
    /// Voice input section for answering questions
    @ViewBuilder
    private var voiceInputSection: some View {
        VStack(spacing: 12) {
            Divider()
                .opacity(0.5)
            
            HStack {
                // Voice input button
                Button(action: {
                    Task {
                        await viewModel.toggleVoiceInput()
                    }
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isVoiceInputMode {
                            VoiceRecordingIndicator.compact(
                                audioLevel: viewModel.audioTranscriber.audioLevel,
                                isRecording: true
                            )
                        } else {
                            Image(systemName: "mic.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Text(viewModel.isVoiceInputMode ? "Recording..." : "Voice Answer")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.isVoiceInputMode ? .red : .blue)
                }
                .disabled(!viewModel.voicePermissionsGranted && !viewModel.isVoiceInputMode)
                
                Spacer()
                
                // Show transcription status
                if !viewModel.voiceAnswer.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else if !viewModel.audioTranscriber.partialTranscription.isEmpty {
                    Text("Listening...")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Transcription preview (if available)
            if !viewModel.voiceAnswer.isEmpty {
                transcriptionPreview
            } else if viewModel.isVoiceInputMode && !viewModel.audioTranscriber.partialTranscription.isEmpty {
                liveTranscriptionPreview
            }
            
            // Permission warning (if needed)
            if !viewModel.voicePermissionsGranted {
                permissionPrompt
            }
            
            // Error display (if any)
            if let error = viewModel.audioTranscriber.currentError {
                errorDisplay(error)
            }
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    /// Shows final transcription with edit options
    @ViewBuilder
    private var transcriptionPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Answer:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Clear") {
                    viewModel.clearVoiceAnswer()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Text(viewModel.voiceAnswer)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(3)
        }
    }
    
    /// Shows live transcription during recording
    @ViewBuilder
    private var liveTranscriptionPreview: some View {
        Text(viewModel.audioTranscriber.partialTranscription)
            .font(.subheadline)
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
            .lineLimit(2)
            .transition(.opacity)
    }
    
    /// Permission prompt for first-time users
    @ViewBuilder
    private var permissionPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            
            Text("Tap to enable voice input")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    
    /// Error display for transcription issues
    @ViewBuilder
    private func errorDisplay(_ error: AudioTranscriberError) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Voice Recording Error")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Spacer()
                
                Button("Dismiss") {
                    viewModel.audioTranscriber.currentError = nil
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .italic()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(6)
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic card background gradient based on category and state
    private var cardBackgroundGradient: LinearGradient {
        let baseColor = categoryColor
        let lighterShade = baseColor.opacity(0.1)
        let darkerShade = baseColor.opacity(0.05)
        
        return LinearGradient(
            gradient: Gradient(colors: [lighterShade, darkerShade]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Category-specific color theming
    private var categoryColor: Color {
        switch viewModel.category {
        case .firstDate, .blindDate:
            return .blue
        case .personalGrowth, .emotionalIntelligence:
            return .green
        case .funAndPlayful:
            return .orange
        case .deepCouple, .intimacyBuilding:
            return .purple
        case .vulnerabilitySharing:
            return .pink
        case .futureVisions, .longTermRelationship:
            return .indigo
        case .conflictResolution:
            return .red
        case .loveLanguageDiscovery:
            return .teal
        case .earlyDating:
            return .mint
        case .valuesAlignment:
            return .brown
        case .lifeTransitions:
            return .cyan
        }
    }
    
    /// Accessibility label for the card
    private var accessibilityLabel: String {
        if viewModel.isLoading {
            return "Loading \(viewModel.category.displayName) question"
        } else if viewModel.errorMessage != nil {
            return "Error loading \(viewModel.category.displayName) question. Tap to retry."
        } else {
            let cardState = viewModel.isFlipped ? "expanded" : "collapsed"
            return "\(viewModel.category.displayName) conversation card, \(cardState)"
        }
    }
    
    /// Accessibility hint for user guidance
    private var accessibilityHint: String {
        if viewModel.isLoading {
            return "Please wait while the question loads"
        } else if viewModel.errorMessage != nil {
            return "Double tap to retry loading the question"
        } else if viewModel.isFlipped {
            return "Double tap to collapse this card and return to deck view"
        } else {
            return "Double tap to expand this card and read the full question"
        }
    }
    
    /// Accessibility value containing the question text
    private var accessibilityValue: String {
        if viewModel.isLoading {
            return "Loading"
        } else if let error = viewModel.errorMessage {
            return "Error: \(error)"
        } else if !viewModel.question.isEmpty {
            return viewModel.question
        } else {
            return "No question available"
        }
    }
    
    /// Dynamic accessibility traits based on card state
    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.button]
        
        if viewModel.isLoading {
            traits.insert(.updatesFrequently)
        }
        
        if viewModel.isFlipped {
            traits.insert(.isSelected)
        }
        
        return traits
    }
}

// MARK: - Preview Support

#Preview("Single Card - Collapsed") {
    ConversationCard(
        viewModel: CardViewModel.mock(
            question: "What's something that always makes you laugh, even on your worst days?",
            category: .funAndPlayful,
            isFlipped: false
        ),
        cardIndex: 0
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Single Card - Expanded") {
    ConversationCard(
        viewModel: CardViewModel.mock(
            question: "What's a personal value that you've developed or strengthened over the past few years, and how has it changed the way you approach relationships?",
            category: .personalGrowth,
            isFlipped: true
        ),
        cardIndex: 1
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Loading State") {
    ConversationCard(
        viewModel: CardViewModel.mock(
            question: "",
            category: .deepCouple,
            isFlipped: false,
            isLoading: true
        ),
        cardIndex: 2
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Multiple Cards") {
    VStack(spacing: 16) {
        ConversationCard(
            viewModel: CardViewModel.mock(
                question: "What's your favorite childhood memory?",
                category: .firstDate
            ),
            cardIndex: 0
        )
        
        ConversationCard(
            viewModel: CardViewModel.mock(
                question: "What's something you're currently learning about yourself?",
                category: .personalGrowth,
                isFlipped: true
            ),
            cardIndex: 1
        )
        
        ConversationCard(
            viewModel: CardViewModel.mock(
                question: "If you could be any fictional character for a day, who would you choose?",
                category: .funAndPlayful
            ),
            cardIndex: 2
        )
    }
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}