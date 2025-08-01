# QuestionEngine Implementation Guide

## Overview

This document describes the comprehensive QuestionEngine system implemented for the Kickback iOS app. The system generates thoughtful, contextually appropriate conversation questions using an on-device LLM (OpenELM-3B via MLX Swift) without any hardcoded fallback questions.

## Architecture

### Core Components

#### 1. Question Models (`/KickbackApp/Models/QuestionModels.swift`)

**QuestionCategory Enum**: 15 comprehensive categories covering all relationship stages:
- `blindDate`, `firstDate`, `earlyDating` - Initial connection phases
- `deepCouple`, `longTermRelationship` - Established relationships  
- `conflictResolution`, `emotionalIntelligence` - Relationship maintenance
- `loveLanguageDiscovery`, `intimacyBuilding`, `vulnerabilitySharing` - Deeper connection
- `futureVisions`, `personalGrowth`, `lifeTransitions` - Growth-oriented
- `funAndPlayful`, `valuesAlignment` - Varied interaction styles

**Supporting Types**:
- `RelationshipStage`: meeting, dating, serious, committed, any
- `ComplexityLevel`: light, medium, deep, profound  
- `QuestionTone`: curious, playful, thoughtful, vulnerable, supportive, exploratory, intimate, reflective
- `QuestionConfiguration`: Comprehensive configuration object with category, tone, complexity, duration, previous topics, and contextual hints
- `QuestionResult`: Result container with question, metadata, and processing information

#### 2. Prompt Template System (`/KickbackApp/Models/PromptTemplates.swift`)

**QuestionPromptTemplates**: Category-specific prompt templates with variable substitution:
- 15 specialized templates, one for each question category
- Variable placeholders: `{{category}}`, `{{relationship_stage}}`, `{{tone}}`, `{{complexity}}`, `{{duration}}`, `{{previous_topics}}`, `{{contextual_hints}}`
- Context-aware avoidance guidance to prevent inappropriate or generic questions
- Detailed format instructions for consistent LLM output

**PromptProcessor**: Template processing utility that:
- Substitutes variables with actual values from configuration
- Cleans up formatting and excessive whitespace
- Ensures prompts are properly structured for LLM consumption

#### 3. QuestionEngine Service (`/KickbackApp/Services/QuestionEngine.swift`)

**QuestionEngine Protocol**: Defines the interface for question generation:
```swift
public protocol QuestionEngine {
    func generateQuestion(for category: QuestionCategory) async throws -> String
    func generateQuestion(with configuration: QuestionConfiguration) async throws -> QuestionResult
}
```

**QuestionEngineService**: Production implementation featuring:
- Integration with existing `LLMService.shared`
- Configurable retry logic with exponential backoff
- Request timeouts (default: 30 seconds)
- Comprehensive error handling and logging using `OSLog`
- Response processing and sanitization pipeline

**ResponseProcessor**: Cleans and validates LLM responses:
- Removes markdown formatting (bold, italic, code blocks, headers)
- Extracts actual questions from verbose responses
- Normalizes punctuation and capitalization
- Validates question structure and quality
- Tracks sanitization steps for debugging

### Error Handling

**QuestionEngineError**: Comprehensive error types:
- `llmServiceError`: Wraps underlying LLM service failures
- `invalidResponse`: Response couldn't be processed into valid question
- `generationFailed`: General generation failures with context
- `timeout`: Request exceeded time limits
- `configurationError`: Invalid configuration parameters

**Retry Strategy**:
- Configurable retry attempts (default: 2)
- Exponential backoff with jitter: `min(2^attempt, 8) + random(0...1)` seconds
- Fails fast on configuration errors, retries on transient LLM issues

## Usage Examples

### Basic Usage
```swift
let questionEngine = QuestionEngineService()
let question = try await questionEngine.generateQuestion(for: .firstDate)
```

### Advanced Configuration
```swift
let config = QuestionConfiguration(
    category: .deepCouple,
    tone: .intimate,
    customComplexity: .profound,
    relationshipDuration: TimeInterval(365 * 24 * 60 * 60), // 1 year
    previousTopics: ["childhood", "dreams", "fears"],
    contextualHints: ["planning to move in together", "discussing marriage"]
)

let result = try await questionEngine.generateQuestion(with: config)
print("Question: \(result.question)")
print("Processing time: \(result.processingMetadata.processingDuration)s")
```

