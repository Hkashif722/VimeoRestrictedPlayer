# VimeoRestrictedPlayer

A powerful, production-ready iOS library for embedding Vimeo videos with advanced playback restrictions, progress tracking, and resume functionality. Perfect for educational platforms, course management systems, and any app requiring controlled video playback.

![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2013.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)

## ✨ Features

### 🎬 **Core Video Playback**
- Seamless Vimeo video embedding with WKWebView
- Optimized for performance and battery life
- Support for all Vimeo video formats and quality settings
- Automatic quality adaptation based on network conditions

### 🚫 **Advanced Seek Restrictions**
- Prevent users from skipping ahead beyond watched content
- Configurable seek tolerance and restriction messages
- Visual feedback for restricted seek attempts
- Support for different restriction types (content lock, time limit, subscription)

### 📊 **Comprehensive Progress Tracking**
- Real-time progress monitoring with customizable update intervals
- Automatic tracking of maximum watched position
- Detailed analytics and interaction logging
- State persistence across app sessions

### ⏯️ **Smart Resume Functionality**
- Intelligent resume dialogs with customizable thresholds
- Bookmark support with visual indicators
- Automatic progress restoration
- User preference handling

### 🎨 **Complete Theming System**
- Full UI customization with comprehensive theme support
- Dark/light mode compatibility
- Custom color schemes, typography, and animations
- Backward compatibility with existing configurations

### 📱 **Native iOS Experience**
- Built with WKWebView for optimal performance
- Native overlay controls with gesture support
- Accessibility support and VoiceOver compatibility
- Seamless integration with iOS media controls

### 🔄 **State Management**
- Advanced state machine for reliable playback state tracking
- Comprehensive error handling and recovery
- Network monitoring and automatic retry logic
- Detailed logging and analytics support

### 🛡️ **Error Handling & Recovery**
- Comprehensive error classification and reporting
- Automatic retry mechanisms for transient errors
- User-friendly error messages and recovery suggestions
- Network connectivity monitoring

### 🔧 **SwiftUI Integration**
- Full SwiftUI support with reactive bindings
- Declarative API with method chaining
- Environment-based theming
- Built-in state management integration

## 📦 Installation

### Swift Package Manager (Recommended)

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/VimeoRestrictedPlayer.git", from: "2.0.0")
]
```

Or add through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/yourusername/VimeoRestrictedPlayer.git`
3. Select version requirements

### CocoaPods

```ruby
pod 'VimeoRestrictedPlayer', '~> 2.0'
```

### Carthage

```
github "yourusername/VimeoRestrictedPlayer" ~> 2.0
```

## 🚀 Quick Start

### UIKit - Basic Usage

```swift
import VimeoRestrictedPlayer

class ViewController: UIViewController {
    
    func playVideo() {
        // Create configuration
        let config = VimeoPlayerConfiguration(
            videoURL: "https://vimeo.com/123456789/abcdef123",
            videoTitle: "Introduction to Swift",
            lastWatchedDuration: 120.0,
            allowsFullSeek: false
        )
        
        // Initialize player
        let player = VimeoRestrictedPlayerViewController(configuration: config)
        player.delegate = self
        player.showsNativeControls = true
        
        // Present player
        present(player, animated: true)
    }
}

extension ViewController: VimeoPlayerDelegate {
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalDuration: TimeInterval) {
        // Save progress to your backend
        saveProgress(currentTime)
    }
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didCompleteWithDuration duration: TimeInterval) {
        // Handle video completion
        markAsCompleted()
    }
}
```

### SwiftUI - Declarative Usage

```swift
import SwiftUI
import VimeoRestrictedPlayer

struct VideoPlayerView: View {
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var playerState = VimeoPlayerState()
    
    var body: some View {
        VimeoPlayerView(
            videoURL: "https://vimeo.com/123456789/abcdef123",
            videoTitle: "SwiftUI Video Example",
            allowsFullSeek: false,
            isPlaying: $isPlaying,
            currentTime: $currentTime,
            playerState: $playerState
        )
        .aspectRatio(16/9, contentMode: .fit)
        .onPlayerReady { duration in
            print("Ready! Duration: \(duration)")
        }
        .onProgressUpdate { current, total in
            saveProgress(current: current, total: total)
        }
        .onVideoCompleted { duration in
            markAsCompleted()
        }
        .theme(createCustomTheme())
    }
}
```

## 🔧 Advanced Configuration

### Complete Configuration Example

