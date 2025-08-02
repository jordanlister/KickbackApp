//
//  HowItWorksScreen.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// How It Works screen explaining the app workflow with animated step indicators
/// Features liquid glass design and smooth step-by-step reveal animations
struct HowItWorksScreen: View {
    
    // MARK: - Properties
    
    /// Whether the screen is currently visible
    let isVisible: Bool
    
    /// Action to perform when Previous button is tapped
    let onPrevious: () -> Void
    
    /// Action to perform when Next button is tapped
    let onNext: () -> Void
    
    /// Animation state properties for staggered reveals
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0.0
    @State private var step1Opacity: Double = 0.0
    @State private var step1Scale: CGFloat = 0.9
    @State private var step2Opacity: Double = 0.0
    @State private var step2Scale: CGFloat = 0.9
    @State private var step3Opacity: Double = 0.0
    @State private var step3Scale: CGFloat = 0.9
    @State private var connectingLine1Opacity: Double = 0.0
    @State private var connectingLine2Opacity: Double = 0.0
    
    /// Animation timing constants
    private let titleAnimationDelay: Double = 0.2
    private let step1AnimationDelay: Double = 0.5
    private let line1AnimationDelay: Double = 0.8
    private let step2AnimationDelay: Double = 1.1
    private let line2AnimationDelay: Double = 1.4
    private let step3AnimationDelay: Double = 1.7
    
    // MARK: - Step Data
    
    private let steps: [WorkflowStep] = [
        WorkflowStep(
            number: 1,
            title: "Select Cards",
            description: "Choose from AI-curated conversation cards designed for meaningful connections",
            iconName: "rectangle.stack.fill",
            color: Color("BrandPurple")
        ),
        WorkflowStep(
            number: 2,
            title: "Answer Questions",
            description: "Share your thoughts naturally through voice responses or written answers",
            iconName: "mic.circle.fill",
            color: Color("BrandPurpleLight")
        ),
        WorkflowStep(
            number: 3,
            title: "Discover Compatibility",
            description: "Get AI-powered insights about your connection and conversation dynamics",
            iconName: "heart.circle.fill",
            color: Color("BrandPurple")
        )
    ]
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing
                    Spacer(minLength: 20)
                    
                    // Title section
                    titleSection
                        .padding(.bottom, 20)
                    
                    // Steps section
                    stepsSection
                        .padding(.horizontal, 20)
                    
                    // Navigation buttons
                    HStack {
                        // Previous button
                        Button(action: onPrevious) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Previous")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color("BrandPurple"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color("BrandPurple").opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Spacer()
                        
                        // Next button
                        Button(action: onNext) {
                            HStack(spacing: 8) {
                                Text("Next")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color("BrandPurple"))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    
                    // Bottom spacing
                    Spacer(minLength: 20)
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollDisabled(true) // Prevent scrolling to maintain consistent layout
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
        .accessibilityLabel("How Kickback Works")
        .accessibilityHint("Explanation of the three-step process: select cards, answer questions, discover compatibility")
    }
    
    // MARK: - Subviews
    
    /// Title section with animated entrance
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("How It Works")
                .font(.system(size: 28, weight: .bold, design: .rounded))
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
            
            Text("Three simple steps to meaningful conversation")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .offset(y: titleOffset)
        .opacity(titleOpacity)
        .padding(.horizontal, 40)
    }
    
    /// Workflow steps with connecting lines
    @ViewBuilder
    private var stepsSection: some View {
        VStack(spacing: 0) {
            // Step 1
            workflowStepView(
                step: steps[0],
                opacity: step1Opacity,
                scale: step1Scale
            )
            
            // Connecting line 1
            connectingLine
                .opacity(connectingLine1Opacity)
                .padding(.vertical, 10)
            
            // Step 2
            workflowStepView(
                step: steps[1],
                opacity: step2Opacity,
                scale: step2Scale
            )
            
            // Connecting line 2
            connectingLine
                .opacity(connectingLine2Opacity)
                .padding(.vertical, 10)
            
            // Step 3
            workflowStepView(
                step: steps[2],
                opacity: step3Opacity,
                scale: step3Scale
            )
        }
    }
    
    /// Individual workflow step view with glass morphism
    @ViewBuilder
    private func workflowStepView(step: WorkflowStep, opacity: Double, scale: CGFloat) -> some View {
        HStack(spacing: 16) {
            // Step number and icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        step.color.opacity(0.4),
                                        step.color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(
                        color: step.color.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Image(systemName: step.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(step.color)
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Step number badge
                    Text("\(step.number)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(step.color)
                        )
                    
                    Text(step.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text(step.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassEffect(
            style: .regular,
            tint: step.color.opacity(0.08)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step.number): \(step.title)")
        .accessibilityHint(step.description)
    }
    
    /// Connecting line between steps
    @ViewBuilder
    private var connectingLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color("BrandPurple").opacity(0.3),
                        Color("BrandPurpleLight").opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: 40)
            .accessibilityHidden(true)
    }
    
    // MARK: - Animation Methods
    
    /// Starts the staggered entrance animation sequence
    private func startEntranceAnimation() {
        // Title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(titleAnimationDelay)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Step 1 animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(step1AnimationDelay)) {
            step1Opacity = 1.0
            step1Scale = 1.0
        }
        
        // Connecting line 1 animation
        withAnimation(.easeInOut(duration: 0.4).delay(line1AnimationDelay)) {
            connectingLine1Opacity = 1.0
        }
        
        // Step 2 animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(step2AnimationDelay)) {
            step2Opacity = 1.0
            step2Scale = 1.0
        }
        
        // Connecting line 2 animation
        withAnimation(.easeInOut(duration: 0.4).delay(line2AnimationDelay)) {
            connectingLine2Opacity = 1.0
        }
        
        // Step 3 animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(step3AnimationDelay)) {
            step3Opacity = 1.0
            step3Scale = 1.0
        }
    }
    
    /// Resets all animation states to initial values
    private func resetAnimationState() {
        titleOffset = 30
        titleOpacity = 0.0
        step1Opacity = 0.0
        step1Scale = 0.9
        step2Opacity = 0.0
        step2Scale = 0.9
        step3Opacity = 0.0
        step3Scale = 0.9
        connectingLine1Opacity = 0.0
        connectingLine2Opacity = 0.0
    }
}

// MARK: - Supporting Types

/// Data model for workflow steps
private struct WorkflowStep {
    let number: Int
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

// MARK: - Preview Support

#Preview("How It Works - Visible") {
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
        
        HowItWorksScreen(isVisible: true, onPrevious: {}, onNext: {})
    }
    .preferredColorScheme(.light)
}

#Preview("How It Works - Hidden") {
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
        
        HowItWorksScreen(isVisible: false, onPrevious: {}, onNext: {})
    }
    .preferredColorScheme(.light)
}

#Preview("How It Works - Animation Sequence") {
    struct HowItWorksAnimationDemo: View {
        @State private var isVisible = false
        
        var body: some View {
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
                
                HowItWorksScreen(isVisible: isVisible, onPrevious: {}, onNext: {})
                
                // Control button for preview
                VStack {
                    Spacer()
                    Button(isVisible ? "Hide" : "Show") {
                        withAnimation {
                            isVisible.toggle()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                // Auto-start animation after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isVisible = true
                }
            }
        }
    }
    
    return HowItWorksAnimationDemo()
        .preferredColorScheme(.light)
}