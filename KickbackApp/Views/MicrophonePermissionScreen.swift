//
//  MicrophonePermissionScreen.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI
import AVFoundation

/// Microphone permission screen with clear explanation and request integration
/// Features liquid glass design and smooth permission state transitions
struct MicrophonePermissionScreen: View {
    
    // MARK: - Properties
    
    /// Whether the screen is currently visible
    let isVisible: Bool
    
    /// Current microphone permission status
    let permissionStatus: AVAudioSession.RecordPermission
    
    /// Whether permission request is in progress
    let isRequestingPermission: Bool
    
    /// Error message for failed permission requests
    let permissionError: String?
    
    /// Callback for permission request
    let onRequestPermission: () async -> Void
    
    /// Animation state properties
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0.0
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 30
    @State private var contentOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 30
    @State private var buttonOpacity: Double = 0.0
    @State private var microphoneRotation: Double = 0.0
    
    /// Animation timing constants
    private let titleAnimationDelay: Double = 0.2
    private let iconAnimationDelay: Double = 0.5
    private let contentAnimationDelay: Double = 0.8
    private let buttonAnimationDelay: Double = 1.1
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Main content area
                VStack(spacing: 40) {
                    // Title section
                    titleSection
                    
                    // Microphone icon section
                    microphoneIconSection
                    
                    // Content explanation section
                    contentSection
                    
                    // Permission button section
                    permissionButtonSection
                }
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer() // Extra spacer for better balance
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                startEntranceAnimation()
            } else {
                resetAnimationState()
            }
        }
        .onAppear {
            if isVisible {
                startEntranceAnimation()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Microphone Permission")
        .accessibilityHint("Request microphone access for voice recording features")
    }
    
    // MARK: - Subviews
    
    /// Title section with permission status indication
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Voice Features")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color("BrandPurple"),
                            Color("BrandPurpleLight")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(permissionStatusText)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(permissionStatusColor)
                .multilineTextAlignment(.center)
        }
        .offset(y: titleOffset)
        .opacity(titleOpacity)
    }
    
    /// Microphone icon with status-based styling
    @ViewBuilder
    private var microphoneIconSection: some View {
        ZStack {
            // Background glass circle
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    permissionStatusIconColor.opacity(0.4),
                                    permissionStatusIconColor.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .frame(width: 120, height: 120)
                .shadow(
                    color: permissionStatusIconColor.opacity(0.3),
                    radius: 15,
                    x: 0,
                    y: 8
                )
            
            // Microphone icon with status indication
            Image(systemName: microphoneIconName)
                .font(.system(size: 50, weight: .medium))
                .foregroundColor(permissionStatusIconColor)
                .rotationEffect(.degrees(microphoneRotation))
                .symbolEffect(
                    permissionStatus == AVAudioSession.RecordPermission.granted ? .bounce : .bounce,
                    options: permissionStatus == AVAudioSession.RecordPermission.granted ? .repeating : .nonRepeating
                )
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
    }
    
    /// Content explanation section
    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 24) {
            // Main explanation
            VStack(spacing: 16) {
                Text("Enhanced Conversation Experience")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Kickback uses your microphone to record voice responses, enabling AI-powered transcription and deeper compatibility analysis.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Feature benefits in glass container
            VStack(spacing: 12) {
                benefitRow(
                    icon: "waveform.circle.fill",
                    title: "Voice Transcription",
                    description: "Automatic conversion of speech to text"
                )
                
                benefitRow(
                    icon: "brain.head.profile",
                    title: "AI Analysis",
                    description: "Advanced compatibility insights from responses"
                )
                
                benefitRow(
                    icon: "lock.circle.fill",
                    title: "Privacy Protected",
                    description: "Audio stays on your device, never uploaded"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .glassEffect(
                style: .regular,
                tint: Color("BrandPurple").opacity(0.08)
            )
            
            // Error message if permission failed
            if let error = permissionError {
                Text(error)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .offset(y: contentOffset)
        .opacity(contentOpacity)
    }
    
    /// Permission button section with status-based styling
    @ViewBuilder
    private var permissionButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await onRequestPermission()
                }
            }) {
                HStack(spacing: 12) {
                    if isRequestingPermission {
                        ProgressView()
                            .scaleEffect(0.9)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: permissionButtonIconName)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(permissionButtonText)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    permissionButtonColor,
                                    permissionButtonColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: permissionButtonColor.opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .scaleEffect(isRequestingPermission ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRequestingPermission)
            }
            .disabled(isRequestingPermission || permissionStatus == AVAudioSession.RecordPermission.granted)
            
            // Additional guidance for denied permission
            if permissionStatus == AVAudioSession.RecordPermission.denied {
                Text("To enable microphone access, go to Settings > Privacy & Security > Microphone > Kickback")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .offset(y: buttonOffset)
        .opacity(buttonOpacity)
    }
    
    /// Individual benefit row with icon and description
    @ViewBuilder
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color("BrandPurple"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Permission status text based on current state
    private var permissionStatusText: String {
        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            return "Enable microphone for the best experience"
        case AVAudioSession.RecordPermission.granted:
            return "Microphone access granted"
        case AVAudioSession.RecordPermission.denied:
            return "Microphone access required"
        @unknown default:
            return "Microphone permission status unknown"
        }
    }
    
    /// Permission status color based on current state
    private var permissionStatusColor: Color {
        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            return .secondary
        case AVAudioSession.RecordPermission.granted:
            return .green
        case AVAudioSession.RecordPermission.denied:
            return .red
        @unknown default:
            return .secondary
        }
    }
    
    /// Microphone icon name based on permission status
    private var microphoneIconName: String {
        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            return "mic.circle"
        case AVAudioSession.RecordPermission.granted:
            return "mic.circle.fill"
        case AVAudioSession.RecordPermission.denied:
            return "mic.slash.circle.fill"
        @unknown default:
            return "mic.circle"
        }
    }
    
    /// Icon color based on permission status
    private var permissionStatusIconColor: Color {
        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            return Color("BrandPurple")
        case AVAudioSession.RecordPermission.granted:
            return .green
        case AVAudioSession.RecordPermission.denied:
            return .red
        @unknown default:
            return Color("BrandPurple")
        }
    }
    
    /// Permission button text based on current state
    private var permissionButtonText: String {
        if isRequestingPermission {
            return "Requesting Permission..."
        }
        
        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            return "Allow Microphone Access"
        case AVAudioSession.RecordPermission.granted:
            return "Microphone Access Granted"
        case AVAudioSession.RecordPermission.denied:
            return "Open Settings"
        @unknown default:
            return "Check Microphone Permission"
        }
    }
    
    /// Permission button icon name
    private var permissionButtonIconName: String {
        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            return "mic.badge.plus"
        case AVAudioSession.RecordPermission.granted:
            return "checkmark.circle.fill"
        case AVAudioSession.RecordPermission.denied:
            return "gear"
        @unknown default:
            return "mic"
        }
    }
    
    /// Permission button color based on status
    private var permissionButtonColor: Color {
        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            return Color("BrandPurple")
        case AVAudioSession.RecordPermission.granted:
            return .green
        case AVAudioSession.RecordPermission.denied:
            return .orange
        @unknown default:
            return Color("BrandPurple")
        }
    }
    
    // MARK: - Animation Methods
    
    /// Starts the staggered entrance animation sequence
    private func startEntranceAnimation() {
        // Title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(titleAnimationDelay)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Icon animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(iconAnimationDelay)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Content animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(contentAnimationDelay)) {
            contentOffset = 0
            contentOpacity = 1.0
        }
        
        // Button animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(buttonAnimationDelay)) {
            buttonOffset = 0
            buttonOpacity = 1.0
        }
    }
    
    /// Resets all animation states to initial values
    private func resetAnimationState() {
        titleOffset = 30
        titleOpacity = 0.0
        iconScale = 0.8
        iconOpacity = 0.0
        contentOffset = 30
        contentOpacity = 0.0
        buttonOffset = 30
        buttonOpacity = 0.0
    }
}