```swift
var config = VimeoPlayerConfiguration(
    videoURL: "https://vimeo.com/123456789/abcdef123",
    videoTitle: "Advanced Course: Data Structures",
    lastWatchedDuration: 300.0,
    isCompleted: false,
    allowsFullSeek: false,
    videoID: "course_123_lesson_1"
)

// Customize theme
config.theme = VimeoPlayerTheme(
    colors: ColorTheme(
        primaryBackground: UIColor(hex: "#1a1a1a"),
        accent: .systemBlue,
        error: .systemRed
    ),
    typography: TypographyTheme(
        titleFont: .systemFont(ofSize: 20, weight: .bold),
        bodyFont: .systemFont(ofSize: 16)
    ),
    controls: ControlsTheme(
        backButton: BackButtonTheme(
            size: CGSize(width: 50, height: 50),
            cornerRadius: 25
        )
    )
)

// Configure resume behavior
config.resumeOptions = ResumeOptions(
    showResumeDialog: true,
    minimumWatchedForResume: 10.0,
    resumeDialogTitle: "Continue Learning?",
    resumeDialogMessage: "Resume from {TIME}?",
    continueButtonTitle: "Continue",
    startOverButtonTitle: "Start Over"
)

// Configure restrictions
config.seekRestriction = SeekRestrictionOptions(
    enabled: true,
    allowSeekToWatchedPosition: true,
    showAlertOnRestriction: true,
    restrictionMessage: "Watch the video to unlock this section",
    seekTolerance: 1.0
)

// Configure localization
config.localization = VimeoPlayerLocalization(
    resumeDialogTitle: "Continuar viendo?", // Spanish
    resumeDialogMessage: "¿Continuar desde {TIME}?",
    // ... other localized strings
)
```

### Advanced State Management

```swift
// Setup state machine for detailed state tracking
let stateMachine = VimeoPlayerStateMachine()
stateMachine.delegate = self

// Track user interactions
stateMachine.recordUserInteraction(.play)
stateMachine.recordUserInteraction(.seek)

// Get detailed state information
let state = stateMachine.currentState
print("Progress: \(state.progressPercentage * 100)%")
print("Can seek to 5 minutes: \(stateMachine.shouldAllowSeek(to: 300))")
print("State: \(state.debugDescription)")
```

### Error Handling & Analytics

```swift
// Setup comprehensive error logging
let errorLogger = VimeoPlayerErrorLogger(reporter: CustomAnalyticsReporter())

// Custom error reporter for analytics
class CustomAnalyticsReporter: VimeoPlayerErrorReporter {
    func reportError(_ error: VimeoPlayerError, context: [String : Any]?) {
        // Send to your analytics service
        Analytics.track("video_player_error", properties: [
            "error_code": error.errorCode,
            "error_category": error.category.rawValue,
            "is_retryable": error.isRetryable,
            "context": context ?? [:]
        ])
    }
    
    func reportErrorRecovery(_ error: VimeoPlayerError, recoveryMethod: String, success: Bool) {
        Analytics.track("video_player_recovery", properties: [
            "error_code": error.errorCode,
            "recovery_method": recoveryMethod,
            "success": success
        ])
    }
}
```

## 🎨 Theming & Customization

### Predefined Themes

```swift
// Dark theme (default)
config.theme = VimeoPlayerTheme(colors: .dark)

// Light theme
config.theme = VimeoPlayerTheme(colors: .light)

// Cinema theme
config.theme = VimeoPlayerTheme(colors: .cinema)

// Custom theme
config.theme = VimeoPlayerTheme(
    colors: ColorTheme(
        primaryBackground: .systemBackground,
        accent: .systemBlue,
        error: .systemRed
    )
)
```

### Custom Controls

```swift
// Enable native overlay controls
player.showsNativeControls = true

// Customize control appearance
config.theme.controls.playButton.size = CGSize(width: 80, height: 80)
config.theme.controls.progressBar.height = 6
config.theme.controls.backButton.position = .topRight()

// Custom back button
player.backButtonStyle = .custom(image: UIImage(named: "custom_back_icon"))
```

### Animation Customization

```swift
config.theme.animations = AnimationTheme(
    controlsFadeInDuration: 0.3,
    controlsFadeOutDuration: 0.3,
    controlsAnimationDelay: 3.0,
    seekAnimationDuration: 0.2
)
```

## 🔄 State Management

### Player States

```swift
public enum PlaybackState {
    case idle
    case playing
    case paused
    case ended
    case buffering
    case seeking
    case error
}

// Check current state
if player.state.isPlaying {
    // Player is currently playing
}

if player.state.isReady {
    // Player is ready for interaction
}
```

### Progress Tracking

```swift
// Get detailed progress information
let progress = stateMachine.currentState.progressInfo
print("Current: \(progress.currentTime)")
print("Duration: \(progress.duration)")
print("Max watched: \(progress.maxWatchedPosition)")
print("Percentage: \(progress.watchPercentage * 100)%")
```

## 🛡️ Error Handling

### Error Types

The library provides comprehensive error handling with detailed error types:

```swift
public enum VimeoPlayerError {
    // Configuration errors
    case invalidURL(String)
    case missingVideoID
    case unsupportedVideoFormat
    
    // Network errors
    case networkError(NetworkErrorInfo)
    case connectionTimeout
    case serverError(Int, String?)
    
    // Playback errors
    case playbackFailed(PlaybackErrorInfo)
    case seekFailed(SeekErrorInfo)
    case bufferingTimeout
    
    // User interaction errors
    case seekRestricted(SeekRestrictionInfo)
    case controlsDisabled
    
    // System errors
    case memoryWarning
    case deviceNotSupported
    
    // Custom errors
    case custom(CustomErrorInfo)
}
```

