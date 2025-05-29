//
//  VimeoPlayerState.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  VimeoPlayerState.swift
//  VimeoRestrictedPlayer
//
//  Created by Assistant on 28/05/25.
//

import Foundation

/// Comprehensive state management for VimeoRestrictedPlayer
public struct VimeoPlayerState: Equatable {
    
    // MARK: - Core State Properties
    
    /// Current playback state
    public private(set) var playbackState: PlaybackState
    
    /// Loading state information
    public private(set) var loadingState: LoadingState
    
    /// Error state information
    public private(set) var errorState: ErrorState?
    
    /// Network state information
    public private(set) var networkState: NetworkState
    
    /// Player readiness state
    public private(set) var readinessState: ReadinessState
    
    /// Seek restriction state
    public private(set) var seekState: SeekState
    
    /// Video information
    public private(set) var videoInfo: VideoInfo
    
    /// Playback progress information
    public private(set) var progressInfo: ProgressInfo
    
    /// User interaction state
    public private(set) var interactionState: InteractionState
    
    /// Quality and performance metrics
    public private(set) var performanceInfo: PerformanceInfo
    
    // MARK: - Initialization
    
    public init() {
        self.playbackState = .idle
        self.loadingState = .notStarted
        self.errorState = nil
        self.networkState = .unknown
        self.readinessState = .notReady
        self.seekState = .idle
        self.videoInfo = VideoInfo()
        self.progressInfo = ProgressInfo()
        self.interactionState = InteractionState()
        self.performanceInfo = PerformanceInfo()
    }
    
    // MARK: - State Update Methods
    
    public mutating func updatePlaybackState(_ state: PlaybackState) {
        playbackState = state
        interactionState.lastPlaybackChange = Date()
    }
    
