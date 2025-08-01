//
//  VoiceInputView.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Complete voice input interface for conversation cards
/// Handles recording, transcription display, and user interaction
struct VoiceInputView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: CardViewModel
    
    // MARK: - Constants
    
    private let cornerRadius: CGFloat = 12
    private let padding: CGFloat = 16
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Voice input header
            voiceInputHeader
            
            // Recording interface
            recordingInterface
            
            // Transcription display
            if !viewModel.voiceAnswer.isEmpty || !viewModel.audioTranscriber.partialTranscription.isEmpty {
                transcriptionDisplay
            }
            
            // Action buttons
            actionButtons
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    viewModel.isVoiceInputMode ? Color.red.opacity(0.3) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.isVoiceInputMode)
    }
    
    // MARK: - Subviews
    
    /// Header with title and status
    @ViewBuilder
    private var voiceInputHeader: some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("Your Voice Answer")
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            if viewModel.isVoiceInputMode {
                Text("Recording...")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    /// Main recording interface with indicator and button
    @ViewBuilder
    private var recordingInterface: some View {
        VStack(spacing: 16) {
            // Recording indicator
            VoiceRecordingIndicator(
                audioLevel: viewModel.audioTranscriber.audioLevel,
                isRecording: viewModel.isVoiceInputMode
            )
            
            // Record button
            Button(action: {
                Task {
                    await viewModel.toggleVoiceInput()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isVoiceInputMode ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                    
                    Text(viewModel.isVoiceInputMode ? "Stop Recording" : "Start Recording")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(viewModel.isVoiceInputMode ? Color.red : Color.blue)
                )
            }
            .disabled(!viewModel.voicePermissionsGranted && !viewModel.isVoiceInputMode)
            .scaleEffect(viewModel.isVoiceInputMode ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isVoiceInputMode)
            
            // Permission status
            if !viewModel.voicePermissionsGranted {
                permissionWarning
            }
        }
    }
    
    /// Transcription display area
    @ViewBuilder
    private var transcriptionDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Transcription")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if viewModel.isVoiceInputMode && !viewModel.audioTranscriber.partialTranscription.isEmpty {
                    Text("Live")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            ScrollView {
                Text(currentTranscriptionText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                viewModel.isVoiceInputMode ? Color.green.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            }
            .frame(maxHeight: 120)
        }
    }
    
    /// Action buttons for managing voice answer
    @ViewBuilder
    private var actionButtons: some View {
        if !viewModel.voiceAnswer.isEmpty {
            HStack(spacing: 12) {
                // Clear answer button
                Button("Clear Answer") {
                    viewModel.clearVoiceAnswer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                
                Spacer()
                
                // Edit answer button (future enhancement)
                Button("Edit") {
                    // TODO: Implement text editing interface
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    /// Permission warning display
    @ViewBuilder
    private var permissionWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text("Microphone and speech recognition permissions are required")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    /// Current transcription text to display
    private var currentTranscriptionText: String {
        if viewModel.isVoiceInputMode && !viewModel.audioTranscriber.partialTranscription.isEmpty {
            return viewModel.audioTranscriber.partialTranscription
        } else if !viewModel.voiceAnswer.isEmpty {
            return viewModel.voiceAnswer
        } else {
            return "Your voice answer will appear here..."
        }
    }
}

// MARK: - Preview Support

#Preview("Voice Input - Ready") {
    VoiceInputView(
        viewModel: CardViewModel.mockWithVoice(
            question: "What's your favorite childhood memory?",
            voicePermissionsGranted: true
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Voice Input - Recording") {
    VoiceInputView(
        viewModel: CardViewModel.mockWithVoice(
            question: "What's your favorite childhood memory?",
            isVoiceInputMode: true,
            voicePermissionsGranted: true
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Voice Input - With Answer") {
    VoiceInputView(
        viewModel: CardViewModel.mockWithVoice(
            question: "What's your favorite childhood memory?",
            voiceAnswer: "I remember building sandcastles at the beach with my family every summer. The smell of salt air and the feeling of warm sand between my toes always brings me back to those carefree days.",
            voicePermissionsGranted: true
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Voice Input - No Permissions") {
    VoiceInputView(
        viewModel: CardViewModel.mockWithVoice(
            question: "What's your favorite childhood memory?",
            voicePermissionsGranted: false
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

// MARK: - CardViewModel Mock Extension

#if DEBUG
extension CardViewModel {
    static func mockWithVoice(
        question: String = "What's something you've learned about yourself in the past year?",
        category: QuestionCategory = .personalGrowth,
        isVoiceInputMode: Bool = false,
        voiceAnswer: String = "",
        voicePermissionsGranted: Bool = false
    ) -> CardViewModel {
        let viewModel = CardViewModel.mock(question: question, category: category)
        viewModel.isVoiceInputMode = isVoiceInputMode
        viewModel.voiceAnswer = voiceAnswer
        viewModel.voicePermissionsGranted = voicePermissionsGranted
        return viewModel
    }
}
#endif