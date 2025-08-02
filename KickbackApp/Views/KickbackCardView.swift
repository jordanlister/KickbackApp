//
//  KickbackCardView.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Individual Kickback card with iOS 26 Liquid Glass design
/// Features stunning glass morphism with logo and interactive effects
struct KickbackCardView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: CardViewModel
    let cardIndex: Int
    let isBack: Bool
    
    /// Tap action closure passed from parent view
    var onTap: (() -> Void)?
    
    /// Visual feedback state for taps
    @State private var isPressed: Bool = false
    
    /// Glass effect ID for smooth morphing transitions
    private var glassEffectID: String {
        return "glass_card_\(cardIndex)_\(isBack ? "back" : "front")"
    }
    
    /// Glass card styling constants
    private let glassCornerRadius: CGFloat = 20
    private let glassShadowRadius: CGFloat = 12
    private let glassBorderWidth: CGFloat = 1.5
    private let glassBlurIntensity: CGFloat = 0.8
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Glass card background with stunning morphism
            glassCardBackground
            
            // Glass card content based on flip state
            if isBack {
                glassCardBackContent
            } else {
                glassCardFrontContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: glassCornerRadius))
        .glassEffect(
            style: .prominent,
            tint: categoryColor.opacity(0.1),
            glassID: glassEffectID
        )
        .interactive()
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .shadow(
            color: categoryColor.opacity(isPressed ? 0.4 : 0.2),
            radius: glassShadowRadius,
            x: 0,
            y: isPressed ? 3 : 6
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            handleCardTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to expand this conversation card")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Subviews
    
    /// Glass card background with stunning morphism
    @ViewBuilder
    private var glassCardBackground: some View {
        RoundedRectangle(cornerRadius: glassCornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: glassCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                categoryColor.opacity(0.15),
                                categoryColor.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: glassCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: glassBorderWidth
                    )
            )
    }
    
    /// Glass card back content with stunning logo presentation
    @ViewBuilder
    private var glassCardBackContent: some View {
        VStack {
            Spacer()
            
            // Kickback logo with glass effects
            Image("KickbackLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(Color("BrandPurple"))
                .glassEffect(
                    style: .prominent,
                    tint: Color("BrandPurple").opacity(0.1)
                )
                .interactive()
                .scaleEffect(1.1)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).repeatForever(autoreverses: true), value: true)
            
            Spacer()
        }
        .padding(16)
    }
    
    /// Glass card front content with stunning question preview
    @ViewBuilder
    private var glassCardFrontContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category header with glass effects
            HStack {
                Text(viewModel.category.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(
                        style: .regular,
                        tint: categoryColor.opacity(0.1)
                    )
                    .interactive()
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .progressViewStyle(CircularProgressViewStyle(tint: categoryColor))
                        .glassEffect(
                            style: .regular,
                            tint: categoryColor.opacity(0.05)
                        )
                        .interactive()
                }
            }
            
            Spacer()
            
            // Question preview with glass effects
            if viewModel.isLoading {
                glassLoadingPlaceholder
            } else if !viewModel.question.isEmpty {
                glassQuestionPreview
            } else {
                glassEmptyQuestionState
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    /// Glass loading placeholder with stunning shimmer effect
    @ViewBuilder
    private var glassLoadingPlaceholder: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .frame(height: 10)
                .glassEffect(
                    style: .regular,
                    tint: categoryColor.opacity(0.1)
                )
                .redacted(reason: .placeholder)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .frame(height: 10)
                .frame(width: .random(in: 40...70))
                .glassEffect(
                    style: .regular,
                    tint: categoryColor.opacity(0.1)
                )
                .redacted(reason: .placeholder)
        }
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isLoading)
    }
    
    /// Glass question preview with stunning typography
    @ViewBuilder
    private var glassQuestionPreview: some View {
        let words = viewModel.question.components(separatedBy: " ")
        let previewWords = Array(words.prefix(6)).joined(separator: " ")
        let hasMore = words.count > 6
        
        Text(previewWords + (hasMore ? "..." : ""))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .glassEffect(
                style: .regular,
                tint: categoryColor.opacity(0.05)
            )
            .interactive()
    }
    
    /// Glass empty question state with elegant styling
    @ViewBuilder
    private var glassEmptyQuestionState: some View {
        Text("Tap to reveal")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .italic()
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .glassEffect(
                style: .regular,
                tint: categoryColor.opacity(0.05)
            )
            .interactive()
    }
    
    // MARK: - Private Methods
    
    /// Handles card tap with haptic feedback and calls the provided onTap closure
    private func handleCardTap() {
        print("KickbackCardView handleCardTap called for card \(cardIndex)") // Debug log
        
        // Provide haptic feedback for better user experience
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Call the tap handler provided by parent view
        onTap?()
        
        print("KickbackCardView onTap closure executed for card \(cardIndex)") // Debug log
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic glass material based on category and state
    private var glassMaterial: Material {
        return isBack ? .ultraThinMaterial : .thinMaterial
    }
    
    /// Dynamic glass tint color based on category and state
    private var glassTintColor: Color {
        if isBack {
            return Color("BrandPurple").opacity(0.1)
        } else {
            return categoryColor.opacity(0.1)
        }
    }
    
    /// Category-specific color theming
    private var categoryColor: Color {
        switch viewModel.category {
        case .firstDate, .blindDate:
            return .blue
        case .personalGrowth, .emotionalIntelligence:
            return .green
        case .funAndPlayful:
            return .orange
        case .deepCouple, .intimacyBuilding:
            return .purple
        case .vulnerabilitySharing:
            return .pink
        case .futureVisions, .longTermRelationship:
            return .indigo
        case .conflictResolution:
            return .red
        case .loveLanguageDiscovery:
            return .teal
        case .earlyDating:
            return .mint
        case .valuesAlignment:
            return .brown
        case .lifeTransitions:
            return .cyan
        }
    }
    
    /// Accessibility label for the card
    private var accessibilityLabel: String {
        if isBack {
            return "Kickback conversation card for \(viewModel.category.displayName)"
        } else if viewModel.isLoading {
            return "Loading \(viewModel.category.displayName) question"
        } else if !viewModel.question.isEmpty {
            let words = viewModel.question.components(separatedBy: " ")
            let preview = Array(words.prefix(10)).joined(separator: " ")
            return "\(viewModel.category.displayName) card: \(preview)"
        } else {
            return "Empty \(viewModel.category.displayName) card"
        }
    }
}

