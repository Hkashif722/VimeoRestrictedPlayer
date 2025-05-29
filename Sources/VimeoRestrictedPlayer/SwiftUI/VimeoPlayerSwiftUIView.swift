//
//  VimeoPlayerView.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  VimeoPlayerSwiftUIView.swift
//  VimeoRestrictedPlayer
//
//  Created by Assistant on 28/05/25.
//

import SwiftUI
import UIKit

/// SwiftUI wrapper for VimeoRestrictedPlayerViewController
@available(iOS 13.0, *)
public struct VimeoPlayerView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    public let configuration: VimeoPlayerConfiguration
    
    // Bindings for two-way data flow
    @Binding public var isPlaying: Bool
    @Binding public var currentTime: TimeInterval
    @Binding public var duration: TimeInterval
    @Binding public var playerState: VimeoPlayerState
    
    // Callbacks
    public var onReady: ((TimeInterval) -> Void)?
    public var onPlay: (() -> Void)?
    public var onPause: (() -> Void)?
    public var onProgress: ((TimeInterval, TimeInterval) -> Void)?
    public var onComplete: ((TimeInterval) -> Void)?
    public var onExit: ((TimeInterval) -> Void)?
    public var onSeekRestricted: ((TimeInterval, TimeInterval) -> Void)?
    public var onResume: ((TimeInterval) -> Void)?
    public var onStartOver: (() -> Void)?
    public var onError: ((VimeoPlayerError) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        configuration: VimeoPlayerConfiguration,
        isPlaying: Binding<Bool> = .constant(false),
        currentTime: Binding<TimeInterval> = .constant(0),
        duration: Binding<TimeInterval> = .constant(0),
        playerState: Binding<VimeoPlayerState> = .constant(.idle),
        onReady: ((TimeInterval) -> Void)? = nil,
        onPlay: (() -> Void)? = nil,
        onPause: (() -> Void)? = nil,
        onProgress: ((TimeInterval, TimeInterval) -> Void)? = nil,
        onComplete: ((TimeInterval) -> Void)? = nil,
        onExit: ((TimeInterval) -> Void)? = nil,
        onSeekRestricted: ((TimeInterval, TimeInterval) -> Void)? = nil,
        onResume: ((TimeInterval) -> Void)? = nil,
        onStartOver: (() -> Void)? = nil,
        onError: ((VimeoPlayerError) -> Void)? = nil
    ) {
        self.configuration = configuration
        self._isPlaying = isPlaying
        self._currentTime = currentTime
        self._duration = duration
        self._playerState = playerState
        self.onReady = onReady
        self.onPlay = onPlay
        self.onPause = onPause
        self.onProgress = onProgress
        self.onComplete = onComplete
        self.onExit = onExit
        self.onSeekRestricted = onSeekRestricted
        self.onResume = onResume
        self.onStartOver = onStartOver
        self.onError = onError
    }
    
    // MARK: - UIViewControllerRepresentable
    
    public func makeUIViewController(context: Context) -> VimeoRestrictedPlayerViewController {
        let playerVC = VimeoRestrictedPlayerViewController(configuration: configuration)
        playerVC.delegate = context.coordinator
        return playerVC
    }
    
    public func updateUIViewController(_ uiViewController: VimeoRestrictedPlayerViewController, context: Context) {
        // Update coordinator with latest callbacks
        context.coordinator.updateCallbacks(
            onReady: onReady,
            onPlay: onPlay,
            onPause: onPause,
            onProgress: onProgress,
            onComplete: onComplete,
            onExit: onExit,
            onSeekRestricted: onSeekRestricted,
            onResume: onResume,
            onStartOver: onStartOver,
            onError: onError
        )
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            isPlaying: $isPlaying,
            currentTime: $currentTime,
            duration: $duration,
            playerState: $playerState,
            onReady: onReady,
            onPlay: onPlay,
            onPause: onPause,
            onProgress: onProgress,
            onComplete: onComplete,
            onExit: onExit,
            onSeekRestricted: onSeekRestricted,
            onResume: onResume,
            onStartOver: onStartOver,
            onError: onError
        )
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: VimeoPlayerDelegate {
        
        // Bindings
        @Binding var isPlaying: Bool
        @Binding var currentTime: TimeInterval
        @Binding var duration: TimeInterval
        @Binding var playerState: VimeoPlayerState
        
        // Callbacks
        var onReady: ((TimeInterval) -> Void)?
        var onPlay: (() -> Void)?
        var onPause: (() -> Void)?
        var onProgress: ((TimeInterval, TimeInterval) -> Void)?
        var onComplete: ((TimeInterval) -> Void)?
        var onExit: ((TimeInterval) -> Void)?
        var onSeekRestricted: ((TimeInterval, TimeInterval) -> Void)?
        var onResume: ((TimeInterval) -> Void)?
        var onStartOver: (() -> Void)?
        var onError: ((VimeoPlayerError) -> Void)?
        
        init(
            isPlaying: Binding<Bool>,
            currentTime: Binding<TimeInterval>,
            duration: Binding<TimeInterval>,
            playerState: Binding<VimeoPlayerState>,
            onReady: ((TimeInterval) -> Void)?,
            onPlay: (() -> Void)?,
            onPause: (() -> Void)?,
            onProgress: ((TimeInterval, TimeInterval) -> Void)?,
            onComplete: ((TimeInterval) -> Void)?,
            onExit: ((TimeInterval) -> Void)?,
            onSeekRestricted: ((TimeInterval, TimeInterval) -> Void)?,
            onResume: ((TimeInterval) -> Void)?,
            onStartOver: (() -> Void)?,
            onError: ((VimeoPlayerError) -> Void)?
        ) {
            self._isPlaying = isPlaying
            self._currentTime = currentTime
            self._duration = duration
            self._playerState = playerState
            self.onReady = onReady
            self.onPlay = onPlay
            self.onPause = onPause
            self.onProgress = onProgress
            self.onComplete = onComplete
            self.onExit = onExit
            self.onSeekRestricted = onSeekRestricted
            self.onResume = onResume
            self.onStartOver = onStartOver
            self.onError = onError
        }
        
        func updateCallbacks(
            onReady: ((TimeInterval) -> Void)?,
            onPlay: (() -> Void)?,
            onPause: (() -> Void)?,
            onProgress: ((TimeInterval, TimeInterval) -> Void)?,
            onComplete: ((TimeInterval) -> Void)?,
            onExit: ((TimeInterval) -> Void)?,
            onSeekRestricted: ((TimeInterval, TimeInterval) -> Void)?,
            onResume: ((TimeInterval) -> Void)?,
            onStartOver: (() -> Void)?,
            onError: ((VimeoPlayerError) -> Void)?
        ) {
            self.onReady = onReady
            self.onPlay = onPlay
            self.onPause = onPause
            self.onProgress = onProgress
            self.onComplete = onComplete
            self.onExit = onExit
            self.onSeekRestricted = onSeekRestricted
            self.onResume = onResume
            self.onStartOver = onStartOver
            self.onError = onError
        }
        
        // MARK: - VimeoPlayerDelegate
        
        public func vimeoPlayerDidBecomeReady(_ player: VimeoRestrictedPlayerViewController, duration: TimeInterval) {
            DispatchQueue.main.async {
                self.duration = duration
                self.playerState = .ready
                self.onReady?(duration)
            }
        }
        
        public func vimeoPlayerDidStartPlaying(_ player: VimeoRestrictedPlayerViewController) {
            DispatchQueue.main.async {
                self.isPlaying = true
                self.playerState = .playing
                self.onPlay?()
            }
        }
        
        public func vimeoPlayerDidPause(_ player: VimeoRestrictedPlayerViewController) {
            DispatchQueue.main.async {
                self.isPlaying = false
                self.playerState = .paused
                self.onPause?()
            }
        }
        
        public func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalDuration: TimeInterval) {
            DispatchQueue.main.async {
                self.currentTime = currentTime
                self.duration = totalDuration
                self.onProgress?(currentTime, totalDuration)
            }
        }
        
        public func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didCompleteWithDuration duration: TimeInterval) {
            DispatchQueue.main.async {
                self.isPlaying = false
                self.playerState = .ended
                self.onComplete?(duration)
            }
        }
        
        public func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didExitAtTime currentTime: TimeInterval) {
            DispatchQueue.main.async {
                self.onExit?(currentTime)
            }
        }
        
        public func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didRestrictSeekFrom attemptedTime: TimeInterval, to allowedTime: TimeInterval) {
            DispatchQueue.main.async {
                self.onSeekRestricted?(attemptedTime, allowedTime)
            }
        }
        
        public func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didResumeFromTime resumeTime: TimeInterval) {
            DispatchQueue.main.async {
                self.onResume?(resumeTime)
            }
        }
        
        public func vimeoPlayerDidStartOver(_ player: VimeoRestrictedPlayerViewController) {
            DispatchQueue.main.async {
                self.currentTime = 0
                self.onStartOver?()
            }
        }
        
        public func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didEncounterError error: VimeoPlayerError) {
            DispatchQueue.main.async {
                self.playerState = .error(error)
                self.onError?(error)
            }
        }
    }
}

