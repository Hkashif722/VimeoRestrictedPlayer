# VimeoRestrictedPlayer

A powerful iOS library for embedding Vimeo videos with playback restrictions, progress tracking, and resume functionality. Perfect for educational platforms, course management systems, and any app requiring controlled video playback.

![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2013.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- 🎬 **Vimeo Player Integration** - Seamless embedding of Vimeo videos
- 🚫 **Seek Restrictions** - Prevent users from skipping ahead beyond watched content
- 📊 **Progress Tracking** - Automatic tracking of watched duration
- ⏯️ **Resume Functionality** - Continue from where users left off
- 🎨 **Customizable UI** - Configurable player appearance and controls [Comming Soon ⏳]
- 📱 **Native iOS Experience** - Built with WKWebView for optimal performance
- 🔄 **Completion Callbacks** - Get notified of playback events
- 🛡️ **Error Handling** - Comprehensive error management [Comming Soon ⏳]

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/VimeoRestrictedPlayer.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version requirements

### CocoaPods

```ruby
pod 'VimeoRestrictedPlayer', '~> 1.0'
```

## Quick Start

```swift
import VimeoRestrictedPlayer

// Create configuration
let config = VimeoPlayerConfiguration(
    videoURL: "https://vimeo.com/123456789/abcdef123",
    lastWatchedDuration: 120.0, // Resume from 2 minutes
    isCompleted: false
)

// Initialize player
let playerVC = VimeoRestrictedPlayerViewController(configuration: config)

// Set delegate
playerVC.delegate = self

// Present player
present(playerVC, animated: true)
```

## Usage

### Basic Implementation

```swift
class ViewController: UIViewController {
    
    func playVideo() {
        let config = VimeoPlayerConfiguration(
            videoURL: "https://vimeo.com/123456789/abcdef123",
            videoTitle: "Introduction to Swift",
            lastWatchedDuration: 0,
            isCompleted: false,
            allowsFullSeek: false // Restrict seeking
        )
        
        let player = VimeoRestrictedPlayerViewController(configuration: config)
        player.delegate = self
        
        // Customize appearance
        player.showsBackButton = true
        player.backButtonStyle = .custom(image: UIImage(named: "back"))
        
        present(player, animated: true)
    }
}

// MARK: - VimeoPlayerDelegate
extension ViewController: VimeoPlayerDelegate {
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalDuration: TimeInterval) {
        print("Progress: \(currentTime) / \(totalDuration)")
    }
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didCompleteWithDuration duration: TimeInterval) {
        print("Video completed!")
        // Save progress to your backend
    }
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didExitAtTime currentTime: TimeInterval) {
        print("User exited at: \(currentTime)")
        // Save progress
    }
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didEncounterError error: VimeoPlayerError) {
        print("Error: \(error.localizedDescription)")
    }
}
```

### Advanced Configuration

```swift
// Create a fully customized configuration
var config = VimeoPlayerConfiguration(
    videoURL: "https://vimeo.com/123456789/abcdef123",
    videoTitle: "Advanced Mathematics Lecture",
    lastWatchedDuration: 300.0, // 5 minutes watched
    isCompleted: false,
    allowsFullSeek: false
)

// Customize UI
config.theme = VimeoPlayerTheme(
    backgroundColor: .black,
    controlsTintColor: .white,
    loadingIndicatorStyle: .large
)

// Configure resume behavior
config.resumeOptions = .init(
    showResumeDialog: true,
    minimumWatchedForResume: 5.0, // Show resume after 5 seconds
    resumeDialogTitle: "Continue Watching?",
    resumeDialogMessage: "Resume from {TIME}?",
    continueButtonTitle: "Continue",
    startOverButtonTitle: "Start Over"
)

// Configure restrictions
config.seekRestriction = .init(
    enabled: true,
    allowSeekToWatchedPosition: true,
    showAlertOnRestriction: true,
    restrictionMessage: "You can only seek to previously watched content"
)

let player = VimeoRestrictedPlayerViewController(configuration: config)
```

### Programmatic Control

```swift
// Get player instance
let player = VimeoRestrictedPlayerViewController(configuration: config)

// Control playback
player.play()
player.pause()
player.seek(to: 60.0) // Seek to 1 minute
player.restart()

// Get current state
let currentTime = player.currentTime
let duration = player.duration
let isPlaying = player.isPlaying

// Update configuration
player.updateMaxAllowedSeekTime(180.0) // Allow seeking up to 3 minutes
```

## Architecture

### File Structure

```
VimeoRestrictedPlayer/
├── Sources/
│   └── VimeoRestrictedPlayer/
│       ├── Core/
│       │   ├── VimeoRestrictedPlayerViewController.swift
│       │   └── VimeoPlayerWebViewBridge.swift [TODO]
│       ├── Models/
│       │   ├── VimeoPlayerConfiguration.swift
│       │   ├── VimeoPlayerState.swift [TODO]
│       │   └── VimeoPlayerError.swift [TODO]
│       ├── Protocols/
│       │   └── VimeoPlayerDelegate.swift
│       ├── Utilities/
│       │   ├── VimeoHTMLGenerator.swift
│       │   ├── TimeFormatter.swift
│       │   └── VimeoURLParser.swift
│       └── UI/
│           ├── VimeoPlayerTheme.swift [TODO]
│           └── VimeoPlayerControls.swift [TODO]
```

### Core Components

1. **VimeoRestrictedPlayerViewController** - Main view controller handling video playback
2. **VimeoPlayerConfiguration** - Configuration model for player settings
3. **VimeoPlayerDelegate** - Protocol for playback events and callbacks
4. **VimeoHTMLGenerator** - Generates the HTML/JavaScript for Vimeo player
5. **VimeoPlayerWebViewBridge** - Handles communication between JavaScript and Swift

## Customization

### Theming

```swift
let theme = VimeoPlayerTheme(
    backgroundColor: UIColor(hex: "#1a1a1a"),
    controlsTintColor: .systemBlue,
    loadingIndicatorStyle: .medium,
    backButtonImage: UIImage(systemName: "arrow.left.circle.fill"),
    backButtonPosition: .topLeft(insets: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 0))
)

config.theme = theme
```

### Localization

```swift
config.localization = VimeoPlayerLocalization(
    resumeDialogTitle: "Continue Watching?",
    resumeDialogMessage: "Would you like to resume from %@?",
    continueButtonTitle: "Continue",
    startOverButtonTitle: "Start Over",
    seekRestrictionTitle: "Seek Restricted",
    seekRestrictionMessage: "You can only seek to previously watched content",
    errorTitle: "Error",
    errorRetryButton: "Retry"
)
```

## Best Practices

1. **Save Progress Regularly** - Implement the delegate methods to save progress
2. **Handle Errors Gracefully** - Always implement error handling
3. **Test on Real Devices** - Video playback performs differently on simulators
4. **Consider Data Usage** - Implement quality settings for cellular connections
5. **Respect User Preferences** - Store resume preferences per user

## Requirements

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

## Migration Guide

If you're migrating from a custom implementation:

1. Replace your video player view controller with `VimeoRestrictedPlayerViewController`
2. Convert your video metadata to `VimeoPlayerConfiguration`
3. Implement `VimeoPlayerDelegate` methods
4. Update your UI customization code

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Vimeo Player API
- Inspired by educational platform requirements
- Thanks to all contributors

## Support

- 📧 Email: support@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/VimeoRestrictedPlayer/issues)
- 📖 Documentation: [Full Documentation](https://github.com/yourusername/VimeoRestrictedPlayer/wiki)
# VimeoRestrictedPlayer
