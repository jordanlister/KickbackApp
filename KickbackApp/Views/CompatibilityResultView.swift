import SwiftUI

// MARK: - Main Compatibility Result View

/// Primary view for displaying compatibility analysis results
/// Shows score, summary, dimensions, and insights in an engaging layout
struct CompatibilityResultView: View {
    @ObservedObject var viewModel: CompatibilityViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isAnalyzing {
                    AnalysisProgressView()
                } else if let result = viewModel.currentResult {
                    CompatibilityScoreCard(result: result, viewModel: viewModel)
                    CompatibilityDimensionsView(dimensions: result.dimensions)
                    CompatibilityInsightsView(insights: result.insights, viewModel: viewModel)
                } else if viewModel.hasError {
                    ErrorStateView(
                        error: viewModel.currentError?.localizedDescription ?? "Unknown error",
                        onRetry: {
                            Task {
                                await viewModel.retryAnalysis()
                            }
                        }
                    )
                } else {
                    EmptyStateView()
                }
            }
            .padding()
        }
        .navigationTitle("Compatibility Analysis")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("New Analysis", systemImage: "plus.circle") {
                        viewModel.clearCurrentResult()
                    }
                    Button("View History", systemImage: "clock") {
                        // Navigate to history view
                    }
                    Button("Session Analysis", systemImage: "chart.line.uptrend.xyaxis") {
                        Task {
                            await viewModel.analyzeCurrentSession()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}


// MARK: - Compatibility Score Card

struct CompatibilityScoreCard: View {
    let result: CompatibilityResult
    @ObservedObject var viewModel: CompatibilityViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Score display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compatibility Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(viewModel.formattedScore)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.scoreColor)
                        
                        Text("/ 100")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    
                    Text(viewModel.scoreCategory)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.scoreColor)
                }
                
                Spacer()
                
                // Score visualization
                ScoreRingView(score: result.score, color: viewModel.scoreColor)
            }
            
            Divider()
            
            // Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Analysis Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(result.summary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            // Tone indicator
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Detected Tone: \(result.tone)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
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

// MARK: - Score Ring View

struct ScoreRingView: View {
    let score: Int
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: Double(score) / 100.0)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: score)
            
            Text("\(score)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Compatibility Dimensions View

struct CompatibilityDimensionsView: View {
    let dimensions: CompatibilityDimensions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compatibility Dimensions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DimensionRow(name: "Emotional Openness", score: dimensions.emotionalOpenness, icon: "heart.circle.fill")
                DimensionRow(name: "Clarity", score: dimensions.clarity, icon: "message.circle.fill")
                DimensionRow(name: "Empathy", score: dimensions.empathy, icon: "person.2.circle.fill")
                DimensionRow(name: "Vulnerability", score: dimensions.vulnerability, icon: "lock.open.fill")
                DimensionRow(name: "Communication Style", score: dimensions.communicationStyle, icon: "bubble.left.and.bubble.right.fill")
            }
            
            // Dimension insights
            DimensionInsightsView(dimensions: dimensions)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Dimension Row

struct DimensionRow: View {
    let name: String
    let score: Int
    let icon: String
    
    var dimensionColor: Color {
        switch score {
        case 85...100: return .green
        case 70..<85: return .blue
        case 55..<70: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(dimensionColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ProgressView(value: Double(score), total: 100)
                    .tint(dimensionColor)
                    .scaleEffect(y: 0.8)
            }
            
            Spacer()
            
            Text("\(score)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(dimensionColor)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Dimension Insights View

struct DimensionInsightsView: View {
    let dimensions: CompatibilityDimensions
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strongest Area")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let strongest = dimensions.strongestDimension
                    Text(strongest.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Growth Area")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let growth = dimensions.growthArea
                    Text(growth.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}


// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Ready for Analysis")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Answer a question to get your compatibility insights")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CompatibilityResultView(viewModel: CompatibilityViewModel.mockViewModel())
    }
}