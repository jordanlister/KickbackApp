//
//  OnboardingView.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI
import AVFoundation

/// Main onboarding flow container with page navigation and liquid glass design
/// Features smooth page transitions, progress indicators, and gesture navigation
struct OnboardingView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = OnboardingViewModel()
    @Namespace private var pageTransition
    
    /// Callback for onboarding completion
    let onComplete: () -> Void
    
    /// Animation constants
    private let pageTransitionDuration: Double = 0.6
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient matching main app
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top navigation area
                    topNavigationArea
                        .frame(height: 80)
                        .padding(.horizontal, 20)
                    
                    // Main content area with page transitions
                    pageContentArea(geometry: geometry)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom navigation area
                    bottomNavigationArea
                        .frame(height: 120)
                        .padding(.horizontal, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
                }
            }
        }
        .onChange(of: viewModel.isOnboardingCompleted) { _, isCompleted in
            if isCompleted {
                onComplete()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding flow")
        .accessibilityHint("Use Next and Previous buttons to navigate between pages")
    }
    
    // MARK: - Subviews
    
    /// Top navigation with progress indicator and skip button
    @ViewBuilder
    private var topNavigationArea: some View {
        HStack {
            // Skip button (left side)
            Button("Skip") {
                viewModel.skipOnboarding()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color("BrandPurple"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color("BrandPurple").opacity(0.3), lineWidth: 1)
                    )
            )
            .accessibilityLabel("Skip onboarding")
            .accessibilityHint("Skip the onboarding process and go directly to the app")
            
            Spacer()
            
            // Progress indicator (center)
            progressIndicator
            
            Spacer()
            
            // Placeholder for visual balance
            Color.clear
                .frame(width: 60, height: 36)
        }
        .padding(.top, 20)
    }
    
    /// Progress indicator with page dots
    @ViewBuilder
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                Circle()
                    .fill(
                        index == viewModel.currentPage ? 
                        Color("BrandPurple") : 
                        Color("BrandPurple").opacity(0.3)
                    )
                    .frame(
                        width: index == viewModel.currentPage ? 12 : 8,
                        height: index == viewModel.currentPage ? 12 : 8
                    )
                    .scaleEffect(index == viewModel.currentPage ? 1.0 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentPage)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress indicator")
        .accessibilityValue("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
    }
    
    /// Main page content area with transitions
    @ViewBuilder
    private func pageContentArea(geometry: GeometryProxy) -> some View {
        ZStack {
            // Page content with horizontal offset for swipe gesture
            HStack(spacing: 0) {
                ForEach(0..<viewModel.totalPages, id: \.self) { pageIndex in
                    pageView(for: pageIndex)
                        .frame(width: geometry.size.width)
                        .matchedGeometryEffect(
                            id: "page_\(pageIndex)",
                            in: pageTransition
                        )
                }
            }
            .offset(
                x: -CGFloat(viewModel.currentPage) * geometry.size.width
            )
            .animation(
                viewModel.isTransitioning ? 
                .spring(response: pageTransitionDuration, dampingFraction: 0.8) : 
                .interactiveSpring(),
                value: viewModel.currentPage
            )
        }
        .clipped()
    }
    
    /// Individual page view based on index
    @ViewBuilder
    private func pageView(for pageIndex: Int) -> some View {
        let page = OnboardingViewModel.OnboardingPage(rawValue: pageIndex) ?? .welcome
        let isCurrentPage = pageIndex == viewModel.currentPage
        
        switch page {
        case .welcome:
            WelcomeScreen(isVisible: isCurrentPage)
            
        case .howItWorks:
            HowItWorksScreen(isVisible: isCurrentPage)
            
        case .microphonePermission:
            MicrophonePermissionScreen(
                isVisible: isCurrentPage,
                permissionStatus: viewModel.microphonePermissionStatus,
                isRequestingPermission: viewModel.isRequestingMicrophonePermission,
                permissionError: viewModel.permissionError,
                onRequestPermission: {
                    await viewModel.requestMicrophonePermission()
                }
            )
        }
    }
    
    /// Bottom navigation with next/previous buttons
    @ViewBuilder
    private var bottomNavigationArea: some View {
        HStack {
            // Previous button (left side)
            if viewModel.currentPage > 0 {
                Button(action: {
                    viewModel.previousPage()
                }) {
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
                .disabled(viewModel.isTransitioning)
                .accessibilityLabel("Previous page")
                .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                Spacer()
                    .frame(width: 100) // Maintain layout balance
            }
            
            Spacer()
            
            // Next/Complete button (right side)
            Button(action: {
                if viewModel.isLastPage && viewModel.canProceedToNext {
                    viewModel.completeOnboarding()
                } else if viewModel.canProceedToNext || !viewModel.isLastPage {
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 8) {
                    Text(buttonText)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Image(systemName: buttonIconName)
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    buttonColor,
                                    buttonColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: buttonColor.opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(canProceed ? 1.0 : 0.95)
                .opacity(canProceed ? 1.0 : 0.6)
            }
            .disabled(viewModel.isTransitioning || !canProceed)
            .animation(.easeInOut(duration: 0.2), value: canProceed)
            .accessibilityLabel(buttonText)
            .accessibilityHint(buttonAccessibilityHint)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Computed Properties
    
    /// Background gradient matching the main app
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Whether the user can proceed to the next page
    private var canProceed: Bool {
        if viewModel.isLastPage {
            return viewModel.canProceedToNext
        } else {
            return true // Can always proceed to non-final pages
        }
    }
    
    /// Text for the main action button
    private var buttonText: String {
        if viewModel.isLastPage {
            return viewModel.canProceedToNext ? "Begin" : "Allow Access"
        } else {
            return "Next"
        }
    }
    
    /// Icon name for the main action button
    private var buttonIconName: String {
        if viewModel.isLastPage {
            return viewModel.canProceedToNext ? "arrow.right.circle.fill" : "mic.badge.plus"
        } else {
            return "chevron.right"
        }
    }
    
    /// Color for the main action button
    private var buttonColor: Color {
        if viewModel.isLastPage && !viewModel.canProceedToNext {
            return Color("BrandPurple")
        } else {
            return Color("BrandPurple")
        }
    }
    
    /// Accessibility hint for the main action button
    private var buttonAccessibilityHint: String {
        if viewModel.isLastPage {
            return viewModel.canProceedToNext ? 
                "Complete onboarding and start using the app" : 
                "Grant microphone permission to continue"
        } else {
            return "Go to the next onboarding page"
        }
    }
    
}

// MARK: - Preview Support

#Preview("Onboarding - Welcome Page") {
    OnboardingView(onComplete: {})
        .preferredColorScheme(.light)
}

#Preview("Onboarding - How It Works Page") {
    struct OnboardingPreview: View {
        var body: some View {
            OnboardingView(onComplete: {})
                .onAppear {
                    // Simulate navigation to page 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // This would be handled by the ViewModel in real usage
                    }
                }
        }
    }
    
    return OnboardingPreview()
        .preferredColorScheme(.light)
}

#Preview("Onboarding - Permission Page") {
    struct OnboardingPermissionPreview: View {
        var body: some View {
            OnboardingView(onComplete: {})
                .onAppear {
                    // Simulate navigation to page 2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // This would be handled by the ViewModel in real usage
                    }
                }
        }
    }
    
    return OnboardingPermissionPreview()
        .preferredColorScheme(.light)
}

#Preview("Onboarding - Complete Flow") {
    struct OnboardingFlowDemo: View {
        @State private var showOnboarding = true
        
        var body: some View {
            if showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation {
                        showOnboarding = false
                    }
                })
            } else {
                ZStack {
                    Color.green.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        Text("Onboarding Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Button("Show Onboarding Again") {
                            withAnimation {
                                showOnboarding = true
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    return OnboardingFlowDemo()
        .preferredColorScheme(.light)
}