//
//  KickbackCardView.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Individual Kickback card component with brand-consistent design
/// Shows card back with logo when not flipped, question preview when flipped
struct KickbackCardView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: CardViewModel
    let cardIndex: Int
    let isBack: Bool
    
    /// Card styling constants
    private let cornerRadius: CGFloat = 12
    private let shadowRadius: CGFloat = 8
    private let borderWidth: CGFloat = 1
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Card background with subtle gradient
            cardBackground
            
            // Card content based on flip state
            if isBack {
                cardBackContent
            } else {
                cardFrontContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(
            color: Color.black.opacity(0.15),
            radius: shadowRadius,
            x: 0,
            y: 4
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to expand this conversation card")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Subviews
    
    /// Card background with brand-consistent styling
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(cardBackgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            )
    }
    
    /// Card back content showing Kickback logo only
    @ViewBuilder
    private var cardBackContent: some View {
        VStack {
            Spacer()
            
            // Kickback logo centered
            Image("KickbackLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(12)
    }
    
    /// Card front content showing question preview
    @ViewBuilder
    private var cardFrontContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category header
            HStack {
                Text(viewModel.category.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .progressViewStyle(CircularProgressViewStyle(tint: categoryColor))
                }
            }
            
            Spacer()
            
            // Question preview (first few words)
            if viewModel.isLoading {
                loadingPlaceholder
            } else if !viewModel.question.isEmpty {
                questionPreview
            } else {
                emptyQuestionState
            }
            
            Spacer()
        }
        .padding(12)
    }
    
    /// Loading placeholder with animated shimmer effect
    @ViewBuilder
    private var loadingPlaceholder: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(height: 8)
                .redacted(reason: .placeholder)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(height: 8)
                .frame(width: .random(in: 40...70))
                .redacted(reason: .placeholder)
        }
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isLoading)
    }
    
    /// Question preview showing first few words
    @ViewBuilder
    private var questionPreview: some View {
        let words = viewModel.question.components(separatedBy: " ")
        let previewWords = Array(words.prefix(6)).joined(separator: " ")
        let hasMore = words.count > 6
        
        Text(previewWords + (hasMore ? "..." : ""))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.leading)
            .lineLimit(3)
    }
    
    /// Empty question state
    @ViewBuilder
    private var emptyQuestionState: some View {
        Text("Tap to reveal")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.6))
            .italic()
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic card background based on category and state
    private var cardBackgroundGradient: LinearGradient {
        if isBack {
            // Unified back design with brand colors
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color("BrandPurple").opacity(0.8),
                    Color("BrandPurpleLight").opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Category-specific front design
            let baseColor = categoryColor
            return LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.7),
                    baseColor.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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

// MARK: - Preview Support

#Preview("Card Back") {
    KickbackCardView(
        viewModel: CardViewModel.mock(
            question: "What's something that always makes you laugh?",
            category: .funAndPlayful,
            isFlipped: false
        ),
        cardIndex: 0,
        isBack: true
    )
    .frame(width: 100, height: 140)
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Card Front") {
    KickbackCardView(
        viewModel: CardViewModel.mock(
            question: "What's something that always makes you laugh, even on your worst days?",
            category: .funAndPlayful,
            isFlipped: true
        ),
        cardIndex: 0,
        isBack: false
    )
    .frame(width: 100, height: 140)
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Loading State") {
    KickbackCardView(
        viewModel: CardViewModel.mock(
            question: "",
            category: .personalGrowth,
            isFlipped: false,
            isLoading: true
        ),
        cardIndex: 0,
        isBack: false
    )
    .frame(width: 100, height: 140)
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("All Cards Horizontal") {
    HStack(spacing: 20) {
        KickbackCardView(
            viewModel: CardViewModel.mock(
                question: "What's your favorite childhood memory?",
                category: .firstDate
            ),
            cardIndex: 0,
            isBack: true
        )
        
        KickbackCardView(
            viewModel: CardViewModel.mock(
                question: "What's something you're currently learning about yourself?",
                category: .personalGrowth
            ),
            cardIndex: 1,
            isBack: true
        )
        
        KickbackCardView(
            viewModel: CardViewModel.mock(
                question: "If you could be any fictional character for a day, who would you choose?",
                category: .funAndPlayful
            ),
            cardIndex: 2,
            isBack: true
        )
    }
    .frame(width: 100, height: 140)
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BrandPurple"),
                Color("BrandPurpleLight")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}