// MARK: - SwiftUI View Extensions

@available(iOS 13.0, *)
extension VimeoPlayerView {
    
    /// Convenience initializer for simple use cases
    public init(
        videoURL: String,
        videoTitle: String? = nil,
        lastWatchedDuration: TimeInterval = 0,
        isCompleted: Bool = false,
        allowsFullSeek: Bool = true
    ) {
        let config = VimeoPlayerConfiguration(
            videoURL: videoURL,
            videoTitle: videoTitle,
            lastWatchedDuration: lastWatchedDuration,
            isCompleted: isCompleted,
            allowsFullSeek: allowsFullSeek
        )
        
        self.init(configuration: config)
    }
    
    /// Apply custom theme
    public func theme(_ theme: VimeoPlayerTheme) -> Self {
        var newConfig = configuration
        newConfig.theme = theme
        return VimeoPlayerView(
            configuration: newConfig,
            isPlaying: $isPlaying,
            currentTime: $currentTime,
            duration: $duration,
            playerState: $playerState,
            onReady: onReady,
            onPlay: onPlay,
            onPause: onPause,
            onProgress: onProgress,
            onComplete: onComplete,
            onExit: onExit,
            onSeekRestricted: onSeekRestricted,
            onResume: onResume,
            onStartOver: onStartOver,
            onError: onError
        )
    }
    
