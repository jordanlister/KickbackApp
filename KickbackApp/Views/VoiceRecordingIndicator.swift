//
//  VoiceRecordingIndicator.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Visual indicator for voice recording with animated waveform and audio level feedback
/// Provides real-time visual feedback during voice recording sessions
struct VoiceRecordingIndicator: View {
    
    // MARK: - Properties
    
    /// Audio level from 0.0 to 1.0 for waveform animation
    let audioLevel: Float
    
    /// Whether recording is currently active
    let isRecording: Bool
    
    /// Size configuration for the indicator
    let size: CGFloat
    
    // MARK: - Animation State
    
    @State private var animationPhase: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    // MARK: - Constants
    
    private let waveformBars = 5
    private let animationDuration: Double = 0.1
    private let pulseAnimationDuration: Double = 1.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Pulsing background circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.3),
                            Color.red.opacity(0.1)
                        ]),
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(pulseScale)
                .opacity(isRecording ? 1.0 : 0.0)
                .animation(
                    isRecording ? 
                        .easeInOut(duration: pulseAnimationDuration).repeatForever(autoreverses: true) :
                        .easeOut(duration: 0.3),
                    value: isRecording
                )
            
            // Central microphone icon
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .font(.system(size: size * 0.3, weight: .medium))
                .foregroundColor(isRecording ? .red : .primary)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
            
            // Animated waveform bars
            if isRecording {
                waveformBars(for: audioLevel)
            }
        }
        .onReceive(Timer.publish(every: animationDuration, on: .main, in: .common).autoconnect()) { _ in
            if isRecording {
                withAnimation(.linear(duration: animationDuration)) {
                    animationPhase += 1
                }
            }
        }
        .onAppear {
            if isRecording {
                withAnimation(.easeInOut(duration: pulseAnimationDuration).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: pulseAnimationDuration).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    pulseScale = 1.0
                    animationPhase = 0
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Creates animated waveform bars around the microphone icon
    @ViewBuilder
    private func waveformBars(for level: Float) -> some View {
        let normalizedLevel = max(0.1, CGFloat(level))
        
        ForEach(0..<waveformBars, id: \.self) { index in
            let angle = Double(index) * (360.0 / Double(waveformBars))
            let barHeight = size * 0.15 * normalizedLevel * randomMultiplier(for: index)
            let radius = size * 0.4
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red.opacity(0.8))
                .frame(width: 3, height: barHeight)
                .offset(y: -radius)
                .rotationEffect(.degrees(angle))
                .animation(
                    .easeInOut(duration: animationDuration * 2)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * animationDuration * 0.1),
                    value: animationPhase
                )
        }
    }
    
    /// Generates a pseudo-random multiplier for waveform variation
    private func randomMultiplier(for index: Int) -> CGFloat {
        let phase = animationPhase + Double(index) * 0.5
        return CGFloat(0.5 + 0.5 * sin(phase * 0.5))
    }
}

// MARK: - Convenience Initializers

extension VoiceRecordingIndicator {
    /// Creates a standard-sized recording indicator
    init(audioLevel: Float, isRecording: Bool) {
        self.audioLevel = audioLevel
        self.isRecording = isRecording
        self.size = 80
    }
    
    /// Creates a compact recording indicator for smaller spaces
    static func compact(audioLevel: Float, isRecording: Bool) -> VoiceRecordingIndicator {
        VoiceRecordingIndicator(audioLevel: audioLevel, isRecording: isRecording, size: 50)
    }
    
    /// Creates a large recording indicator for prominent display
    static func large(audioLevel: Float, isRecording: Bool) -> VoiceRecordingIndicator {
        VoiceRecordingIndicator(audioLevel: audioLevel, isRecording: isRecording, size: 120)
    }
}

// MARK: - Preview Support

#Preview("Recording Active") {
    VStack(spacing: 30) {
        VoiceRecordingIndicator(audioLevel: 0.7, isRecording: true)
        VoiceRecordingIndicator.compact(audioLevel: 0.5, isRecording: true)
        VoiceRecordingIndicator.large(audioLevel: 0.9, isRecording: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Recording Inactive") {
    VStack(spacing: 30) {
        VoiceRecordingIndicator(audioLevel: 0.0, isRecording: false)
        VoiceRecordingIndicator.compact(audioLevel: 0.0, isRecording: false)
        VoiceRecordingIndicator.large(audioLevel: 0.0, isRecording: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Different Audio Levels") {
    HStack(spacing: 20) {
        VoiceRecordingIndicator(audioLevel: 0.2, isRecording: true)
        VoiceRecordingIndicator(audioLevel: 0.5, isRecording: true)
        VoiceRecordingIndicator(audioLevel: 0.8, isRecording: true)
        VoiceRecordingIndicator(audioLevel: 1.0, isRecording: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}