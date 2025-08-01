//
//  AudioSessionManager.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import Foundation
import AVFoundation
import SwiftUI

/// Manages audio session lifecycle, interruptions, and proper cleanup
/// Ensures optimal audio recording experience with proper iOS audio session handling
@MainActor 
public final class AudioSessionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current audio session state
    @Published var sessionState: AudioSessionState = .inactive
    
    /// Whether the audio session is currently active
    @Published var isSessionActive: Bool = false
    
    /// Current interruption state
    @Published var isInterrupted: Bool = false
    
    /// Audio route information for debugging
    @Published var currentAudioRoute: String = ""
    
    // MARK: - Private Properties
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var silenceObserver: NSObjectProtocol?
    
    /// Delegate for handling session events
    weak var delegate: AudioSessionManagerDelegate?
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
        updateAudioRoute()
    }
    
    deinit {
        deactivateSession()
        removeNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /// Activates the audio session for recording
    /// - Throws: AudioSessionError for various failure cases
    func activateSession() throws {
        do {
            // Configure audio session for recording
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.duckOthers, .allowBluetooth]
            )
            
            // Set preferred sample rate and buffer duration for optimal recording
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms for low latency
            
            // Activate the session
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            sessionState = .active
            isSessionActive = true
            updateAudioRoute()
            
            print("Audio session activated successfully")
            
        } catch {
            sessionState = .error(error.localizedDescription)
            throw AudioSessionError.activationFailed(error.localizedDescription)
        }
    }
    
    /// Deactivates the audio session
    func deactivateSession() {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            sessionState = .inactive
            isSessionActive = false
            
            print("Audio session deactivated successfully")
            
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
            sessionState = .error(error.localizedDescription)
        }
    }
    
    /// Handles interruption begin event
    func handleInterruptionBegan() {
        isInterrupted = true
        sessionState = .interrupted
        delegate?.audioSessionWasInterrupted()
    }
    
    /// Handles interruption end event
    /// - Parameter shouldResume: Whether the session should be resumed automatically
    func handleInterruptionEnded(shouldResume: Bool) {
        isInterrupted = false
        
        if shouldResume {
            do {
                try activateSession()
                delegate?.audioSessionInterruptionEnded(shouldResume: true)
            } catch {
                sessionState = .error("Failed to resume after interruption: \(error.localizedDescription)")
                delegate?.audioSessionInterruptionEnded(shouldResume: false)
            }
        } else {
            sessionState = .inactive
            delegate?.audioSessionInterruptionEnded(shouldResume: false)
        }
    }
    
    /// Checks if the current audio route is suitable for recording
    func validateAudioRoute() -> AudioRouteValidation {
        let currentRoute = audioSession.currentRoute
        
        // Check if we have an input available
        guard !currentRoute.inputs.isEmpty else {
            return .invalid("No audio input available")
        }
        
        let input = currentRoute.inputs[0]
        
        // Check for wired headset (best quality)
        if input.portType == .headsetMic {
            return .optimal("Wired headset microphone")
        }
        
        // Check for built-in microphone
        if input.portType == .builtInMic {
            return .good("Built-in microphone")
        }
        
        // Check for Bluetooth
        if input.portType == .bluetoothHFP {
            return .acceptable("Bluetooth microphone (reduced quality)")
        }
        
        // Other input types
        return .acceptable("External microphone: \(input.portName)")
    }
    
    // MARK: - Private Methods
    
    /// Sets up notification observers for audio session events
    private func setupNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        // Audio interruption handling
        interruptionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruptionNotification(notification)
        }
        
        // Audio route change handling
        routeChangeObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChangeNotification(notification)
        }
        
        // Audio session silence handling (iOS 15+)
        if #available(iOS 15.0, *) {
            silenceObserver = notificationCenter.addObserver(
                forName: AVAudioSession.silenceSecondaryAudioHintNotification,
                object: audioSession,
                queue: .main
            ) { [weak self] notification in
                self?.handleSilenceNotification(notification)
            }
        }
    }
    
    /// Removes notification observers
    private func removeNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        if let observer = interruptionObserver {
            notificationCenter.removeObserver(observer)
        }
        
        if let observer = routeChangeObserver {
            notificationCenter.removeObserver(observer)
        }
        
        if let observer = silenceObserver {
            notificationCenter.removeObserver(observer)
        }
    }
    
    /// Handles audio interruption notifications
    private func handleInterruptionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            handleInterruptionBegan()
            
        case .ended:
            let shouldResume: Bool
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                shouldResume = options.contains(.shouldResume)
            } else {
                shouldResume = false
            }
            
            handleInterruptionEnded(shouldResume: shouldResume)
            
        @unknown default:
            print("Unknown interruption type: \(type)")
        }
    }
    
    /// Handles audio route change notifications
    private func handleRouteChangeNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        updateAudioRoute()
        
        switch reason {
        case .newDeviceAvailable:
            print("New audio device available")
            delegate?.audioRouteChanged(reason: "New device connected")
            
        case .oldDeviceUnavailable:
            print("Audio device disconnected")
            delegate?.audioRouteChanged(reason: "Device disconnected")
            
        case .categoryChange:
            print("Audio category changed")
            
        case .override:
            print("Audio route overridden")
            
        case .wakeFromSleep:
            print("Audio session wake from sleep")
            
        case .noSuitableRouteForCategory:
            print("No suitable route for category")
            sessionState = .error("No suitable audio route available")
            
        case .routeConfigurationChange:
            print("Audio route configuration changed")
            
        @unknown default:
            print("Unknown route change reason: \(reason)")
        }
    }
    
    /// Handles silence secondary audio notifications
    private func handleSilenceNotification(_ notification: Notification) {
        print("Secondary audio silenced")
        // This notification indicates that another audio session has started
        // and may have silenced our audio. We might want to pause recording.
        delegate?.audioSessionSecondaryAudioSilenced()
    }
    
    /// Updates the current audio route information
    private func updateAudioRoute() {
        let route = audioSession.currentRoute
        if let input = route.inputs.first {
            currentAudioRoute = "\(input.portName) (\(input.portType.rawValue))"
        } else {
            currentAudioRoute = "No input available"
        }
    }
}

// MARK: - Supporting Types

/// Audio session state
public enum AudioSessionState: Equatable {
    case inactive
    case active
    case interrupted
    case error(String)
}

/// Audio route validation result
public enum AudioRouteValidation {
    case optimal(String)
    case good(String)
    case acceptable(String)
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .invalid:
            return false
        default:
            return true
        }
    }
    
    var message: String {
        switch self {
        case .optimal(let msg), .good(let msg), .acceptable(let msg), .invalid(let msg):
            return msg
        }
    }
}

/// Audio session errors
public enum AudioSessionError: LocalizedError {
    case activationFailed(String)
    case configurationFailed(String)
    case routeNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .activationFailed(let message):
            return "Audio session activation failed: \(message)"
        case .configurationFailed(let message):
            return "Audio session configuration failed: \(message)"
        case .routeNotAvailable:
            return "No suitable audio route is available"
        }
    }
}

/// Delegate protocol for audio session events
public protocol AudioSessionManagerDelegate: AnyObject {
    func audioSessionWasInterrupted()
    func audioSessionInterruptionEnded(shouldResume: Bool)
    func audioRouteChanged(reason: String)
    func audioSessionSecondaryAudioSilenced()
}