    public mutating func updateLoadingState(_ state: LoadingState) {
        loadingState = state
        if case .loading = state {
            performanceInfo.lastLoadingStartTime = Date()
        } else if case .loaded = state, let startTime = performanceInfo.lastLoadingStartTime {
            performanceInfo.lastLoadingDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    public mutating func updateError(_ error: VimeoPlayerError?) {
        if let error = error {
            errorState = ErrorState(error: error, timestamp: Date(), recoveryAttempts: errorState?.recoveryAttempts ?? 0)
        } else {
            errorState = nil
        }
    }
    
    public mutating func updateNetworkState(_ state: NetworkState) {
        networkState = state
    }
    
    public mutating func updateReadinessState(_ state: ReadinessState) {
        readinessState = state
    }
    
    public mutating func updateSeekState(_ state: SeekState) {
        seekState = state
    }
    
    public mutating func updateVideoInfo(_ info: VideoInfo) {
        videoInfo = info
    }
    
    public mutating func updateProgress(currentTime: TimeInterval, duration: TimeInterval, maxWatched: TimeInterval) {
        progressInfo.currentTime = currentTime
        progressInfo.duration = duration
        progressInfo.maxWatchedPosition = max(progressInfo.maxWatchedPosition, maxWatched)
        progressInfo.lastUpdateTime = Date()
        
        // Update watch percentage
        if duration > 0 {
            progressInfo.watchPercentage = currentTime / duration
        }
    }
    
    public mutating func incrementErrorRecoveryAttempts() {
        if errorState != nil {
            errorState!.recoveryAttempts += 1
        }
    }
    
    public mutating func recordSeekAttempt(from: TimeInterval, to: TimeInterval, success: Bool) {
        interactionState.lastSeekAttempt = SeekAttempt(
            fromTime: from,
            toTime: to,
            timestamp: Date(),
            wasSuccessful: success
        )
        interactionState.totalSeekAttempts += 1
        if !success {
            interactionState.failedSeekAttempts += 1
        }
    }
    
    public mutating func recordUserInteraction(_ type: UserInteractionType) {
        interactionState.lastInteractionType = type
        interactionState.lastInteractionTime = Date()
        interactionState.totalInteractions += 1
    }
    
    // MARK: - Computed Properties
    
    /// Whether the player is currently playing
    public var isPlaying: Bool {
        return playbackState == .playing
    }
    
    /// Whether the player is ready for interaction
    public var isReady: Bool {
        return readinessState == .ready && loadingState == .loaded
    }
    
    /// Whether there's an active error
    public var hasError: Bool {
        return errorState != nil
    }
    
    /// Whether the video has ended
    public var hasEnded: Bool {
        return playbackState == .ended
    }
    
    /// Whether seeking is currently restricted
    public var isSeekRestricted: Bool {
        return seekState.isRestricted
    }
    
    /// Current progress as a percentage (0.0 - 1.0)
    public var progressPercentage: Double {
        return progressInfo.watchPercentage
    }
    
    /// Whether the video is currently loading
    public var isLoading: Bool {
        switch loadingState {
        case .loading, .buffering:
            return true
        default:
            return false
        }
    }
    
    /// Summary of current state for debugging
    public var debugDescription: String {
        return """
        VimeoPlayerState:
        - Playback: \(playbackState)
        - Loading: \(loadingState)
        - Readiness: \(readinessState)
        - Network: \(networkState)
        - Error: \(errorState?.error.localizedDescription ?? "None")
        - Progress: \(String(format: "%.1f", progressPercentage * 100))%
        - Current Time: \(progressInfo.currentTime)s
        - Duration: \(progressInfo.duration)s
        """
    }
}

// MARK: - Nested State Types

public enum PlaybackState: Equatable, CaseIterable {
    case idle
    case playing
    case paused
    case ended
    case buffering
    case seeking
    case error
}

public enum LoadingState: Equatable {
    case notStarted
    case loading
    case loaded
    case buffering
    case failed(VimeoPlayerError)
}

public enum NetworkState: Equatable {
    case unknown
    case connected
    case disconnected
    case slow
    case cellular
    case wifi
}

public enum ReadinessState: Equatable {
    case notReady
    case initializing
    case ready
    case failed
}

public struct SeekState: Equatable {
    public var isRestricted: Bool
    public var maxAllowedPosition: TimeInterval
    public var isUserSeeking: Bool
    public var pendingSeekTime: TimeInterval?
    public var lastRestrictedSeekTime: TimeInterval?
    
    public init() {
        self.isRestricted = false
        self.maxAllowedPosition = 0
        self.isUserSeeking = false
        self.pendingSeekTime = nil
        self.lastRestrictedSeekTime = nil
    }
    
    static let idle = SeekState()
}

public struct VideoInfo: Equatable {
    public var url: String
    public var title: String?
    public var videoID: String?
    public var hash: String?
    public var thumbnail: String?
    public var quality: VideoQuality?
    public var aspectRatio: Double?
    
    public init() {
        self.url = ""
        self.title = nil
        self.videoID = nil
        self.hash = nil
        self.thumbnail = nil
        self.quality = nil
        self.aspectRatio = nil
    }
}

public enum VideoQuality: String, Equatable, CaseIterable {
    case auto = "auto"
    case low = "360p"
    case medium = "480p"
    case high = "720p"
    case hd = "1080p"
    case uhd = "4K"
}

public struct ProgressInfo: Equatable {
    public var currentTime: TimeInterval
    public var duration: TimeInterval
    public var maxWatchedPosition: TimeInterval
    public var watchPercentage: Double
    public var bufferProgress: Double
    public var lastUpdateTime: Date?
    
    public init() {
        self.currentTime = 0
        self.duration = 0
        self.maxWatchedPosition = 0
        self.watchPercentage = 0
        self.bufferProgress = 0
        self.lastUpdateTime = nil
    }
}

public struct InteractionState: Equatable {
    public var lastInteractionType: UserInteractionType?
    public var lastInteractionTime: Date?
    public var lastPlaybackChange: Date?
    public var lastSeekAttempt: SeekAttempt?
    public var totalInteractions: Int
    public var totalSeekAttempts: Int
    public var failedSeekAttempts: Int
    
    public init() {
        self.lastInteractionType = nil
        self.lastInteractionTime = nil
        self.lastPlaybackChange = nil
        self.lastSeekAttempt = nil
        self.totalInteractions = 0
        self.totalSeekAttempts = 0
        self.failedSeekAttempts = 0
    }
}

public enum UserInteractionType: String, Equatable, CaseIterable {
    case play
    case pause
    case seek
    case volumeChange
    case fullscreen
    case back
    case retry
    case dismiss
}

public struct SeekAttempt: Equatable {
    public let fromTime: TimeInterval
    public let toTime: TimeInterval
    public let timestamp: Date
    public let wasSuccessful: Bool
    
    public init(fromTime: TimeInterval, toTime: TimeInterval, timestamp: Date, wasSuccessful: Bool) {
        self.fromTime = fromTime
        self.toTime = toTime
        self.timestamp = timestamp
        self.wasSuccessful = wasSuccessful
    }
}

public struct ErrorState: Equatable {
    public let error: VimeoPlayerError
    public let timestamp: Date
    public var recoveryAttempts: Int
    
    public init(error: VimeoPlayerError, timestamp: Date, recoveryAttempts: Int = 0) {
        self.error = error
        self.timestamp = timestamp
        self.recoveryAttempts = recoveryAttempts
    }
}

public struct PerformanceInfo: Equatable {
    public var lastLoadingStartTime: Date?
    public var lastLoadingDuration: TimeInterval?
    public var averageLoadingTime: TimeInterval?
    public var totalLoadingEvents: Int
    public var bufferingEvents: Int
    public var errorCount: Int
    
    public init() {
        self.lastLoadingStartTime = nil
        self.lastLoadingDuration = nil
        self.averageLoadingTime = nil
        self.totalLoadingEvents = 0
        self.bufferingEvents = 0
        self.errorCount = 0
    }
}

// MARK: - State Machine

/// State machine for managing VimeoPlayer state transitions
public class VimeoPlayerStateMachine {
    
    public private(set) var currentState: VimeoPlayerState
    public weak var delegate: VimeoPlayerStateMachineDelegate?
    
    private var stateHistory: [VimeoPlayerState] = []
    private let maxHistorySize = 10
    
    public init() {
        self.currentState = VimeoPlayerState()
    }
    
    // MARK: - State Transitions
    
    public func transition(to newPlaybackState: PlaybackState) {
        let previousState = currentState
        currentState.updatePlaybackState(newPlaybackState)
        handleStateTransition(from: previousState, to: currentState)
    }
    
    public func updateLoading(_ loadingState: LoadingState) {
        let previousState = currentState
        currentState.updateLoadingState(loadingState)
        handleStateTransition(from: previousState, to: currentState)
    }
    
    public func reportError(_ error: VimeoPlayerError) {
        let previousState = currentState
        currentState.updateError(error)
        currentState.updatePlaybackState(.error)
        handleStateTransition(from: previousState, to: currentState)
    }
    
    public func clearError() {
        let previousState = currentState
        currentState.updateError(nil)
        if currentState.playbackState == .error {
            currentState.updatePlaybackState(.idle)
        }
        handleStateTransition(from: previousState, to: currentState)
    }
    
    public func updateProgress(currentTime: TimeInterval, duration: TimeInterval, maxWatched: TimeInterval) {
        currentState.updateProgress(currentTime: currentTime, duration: duration, maxWatched: maxWatched)
        delegate?.stateMachine(self, didUpdateProgress: currentState.progressInfo)
    }
    
    public func recordUserInteraction(_ type: UserInteractionType) {
        currentState.recordUserInteraction(type)
        delegate?.stateMachine(self, didRecordInteraction: type, at: Date())
    }
    
    public func attemptSeek(from: TimeInterval, to: TimeInterval) -> Bool {
        let canSeek = !currentState.isSeekRestricted || to <= currentState.seekState.maxAllowedPosition
        currentState.recordSeekAttempt(from: from, to: to, success: canSeek)
        
        if canSeek {
            currentState.updatePlaybackState(.seeking)
        }
        
        delegate?.stateMachine(self, didAttemptSeek: from, to: to, success: canSeek)
        return canSeek
    }
    
    // MARK: - State Queries
    
    public func canTransition(to state: PlaybackState) -> Bool {
        switch (currentState.playbackState, state) {
        case (.idle, .playing), (.idle, .buffering):
            return currentState.isReady
        case (.playing, .paused), (.paused, .playing):
            return true
        case (.seeking, .playing), (.seeking, .paused):
            return true
        case (_, .error):
            return true
        case (.error, .idle):
            return true
        default:
            return false
        }
    }
    
    public func shouldAllowSeek(to time: TimeInterval) -> Bool {
        if !currentState.isReady {
            return false
        }
        
        if currentState.isSeekRestricted {
            return time <= currentState.seekState.maxAllowedPosition
        }
        
        return time >= 0 && time <= currentState.progressInfo.duration
    }
    
    // MARK: - Private Methods
    
    private func handleStateTransition(from previousState: VimeoPlayerState, to newState: VimeoPlayerState) {
        // Add to history
        stateHistory.append(previousState)
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
        }
        
        // Notify delegate
        delegate?.stateMachine(self, didTransition: previousState, to: newState)
        
        // Handle specific transitions
        if previousState.playbackState != newState.playbackState {
            delegate?.stateMachine(self, didChangePlaybackState: newState.playbackState)
        }
        
        if previousState.hasError != newState.hasError {
            if newState.hasError {
                delegate?.stateMachine(self, didEncounterError: newState.errorState!.error)
            } else {
                delegate?.stateMachine(self, didRecoverFromError: previousState.errorState!.error)
            }
        }
    }
}

// MARK: - State Machine Delegate

public protocol VimeoPlayerStateMachineDelegate: AnyObject {
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didTransition from: VimeoPlayerState, to: VimeoPlayerState)
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didChangePlaybackState state: PlaybackState)
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didUpdateProgress progress: ProgressInfo)
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didRecordInteraction type: UserInteractionType, at time: Date)
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didAttemptSeek from: TimeInterval, to: TimeInterval, success: Bool)
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didEncounterError error: VimeoPlayerError)
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didRecoverFromError error: VimeoPlayerError)
}