### Error Handling with Fallback Categories
```swift
let fallbackCategories: [QuestionCategory] = [.firstDate, .funAndPlayful, .personalGrowth]

for category in fallbackCategories {
    do {
        let question = try await questionEngine.generateQuestion(for: category)
        return question
    } catch let error as QuestionEngineError {
        print("Failed \(category.displayName): \(error.localizedDescription)")
        continue // Try next category
    }
}
```

## Integration Points

### LLMService Integration
The QuestionEngine integrates seamlessly with the existing `LLMService`:
- Uses `LLMService.shared` by default
- Respects LLM service initialization and error states
- Passes processed prompts to `generateResponse(for:)` method
- Handles `LLMServiceError` types appropriately

### Dependency Injection Support
For testing and flexibility:
```swift
let mockLLM = MockLLMService()
let testEngine = QuestionEngineService(
    llmService: mockLLM,
    maxRetryAttempts: 1,
    requestTimeout: 5.0
)
```

## Testing

### Unit Tests (`/KickbackAppTests/QuestionEngineTests.swift`)

**Comprehensive Test Coverage**:
- Basic question generation for all categories
- Configuration-based generation with custom parameters
- Error handling for LLM failures, timeouts, and invalid responses
- Response processing with various messy LLM outputs
- Retry logic validation
- Concurrent generation testing
- Integration testing with mock LLM service

**Mock LLMService**: Configurable mock with:
- Controllable success/failure states
- Response delay simulation for timeout testing
- Call count tracking for retry verification
- Custom response content for processing tests

### Test Examples
```swift
func testGenerateQuestionWithConfiguration() async throws {
    let config = QuestionConfiguration(
        category: .deepCouple,
        tone: .intimate,
        previousTopics: ["dreams", "fears"]
    )
    mockLLMService.mockResponse = "What's something about me that surprised you recently?"
    
    let result = try await questionEngine.generateQuestion(with: config)
    
    XCTAssertEqual(result.question, "What's something about me that surprised you recently?")
    XCTAssertTrue(mockLLMService.lastPrompt.contains("dreams, fears"))
}
```

## Key Features

### 1. Zero Hardcoded Questions
- All questions come from the LLM - no fallback database
- System fails gracefully with clear error messages when LLM unavailable
- Maintains conversation authenticity and prevents repetition

### 2. Context-Aware Generation
- Considers relationship stage, duration, and complexity
- Avoids previously covered topics
- Incorporates contextual hints for personalization
- Tone-appropriate question styling

### 3. Quality Assurance
- Multi-stage response validation
- Automatic sanitization of LLM output
- Question structure verification (length, format, appropriateness)
- Debug logging for prompt optimization

### 4. Production-Ready Architecture
- Protocol-based design for testability
- Comprehensive error handling
- Configurable timeouts and retry logic
- Performance monitoring and logging
- Thread-safe concurrent operation

### 5. Extensibility
- Easy addition of new question categories
- Customizable prompt templates
- Pluggable response processing
- Configurable generation parameters

## File Structure

```
KickbackApp/
├── Models/
│   ├── QuestionModels.swift        # Core data models and enums
│   └── PromptTemplates.swift       # Template system and processing
├── Services/
│   ├── LLMService.swift           # Enhanced with public access
│   └── QuestionEngine.swift       # Main service implementation
├── Examples/
│   └── QuestionEngineExample.swift # Usage examples and demos
└── Tests/
    └── QuestionEngineTests.swift   # Comprehensive unit tests
```

## Performance Characteristics

- **Question Generation**: ~2-5 seconds depending on LLM inference time
- **Concurrent Requests**: Fully thread-safe, supports multiple simultaneous generations
- **Memory Usage**: Minimal - stateless service with lightweight configuration objects
- **Error Recovery**: Fast failure detection with configurable retry attempts

## Future Enhancements

1. **Question Chaining**: Generate follow-up questions based on responses
2. **Difficulty Progression**: Automatically adjust complexity over conversation sessions  
3. **Topic Clustering**: Group related questions to avoid repetition patterns
4. **Mood Detection**: Adjust tone based on conversation sentiment
5. **Custom Templates**: User-defined prompt templates for specialized scenarios
6. **Analytics Integration**: Track question effectiveness and user engagement

This implementation provides a robust, scalable foundation for intelligent conversation facilitation in the Kickback app while maintaining full integration with the existing MLX-based LLM infrastructure.