// Glass effects are imported from GlassEffectExtensions.swift

// MARK: - Preview Support

#Preview("Card Back") {
    KickbackCardView(
        viewModel: CardViewModel.preview(
            question: "What's something that always makes you laugh?",
            category: .funAndPlayful,
            isFlipped: false
        ),
        cardIndex: 0,
        isBack: true,
        onTap: {
            print("Card tapped in preview")
        }
    )
    .frame(width: 100, height: 140)
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Card Front") {
    KickbackCardView(
        viewModel: CardViewModel.preview(
            question: "What's something that always makes you laugh, even on your worst days?",
            category: .funAndPlayful,
            isFlipped: true
        ),
        cardIndex: 0,
        isBack: false,
        onTap: {
            print("Card tapped in preview")
        }
    )
    .frame(width: 100, height: 140)
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Loading State") {
    KickbackCardView(
        viewModel: CardViewModel.preview(
            question: "",
            category: .personalGrowth,
            isFlipped: false,
            isLoading: true
        ),
        cardIndex: 0,
        isBack: false,
        onTap: {
            print("Loading card tapped in preview")
        }
    )
    .frame(width: 100, height: 140)
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.3),
                Color("BrandPurpleLight").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("All Cards Horizontal") {
    HStack(spacing: 20) {
        KickbackCardView(
            viewModel: CardViewModel.preview(
                question: "What's your favorite childhood memory?",
                category: .firstDate
            ),
            cardIndex: 0,
            isBack: true,
            onTap: { print("First card tapped") }
        )
        
        KickbackCardView(
            viewModel: CardViewModel.preview(
                question: "What's something you're currently learning about yourself?",
                category: .personalGrowth
            ),
            cardIndex: 1,
            isBack: true,
            onTap: { print("Second card tapped") }
        )
        
        KickbackCardView(
            viewModel: CardViewModel.preview(
                question: "If you could be any fictional character for a day, who would you choose?",
                category: .funAndPlayful
            ),
            cardIndex: 2,
            isBack: true,
            onTap: { print("Third card tapped") }
        )
    }
    .frame(width: 100, height: 140)
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple").opacity(0.4),
                Color("BrandPurpleLight").opacity(0.3),
                Color.clear.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}