//
//  ContentView.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI

/// Main content view orchestrating the card-based conversation interface
/// Features launch animation, card deck management, and responsive design
struct ContentView: View {
    
    // MARK: - ViewModels
    
    @StateObject private var mainViewModel = MainContentViewModel()
    
    // MARK: - State Properties
    
    @State private var hasLaunched = false
    @State private var showNavigationMenu = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if mainViewModel.showOnboarding {
                // Onboarding flow
                OnboardingView(onComplete: {
                    mainViewModel.completeOnboarding()
                })
                .transition(.opacity)
                .zIndex(2)
            } else if mainViewModel.showLaunchAnimation {
                // Launch animation overlay
                LaunchAnimationView(progress: mainViewModel.launchAnimationProgress)
                    .transition(.opacity)
                    .zIndex(1)
            } else if mainViewModel.showGameResults {
                // Game completion results
                GameCompletionResultsView(mainViewModel: mainViewModel)
                    .transition(.opacity)
                    .zIndex(0)
            } else {
                // Main card interface
                CardDeckView(mainViewModel: mainViewModel)
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            // Global navigation button - only show when not in onboarding, launch animation, or game results
            if !mainViewModel.showOnboarding && !mainViewModel.showLaunchAnimation && !mainViewModel.showGameResults {
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showNavigationMenu.toggle()
                            }
                        }) {
                            Image(systemName: showNavigationMenu ? "xmark" : "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .rotationEffect(.degrees(showNavigationMenu ? 180 : 0))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showNavigationMenu)
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                    
                    Spacer()
                }
                .zIndex(10)
            }
            
            // Navigation menu overlay
            if showNavigationMenu {
                NavigationMenuView(
                    isPresented: $showNavigationMenu,
                    mainViewModel: mainViewModel
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: mainViewModel.showLaunchAnimation)
        .animation(.easeInOut(duration: 0.8), value: mainViewModel.showOnboarding)
        .animation(.easeInOut(duration: 0.8), value: mainViewModel.showGameResults)
        .onAppear {
            startAppIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            mainViewModel.handleAppBackgrounding()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetOnboarding"))) { _ in
            mainViewModel.checkOnboardingStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            mainViewModel.handleAppForegrounding()
        }
        .preferredColorScheme(.light) // Optimized for light mode gradient design
    }
    
    // MARK: - Private Methods
    
    /// Starts the app launch sequence if not already launched
    private func startAppIfNeeded() {
        guard !hasLaunched else { return }
        hasLaunched = true
        
        Task {
            await mainViewModel.startLaunchSequence()
        }
    }
}

#Preview {
    ContentView()
}
