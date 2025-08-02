import SwiftUI

// MARK: - Game Completion Results View

/// Comprehensive view for displaying game completion analysis results
/// Shows individual player analyses, compatibility insights, and relationship potential
struct GameCompletionResultsView: View {
    @ObservedObject var mainViewModel: MainContentViewModel
    
    @State private var currentTab = 0
    @State private var showDetailedAnalysis = false
    @State private var animateScores = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if mainViewModel.isAnalyzingGame {
                    AnalysisProgressView()
                } else if let error = mainViewModel.gameAnalysisError {
                    ErrorStateView(error: error, onRetry: {
                        mainViewModel.retryGameAnalysis()
                    })
                } else if let result = mainViewModel.gameCompletionResult {
                    CompletionResultsContent(result: result, currentTab: $currentTab, animateScores: $animateScores)
                } else {
                    EmptyResultsState()
                }
            }
            .navigationTitle("Your Results")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Game") {
                        mainViewModel.startNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Share Results", systemImage: "square.and.arrow.up") {
                            // Implement sharing functionality
                        }
                        Button("Save Analysis", systemImage: "square.and.arrow.down") {
                            // Implement save functionality
                        }
                        Button("Detailed Insights", systemImage: "chart.bar.doc.horizontal") {
                            showDetailedAnalysis = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
                    animateScores = true
                }
            }
        }
        .sheet(isPresented: $showDetailedAnalysis) {
            if let result = mainViewModel.gameCompletionResult {
                DetailedAnalysisView(result: result)
            }
        }
    }
}

// MARK: - Analysis Progress View

struct AnalysisProgressView: View {
    @State private var progressPhase = 0
    @State private var progressValue: Double = 0.0
    
    private let phases = [
        "Analyzing individual responses...",
        "Comparing communication styles...",
        "Calculating compatibility scores...",
        "Generating insights...",
        "Finalizing results..."
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Main progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progressValue)
                
                VStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("\(Int(progressValue * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Phase description
            VStack(spacing: 8) {
                Text("Analyzing Your Compatibility")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(phases[min(progressPhase, phases.count - 1)])
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut, value: progressPhase)
            }
            .padding(.horizontal)
            
            // Animated thinking indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .scaleEffect(progressPhase == index ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: progressPhase
                        )
                }
            }
        }
        .padding()
        .onAppear {
            simulateProgress()
        }
    }
    
    private func simulateProgress() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progressValue = min(progressValue + 0.02, 1.0)
            
            let newPhase = Int(progressValue * Double(phases.count))
            if newPhase != progressPhase && newPhase < phases.count {
                progressPhase = newPhase
            }
            
            if progressValue >= 1.0 {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Completion Results Content

struct CompletionResultsContent: View {
    let result: GameCompletionResult
    @Binding var currentTab: Int
    @Binding var animateScores: Bool
    
    var body: some View {
        TabView(selection: $currentTab) {
            // Overview Tab
            OverviewTab(result: result, animateScores: $animateScores)
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Overview")
                }
                .tag(0)
            
            // Individual Analysis Tab
            IndividualAnalysisTab(result: result)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Individual")
                }
                .tag(1)
            
            // Compatibility Tab
            CompatibilityTab(result: result)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Compatibility")
                }
                .tag(2)
            
            // Insights Tab
            InsightsTab(result: result)
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Insights")
                }
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let result: GameCompletionResult
    @Binding var animateScores: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with overall score
                OverallScoreCard(
                    score: result.comparativeAnalysis.overallCompatibilityScore,
                    tier: result.comparativeAnalysis.compatibilityTier,
                    animateScores: $animateScores
                )
                
                // Game metrics cards
                GameMetricsGrid(metrics: result.gameMetrics, animateScores: $animateScores)
                
                // Quick insights
                QuickInsightsCard(insights: result.sessionInsights)
                
                // Next steps
                NextStepsCard(steps: result.comparativeAnalysis.recommendedNextSteps)
            }
            .padding()
        }
    }
}

// MARK: - Overall Score Card

struct OverallScoreCard: View {
    let score: Int
    let tier: CompatibilityTier
    @Binding var animateScores: Bool
    
    private var scoreColor: Color {
        switch score {
        case 85...100: return .green
        case 70..<85: return .blue
        case 55..<70: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 16)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: animateScores ? Double(score) / 100.0 : 0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: animateScores)
                
