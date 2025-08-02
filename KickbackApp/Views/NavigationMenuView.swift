//
//  NavigationMenuView.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/2/25.
//

import SwiftUI

/// Global navigation menu overlay providing access to all app sections
/// Features glass morphism design and smooth animations
struct NavigationMenuView: View {
    
    // MARK: - Binding Properties
    
    @Binding var isPresented: Bool
    let mainViewModel: MainContentViewModel
    
    // MARK: - State Properties
    
    @State private var selectedSection: NavigationSection? = nil
    @State private var showingSpecialView: NavigationSection? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Menu content
            VStack(spacing: 0) {
                // Header
                menuHeader
                
                // Menu items
                menuItems
                
                Spacer()
            }
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
            .padding(.top, 100)
            
            // Special view overlays
            if let specialView = showingSpecialView {
                SpecialViewOverlay(
                    viewType: specialView,
                    isPresented: Binding(
                        get: { showingSpecialView != nil },
                        set: { if !$0 { showingSpecialView = nil } }
                    )
                )
                .zIndex(30)
            }
        }
    }
    
    // MARK: - Menu Components
    
    private var menuHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image("KickbackLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                
                Text("Kickback")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Divider()
                .overlay(Color.white.opacity(0.3))
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
    
    private var menuItems: some View {
        VStack(spacing: 12) {
            ForEach(NavigationSection.allCases, id: \.self) { section in
                MenuItemView(
                    section: section,
                    isSelected: selectedSection == section,
                    action: {
                        handleSectionTap(section)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Actions
    
    private func handleSectionTap(_ section: NavigationSection) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        selectedSection = section
        
        // Handle navigation based on section
        if section == .development {
            // For development tools, show overlay immediately without closing menu
            showingSpecialView = .development
        } else {
            // Add delay for visual feedback before navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isPresented = false
                }
                
                // Handle navigation based on section
                handleNavigation(to: section)
            }
        }
    }
    
    private func handleNavigation(to section: NavigationSection) {
        switch section {
        case .modeSelection:
            // Return to mode selection
            mainViewModel.returnToModeSelection()
            
        case .conversations:
            // Show conversation cards if not already showing
            if mainViewModel.showModeSelection {
                // If on mode selection, stay there
                break
            } else if !mainViewModel.showCards {
                // Show cards if hidden
                withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                    mainViewModel.showCards = true
                }
            }
            
        case .compatibilityResults:
            // Show compatibility results view
            showingSpecialView = .compatibilityResults
            
        case .compatibilityInsights:
            // Show compatibility insights view
            showingSpecialView = .compatibilityInsights
            
        case .voiceInput:
            // Show voice input view
            showingSpecialView = .voiceInput
            
        case .voiceRecording:
            // Show voice recording indicator
            showingSpecialView = .voiceRecording
            
        case .launchAnimation:
            // Show launch animation (for demo purposes)
            withAnimation(.easeInOut(duration: 0.8)) {
                mainViewModel.showLaunchAnimation = true
                mainViewModel.launchAnimationProgress = 0.0
            }
            
            // Auto-hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    mainViewModel.showLaunchAnimation = false
                }
            }
            
        case .development:
            // Development tools are handled in handleSectionTap
            break
        }
    }
}

// MARK: - Menu Item View

private struct MenuItemView: View {
    let section: NavigationSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: section.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? Color("BrandPurple") : .primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(section.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("BrandPurple").opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("BrandPurple").opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Navigation Section Model

enum NavigationSection: CaseIterable {
    case modeSelection
    case conversations
    case compatibilityResults
    case compatibilityInsights
    case voiceInput
    case voiceRecording
    case launchAnimation
    case development
    
    var title: String {
        switch self {
        case .modeSelection:
            return "Mode Selection"
        case .conversations:
            return "Conversation Cards"
        case .compatibilityResults:
            return "Compatibility Results"
        case .compatibilityInsights:
            return "Compatibility Insights"
        case .voiceInput:
            return "Voice Input"
        case .voiceRecording:
            return "Voice Recording"
        case .launchAnimation:
            return "Launch Screen"
        case .development:
            return "Development"
        }
    }
    
    var subtitle: String {
        switch self {
        case .modeSelection:
            return "Choose conversation mode"
        case .conversations:
            return "Question cards & deck"
        case .compatibilityResults:
            return "Compatibility analysis"
        case .compatibilityInsights:
            return "Detailed insights view"
        case .voiceInput:
            return "Record voice answers"
        case .voiceRecording:
            return "Voice recording indicator"
        case .launchAnimation:
            return "App startup sequence"
        case .development:
            return "Reset onboarding & dev tools"
        }
    }
    
    var iconName: String {
        switch self {
        case .modeSelection:
            return "list.bullet.rectangle"
        case .conversations:
            return "rectangle.stack"
        case .compatibilityResults:
            return "chart.line.uptrend.xyaxis"
        case .compatibilityInsights:
            return "lightbulb"
        case .voiceInput:
            return "mic"
        case .voiceRecording:
            return "waveform"
        case .launchAnimation:
            return "sparkles"
        case .development:
            return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Special View Overlay

struct SpecialViewOverlay: View {
    let viewType: NavigationSection
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Content
            VStack(spacing: 20) {
                HStack {
                    Button("Close") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    
                    Spacer()
                }
                .padding(.top, 60)
                
                // View content based on type
                Group {
                    switch viewType {
                    case .development:
                        DevelopmentToolsView(isPresented: $isPresented)
                    default:
                        PlaceholderView(title: viewType.title, subtitle: viewType.subtitle)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Placeholder View

struct PlaceholderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(Color("BrandPurple"))
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Development Tools View

struct DevelopmentToolsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 40))
                    .foregroundColor(Color("BrandPurple"))
                
                Text("Development Tools")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Reset app state for testing")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Development actions
            VStack(spacing: 16) {
                // Reset Onboarding
                Button(action: {
                    UserDefaults.standard.removeObject(forKey: "KickbackOnboardingCompleted")
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                    
                    // Brief delay to allow menu to close, then trigger onboarding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // This will trigger the main view to re-check onboarding status
                        NotificationCenter.default.post(name: NSNotification.Name("ResetOnboarding"), object: nil)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset Onboarding")
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BrandPurple").opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("BrandPurple").opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .foregroundColor(Color("BrandPurple"))
                
                // Clear UserDefaults
                Button(action: {
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    UserDefaults.standard.synchronize()
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Data")
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview Support

#Preview("Navigation Menu") {
    NavigationMenuView(
        isPresented: .constant(true),
        mainViewModel: MainContentViewModel.preview()
    )
    .preferredColorScheme(.light)
}

#Preview("Navigation Menu - Dark") {
    NavigationMenuView(
        isPresented: .constant(true),
        mainViewModel: MainContentViewModel.preview()
    )
    .preferredColorScheme(.dark)
}