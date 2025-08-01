import Foundation

// MARK: - QuestionEngine Usage Examples

/// Example implementations showing how to use the QuestionEngine system
/// in various scenarios within the Kickback app
public final class QuestionEngineExampleUsage {
    
    private let questionEngine: QuestionEngine
    
    public init(questionEngine: QuestionEngine = QuestionEngineService()) {
        self.questionEngine = questionEngine
    }
    
    // MARK: - Basic Usage Examples
    
    /// Example 1: Simple question generation for a specific category
    public func generateSimpleQuestion() async {
        do {
            let question = try await questionEngine.generateQuestion(for: .firstDate)
            print("Generated question: \(question)")
        } catch {
            print("Failed to generate question: \(error.localizedDescription)")
        }
    }
    
    /// Example 2: Advanced question generation with full configuration
    public func generateAdvancedQuestion() async {
        let configuration = QuestionConfiguration(
            category: .deepCouple,
            tone: .intimate,
            customComplexity: .profound,
            relationshipDuration: TimeInterval(365 * 24 * 60 * 60), // 1 year
            previousTopics: ["childhood", "dreams", "fears", "family"],
            contextualHints: ["planning to move in together", "discussing marriage"]
        )
        
        do {
            let result = try await questionEngine.generateQuestion(with: configuration)
            
            print("Generated question: \(result.question)")
            print("Category: \(result.category.displayName)")
            print("Processing time: \(result.processingMetadata.processingDuration)s")
            print("Sanitization applied: \(result.processingMetadata.sanitizationApplied)")
            
        } catch {
            print("Failed to generate question: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Practical App Integration Examples
    
    /// Example 3: Question generation for different relationship stages
    public func generateQuestionsForRelationshipJourney() async {
        let stages: [(category: QuestionCategory, description: String)] = [
            (.blindDate, "Meeting for the first time"),
            (.firstDate, "Going on your first official date"),
            (.earlyDating, "Getting to know each other better"),
            (.deepCouple, "Building deeper intimacy"),
            (.longTermRelationship, "Maintaining connection over time")
        ]
        
        print("🎯 Relationship Journey Question Examples:")
        print("=" * 50)
        
        for (category, description) in stages {
            do {
                let question = try await questionEngine.generateQuestion(for: category)
                print("\n\(category.displayName) - \(description)")
                print("💬 \(question)")
            } catch {
                print("\n\(category.displayName) - Failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Example 4: Conversation repair and conflict resolution
    public func generateConflictResolutionQuestions() async {
        let configurations = [
            QuestionConfiguration(
                category: .conflictResolution,
                tone: .supportive,
                contextualHints: ["recent disagreement about finances"]
            ),
            QuestionConfiguration(
                category: .emotionalIntelligence,
                tone: .reflective,
                contextualHints: ["feeling misunderstood"]
            ),
            QuestionConfiguration(
                category: .valuesAlignment,
                tone: .thoughtful,
                contextualHints: ["different life priorities"]
            )
        ]
        
        print("\n🤝 Conflict Resolution Question Examples:")
        print("=" * 50)
        
        for config in configurations {
            do {
                let result = try await questionEngine.generateQuestion(with: config)
                print("\n\(config.category.displayName) (\(config.effectiveTone.displayName))")
                print("💬 \(result.question)")
            } catch {
                print("\n\(config.category.displayName) - Failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Example 5: Fun and playful question session
    public func generatePlayfulQuestionSession() async {
        let playfulCategories: [QuestionCategory] = [
            .funAndPlayful,
            .futureVisions,
            .personalGrowth
        ]
        
        print("\n🎉 Fun Question Session:")
        print("=" * 30)
        
        for category in playfulCategories {
            let config = QuestionConfiguration(
                category: category,
                tone: .playful,
                customComplexity: .light
            )
            
            do {
                let result = try await questionEngine.generateQuestion(with: config)
                print("\n💫 \(result.question)")
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay between questions
            } catch {
                print("\n❌ Failed to generate \(category.displayName) question: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Error Handling Examples
    
    /// Example 6: Robust error handling in a real app context
    public func handleQuestionGenerationWithFallback() async -> String? {
        let fallbackCategories: [QuestionCategory] = [.firstDate, .funAndPlayful, .personalGrowth]
        
        for category in fallbackCategories {
            do {
                let question = try await questionEngine.generateQuestion(for: category)
                print("✅ Successfully generated question from \(category.displayName)")
                return question
            } catch let error as QuestionEngineError {
                print("⚠️ Failed to generate question for \(category.displayName): \(error.localizedDescription)")
                
                switch error {
                case .timeout:
                    print("   Reason: Request timed out - may retry with different category")
                case .llmServiceError:
                    print("   Reason: LLM service unavailable - trying different category")
                case .invalidResponse:
                    print("   Reason: Generated response was invalid - trying different category")
                default:
                    print("   Reason: \(error.failureReason ?? "Unknown error")")
                }
                
                continue // Try next category
            } catch {
                print("❌ Unexpected error for \(category.displayName): \(error)")
                continue
            }
        }
        
        print("💥 All question generation attempts failed")
        return nil
    }
    
    // MARK: - Performance and Concurrency Examples
    
    /// Example 7: Generating multiple questions concurrently
    public func generateMultipleQuestionsConcurrently() async {
        let categories: [QuestionCategory] = [
            .firstDate, .deepCouple, .funAndPlayful, .futureVisions, .personalGrowth
        ]
        
        let startTime = Date()
        
        print("\n⚡ Generating \(categories.count) questions concurrently...")
        
        // Generate all questions concurrently
        let questionTasks = categories.map { category in
            Task {
                do {
                    let question = try await questionEngine.generateQuestion(for: category)
                    return (category: category.displayName, question: question, error: nil as Error?)
                } catch {
                    return (category: category.displayName, question: "", error: error)
                }
            }
        }
        
        // Wait for all to complete
        let results = await withTaskGroup(of: (category: String, question: String, error: Error?).self) { group in
            for task in questionTasks {
                group.addTask { await task.value }
            }
            
            var allResults: [(category: String, question: String, error: Error?)] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("📊 Results (completed in \(String(format: "%.2f", duration))s):")
        print("-" * 50)
        
        for result in results {
            if result.error == nil && !result.question.isEmpty {
                print("✅ \(result.category): \(result.question)")
            } else {
                print("❌ \(result.category): \(result.error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Session Management Example
    
    /// Example 8: Question session with topic tracking
    public func runQuestionSession(numberOfQuestions: Int = 5) async {
        var usedCategories: Set<QuestionCategory> = []
        var previousTopics: [String] = []
        
        print("\n🎭 Starting Question Session (\(numberOfQuestions) questions)")
        print("=" * 60)
        
        for questionNumber in 1...numberOfQuestions {
            // Select a category we haven't used yet
            let availableCategories = Set(QuestionCategory.allCases).subtracting(usedCategories)
            guard let selectedCategory = availableCategories.randomElement() else {
                print("No more unique categories available")
                break
            }
            
            let configuration = QuestionConfiguration(
                category: selectedCategory,
                previousTopics: previousTopics
            )
            
            do {
                let result = try await questionEngine.generateQuestion(with: configuration)
                
                print("\nQuestion \(questionNumber) (\(selectedCategory.displayName)):")
                print("💬 \(result.question)")
                
                // Track usage
                usedCategories.insert(selectedCategory)
                previousTopics.append(selectedCategory.rawValue)
                
                // Simulate thinking/response time
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
            } catch {
                print("\nQuestion \(questionNumber) failed: \(error.localizedDescription)")
                // Don't mark as used if it failed
            }
        }
        
        print("\n🎯 Session Complete!")
        print("Used categories: \(usedCategories.map { $0.displayName }.joined(separator: ", "))")
    }
}

// MARK: - Usage Demo

/// Main demo function showing various QuestionEngine capabilities
public func demoQuestionEngineUsage() async {
    let examples = QuestionEngineExampleUsage()
    
    print("🚀 QuestionEngine Demo Starting...")
    print("=" * 60)
    
    // Run various examples
    await examples.generateSimpleQuestion()
    await examples.generateAdvancedQuestion()
    await examples.generateQuestionsForRelationshipJourney()
    await examples.generateConflictResolutionQuestions()
    await examples.generatePlayfulQuestionSession()
    
    if let fallbackQuestion = await examples.handleQuestionGenerationWithFallback() {
        print("\n🎯 Fallback question: \(fallbackQuestion)")
    }
    
    await examples.generateMultipleQuestionsConcurrently()
    await examples.runQuestionSession(numberOfQuestions: 3)
    
    print("\n✨ QuestionEngine Demo Complete!")
}

// MARK: - Helper Extension

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}