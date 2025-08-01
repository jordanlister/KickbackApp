# Kickback 🃏

> Privacy-first iOS conversation card app with on-device AI

[\![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[\![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[\![MLX](https://img.shields.io/badge/MLX-Swift-red.svg)](https://github.com/ml-explore/mlx-swift)
[\![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Kickback is a revolutionary conversation card app that generates thoughtful questions using Apple's OpenELM-3B LLM running entirely on-device. Perfect for couples, friends, and new relationships - all while keeping your conversations completely private.

## ✨ Features

### 🧠 **On-Device AI**
- **Apple OpenELM-3B LLM** via MLX Swift for complete privacy
- **Zero network requests** - everything processes locally
- **Real-time question generation** with context awareness
- **No hardcoded fallbacks** - pure AI-generated content

### 🎤 **Voice Recording**
- **On-device speech recognition** using Apple's Speech framework
- **Real-time transcription** with audio level visualization
- **Privacy compliant** - audio never leaves your device
- **Interruption handling** with automatic recovery

### 💬 **Smart Questions**
- **12 conversation categories** from first dates to deep relationships
- **Context-aware prompting** based on relationship stage
- **Personalized conversation starters** tailored to your situation
- **Relationship compatibility analysis** with actionable insights

### 🎨 **Beautiful Interface**
- **Modern SwiftUI design** with 60fps animations
- **Three-card deck** with smooth flip interactions
- **Pull-to-refresh** with haptic feedback
- **Accessibility support** with proper traits and labels

## 🏗️ Architecture

### **MVVM + Protocol-Oriented Design**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI Views │    │   ViewModels    │    │    Services     │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • CardDeckView  │◄──►│ • MainContent   │◄──►│ • LLMService    │
│ • ConversationCard    │ • CardViewModel │    │ • QuestionEngine│
│ • VoiceInput    │    │ • Compatibility │    │ • AudioTranscriber
│ • Insights      │    └─────────────────┘    │ • CompatibilityAnalyzer
└─────────────────┘                           └─────────────────┘
```

### **Five Specialized Agents**
1. **LLMService** - MLX Swift integration with OpenELM-3B
2. **QuestionEngine** - AI-powered conversation generation
3. **AudioTranscriber** - On-device speech recognition
4. **CompatibilityAnalyzer** - Relationship insight generation
5. **SwiftUI Interface** - Modern animated user experience

## 🚀 Getting Started

### Prerequisites
- **Xcode 15.0+** with iOS 17.0+ SDK
- **Apple Silicon Mac** (M1/M2/M3) for MLX Swift
- **iOS device** for testing (MLX doesn't work in Simulator)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/jordanlister/KickbackApp.git
   cd KickbackApp
   ```

2. **Download the AI model** (required)
   ```bash
   ./setup.sh
   ```
   This downloads Apple's OpenELM-3B model configuration (~6GB total)

3. **Open in Xcode**
   ```bash
   open KickbackApp.xcodeproj
   ```

4. **Build and run on device**
   - Select your iOS device (not Simulator)
   - Enable Developer Mode in Settings > Privacy & Security
   - Build and run (⌘R)

### Model Setup Details

The `setup.sh` script downloads:
- `config.json` - Model configuration
- `generation_config.json` - Generation parameters  
- `model-*.safetensors` - Model weights (~5.7GB)

Large model files are excluded from git via `.gitignore` but are required for the app to function.

## 🛠️ Development

### Code Quality
```bash
# Run SwiftLint
swiftlint

# Format code
swift-format --in-place --recursive .

# Pre-commit hooks
pre-commit install
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme KickbackApp -destination 'platform=iOS,name=iPhone'

# Performance testing
# Enable performance monitoring in debug builds
```

### Architecture Principles
- **Privacy First** - No network requests, all processing on-device
- **Protocol-Oriented** - Testable, mockable interfaces
- **Swift Concurrency** - Modern async/await patterns
- **60fps Performance** - GPU-accelerated animations
- **Accessibility** - Proper VoiceOver support

## 📱 App Capabilities

### Question Categories
- 🌹 **First Date** - Ice breakers and getting to know you
- 🧠 **Personal Growth** - Self-reflection and values
- 🎉 **Fun & Playful** - Light-hearted conversation starters
- 💕 **Deep Couple** - Intimate questions for established relationships
- 🗣️ **Communication** - Improving relationship dialogue
- 🔮 **Future Visions** - Dreams and aspirations
- ❤️ **Intimacy Building** - Emotional and physical connection
- 💪 **Vulnerability** - Deeper emotional sharing
- ⚖️ **Values Alignment** - Core beliefs and principles
- 🔄 **Life Transitions** - Change and growth together
- 🧘 **Emotional Intelligence** - Understanding emotions
- 💖 **Love Languages** - How you give and receive love

### Voice Features
- **Real-time transcription** with live feedback
- **Audio level visualization** for recording quality
- **Error recovery** with user-friendly messages
- **Interruption handling** for calls and notifications

### Compatibility Analysis
- **Multi-dimensional scoring** across relationship aspects
- **Personalized insights** with confidence levels
- **Growth recommendations** for relationship improvement
- **Trend tracking** over time (future feature)

## 🔒 Privacy & Security

### Complete Privacy
- ✅ **100% on-device processing** - No data sent to servers
- ✅ **No network requests** - Fully offline functionality  
- ✅ **No user tracking** - Zero analytics or telemetry
- ✅ **Secure audio** - Recordings never stored permanently
- ✅ **Local AI inference** - MLX Swift on Apple Silicon

### Permissions
- 🎤 **Microphone** - For voice recording (optional)
- 🗣️ **Speech Recognition** - For transcription (optional)

## 🔧 Technical Stack

### Core Technologies
- **SwiftUI** - Modern declarative UI framework
- **MLX Swift** - Apple's ML framework for on-device inference
- **OpenELM-3B** - Apple's 3 billion parameter language model
- **AVFoundation** - Audio recording and playback
- **Speech Framework** - On-device speech recognition
- **Swift Concurrency** - Async/await for performance

### Dependencies
- **MLX Swift** - On-device machine learning
- **Swift Numerics** - Mathematical operations

### Performance Optimizations
- **GPU acceleration** with `drawingGroup()`
- **Thermal state monitoring** for device health
- **Memory-efficient model loading**
- **Background processing** with proper lifecycle
- **60fps animations** with optimized drawing

## 📊 Project Status

- ✅ **MVP Complete** - All core features implemented
- ✅ **Device Tested** - Working on physical iOS devices  
- ✅ **Performance Optimized** - 60fps target achieved
- ✅ **Code Quality** - SwiftLint compliant, well documented
- 🚧 **App Store Ready** - Pending final polish and review

## 🤝 Contributing

Contributions are welcome\! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and linting
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple** for OpenELM-3B and MLX Swift framework
- **MLX Team** for making on-device ML accessible
- **SwiftUI Community** for animation and UI inspiration
- **Claude Code** for development assistance 🤖

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/jordanlister/KickbackApp/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/jordanlister/KickbackApp/discussions)
- 📧 **Contact**: [Your Contact Info]

---

<div align="center">

**Made with ❤️ and 🤖 AI assistance**

[⭐ Star this repo](https://github.com/jordanlister/KickbackApp) if you find it useful\!

</div>
EOF < /dev/null