### Error Recovery

```swift
func handlePlayerError(_ error: VimeoPlayerError) {
    switch error {
    case .networkError(let info) where info.isConnectivityIssue:
        showNetworkErrorDialog()
        
    case .seekRestricted(let info):
        showSeekRestrictionMessage(info: info)
        
    case .loadingFailed where error.isRetryable:
        retryWithBackoff()
        
    default:
        showGenericErrorDialog(error: error)
    }
}
```

## 📱 Platform Support

- **iOS**: 13.0+
- **macOS**: 12.0+ (for Mac Catalyst apps)
- **Swift**: 5.0+
- **Xcode**: 12.0+

## 🔧 Advanced Features

### Custom JavaScript Bridge

```swift
// Access the underlying bridge for advanced control
if let bridge = player.webViewBridge {
    bridge.executeJavaScript("customFunction()") { result, error in
        // Handle custom JavaScript execution
    }
    
    bridge.getCurrentTime { time, error in
        print("Current time: \(time)")
    }
}
```

### Network Monitoring

```swift
// Built-in network monitoring
player.networkMonitor?.startMonitoring()

// Automatic retry on network recovery
player.enableAutomaticRetry = true
```

### Analytics Integration

```swift
// Track detailed user interactions
extension ViewController: VimeoPlayerStateMachineDelegate {
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didRecordInteraction type: UserInteractionType, at time: Date) {
        Analytics.track("video_interaction", properties: [
            "interaction_type": type.rawValue,
            "timestamp": time.timeIntervalSince1970,
            "video_id": currentVideoID
        ])
    }
}
```

## 🔄 Migration Guide

### From Version 1.x to 2.x

**Breaking Changes:**
- `VimeoPlayerState` is now a struct instead of enum
- Theme configuration has been completely redesigned
- Error types have been restructured

**Migration Steps:**

1. **Update State Handling:**
```swift
// Old (v1.x)
if case .playing = player.state {
    // Handle playing state
}

// New (v2.x)
if player.state.isPlaying {
    // Handle playing state
}
```

2. **Update Theme Configuration:**
```swift
// Old (v1.x)
config.backgroundColor = .black
config.controlsTintColor = .white

// New (v2.x)
config.theme.colors.primaryBackground = .black
config.theme.colors.controlsTint = .white
```

3. **Update Error Handling:**
```swift
// Old (v1.x)
case .error(let message):
    print("Error: \(message)")

// New (v2.x)
case .error(let error):
    print("Error: \(error.localizedDescription)")
    if error.isRetryable {
        retryPlayback()
    }
```

## 📚 Examples

### Educational Platform

```swift
class CourseVideoViewController: UIViewController {
    
    func setupEducationalVideo() {
        let config = VimeoPlayerConfiguration(
            videoURL: courseVideo.vimeoURL,
            videoTitle: courseVideo.title,
            lastWatchedDuration: userProgress.lastWatchedTime,
            isCompleted: userProgress.isCompleted,
            allowsFullSeek: false, // Enforce sequential watching
            videoID: courseVideo.id
        )
        
        config.seekRestriction.restrictionMessage = "Complete previous sections to unlock"
        config.resumeOptions.minimumWatchedForResume = 30.0
        
        let player = VimeoRestrictedPlayerViewController(configuration: config)
        player.delegate = self
        
        // Track learning analytics
        setupLearningAnalytics(player: player)
    }
}
```

### Training Platform

```swift
class TrainingVideoViewController: UIViewController {
    
    func setupTrainingVideo() {
        let config = VimeoPlayerConfiguration(
            videoURL: trainingModule.videoURL,
            videoTitle: trainingModule.title,
            allowsFullSeek: true // Allow full seek for training review
        )
        
        // Custom completion tracking
        config.theme.colors.accent = companyBrandColor
        
        let player = VimeoRestrictedPlayerViewController(configuration: config)
        player.delegate = self
        
        // Require video completion for certification
        setupCompletionTracking(player: player)
    }
}
```

## 🧪 Testing

The library includes comprehensive tests covering:

- URL parsing and validation
- State management and transitions
- Error handling and recovery
- Theme configuration
- Performance benchmarks

```bash
# Run tests
swift test

# Run with coverage
swift test --enable-code-coverage
```

## 🔧 Build Configuration

### Debug Features

```swift
#if DEBUG
// Enable detailed logging
player.enableDebugLogging = true

// Show performance metrics
player.showPerformanceOverlay = true
#endif
```

### Release Optimization

```swift
#if RELEASE
// Optimize for production
player.enableAnalytics = true
player.enableCrashReporting = true
#endif
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Include unit tests for new features
- Update documentation for public APIs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Vimeo Player API](https://developer.vimeo.com/player)
- Inspired by educational platform requirements
- Thanks to all contributors and users


---

Made with ❤️ for the iOS developer community