    /// Set callbacks using method chaining
    public func onPlayerReady(_ callback: @escaping (TimeInterval) -> Void) -> Self {
        var view = self
        view.onReady = callback
        return view
    }
    
    public func onPlaybackStarted(_ callback: @escaping () -> Void) -> Self {
        var view = self
        view.onPlay = callback
        return view
    }
    
    public func onPlaybackPaused(_ callback: @escaping () -> Void) -> Self {
        var view = self
        view.onPause = callback
        return view
    }
    
    public func onProgressUpdate(_ callback: @escaping (TimeInterval, TimeInterval) -> Void) -> Self {
        var view = self
        view.onProgress = callback
        return view
    }
    
    public func onVideoCompleted(_ callback: @escaping (TimeInterval) -> Void) -> Self {
        var view = self
        view.onComplete = callback
        return view
    }
    
    public func onPlayerExit(_ callback: @escaping (TimeInterval) -> Void) -> Self {
        var view = self
        view.onExit = callback
        return view
    }
    
    public func onSeekRestricted(_ callback: @escaping (TimeInterval, TimeInterval) -> Void) -> Self {
        var view = self
        view.onSeekRestricted = callback
        return view
    }
    
    public func onVideoResumed(_ callback: @escaping (TimeInterval) -> Void) -> Self {
        var view = self
        view.onResume = callback
        return view
    }
    
    public func onVideoStartedOver(_ callback: @escaping () -> Void) -> Self {
        var view = self
        view.onStartOver = callback
        return view
    }
    
