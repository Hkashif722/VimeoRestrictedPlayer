//
//  for.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  VimeoPlayerDelegate.swift
//  VimeoRestrictedPlayer
//
//  Delegate protocol for VimeoRestrictedPlayer events
//

import Foundation

/// Delegate protocol for receiving VimeoRestrictedPlayer events
public protocol VimeoPlayerDelegate: AnyObject {
    
    // MARK: - Playback Events
    
    /// Called when the video player is ready
    /// - Parameters:
    ///   - player: The player instance
    ///   - duration: Total duration of the video
    func vimeoPlayerDidBecomeReady(_ player: VimeoRestrictedPlayerViewController, duration: TimeInterval)
    
    /// Called when playback starts
    /// - Parameter player: The player instance
    func vimeoPlayerDidStartPlaying(_ player: VimeoRestrictedPlayerViewController)
    
    /// Called when playback pauses
    /// - Parameter player: The player instance
    func vimeoPlayerDidPause(_ player: VimeoRestrictedPlayerViewController)
    
    /// Called periodically during playback with progress updates
    /// - Parameters:
    ///   - player: The player instance
    ///   - currentTime: Current playback position in seconds
    ///   - totalDuration: Total video duration in seconds
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalDuration: TimeInterval)
    
    /// Called when the video completes playback
    /// - Parameters:
    ///   - player: The player instance
    ///   - duration: Total duration watched
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didCompleteWithDuration duration: TimeInterval)
    
    // MARK: - User Interaction Events
    
    /// Called when user exits the video
    /// - Parameters:
    ///   - player: The player instance
    ///   - currentTime: Time at which user exited
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didExitAtTime currentTime: TimeInterval)
    
    /// Called when user attempts to seek beyond allowed position
    /// - Parameters:
    ///   - player: The player instance
    ///   - attemptedTime: Time user tried to seek to
    ///   - allowedTime: Maximum allowed seek time
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didRestrictSeekFrom attemptedTime: TimeInterval, to allowedTime: TimeInterval)
    
    /// Called when user chooses to resume from bookmark
    /// - Parameters:
    ///   - player: The player instance
    ///   - resumeTime: Time from which playback resumed
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didResumeFromTime resumeTime: TimeInterval)
    
    /// Called when user chooses to start over
    /// - Parameter player: The player instance
    func vimeoPlayerDidStartOver(_ player: VimeoRestrictedPlayerViewController)
    
    // MARK: - Error Events
    
    /// Called when an error occurs
    /// - Parameters:
    ///   - player: The player instance
    ///   - error: The error that occurred
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didEncounterError error: VimeoPlayerError)
}

// MARK: - Optional Methods

public extension VimeoPlayerDelegate {
    
    func vimeoPlayerDidBecomeReady(_ player: VimeoRestrictedPlayerViewController, duration: TimeInterval) {}
    
    func vimeoPlayerDidStartPlaying(_ player: VimeoRestrictedPlayerViewController) {}
    
    func vimeoPlayerDidPause(_ player: VimeoRestrictedPlayerViewController) {}
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalDuration: TimeInterval) {}
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didCompleteWithDuration duration: TimeInterval) {}
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didExitAtTime currentTime: TimeInterval) {}
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didRestrictSeekFrom attemptedTime: TimeInterval, to allowedTime: TimeInterval) {}
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didResumeFromTime resumeTime: TimeInterval) {}
    
    func vimeoPlayerDidStartOver(_ player: VimeoRestrictedPlayerViewController) {}
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didEncounterError error: VimeoPlayerError) {}
}

// MARK: - Error Types

/// Errors that can occur in VimeoRestrictedPlayer
public enum VimeoPlayerError: LocalizedError {
    case invalidURL(String)
    case loadingFailed(Error)
    case playbackFailed(String)
    case networkError(Error)
    case javascriptError(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid Vimeo URL: \(url)"
        case .loadingFailed(let error):
            return "Failed to load video: \(error.localizedDescription)"
        case .playbackFailed(let message):
            return "Playback error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .javascriptError(let message):
            return "JavaScript error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Player State

/// Current state of the video player
public enum VimeoPlayerState {
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
}