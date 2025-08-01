import SwiftUI

// MARK: - Main Compatibility Insights View

/// View for displaying detailed compatibility insights and recommendations
struct CompatibilityInsightsView: View {
    let insights: [CompatibilityInsight]
    @ObservedObject var viewModel: CompatibilityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Key Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(insights.count) insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if insights.isEmpty {
                EmptyInsightsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(insights) { insight in
                        InsightCard(insight: insight, viewModel: viewModel)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $viewModel.showDetailedInsights) {
            if let selectedInsight = viewModel.selectedInsight {
                InsightDetailView(insight: selectedInsight, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: CompatibilityInsight
    @ObservedObject var viewModel: CompatibilityViewModel
    
    var body: some View {
        Button {
            viewModel.showInsightDetails(insight)
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: viewModel.iconName(for: insight.type))
                    .font(.title3)
                    .foregroundColor(colorForInsightType(insight.type))
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Confidence indicator
                        ConfidenceBadge(confidence: insight.confidence, viewModel: viewModel)
                    }
                    
                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorForInsightType(insight.type).opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func colorForInsightType(_ type: InsightType) -> Color {
        switch type {
        case .strength:
            return .green
        case .growthArea:
            return .orange
        case .communicationPattern:
            return .blue
        case .emotionalIntelligence:
            return .purple
        case .relationshipReadiness:
            return .indigo
        case .compatibility:
            return .pink
        }
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: InsightConfidence
    @ObservedObject var viewModel: CompatibilityViewModel
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<confidenceLevel, id: \.self) { _ in
                Circle()
                    .fill(viewModel.color(for: confidence))
                    .frame(width: 4, height: 4)
            }
            
            ForEach(confidenceLevel..<4, id: \.self) { _ in
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private var confidenceLevel: Int {
        switch confidence {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .veryHigh: return 4
        }
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: CompatibilityInsight
    @ObservedObject var viewModel: CompatibilityViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    InsightDetailHeader(insight: insight, viewModel: viewModel)
                    
                    // Description
                    InsightDetailDescription(insight: insight)
                    
                    // Related dimension (if applicable)
                    if let relatedDimension = insight.relatedDimension {
                        RelatedDimensionView(dimensionName: relatedDimension)
                    }
                    
                    // Recommendations
                    InsightRecommendations(insight: insight)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle(insight.type.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Insight Detail Header

struct InsightDetailHeader: View {
    let insight: CompatibilityInsight
    @ObservedObject var viewModel: CompatibilityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: viewModel.iconName(for: insight.type))
                    .font(.title)
                    .foregroundColor(colorForInsightType(insight.type))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(insight.confidence.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.color(for: insight.confidence))
                }
            }
            
            Text(insight.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorForInsightType(insight.type).opacity(0.1))
        )
    }
    
    private func colorForInsightType(_ type: InsightType) -> Color {
        switch type {
        case .strength:
            return .green
        case .growthArea:
            return .orange
        case .communicationPattern:
            return .blue
        case .emotionalIntelligence:
            return .purple
        case .relationshipReadiness:
            return .indigo
        case .compatibility:
            return .pink
        }
    }
}

// MARK: - Insight Detail Description

struct InsightDetailDescription: View {
    let insight: CompatibilityInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What This Means")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Related Dimension View

struct RelatedDimensionView: View {
    let dimensionName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Dimension")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: iconForDimension(dimensionName))
                    .foregroundColor(.blue)
                
                Text(dimensionName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Focus Area")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func iconForDimension(_ dimension: String) -> String {
        switch dimension.lowercased() {
        case "emotional openness":
            return "heart.circle.fill"
        case "clarity":
            return "message.circle.fill"
        case "empathy":
            return "person.2.circle.fill"
        case "vulnerability":
            return "lock.open.fill"
        case "communication style":
            return "bubble.left.and.bubble.right.fill"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - Insight Recommendations

struct InsightRecommendations: View {
    let insight: CompatibilityInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(recommendationsForInsight(insight), id: \.self) { recommendation in
                    RecommendationRow(text: recommendation)
                }
            }
        }
    }
    
    private func recommendationsForInsight(_ insight: CompatibilityInsight) -> [String] {
        switch insight.type {
        case .strength:
            return [
                "Continue leveraging this strength in your relationships",
                "Share your approach with your partner to help them grow",
                "Use this as a foundation for deeper connection"
            ]
        case .growthArea:
            return [
                "Practice in low-stakes conversations first",
                "Ask trusted friends for feedback on this area",
                "Set small, achievable goals for improvement"
            ]
        case .communicationPattern:
            return [
                "Be aware of this pattern in important conversations",
                "Practice active listening techniques",
                "Consider how your partner might prefer to communicate"
            ]
        case .emotionalIntelligence:
            return [
                "Practice identifying and naming emotions",
                "Read about emotional intelligence techniques",
                "Reflect on your emotional responses in relationships"
            ]
        case .relationshipReadiness:
            return [
                "Focus on personal growth and self-awareness",
                "Consider what you want from a relationship",
                "Work on communication skills in all relationships"
            ]
        case .compatibility:
            return [
                "Discuss these findings with your partner",
                "Focus on understanding each other's perspectives",
                "Use these insights to strengthen your connection"
            ]
        }
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Empty Insights View

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No Insights Available")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Complete the analysis to see your compatibility insights")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Insights Filter View

struct InsightsFilterView: View {
    @Binding var selectedFilter: InsightType?
    let insights: [CompatibilityInsight]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    count: insights.count,
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }
                
                ForEach(InsightType.allCases, id: \.self) { type in
                    let count = insights.filter { $0.type == type }.count
                    if count > 0 {
                        FilterChip(
                            title: type.displayName,
                            count: count,
                            isSelected: selectedFilter == type
                        ) {
                            selectedFilter = type
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let mockInsights = [
        CompatibilityInsight(
            type: .strength,
            title: "Clear Communication",
            description: "You express yourself clearly and directly, making it easy for others to understand your thoughts and feelings.",
            confidence: .high,
            relatedDimension: "Clarity"
        ),
        CompatibilityInsight(
            type: .growthArea,
            title: "Emotional Vulnerability",
            description: "Consider sharing more personal experiences and feelings to deepen emotional connections.",
            confidence: .medium,
            relatedDimension: "Vulnerability"
        ),
        CompatibilityInsight(
            type: .communicationPattern,
            title: "Active Listening",
            description: "You show good listening skills but could improve on asking follow-up questions.",
            confidence: .high
        )
    ]
    
    CompatibilityInsightsView(
        insights: mockInsights,
        viewModel: CompatibilityViewModel.mockViewModel()
    )
}