    public func onPlayerError(_ callback: @escaping (VimeoPlayerError) -> Void) -> Self {
        var view = self
        view.onError = callback
        return view
    }
}

// MARK: - SwiftUI Environment Keys

@available(iOS 13.0, *)
struct VimeoPlayerThemeKey: EnvironmentKey {
    static let defaultValue: VimeoPlayerTheme = .default
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    public var vimeoPlayerTheme: VimeoPlayerTheme {
        get { self[VimeoPlayerThemeKey.self] }
        set { self[VimeoPlayerThemeKey.self] = newValue }
    }
}

// MARK: - SwiftUI Player State Views

@available(iOS 13.0, *)
public struct VimeoPlayerStateView: View {
    let state: VimeoPlayerState
    let theme: VimeoPlayerTheme
    
    public init(state: VimeoPlayerState, theme: VimeoPlayerTheme = .default) {
        self.state = state
        self.theme = theme
    }
    
    public var body: some View {
        Group {
            switch state {
            case .idle:
                idleView
            case .loading:
                loadingView
            case .ready:
                readyView
            case .playing:
                playingView
            case .paused:
                pausedView
            case .ended:
                endedView
            case .error(let error):
                errorView(error)
            }
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle")
                .font(.system(size: 60))
                .foregroundColor(Color(theme.colors.controlsTint))
            Text("Ready to Play")
                .font(.headline)
                .foregroundColor(Color(theme.colors.primaryText))
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(theme.colors.accent)))
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.headline)
                .foregroundColor(Color(theme.colors.primaryText))
        }
    }
    
    private var readyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(Color(theme.colors.success))
            Text("Ready")
                .font(.headline)
                .foregroundColor(Color(theme.colors.primaryText))
        }
    }
    
    private var playingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(theme.colors.accent))
            Text("Playing")
                .font(.headline)
                .foregroundColor(Color(theme.colors.primaryText))
        }
    }
    
    private var pausedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pause.circle")
                .font(.system(size: 60))
                .foregroundColor(Color(theme.colors.controlsTint))
            Text("Paused")
                .font(.headline)
                .foregroundColor(Color(theme.colors.primaryText))
        }
    }
    
    private var endedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(theme.colors.success))
            Text("Completed")
                .font(.headline)
                .foregroundColor(Color(theme.colors.primaryText))
        }
    }
    
    private func errorView(_ error: VimeoPlayerError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(Color(theme.colors.error))
            Text("Error")
                .font(.headline)
                .foregroundColor(Color(theme.colors.primaryText))
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(Color(theme.colors.secondaryText))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Example Usage View

@available(iOS 13.0, *)
struct VimeoPlayerExampleView: View {
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var playerState: VimeoPlayerState = .idle
    @State private var showingPlayer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Player preview
                VStack {
                    VimeoPlayerView(
                        videoURL: "https://vimeo.com/123456789/abcdef123",
                        videoTitle: "Sample Video",
                        allowsFullSeek: false,
                        isPlaying: $isPlaying,
                        currentTime: $currentTime,
                        duration: $duration,
                        playerState: $playerState
                    )
                    .onProgressUpdate { current, total in
                        print("Progress: \(current) / \(total)")
                    }
                    .onVideoCompleted { duration in
                        print("Video completed: \(duration)")
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                }
                
                // Player state indicator
                VimeoPlayerStateView(state: playerState)
                    .frame(height: 120)
                
                // Player info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Playing:")
                        Spacer()
                        Text(isPlaying ? "Yes" : "No")
                    }
                    
                    HStack {
                        Text("Current Time:")
                        Spacer()
                        Text(TimeFormatter.format(seconds: currentTime))
                    }
                    
                    HStack {
                        Text("Duration:")
                        Spacer()
                        Text(TimeFormatter.format(seconds: duration))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Vimeo Player")
        }
    }
}

#if DEBUG && canImport(SwiftUI)
@available(iOS 13.0, *)
struct VimeoPlayerExampleView_Previews: PreviewProvider {
    static var previews: some View {
        VimeoPlayerExampleView()
    }
}
#endif