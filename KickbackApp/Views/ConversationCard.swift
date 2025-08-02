//
//  ConversationCard.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Individual conversation card with iOS 26 Liquid Glass design
/// Features stunning glass morphism with smooth flip animations and text reveal effects
struct ConversationCard: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: CardViewModel
    let cardIndex: Int
    let isExpanded: Bool
    
    /// Glass effect ID for smooth morphing transitions
    private var glassEffectID: String {
        return "glass_morph_\(cardIndex)_\(isExpanded ? "expanded" : "collapsed")"
    }
    
    /// Card dimensions and layout constants
    private let cardHeight: CGFloat = 200
    private let expandedCardHeight: CGFloat = 680
    private let cardPadding: CGFloat = 32
    private let cornerRadius: CGFloat = 28
    
    /// Glass effect constants
    private let glassCornerRadius: CGFloat = 24
    private let glassBlurIntensity: CGFloat = 0.8
    
    /// Animation constants tuned for 60fps performance
    private let flipDuration: Double = 0.8
    private let scaleFactor: CGFloat = 0.95
    
    // MARK: - Computed Properties
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: glassCornerRadius)
            .fill(.ultraThinMaterial)
            .glassEffect(
                style: viewModel.isFlipped ? .prominent : .regular,
                tint: categoryColor.opacity(0.1),
                glassID: glassEffectID
            )
            .interactive()
            .shadow(
                color: categoryColor.opacity(viewModel.isFlipped ? 0.3 : 0.1),
                radius: viewModel.isFlipped ? 20 : 8,
                x: 0,
                y: viewModel.isFlipped ? 10 : 4
            )
    }

    // MARK: - Body
    
    var body: some View {
        cardMainContent
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
            }
    }
    
    private var cardMainContent: some View {
        ZStack {
            cardBackground
            
            // Glass card content container
            VStack(spacing: isExpanded ? 32 : 16) {
                // Category indicator with glass effect
                categoryHeader
                
                // Question content area with glass morphism
                questionContent
                
                // Voice input section when card is expanded
                if isExpanded && !viewModel.isLoading && viewModel.errorMessage == nil {
                    glassVoiceInputSection
                }
                
                Spacer(minLength: 0)
            }
            .padding(cardPadding)
        }
        .frame(height: isExpanded ? expandedCardHeight : cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: glassCornerRadius))
        .scaleEffect(viewModel.isCompletingCard ? 0.8 : 1.0)
        .opacity(viewModel.isCompletingCard ? 0.0 : 1.0)
        .offset(y: viewModel.isCompletingCard ? -200 : 0)
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: viewModel.isCompletingCard)
        // New card pop-up animation (starts from bottom)
        .offset(y: viewModel.isLoading && !viewModel.isCompletingCard ? 100 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.isLoading)
    }
    
    // MARK: - Subviews
    
    /// Category header with glass effects and animated appearance
    @ViewBuilder
    private var categoryHeader: some View {
        HStack {
            Text(viewModel.category.displayName)
                .font(isExpanded ? .subheadline : .caption)
                .fontWeight(.medium)
                .foregroundColor(categoryColor)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, isExpanded ? 16 : 12)
                .padding(.vertical, isExpanded ? 10 : 6)
                .glassEffect(
                    style: .regular,
                    tint: categoryColor.opacity(0.1)
                )
                .interactive()
            
            Spacer()
            
            // Show current player indicator when expanded
            if isExpanded && !viewModel.isLoading, let currentPlayer = viewModel.currentPlayer {
                Text("\(currentPlayer.displayName)'s turn")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(
                        style: .regular,
                        tint: categoryColor.opacity(0.05)
                    )
                    .interactive()
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(isExpanded ? 1.0 : 0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: categoryColor))
                    .glassEffect(
                        style: .regular,
                        tint: categoryColor.opacity(0.05)
                    )
                    .interactive()
            }
        }
        .opacity(isExpanded ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
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
    
    /// Loading state content with glass effects
    @ViewBuilder
    private var loadingContent: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .frame(height: 16)
                .glassEffect(
                    style: .regular,
                    tint: categoryColor.opacity(0.1)
                )
                .redacted(reason: .placeholder)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .frame(height: 16)
                .frame(width: .random(in: 120...200))
                .glassEffect(
                    style: .regular,
                    tint: categoryColor.opacity(0.1)
                )
                .redacted(reason: .placeholder)
        }
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isLoading)
    }
    
    /// Error state content with glass effects
    @ViewBuilder
    private func errorContent(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
                .glassEffect(
                    style: .regular,
                    tint: Color.orange.opacity(0.1)
                )
                .interactive()
            
            VStack(spacing: 4) {
                Text("Unable to load question")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Tap to try again")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassEffect(
                style: .regular,
                tint: Color.orange.opacity(0.05)
            )
            .interactive()
        }
        .multilineTextAlignment(.center)
    }
    
    /// Question text with character-by-character reveal animation
    @ViewBuilder
    private var questionText: some View {
        Text(viewModel.displayedQuestion)
            .font(isExpanded ? .title2 : .body)
            .fontWeight(isExpanded ? .medium : .medium)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(isExpanded ? nil : 3)
            .lineSpacing(isExpanded ? 8 : 4)
            .padding(.horizontal, isExpanded ? 16 : 0)
            .padding(.vertical, isExpanded ? 20 : 0)
            .animation(.none, value: viewModel.displayedQuestion) // Disable automatic animation
            .opacity(viewModel.displayedQuestion.isEmpty ? 0.0 : 1.0)
            .animation(.easeIn(duration: 0.2), value: viewModel.displayedQuestion.isEmpty)
    }
    
    /// Glass voice input section for answering questions
    @ViewBuilder
    private var glassVoiceInputSection: some View {
        VStack(spacing: isExpanded ? 16 : 12) {
            // Glass divider
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 1)
                .glassEffect(
                    style: .regular,
                    tint: categoryColor.opacity(0.2)
                )
                .opacity(0.5)
            
            HStack {
                // Glass voice input button
                Button(action: {
                    Task {
                        await handleVoiceInput()
                    }
                }) {
                    HStack(spacing: isExpanded ? 10 : 6) {
                        if viewModel.isVoiceInputMode {
                            VoiceRecordingIndicator.compact(
                                audioLevel: viewModel.audioTranscriber.audioLevel,
                                isRecording: true
                            )
                        } else {
                            Image(systemName: "mic.circle.fill")
                                .font(isExpanded ? .title : .title2)
                                .foregroundColor(categoryColor)
                        }
                        
                        Text(viewModel.isVoiceInputMode ? "Recording..." : "Voice Answer")
                            .font(isExpanded ? .body : .subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.isVoiceInputMode ? .red : categoryColor)
                    .padding(.horizontal, isExpanded ? 16 : 12)
                    .padding(.vertical, isExpanded ? 12 : 8)
                    .glassEffect(
                        style: .regular,
                        tint: (viewModel.isVoiceInputMode ? Color.red : categoryColor).opacity(0.1)
                    )
                    .interactive()
                }
                // Remove the disabled state since permissions are handled in onboarding
                
                Spacer()
                
                // Show transcription status with glass effects
                if !viewModel.voiceAnswer.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .glassEffect(
                            style: .regular,
                            tint: Color.green.opacity(0.1)
                        )
                        .interactive()
                } else if !viewModel.audioTranscriber.partialTranscription.isEmpty {
                    Text("Listening...")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(
                            style: .regular,
                            tint: Color.green.opacity(0.1)
                        )
                        .interactive()
                }
            }
            
            // Transcription preview with glass effects
            if !viewModel.voiceAnswer.isEmpty {
                glassTranscriptionPreview
                
                // Confirm answer button
                Button(action: {
                    Task {
                        await handleAnswerConfirmation()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Confirm Answer")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(categoryColor)
                    )
                    .glassEffect(
                        style: .prominent,
                        tint: categoryColor.opacity(0.2)
                    )
                    .interactive()
                }
                .padding(.top, 8)
            } else if viewModel.isVoiceInputMode && !viewModel.audioTranscriber.partialTranscription.isEmpty {
                glassLiveTranscriptionPreview
            }
            
            // No longer show permission prompt since permissions are granted in onboarding
            
            // Error display with glass effects
            if let error = viewModel.audioTranscriber.currentError {
                glassErrorDisplay(error)
            }
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    /// Shows final transcription with glass effects and edit options
    @ViewBuilder
    private var glassTranscriptionPreview: some View {
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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassEffect(
                    style: .regular,
                    tint: Color.red.opacity(0.1)
                )
                .interactive()
            }
            
            Text(viewModel.voiceAnswer)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(
                    style: .regular,
                    tint: categoryColor.opacity(0.05)
                )
                .interactive()
                .lineLimit(3)
        }
    }
    
    /// Shows live transcription during recording with glass effects
    @ViewBuilder
    private var glassLiveTranscriptionPreview: some View {
        Text(viewModel.audioTranscriber.partialTranscription)
            .font(.subheadline)
            .foregroundColor(.green)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(
                style: .regular,
                tint: Color.green.opacity(0.1)
            )
            .interactive()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .lineLimit(2)
            .transition(.opacity)
    }
    
    /// Permission prompt for first-time users with glass effects
    @ViewBuilder
    private var glassPermissionPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(categoryColor)
            
            Text("Tap to enable voice input")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(
            style: .regular,
            tint: categoryColor.opacity(0.1)
        )
        .interactive()
    }
    
    /// Error display for transcription issues with glass effects
    @ViewBuilder
    private func glassErrorDisplay(_ error: AudioTranscriberError) -> some View {
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
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .glassEffect(
                    style: .regular,
                    tint: Color.red.opacity(0.1)
                )
                .interactive()
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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(
            style: .regular,
            tint: Color.red.opacity(0.1)
        )
        .interactive()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic glass background based on category and state
    private var glassBackgroundMaterial: Material {
        return viewModel.isFlipped ? .ultraThinMaterial : .thinMaterial
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
            let cardState = isExpanded ? "expanded" : "collapsed"
            return "\(viewModel.category.displayName) conversation card, \(cardState)"
        }
    }
    
    /// Accessibility hint for user guidance
    private var accessibilityHint: String {
        if viewModel.isLoading {
            return "Please wait while the question loads"
        } else if viewModel.errorMessage != nil {
            return "Double tap to retry loading the question"
        } else if isExpanded {
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
        var traits: AccessibilityTraits = []
        
        if viewModel.isLoading {
            traits.insert(.updatesFrequently)
        }
        
        if isExpanded {
            traits.insert(.isSelected)
        }
        
        return traits
    }
    
    // MARK: - Private Methods
    
    /// Handles voice input interaction and answer recording
    private func handleVoiceInput() async {
        if viewModel.isVoiceInputMode {
            // Stop recording
            await viewModel.stopVoiceRecording()
        } else {
            // Start recording
            await viewModel.startVoiceRecording()
        }
    }
    
    /// Handles answer confirmation and saves the response
    private func handleAnswerConfirmation() async {
        guard !viewModel.voiceAnswer.isEmpty else { return }
        
        let success = await viewModel.recordCurrentPlayerAnswer()
        if success {
            print("Answer confirmed and recorded for player \(viewModel.currentPlayer?.displayName ?? "unknown")")
            
            // Haptic feedback for confirmation
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// Glass effects are imported from GlassEffectExtensions.swift

// MARK: - Preview Support

#Preview("Single Card - Collapsed") {
    ConversationCard(
        viewModel: CardViewModel.preview(
            question: "What's something that always makes you laugh, even on your worst days?",
            category: .funAndPlayful,
            isFlipped: false
        ),
        cardIndex: 0,
        isExpanded: false
    )
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Single Card - Expanded") {
    ConversationCard(
        viewModel: CardViewModel.preview(
            question: "What's a personal value that you've developed or strengthened over the past few years, and how has it changed the way you approach relationships?",
            category: .personalGrowth,
            isFlipped: true
        ),
        cardIndex: 1,
        isExpanded: true
    )
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Loading State") {
    ConversationCard(
        viewModel: CardViewModel.preview(
            question: "",
            category: .deepCouple,
            isFlipped: false,
            isLoading: true
        ),
        cardIndex: 2,
        isExpanded: false
    )
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Multiple Cards") {
    VStack(spacing: 16) {
        ConversationCard(
            viewModel: CardViewModel.preview(
                question: "What's your favorite childhood memory?",
                category: .firstDate
            ),
            cardIndex: 0,
            isExpanded: false
        )
        
        ConversationCard(
            viewModel: CardViewModel.preview(
                question: "What's something you're currently learning about yourself?",
                category: .personalGrowth,
                isFlipped: true
            ),
            cardIndex: 1,
            isExpanded: true
        )
        
        ConversationCard(
            viewModel: CardViewModel.preview(
                question: "If you could be any fictional character for a day, who would you choose?",
                category: .funAndPlayful
            ),
            cardIndex: 2,
            isExpanded: false
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