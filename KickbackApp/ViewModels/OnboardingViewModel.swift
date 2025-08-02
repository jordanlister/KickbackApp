//
//  OnboardingViewModel.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Speech

/// ViewModel managing onboarding flow state and progression
/// Handles page navigation, permission requests, and completion tracking
@MainActor
public final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current onboarding page index
    @Published var currentPage: Int = 0
    
    /// Whether onboarding has been completed
    @Published var isOnboardingCompleted: Bool = false
    
    /// Microphone permission status
    @Published var microphonePermissionStatus: AVAudioSession.RecordPermission = .undetermined
    
    /// Speech recognition permission status
    @Published var speechRecognitionPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    /// Whether we're currently requesting microphone permission
    @Published var isRequestingMicrophonePermission: Bool = false
    
    /// Whether we're currently requesting speech recognition permission
    @Published var isRequestingSpeechPermission: Bool = false
    
    /// Error message for failed permission requests
    @Published var permissionError: String?
    
    /// Page transition animation state
    @Published var isTransitioning: Bool = false
    
    // MARK: - Configuration
    
    /// Total number of onboarding pages
    let totalPages: Int = 3
    
    /// Onboarding pages enumeration
    enum OnboardingPage: Int, CaseIterable {
        case welcome = 0
        case howItWorks = 1
        case microphonePermission = 2
        
        var title: String {
            switch self {
            case .welcome:
                return "Welcome to Kickback"
            case .howItWorks:
                return "How It Works"
            case .microphonePermission:
                return "Voice & Speech Permissions"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current onboarding page
    var currentOnboardingPage: OnboardingPage {
        return OnboardingPage(rawValue: currentPage) ?? .welcome
    }
    
    /// Whether we're on the last page
    var isLastPage: Bool {
        return currentPage >= totalPages - 1
    }
    
    /// Whether we can proceed to next page
    var canProceedToNext: Bool {
        switch currentOnboardingPage {
        case .welcome, .howItWorks:
            return true
        case .microphonePermission:
            return microphonePermissionStatus == .granted && speechRecognitionPermissionStatus == .authorized
        }
    }
    
    /// Progress percentage through onboarding
    var progress: Double {
        return Double(currentPage + 1) / Double(totalPages)
    }
    
    // MARK: - UserDefaults Keys
    
    private let onboardingCompletedKey = "KickbackOnboardingCompleted"
    
    // MARK: - Initialization
    
    init() {
        loadOnboardingStatus()
        checkMicrophonePermissionStatus()
    }
    
    // MARK: - Public Methods
    
    /// Advances to the next onboarding page
    func nextPage() {
        guard !isTransitioning && currentPage < totalPages - 1 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isTransitioning = true
            currentPage += 1
        }
        
        // Reset transition state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isTransitioning = false
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Goes back to the previous onboarding page
    func previousPage() {
        guard !isTransitioning && currentPage > 0 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isTransitioning = true
            currentPage -= 1
        }
        
        // Reset transition state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isTransitioning = false
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Jumps to a specific page
    /// - Parameter page: Target page index
    func goToPage(_ page: Int) {
        guard !isTransitioning && page >= 0 && page < totalPages else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isTransitioning = true
            currentPage = page
        }
        
        // Reset transition state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isTransitioning = false
        }
    }
    
    /// Requests microphone permission
    func requestMicrophonePermission() async {
        guard !isRequestingMicrophonePermission else { return }
        
        isRequestingMicrophonePermission = true
        permissionError = nil
        
        do {
            let permission = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted ? AVAudioSession.RecordPermission.granted : .denied)
                }
            }
            
            await MainActor.run {
                microphonePermissionStatus = permission
                isRequestingMicrophonePermission = false
                
                if permission == .granted {
                    // Provide success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                } else {
                    permissionError = "Microphone access is required for voice recording features"
                    
                    // Provide error haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        } catch {
            await MainActor.run {
                permissionError = "Failed to request microphone permission: \(error.localizedDescription)"
                isRequestingMicrophonePermission = false
                
                // Provide error haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
    }
    
    /// Requests speech recognition permission
    func requestSpeechRecognitionPermission() async {
        guard !isRequestingSpeechPermission else { return }
        
        isRequestingSpeechPermission = true
        permissionError = nil
        
        do {
            let permission = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            
            await MainActor.run {
                speechRecognitionPermissionStatus = permission
                isRequestingSpeechPermission = false
                
                if permission == .authorized {
                    // Provide success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                } else {
                    permissionError = "Speech recognition access is required for voice transcription features"
                    
                    // Provide error haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        } catch {
            await MainActor.run {
                permissionError = "Failed to request speech recognition permission: \(error.localizedDescription)"
                isRequestingSpeechPermission = false
                
                // Provide error haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
    }
    
    /// Completes the onboarding flow
    func completeOnboarding() {
        // Save completion status
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            isOnboardingCompleted = true
        }
        
        // Provide success haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Skips onboarding (for development purposes)
    func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isOnboardingCompleted = true
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Resets onboarding status (for development/testing)
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isOnboardingCompleted = false
            currentPage = 0
            permissionError = nil
        }
        
        checkMicrophonePermissionStatus()
    }
    
    // MARK: - Private Methods
    
    /// Loads onboarding completion status from UserDefaults
    private func loadOnboardingStatus() {
        isOnboardingCompleted = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }
    
    /// Checks current microphone permission status
    private func checkMicrophonePermissionStatus() {
        microphonePermissionStatus = AVAudioSession.sharedInstance().recordPermission
    }
}

// MARK: - Preview Support

#if DEBUG
extension OnboardingViewModel {
    /// Creates a preview OnboardingViewModel for SwiftUI previews
    static func preview(
        currentPage: Int = 0,
        isCompleted: Bool = false,
        microphonePermission: AVAudioSession.RecordPermission = .undetermined
    ) -> OnboardingViewModel {
        let viewModel = OnboardingViewModel()
        viewModel.currentPage = currentPage
        viewModel.isOnboardingCompleted = isCompleted
        viewModel.microphonePermissionStatus = microphonePermission
        return viewModel
    }
}
#endif