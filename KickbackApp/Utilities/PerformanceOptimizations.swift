//
//  PerformanceOptimizations.swift
//  KickbackApp
//
//  Created by Jordan Lister on 8/1/25.
//

import SwiftUI
import Combine

/// Performance optimization utilities for maintaining 60fps animations
/// Contains view modifiers and helpers to ensure smooth user experience
struct PerformanceOptimizations {
    
    // MARK: - Animation Performance Constants
    
    /// Optimized animation parameters for 60fps target
    static let smoothSpringAnimation = Animation.spring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    static let fastEaseInOutAnimation = Animation.easeInOut(duration: 0.3)
    
    static let cardFlipAnimation = Animation.spring(
        response: 0.5,
        dampingFraction: 0.9,
        blendDuration: 0
    )
    
    // MARK: - Performance Monitoring
    
    /// Simple performance monitor for development builds
    #if DEBUG
    static func measureAnimationPerformance<T>(
        operation: () -> T,
        name: String = "Animation"
    ) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if timeElapsed > 0.016 { // More than 16ms (60fps threshold)
            print("⚠️ Performance Warning: \(name) took \(timeElapsed * 1000)ms (target: <16ms)")
        }
        
        return result
    }
    #endif
}

// MARK: - Performance-Optimized View Modifiers

/// View modifier that optimizes animations for consistent frame rates
struct SmoothAnimationModifier: ViewModifier {
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(animation, value: UUID()) // Stable animation reference
            .drawingGroup() // Composite animations off-screen for better performance
    }
}

/// View modifier for optimizing card flip animations
struct CardFlipOptimizationModifier: ViewModifier {
    let isFlipped: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isFlipped ? 1.05 : 1.0)
            .animation(PerformanceOptimizations.cardFlipAnimation, value: isFlipped)
            .drawingGroup(opaque: false, colorMode: .linear) // GPU acceleration
    }
}

/// View modifier for optimizing text reveal animations
struct TextRevealOptimizationModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(progress > 0 ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.2), value: progress > 0)
            .compositingGroup() // Reduce overdraw
    }
}

// MARK: - View Extensions

extension View {
    /// Applies performance-optimized smooth animation
    func smoothAnimation(_ animation: Animation = PerformanceOptimizations.smoothSpringAnimation) -> some View {
        modifier(SmoothAnimationModifier(animation: animation))
    }
    
    /// Applies card flip optimization
    func optimizedCardFlip(isFlipped: Bool) -> some View {
        modifier(CardFlipOptimizationModifier(isFlipped: isFlipped))
    }
    
    /// Applies text reveal optimization
    func optimizedTextReveal(progress: Double) -> some View {
        modifier(TextRevealOptimizationModifier(progress: progress))
    }
    
    /// Enables GPU acceleration for complex animations
    func gpuAccelerated() -> some View {
        self.drawingGroup()
    }
    
    /// Reduces animation complexity on older devices
    func adaptivePerformance() -> some View {
        Group {
            if ProcessInfo.processInfo.thermalState == .nominal {
                // Full animations on capable devices
                self
            } else {
                // Reduced animations on thermally constrained devices
                self.animation(.none)
            }
        }
    }
}

// MARK: - Animation Presets

extension Animation {
    /// Optimized card entrance animation
    static var cardEntrance: Animation {
        .spring(response: 0.7, dampingFraction: 0.75, blendDuration: 0)
    }
    
    /// Optimized card selection animation
    static var cardSelection: Animation {
        .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    }
    
    /// Optimized refresh animation
    static var refreshAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.9, blendDuration: 0)
    }
    
    /// Optimized launch animation
    static var launchAnimation: Animation {
        .easeInOut(duration: 0.8)
    }
}

// MARK: - Performance Metrics (Debug Only)

#if DEBUG
/// Performance metrics collector for development
class PerformanceMetrics: ObservableObject {
    @Published var averageFrameTime: Double = 0.0
    @Published var frameDrops: Int = 0
    
    private var frameTimes: [Double] = []
    private let maxSamples = 60 // Track last 60 frames
    
    func recordFrameTime(_ time: Double) {
        frameTimes.append(time)
        
        if frameTimes.count > maxSamples {
            frameTimes.removeFirst()
        }
        
        // Calculate average
        averageFrameTime = frameTimes.reduce(0, +) / Double(frameTimes.count)
        
        // Count frame drops (>16.67ms for 60fps)
        if time > 0.01667 {
            frameDrops += 1
        }
    }
    
    var performanceGrade: String {
        if averageFrameTime < 0.01667 {
            return "Excellent (60+ FPS)"
        } else if averageFrameTime < 0.02 {
            return "Good (50-60 FPS)"
        } else if averageFrameTime < 0.033 {
            return "Fair (30-50 FPS)"
        } else {
            return "Poor (<30 FPS)"
        }
    }
}

/// Performance monitoring view modifier for debugging
struct PerformanceMonitorModifier: ViewModifier {
    @StateObject private var metrics = PerformanceMetrics()
    @State private var lastFrameTime = CFAbsoluteTimeGetCurrent()
    
    func body(content: Content) -> some View {
        content
            .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
                let currentTime = CFAbsoluteTimeGetCurrent()
                let frameTime = currentTime - lastFrameTime
                metrics.recordFrameTime(frameTime)
                lastFrameTime = currentTime
            }
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing) {
                    Text(metrics.performanceGrade)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text("Drops: \(metrics.frameDrops)")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .padding()
            }
    }
}

extension View {
    /// Adds performance monitoring overlay (Debug builds only)
    func monitorPerformance() -> some View {
        modifier(PerformanceMonitorModifier())
    }
}
#endif