// MARK: - Optional Delegate Methods

public extension VimeoPlayerStateMachineDelegate {
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didTransition from: VimeoPlayerState, to: VimeoPlayerState) {}
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didChangePlaybackState state: PlaybackState) {}
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didUpdateProgress progress: ProgressInfo) {}
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didRecordInteraction type: UserInteractionType, at time: Date) {}
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didAttemptSeek from: TimeInterval, to: TimeInterval, success: Bool) {}
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didEncounterError error: VimeoPlayerError) {}
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didRecoverFromError error: VimeoPlayerError) {}
}

// MARK: - State Persistence

extension VimeoPlayerState: Codable {
    
    /// Save state to UserDefaults
    public func save(forKey key: String) {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    /// Load state from UserDefaults
    public static func load(forKey key: String) -> VimeoPlayerState? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(VimeoPlayerState.self, from: data) else {
            return nil
        }
        return state
    }
}

// MARK: - Legacy Compatibility

extension VimeoPlayerState {
    
    /// Legacy VimeoPlayerState enum for backward compatibility
    public var legacyState: LegacyVimeoPlayerState {
        if hasError {
            return .error(errorState!.error)
        }
        
        switch playbackState {
        case .idle:
            return isReady ? .ready : .idle
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .ended:
            return .ended
        case .buffering:
            return .loading
        case .seeking:
            return .playing // Treat seeking as playing for legacy compatibility
        case .error:
            return .error(errorState?.error ?? .unknown("Unknown error"))
        }
    }
}

/// Legacy state enum for backward compatibility
public enum LegacyVimeoPlayerState {
    case idle
    case loading
    case ready
    case playing
    case paused
    case ended
    case error(VimeoPlayerError)
    
    public var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }
    
    public var isReady: Bool {
        switch self {
        case .ready, .playing, .paused, .ended:
            return true
        default:
            return false
        }
    }
    
    public var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}
