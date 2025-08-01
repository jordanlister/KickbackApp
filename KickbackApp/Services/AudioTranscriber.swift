//
//  AudioTranscriber.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import Foundation
import AVFoundation
import Speech
import SwiftUI

/// Comprehensive on-device audio recording and speech recognition service
/// Uses AVFoundation for audio capture and Speech framework for offline transcription
/// Designed for privacy-compliant, on-device processing with proper permission handling
@MainActor
public final class AudioTranscriber: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current recording state
    @Published var isRecording: Bool = false
    
    /// Current transcription text
    @Published var transcriptionText: String = ""
    
    /// Real-time partial transcription during recording
    @Published var partialTranscription: String = ""
    
    /// Audio level for visual feedback (0.0 to 1.0)
    @Published var audioLevel: Float = 0.0
    
    /// Current error state, if any
    @Published var currentError: AudioTranscriberError?
    
    /// Permission states
    @Published var microphonePermission: PermissionState = .notDetermined
    @Published var speechRecognitionPermission: PermissionState = .notDetermined
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    /// Audio recorder for saving raw audio files
    private var audioRecorder: AVAudioRecorder?
    
    /// Audio session manager for handling interruptions
    private let audioSessionManager = AudioSessionManager()
    
    /// Audio format configuration
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
    
    /// Timer for audio level monitoring
    private var audioLevelTimer: Timer?
    
    /// Temporary audio file URL for recording
    private var recordingURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("temp_recording_\(UUID().uuidString).m4a")
    }
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        setupSpeechRecognizer()
        checkPermissions()
        setupAudioSessionDelegate()
    }
    
    deinit {
        Task { @MainActor in
            await stopRecording()
        }
        audioEngine?.stop()
        audioLevelTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Starts audio recording and real-time transcription
    /// - Throws: AudioTranscriberError for various failure cases
    func startRecording() async throws {
        // Check permissions first
        try await ensurePermissions()
        
        // Reset state
        currentError = nil
        transcriptionText = ""
        partialTranscription = ""
        audioLevel = 0.0
        
        // Setup audio session
        try await setupAudioSession()
        
        // Setup audio engine for transcription
        try setupAudioEngine()
        
        // Setup audio recorder for file saving
        try setupAudioRecorder()
        
        try audioRecorder?.record()
        
        // Start audio engine
        try audioEngine?.start()
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
        
        isRecording = true
    }
    
    /// Stops recording and returns final transcription
    /// - Returns: Final transcribed text
    func stopRecording() async -> String {
        guard isRecording else { return transcriptionText }
        
        // Stop audio components
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        audioRecorder?.stop()
        audioLevelTimer?.invalidate()
        audioLevel = 0.0
        
        // Finish recognition
        recognitionRequest?.endAudio()
        
        // Wait a moment for final transcription
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Clean up
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        isRecording = false
        
        // Process and return final transcription
        let finalText = transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return finalText.isEmpty ? partialTranscription : finalText
    }
    
    /// Checks and requests necessary permissions
    func requestPermissions() async -> Bool {
        do {
            try await ensurePermissions()
            return true
        } catch {
            currentError = error as? AudioTranscriberError ?? .permissionDenied("Unknown permission error")
            return false
        }
    }
    
    /// Checks current permission status without requesting
    func checkPermissions() {
        // Check microphone permission
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphonePermission = .granted
        case .denied:
            microphonePermission = .denied
        case .undetermined:
            microphonePermission = .notDetermined
        @unknown default:
            microphonePermission = .notDetermined
        }
        
        // Check speech recognition permission
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionPermission = .granted
        case .denied, .restricted:
            speechRecognitionPermission = .denied
        case .notDetermined:
            speechRecognitionPermission = .notDetermined
        @unknown default:
            speechRecognitionPermission = .notDetermined
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up the speech recognizer for on-device processing
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        
        // Ensure on-device recognition is supported
        guard let recognizer = speechRecognizer else {
            currentError = .speechRecognitionNotAvailable
            return
        }
        
        // Configure for on-device processing
        if recognizer.supportsOnDeviceRecognition {
            print("On-device speech recognition is supported")
        } else {
            print("Warning: On-device speech recognition may not be available")
        }
    }
    
    /// Ensures all required permissions are granted
    private func ensurePermissions() async throws {
        // Request microphone permission
        let micGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        guard micGranted else {
            microphonePermission = .denied
            throw AudioTranscriberError.permissionDenied("Microphone access is required for voice recording")
        }
        
        microphonePermission = .granted
        
        // Request speech recognition permission
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        guard speechGranted else {
            speechRecognitionPermission = .denied
            throw AudioTranscriberError.permissionDenied("Speech recognition access is required for transcription")
        }
        
        speechRecognitionPermission = .granted
    }
    
    /// Sets up the audio session for recording using AudioSessionManager
    private func setupAudioSession() async throws {
        do {
            try audioSessionManager.activateSession()
        } catch {
            throw AudioTranscriberError.audioEngineError("Failed to activate audio session: \(error.localizedDescription)")
        }
    }
    
    /// Sets up audio session manager delegate
    private func setupAudioSessionDelegate() {
        audioSessionManager.delegate = self
    }
    
    /// Sets up the audio engine for real-time transcription
    private func setupAudioEngine() throws {
        guard let speechRecognizer = speechRecognizer else {
            throw AudioTranscriberError.speechRecognitionNotAvailable
        }
        
        // Create audio engine and input node
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw AudioTranscriberError.audioEngineError("Failed to create audio engine")
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            throw AudioTranscriberError.audioEngineError("No audio input available")
        }
        
        // Create recognition request for on-device processing
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw AudioTranscriberError.speechRecognitionNotAvailable
        }
        
        // Configure for on-device recognition
        recognitionRequest.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result, error: error)
            }
        }
        
        // Configure audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Prepare audio engine
        audioEngine.prepare()
    }
    
    /// Sets up audio recorder for saving raw audio files
    private func setupAudioRecorder() throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
    }
    
    /// Handles speech recognition results
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            currentError = .transcriptionError(error.localizedDescription)
            return
        }
        
        guard let result = result else { return }
        
        let transcription = result.bestTranscription.formattedString
        
        if result.isFinal {
            transcriptionText = processTranscription(transcription)
            partialTranscription = ""
        } else {
            partialTranscription = processTranscription(transcription)
        }
    }
    
    /// Processes and cleans up transcribed text
    private func processTranscription(_ text: String) -> String {
        var processed = text
        
        // Capitalize first letter
        if !processed.isEmpty {
            processed = processed.prefix(1).uppercased() + processed.dropFirst()
        }
        
        // Remove common filler words at the end
        let fillerWords = ["um", "uh", "like", "you know"]
        for filler in fillerWords {
            if processed.lowercased().hasSuffix(" \(filler)") {
                processed = String(processed.dropLast(filler.count + 1))
            }
        }
        
        return processed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Starts monitoring audio levels for visual feedback
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }
    
    /// Updates audio level from the recorder
    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0.0
            return
        }
        
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        
        // Convert decibel to linear scale (0.0 to 1.0)
        let normalizedPower = max(0.0, (power + 80.0) / 80.0)
        audioLevel = normalizedPower
    }
}

