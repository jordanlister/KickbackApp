import SwiftUI

/// Game progress indicator showing questions answered and remaining
/// Displays a beautiful progress bar with current progress and completion status
struct GameProgressIndicator: View {
    let questionsAnswered: Int
    let totalQuestions: Int
    
    private var progress: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(questionsAnswered) / Double(totalQuestions)
    }
    
    private var progressColor: Color {
        switch progress {
        case 0.0..<0.3: return .blue
        case 0.3..<0.7: return .purple
        case 0.7..<1.0: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress text
            HStack {
                Text("Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(questionsAnswered)/\(totalQuestions) questions")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.8), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    // Completion celebration effect
                    if progress >= 1.0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 6)
                            .scaleEffect(1.1)
                            .animation(.easeInOut(duration: 0.8).repeatCount(3), value: progress)
                    }
                }
            }
            .frame(height: 6)
            
            // Status text
            if progress >= 1.0 {
                Text("Ready for analysis! 🎉")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            } else {
                Text("\(totalQuestions - questionsAnswered) more to complete")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Question Completion Success Indicator

/// Success indicator shown when both players complete a question
struct QuestionCompletionSuccessIndicator: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var particleAnimations: [Bool] = Array(repeating: false, count: 8)
    
    let onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background blur
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(opacity)
            
            // Success checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.green)
                .scaleEffect(checkmarkScale)
                .opacity(opacity)
            
            // Celebration particles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 6, height: 6)
                    .scaleEffect(particleAnimations[index] ? 0.0 : 1.0)
                    .offset(
                        x: particleAnimations[index] ? cos(Double(index) * .pi / 4) * 80 : 0,
                        y: particleAnimations[index] ? sin(Double(index) * .pi / 4) * 80 : 0
                    )
                    .opacity(particleAnimations[index] ? 0.0 : 1.0)
            }
            
            // Success text
            VStack(spacing: 4) {
                Spacer()
                    .frame(height: 140)
                
                Text("Question Complete!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .opacity(opacity)
                
                Text("Both players answered")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(opacity)
            }
        }
        .onAppear {
            animateSuccess()
        }
    }
    
    private func animateSuccess() {
        // Initial scale and fade in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Checkmark scale in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
            checkmarkScale = 1.0
        }
        
        // Particle explosion
        for index in 0..<particleAnimations.count {
            withAnimation(.easeOut(duration: 1.0).delay(0.4 + Double(index) * 0.05)) {
                particleAnimations[index] = true
            }
        }
        
        // Auto-dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 0.0
                scale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onAnimationComplete()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        GameProgressIndicator(questionsAnswered: 2, totalQuestions: 5)
        GameProgressIndicator(questionsAnswered: 5, totalQuestions: 5)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}