//
//  LaunchAnimationView.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Launch animation view with smooth logo fade-in and progress indicator
/// Designed for optimal 60fps performance during app startup
struct LaunchAnimationView: View {
    
    // MARK: - Properties
    
    let progress: Double
    
    /// Animation state properties
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0.0
    @State private var progressBarWidth: CGFloat = 0.0
    
    /// Animation constants
    private let logoAnimationDelay: Double = 0.2
    private let titleAnimationDelay: Double = 0.8
    private let progressAnimationDelay: Double = 1.2
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            launchBackgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App logo/icon
                logoSection
                
                // App title
                titleSection
                
                Spacer()
                
                // Progress indicator
                progressSection
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startLaunchAnimation()
        }
        .onChange(of: progress) { _, newProgress in
            updateProgressBar(newProgress)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Kickback app launching")
        .accessibilityValue("Loading progress: \(Int(progress * 100)) percent")
        .accessibilityHint("Please wait while the app prepares your conversation cards")
    }
    
    // MARK: - Subviews
    
    /// App logo with scaling animation
    @ViewBuilder
    private var logoSection: some View {
        ZStack {
            // Background circle for logo
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            // Logo icon (using SF Symbol as placeholder - replace with actual logo)
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.white)
                .symbolEffect(.pulse.byLayer, options: .repeating)
                .accessibilityLabel("Kickback app logo")
                .accessibilityHidden(true) // Part of larger element
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
    
    /// App title with slide-up animation
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Kickback")
                .font(.system(size: 36, weight: .light, design: .rounded))
                .foregroundColor(.white)
            
            Text("Conversation Cards")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .tracking(2)
        }
        .offset(y: titleOffset)
        .opacity(titleOpacity)
    }
    
    /// Progress bar with smooth fill animation
    @ViewBuilder
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress bar background
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: progressBarWidth, height: 4)
            }
            .frame(width: 200)
            
            // Progress text
            Text("Preparing your cards...")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .opacity(progress > 0.3 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5), value: progress)
                .accessibilityHidden(true) // Handled by parent element
        }
        .opacity(progress > 0.1 ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic background gradient that shifts during launch
    private var launchBackgroundGradient: LinearGradient {
        let colors: [Color]
        
        if progress < 0.5 {
            colors = [
                Color(red: 0.2, green: 0.3, blue: 0.8),
                Color(red: 0.6, green: 0.2, blue: 0.8)
            ]
        } else {
            colors = [
                Color(red: 0.9, green: 0.6, blue: 0.7),
                Color(red: 0.8, green: 0.5, blue: 0.9),
                Color(red: 0.6, green: 0.7, blue: 0.9)
            ]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Animation Methods
    
    /// Starts the sequential launch animation
    private func startLaunchAnimation() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(logoAnimationDelay)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(titleAnimationDelay)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
    }
    
    /// Updates progress bar width based on loading progress
    private func updateProgressBar(_ newProgress: Double) {
        let clampedProgress = min(max(newProgress, 0.0), 1.0)
        let targetWidth = 200 * clampedProgress
        
        withAnimation(.easeInOut(duration: 0.3)) {
            progressBarWidth = targetWidth
        }
    }
}

// MARK: - Preview Support

#Preview("Launch Animation - Start") {
    LaunchAnimationView(progress: 0.0)
}

#Preview("Launch Animation - Mid") {
    LaunchAnimationView(progress: 0.5)
}

#Preview("Launch Animation - Complete") {
    LaunchAnimationView(progress: 1.0)
}

#Preview("Launch Animation - Sequence") {
    struct LaunchAnimationSequence: View {
        @State private var progress: Double = 0.0
        
        var body: some View {
            LaunchAnimationView(progress: progress)
                .onAppear {
                    // Simulate loading progress
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                        if progress < 1.0 {
                            progress += 0.05
                        } else {
                            timer.invalidate()
                        }
                    }
                }
        }
    }
    
    return LaunchAnimationSequence()
}