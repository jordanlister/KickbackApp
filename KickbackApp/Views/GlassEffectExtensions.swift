//
//  GlassEffectExtensions.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

// MARK: - iOS 26 Liquid Glass Extensions

extension View {
    /// Applies iOS 26 Liquid Glass effect with customizable styling and morphing support
    func glassEffect(
        style: GlassEffectStyle = .regular,
        tint: Color = .clear,
        glassID: String? = nil
    ) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tint)
                    .blendMode(.overlay)
                    .id(glassID ?? UUID().uuidString)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: style.borderWidth
                    )
                    .id("border_\(glassID ?? UUID().uuidString)")
            )
    }
    
    /// Makes glass elements interactive with touch feedback
    func interactive() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: false)
    }
}

/// Glass effect style configuration
enum GlassEffectStyle {
    case regular
    case prominent
    
    var borderWidth: CGFloat {
        switch self {
        case .regular:
            return 1
        case .prominent:
            return 1.5
        }
    }
}

/// Glass Effect Container for grouping related glass elements
struct GlassEffectContainer<Content: View>: View {
    let glassEffectID: String
    let content: Content
    
    init(glassEffectID: String, @ViewBuilder content: () -> Content) {
        self.glassEffectID = glassEffectID
        self.content = content()
    }
    
    var body: some View {
        content
            .glassEffect(
                style: .regular,
                tint: Color("BrandPurple").opacity(0.05)
            )
    }
}