// MARK: - Preview Support

#Preview("Microphone Permission - Undetermined") {
    ZStack {
        // Background gradient matching the main app
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        MicrophonePermissionScreen(
            isVisible: true,
            permissionStatus: AVAudioSession.RecordPermission.undetermined,
            isRequestingPermission: false,
            permissionError: nil,
            onRequestPermission: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Microphone Permission - Granted") {
    ZStack {
        // Background gradient matching the main app
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        MicrophonePermissionScreen(
            isVisible: true,
            permissionStatus: AVAudioSession.RecordPermission.granted,
            isRequestingPermission: false,
            permissionError: nil,
            onRequestPermission: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Microphone Permission - Denied") {
    ZStack {
        // Background gradient matching the main app
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        MicrophonePermissionScreen(
            isVisible: true,
            permissionStatus: AVAudioSession.RecordPermission.denied,
            isRequestingPermission: false,
            permissionError: "Microphone access was denied. Please enable it in Settings.",
            onRequestPermission: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Microphone Permission - Requesting") {
    ZStack {
        // Background gradient matching the main app
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        MicrophonePermissionScreen(
            isVisible: true,
            permissionStatus: AVAudioSession.RecordPermission.undetermined,
            isRequestingPermission: true,
            permissionError: nil,
            onRequestPermission: {}
        )
    }
    .preferredColorScheme(.light)
}