// MARK: - AudioSessionManagerDelegate

extension AudioTranscriber: AudioSessionManagerDelegate {
    nonisolated public func audioSessionWasInterrupted() {
        Task { @MainActor in
            if isRecording {
                _ = await stopRecording()
                currentError = .recordingError("Recording was interrupted by another audio session")
            }
        }
    }
    
    nonisolated public func audioSessionInterruptionEnded(shouldResume: Bool) {
        // For now, we don't automatically resume recording after interruption
        // The user will need to manually start recording again
        if !shouldResume {
            Task { @MainActor in
                currentError = .recordingError("Audio session interruption ended. Please start recording again.")
            }
        }
    }
    
    nonisolated public func audioRouteChanged(reason: String) {
        print("Audio route changed: \(reason)")
        // We could potentially notify the user about audio route changes
        // For now, we'll just log it
    }
    
    nonisolated public func audioSessionSecondaryAudioSilenced() {
        print("Secondary audio was silenced")
        // This might indicate that another app is using audio
        // We could potentially pause recording or notify the user
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioTranscriber: AVAudioRecorderDelegate {
    nonisolated public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                currentError = .recordingError("Audio recording failed")
            }
        }
    }
    
    nonisolated public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            currentError = .recordingError(error?.localizedDescription ?? "Audio encoding error")
        }
    }
}

// MARK: - Supporting Types

/// Permission states for audio and speech recognition
public enum PermissionState {
    case notDetermined
    case granted
    case denied
}

/// Comprehensive error types for audio transcription
public enum AudioTranscriberError: LocalizedError {
    case permissionDenied(String)
    case speechRecognitionNotAvailable
    case audioEngineError(String)
    case recordingError(String)
    case transcriptionError(String)
    case deviceNotSupported
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .speechRecognitionNotAvailable:
            return "Speech recognition is not available on this device"
        case .audioEngineError(let message):
            return "Audio engine error: \(message)"
        case .recordingError(let message):
            return "Recording error: \(message)"
        case .transcriptionError(let message):
            return "Transcription error: \(message)"
        case .deviceNotSupported:
            return "This device does not support the required audio features"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please enable microphone and speech recognition permissions in Settings"
        case .speechRecognitionNotAvailable:
            return "Speech recognition requires iOS 10.0 or later and may not be available in all regions"
        case .audioEngineError, .recordingError:
            return "Please try again or restart the app if the problem persists"
        case .transcriptionError:
            return "Check your internet connection and try again"
        case .deviceNotSupported:
            return "This feature requires a newer device with on-device speech recognition support"
        }
    }
}