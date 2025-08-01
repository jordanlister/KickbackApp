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
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if mainViewModel.showLaunchAnimation {
                // Launch animation overlay
                LaunchAnimationView(progress: mainViewModel.launchAnimationProgress)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                // Main card interface
                CardDeckView(mainViewModel: mainViewModel)
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: mainViewModel.showLaunchAnimation)
        .onAppear {
            startAppIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            mainViewModel.handleAppBackgrounding()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            mainViewModel.handleAppForegrounding()
        }
        .preferredColorScheme(.light) // Optimized for light mode gradient design
        #if DEBUG
        .monitorPerformance() // Performance monitoring in debug builds
        #endif
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