                VStack {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                        .scaleEffect(animateScores ? 1.0 : 0.8)
                        .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.5), value: animateScores)
                    
                    Text("Overall Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Tier description
            VStack(spacing: 8) {
                Text(tier.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor)
                
                Text(tier.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Game Metrics Grid

struct GameMetricsGrid: View {
    let metrics: GameMetrics
    @Binding var animateScores: Bool
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Compatibility Potential",
                score: metrics.compatibilityPotential,
                icon: "heart.circle.fill",
                color: .pink,
                animateScores: $animateScores
            )
            
            MetricCard(
                title: "Communication Quality",
                score: metrics.communicationQuality,
                icon: "bubble.left.and.bubble.right.fill",
                color: .blue,
                animateScores: $animateScores
            )
            
            MetricCard(
                title: "Engagement Level",
                score: metrics.engagementLevel,
                icon: "flame.fill",
                color: .orange,
                animateScores: $animateScores
            )
            
            MetricCard(
                title: "Balance Score",
                score: metrics.balanceScore,
                icon: "scale.3d",
                color: .green,
                animateScores: $animateScores
            )
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let score: Int
    let icon: String
    let color: Color
    @Binding var animateScores: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .scaleEffect(animateScores ? 1.0 : 0.7)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double.random(in: 0.2...0.8)), value: animateScores)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Quick Insights Card

struct QuickInsightsCard: View {
    let insights: [SessionInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insights.prefix(3), id: \.title) { insight in
                InsightRow(insight: insight)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let insight: SessionInsight
    
    private var iconColor: Color {
        switch insight.impact {
        case .positive: return .green
        case .neutral: return .blue
        case .informational: return .purple
        case .cautionary: return .orange
        }
    }
    
    private var iconName: String {
        switch insight.type {
        case .communicationStrength: return "message.circle.fill"
        case .progressionTrend: return "chart.line.uptrend.xyaxis.circle.fill"
        case .categoryStrength: return "star.circle.fill"
        case .balancePattern: return "scale.3d"
        case .growthOpportunity: return "leaf.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Next Steps Card

struct NextStepsCard: View {
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Next Steps")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(steps.prefix(4), id: \.self) { step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 16)
                    
                    Text(step)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Individual Analysis Tab

struct IndividualAnalysisTab: View {
    let result: GameCompletionResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Player 1 Analysis
                PlayerAnalysisCard(
                    playerNumber: 1,
                    analysis: result.player1Analysis,
                    title: "Player 1 Analysis"
                )
                
                // Player 2 Analysis
                PlayerAnalysisCard(
                    playerNumber: 2,
                    analysis: result.player2Analysis,
                    title: "Player 2 Analysis"
                )
            }
            .padding()
        }
    }
}

// MARK: - Player Analysis Card

struct PlayerAnalysisCard: View {
    let playerNumber: Int
    let analysis: PlayerSessionAnalysis
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(analysis.averageScore)/100")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            
            // Dimensions breakdown
            DimensionsBreakdownView(results: analysis.individualResults)
            
            // Strengths and growth areas
            StrengthsAndGrowthView(
                strengths: analysis.strongestDimensions,
                growthAreas: analysis.growthAreas
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var scoreColor: Color {
        switch analysis.averageScore {
        case 85...100: return .green
        case 70..<85: return .blue
        case 55..<70: return .orange
        default: return .red
        }
    }
}

// MARK: - Dimensions Breakdown View

struct DimensionsBreakdownView: View {
    let results: [CompatibilityResult]
    
    private var averageDimensions: CompatibilityDimensions {
        let count = results.count
        guard count > 0 else {
            return CompatibilityDimensions(emotionalOpenness: 0, clarity: 0, empathy: 0, vulnerability: 0, communicationStyle: 0)
        }
        
        let sum = results.reduce(CompatibilityDimensions(emotionalOpenness: 0, clarity: 0, empathy: 0, vulnerability: 0, communicationStyle: 0)) { sum, result in
            CompatibilityDimensions(
                emotionalOpenness: sum.emotionalOpenness + result.dimensions.emotionalOpenness,
                clarity: sum.clarity + result.dimensions.clarity,
                empathy: sum.empathy + result.dimensions.empathy,
                vulnerability: sum.vulnerability + result.dimensions.vulnerability,
                communicationStyle: sum.communicationStyle + result.dimensions.communicationStyle
            )
        }
        
        return CompatibilityDimensions(
            emotionalOpenness: sum.emotionalOpenness / count,
            clarity: sum.clarity / count,
            empathy: sum.empathy / count,
            vulnerability: sum.vulnerability / count,
            communicationStyle: sum.communicationStyle / count
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            DimensionBar(name: "Emotional Openness", score: averageDimensions.emotionalOpenness, icon: "heart.fill")
            DimensionBar(name: "Clarity", score: averageDimensions.clarity, icon: "message.fill")
            DimensionBar(name: "Empathy", score: averageDimensions.empathy, icon: "person.2.fill")
            DimensionBar(name: "Vulnerability", score: averageDimensions.vulnerability, icon: "lock.open.fill")
            DimensionBar(name: "Communication", score: averageDimensions.communicationStyle, icon: "bubble.left.and.bubble.right.fill")
        }
    }
}

// MARK: - Dimension Bar

struct DimensionBar: View {
    let name: String
    let score: Int
    let icon: String
    
    private var barColor: Color {
        switch score {
        case 80...100: return .green
        case 65..<80: return .blue
        case 50..<65: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(barColor)
                .frame(width: 16)
            
            Text(name)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(barColor)
                        .frame(width: geometry.size.width * Double(score) / 100.0, height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 1.0), value: score)
                }
            }
            .frame(height: 6)
            
            Text("\(score)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(barColor)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

// MARK: - Strengths and Growth View

struct StrengthsAndGrowthView: View {
    let strengths: [String]
    let growthAreas: [String]
    
    var body: some View {
        HStack(spacing: 16) {
            // Strengths
            VStack(alignment: .leading, spacing: 8) {
                Text("Strengths")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                ForEach(strengths.prefix(2), id: \.self) { strength in
                    Text("• \(strength)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Growth areas
            VStack(alignment: .leading, spacing: 8) {
                Text("Growth Areas")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                
                ForEach(growthAreas.prefix(2), id: \.self) { area in
                    Text("• \(area)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Compatibility Tab

struct CompatibilityTab: View {
    let result: GameCompletionResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Compatibility score header
                CompatibilityScoreHeader(analysis: result.comparativeAnalysis)
                
                // Question-by-question comparison
                QuestionComparisonList(comparisons: result.comparativeAnalysis.questionComparisons)
                
                // Communication synergy
                CommunicationSynergyCard(synergy: result.comparativeAnalysis.communicationSynergy)
            }
            .padding()
        }
    }
}

// MARK: - Compatibility Score Header

struct CompatibilityScoreHeader: View {
    let analysis: ComparativeGameAnalysis
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Relationship Compatibility")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(analysis.overallCompatibilityScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Overall Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text(analysis.compatibilityTier.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("Compatibility Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Question Comparison List

struct QuestionComparisonList: View {
    let comparisons: [QuestionComparison]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(comparisons.indices, id: \.self) { index in
                QuestionComparisonCard(
                    comparison: comparisons[index],
                    questionNumber: index + 1
                )
            }
        }
    }
}

// MARK: - Question Comparison Card

struct QuestionComparisonCard: View {
    let comparison: QuestionComparison
    let questionNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Question \(questionNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            // Question text
            Text(comparison.question)
                .font(.body)
                .foregroundColor(.primary)
            
            // Scores comparison
            HStack {
                VStack(alignment: .leading) {
                    Text("Player 1: \(comparison.player1Result.score)")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Player 2: \(comparison.player2Result.score)")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Alignment: \(Int(comparison.alignmentScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Complementarity: \(Int(comparison.complementarityScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Communication Synergy Card

struct CommunicationSynergyCard: View {
    let synergy: CommunicationSynergy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Communication Synergy")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Synergy score
            HStack {
                Text("Synergy Score:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(synergy.synergyScore * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Strengths
            if !synergy.strengths.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Strengths")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    ForEach(synergy.strengths, id: \.self) { strength in
                        Text("• \(strength)")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Recommendations
            if !synergy.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    ForEach(synergy.recommendations, id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.body)
                            .foregroundColor(.primary)
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
    }
}

// MARK: - Insights Tab

struct InsightsTab: View {
    let result: GameCompletionResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Session insights
                SessionInsightsCard(insights: result.sessionInsights)
                
                // Relationship insights
                RelationshipInsightsCard(insights: result.comparativeAnalysis.relationshipInsights)
                
                // Action items
                ActionItemsCard(steps: result.comparativeAnalysis.recommendedNextSteps)
            }
            .padding()
        }
    }
}

// MARK: - Session Insights Card

struct SessionInsightsCard: View {
    let insights: [SessionInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insights, id: \.title) { insight in
                SessionInsightRow(insight: insight)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Session Insight Row

struct SessionInsightRow: View {
    let insight: SessionInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(insight.confidence.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Relationship Insights Card

struct RelationshipInsightsCard: View {
    let insights: [RelationshipInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Relationship Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insights, id: \.title) { insight in
                RelationshipInsightRow(insight: insight)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Relationship Insight Row

struct RelationshipInsightRow: View {
    let insight: RelationshipInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(insight.strength.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(strengthColor.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var strengthColor: Color {
        switch insight.strength {
        case .high: return .green
        case .medium: return .orange
        case .developing: return .blue
        }
    }
}

// MARK: - Action Items Card

struct ActionItemsCard: View {
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(steps.indices, id: \.self) { index in
                ActionItemRow(step: steps[index], number: index + 1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Action Item Row

struct ActionItemRow: View {
    let step: String
    let number: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(step)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Analysis Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Empty Results State

struct EmptyResultsState: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("No Results Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Complete all 5 questions to see your compatibility analysis")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Detailed Analysis View

struct DetailedAnalysisView: View {
    let result: GameCompletionResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Detailed metrics and breakdowns would go here
                    Text("Detailed analysis coming soon...")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Detailed Analysis")
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

// MARK: - Preview

#Preview {
    GameCompletionResultsView(mainViewModel: MainContentViewModel.preview())
}