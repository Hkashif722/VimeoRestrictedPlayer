//
//  VimeoRestrictedPlayerTests.swift
//  VimeoRestrictedPlayer Tests
//
//  Created by Assistant on 28/05/25.
//

import Testing
import Foundation
@testable import VimeoRestrictedPlayer

// MARK: - URL Parser Tests

@Test("VimeoURLParser - Valid URLs")
func testVimeoURLParserValidURLs() async throws {
    let testCases = [
        ("https://vimeo.com/123456789", ("123456789", "")),
        ("https://vimeo.com/123456789/abcdef", ("123456789", "abcdef")),
        ("https://player.vimeo.com/video/123456789", ("123456789", "")),
        ("https://player.vimeo.com/video/123456789?h=abcdef", ("123456789", "")),
        ("vimeo.com/123456789/hash123", ("123456789", "hash123")),
        ("123456789/hash456", ("123456789", "hash456"))
    ]
    
    for (url, expected) in testCases {
        let result = VimeoURLParser.parse(url)
        #expect(result?.videoId == expected.0, "Failed for URL: \(url)")
        #expect(result?.hash == expected.1, "Failed for URL: \(url)")
    }
}

@Test("VimeoURLParser - Invalid URLs")
func testVimeoURLParserInvalidURLs() async throws {
    let invalidURLs = [
        "https://youtube.com/watch?v=123",
        "not-a-url",
        "vimeo.com/invalid",
        "",
        "123abc", // Not purely numeric
        "https://vimeo.com/", // No video ID
    ]
    
    for url in invalidURLs {
        let result = VimeoURLParser.parse(url)
        #expect(result == nil, "Should be invalid: \(url)")
    }
}

@Test("VimeoURLParser - Construct Embed URL")
func testConstructEmbedURL() async throws {
    let videoId = "123456789"
    let hash = "abcdef"
    let result = VimeoURLParser.constructEmbedURL(videoId: videoId, hash: hash)
    
    #expect(result.contains("player.vimeo.com/video/123456789"))
    #expect(result.contains("h=abcdef"))
    #expect(result.contains("controls=true"))
}

// MARK: - Time Formatter Tests

@Test("TimeFormatter - Format seconds")
func testTimeFormatterFormat() async throws {
    let testCases: [(TimeInterval, String)] = [
        (0, "0:00"),
        (30, "0:30"),
        (60, "1:00"),
        (90, "1:30"),
        (3661, "1:01:01"), // 1 hour, 1 minute, 1 second
        (7323, "2:02:03")  // 2 hours, 2 minutes, 3 seconds
    ]
    
    for (seconds, expected) in testCases {
        let result = TimeFormatter.format(seconds: seconds)
        #expect(result == expected, "Failed for \(seconds) seconds")
    }
}

@Test("TimeFormatter - Parse time string")
func testTimeFormatterParse() async throws {
    let testCases: [(String, TimeInterval?)] = [
        ("0:30", 30),
        ("1:00", 60),
        ("1:30", 90),
        ("1:01:01", 3661),
        ("2:02:03", 7323),
        ("invalid", nil),
        ("", nil)
    ]
    
    for (timeString, expected) in testCases {
        let result = TimeFormatter.parse(timeString: timeString)
        #expect(result == expected, "Failed for '\(timeString)'")
    }
}

@Test("TimeFormatter - Verbose format")
func testTimeFormatterVerbose() async throws {
    let testCases: [(TimeInterval, String)] = [
        (1, "1 second"),
        (30, "30 seconds"),
        (60, "1 minute"),
        (90, "1 minute and 30 seconds"),
        (3661, "1 hour, 1 minute, and 1 second")
    ]
    
    for (seconds, expected) in testCases {
        let result = TimeFormatter.formatVerbose(seconds: seconds)
        #expect(result == expected, "Failed for \(seconds) seconds")
    }
}

// MARK: - Configuration Tests

@Test("VimeoPlayerConfiguration - Default initialization")
func testVimeoPlayerConfigurationDefaults() async throws {
    let config = VimeoPlayerConfiguration(videoURL: "https://vimeo.com/123/abc")
    
    #expect(config.videoURL == "https://vimeo.com/123/abc")
    #expect(config.lastWatchedDuration == 0)
    #expect(config.isCompleted == false)
    #expect(config.allowsFullSeek == true)
    #expect(config.autoplay == false)
    #expect(config.showsBackButton == true)
}

@Test("VimeoPlayerConfiguration - Custom initialization")
func testVimeoPlayerConfigurationCustom() async throws {
    let config = VimeoPlayerConfiguration(
        videoURL: "https://vimeo.com/456/def",
        videoTitle: "Test Video",
        lastWatchedDuration: 120.0,
        isCompleted: true,
        allowsFullSeek: false,
        videoID: "test123"
    )
    
    #expect(config.videoURL == "https://vimeo.com/456/def")
    #expect(config.videoTitle == "Test Video")
    #expect(config.lastWatchedDuration == 120.0)
    #expect(config.isCompleted == true)
    #expect(config.allowsFullSeek == false)
    #expect(config.videoID == "test123")
}

// MARK: - Player State Tests

@Test("VimeoPlayerState - Initial state")
func testVimeoPlayerStateInitial() async throws {
    let state = VimeoPlayerState()
    
    #expect(state.playbackState == .idle)
    #expect(state.loadingState == .notStarted)
    #expect(state.errorState == nil)
    #expect(state.isPlaying == false)
    #expect(state.isReady == false)
    #expect(state.hasError == false)
    #expect(state.progressPercentage == 0.0)
}

@Test("VimeoPlayerState - State updates")
func testVimeoPlayerStateUpdates() async throws {
    var state = VimeoPlayerState()
    
    // Test playback state update
    state.updatePlaybackState(.playing)
    #expect(state.playbackState == .playing)
    #expect(state.isPlaying == true)
    
    // Test progress update
    state.updateProgress(currentTime: 60, duration: 120, maxWatched: 60)
    #expect(state.progressInfo.currentTime == 60)
    #expect(state.progressInfo.duration == 120)
    #expect(state.progressPercentage == 0.5)
    
    // Test error state
    let error = VimeoPlayerError.networkError(.init(underlyingError: "Test error"))
    state.updateError(error)
    #expect(state.hasError == true)
    #expect(state.errorState?.error == error)
}

@Test("VimeoPlayerState - Seek state")
func testVimeoPlayerStateSeek() async throws {
    var state = VimeoPlayerState()
    
    // Test seek attempt recording
    state.recordSeekAttempt(from: 10, to: 50, success: true)
    #expect(state.interactionState.lastSeekAttempt?.fromTime == 10)
    #expect(state.interactionState.lastSeekAttempt?.toTime == 50)
    #expect(state.interactionState.lastSeekAttempt?.wasSuccessful == true)
    #expect(state.interactionState.totalSeekAttempts == 1)
    #expect(state.interactionState.failedSeekAttempts == 0)
    
    // Test failed seek
    state.recordSeekAttempt(from: 20, to: 100, success: false)
    #expect(state.interactionState.totalSeekAttempts == 2)
    #expect(state.interactionState.failedSeekAttempts == 1)
}

@Test("VimeoPlayerState - Codable")
func testVimeoPlayerStateCodable() async throws {
    var originalState = VimeoPlayerState()
    originalState.updatePlaybackState(.playing)
    originalState.updateProgress(currentTime: 60, duration: 120, maxWatched: 60)
    
    // Encode
    let encoder = JSONEncoder()
    let data = try encoder.encode(originalState)
    
    // Decode
    let decoder = JSONDecoder()
    let decodedState = try decoder.decode(VimeoPlayerState.self, from: data)
    
    #expect(decodedState.playbackState == originalState.playbackState)
    #expect(decodedState.progressInfo.currentTime == originalState.progressInfo.currentTime)
    #expect(decodedState.progressInfo.duration == originalState.progressInfo.duration)
}

// MARK: - State Machine Tests

@Test("VimeoPlayerStateMachine - Initialization")
func testStateMachineInitialization() async throws {
    let stateMachine = VimeoPlayerStateMachine()
    
    #expect(stateMachine.currentState.playbackState == .idle)
    #expect(stateMachine.currentState.loadingState == .notStarted)
}

@Test("VimeoPlayerStateMachine - State transitions")
func testStateMachineTransitions() async throws {
    let stateMachine = VimeoPlayerStateMachine()
    
    // Test valid transition
    stateMachine.currentState.updateReadinessState(.ready)
    stateMachine.currentState.updateLoadingState(.loaded)
    
    let canTransition = stateMachine.canTransition(to: .playing)
    #expect(canTransition == true)
    
    stateMachine.transition(to: .playing)
    #expect(stateMachine.currentState.playbackState == .playing)
}

@Test("VimeoPlayerStateMachine - Seek validation")
func testStateMachineSeekValidation() async throws {
    let stateMachine = VimeoPlayerStateMachine()
    
    // Setup state
    stateMachine.currentState.updateReadinessState(.ready)
    stateMachine.currentState.updateProgress(currentTime: 60, duration: 120, maxWatched: 60)
    stateMachine.currentState.seekState.isRestricted = true
    stateMachine.currentState.seekState.maxAllowedPosition = 60
    
    // Test seek validation
    #expect(stateMachine.shouldAllowSeek(to: 30) == true)  // Within allowed
    #expect(stateMachine.shouldAllowSeek(to: 60) == true)  // At boundary
    #expect(stateMachine.shouldAllowSeek(to: 90) == false) // Beyond allowed
}

// MARK: - Error Tests

@Test("VimeoPlayerError - Error properties")
func testVimeoPlayerErrorProperties() async throws {
    // Test network error
    let networkError = VimeoPlayerError.networkError(.init(
        underlyingError: "Connection failed",
        isConnectivityIssue: true,
        retryable: true
    ))
    
    #expect(networkError.isRetryable == true)
    #expect(networkError.category == .network)
    #expect(networkError.severity == .error)
    #expect(networkError.errorCode == "VPE101")
    
    // Test seek restriction error
    let seekError = VimeoPlayerError.seekRestricted(.init(
        attemptedTime: 100,
        maxAllowedTime: 60,
        currentTime: 30,
        restrictionType: .watchProgress
    ))
    
    #expect(seekError.requiresUserIntervention == true)
    #expect(seekError.category == .userInteraction)
    #expect(seekError.errorCode == "VPE401")
}

@Test("VimeoPlayerError - Error factory")
func testVimeoPlayerErrorFactory() async throws {
    let networkError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: nil)
    let vimeoError = VimeoPlayerErrorFactory.networkError(from: networkError)
    
    if case .networkError(let info) = vimeoError {
        #expect(info.errorCode == -1009)
        #expect(info.isConnectivityIssue == true)
    } else {
        #expect(Bool(false), "Should be network error")
    }
}

@Test("VimeoPlayerError - Custom error")
func testVimeoPlayerErrorCustom() async throws {
    let customError = VimeoPlayerErrorFactory.customError(
        code: "CUSTOM001",
        message: "Custom error message",
        severity: .warning,
        recoverable: true,
        context: ["key": "value"]
    )
    
    if case .custom(let info) = customError {
        #expect(info.code == "CUSTOM001")
        #expect(info.message == "Custom error message")
        #expect(info.severity == .warning)
        #expect(info.isRecoverable == true)
        #expect(info.context?["key"] == "value")
    } else {
        #expect(Bool(false), "Should be custom error")
    }
}

// MARK: - Theme Tests

@Test("VimeoPlayerTheme - Default theme")
func testVimeoPlayerThemeDefault() async throws {
    let theme = VimeoPlayerTheme.default
    
    #expect(theme.colors.primaryBackground == .black)
    #expect(theme.colors.controlsTint == .white)
    #expect(theme.typography.titleFont.pointSize == 18)
    #expect(theme.controls.backButton.size == CGSize(width: 40, height: 40))
}

@Test("VimeoPlayerTheme - Custom theme")
func testVimeoPlayerThemeCustom() async throws {
    let customColors = ColorTheme(
        primaryBackground: .blue,
        accent: .red
    )
    
    let theme = VimeoPlayerTheme(colors: customColors)
    
    #expect(theme.colors.primaryBackground == .blue)
    #expect(theme.colors.accent == .red)
}

@Test("VimeoPlayerTheme - Backward compatibility")
func testVimeoPlayerThemeBackwardCompatibility() async throws {
    var theme = VimeoPlayerTheme.default
    
    // Test legacy properties
    theme.backgroundColor = .red
    #expect(theme.colors.primaryBackground == .red)
    
    theme.controlsTintColor = .green
    #expect(theme.colors.controlsTint == .green)
    
    theme.backButtonSize = CGSize(width: 50, height: 50)
    #expect(theme.controls.backButton.size == CGSize(width: 50, height: 50))
}

// MARK: - Integration Tests

@Test("Integration - Complete player workflow")
func testCompletePlayerWorkflow() async throws {
    // Test the complete workflow with all components
    let config = VimeoPlayerConfiguration(
        videoURL: "https://vimeo.com/123456789/abcdef",
        videoTitle: "Test Video",
        lastWatchedDuration: 30.0,
        allowsFullSeek: false
    )
    
    // Validate URL parsing
    let urlResult = VimeoURLParser.parse(config.videoURL)
    #expect(urlResult?.videoId == "123456789")
    #expect(urlResult?.hash == "abcdef")
    
    // Test state machine
    let stateMachine = VimeoPlayerStateMachine()
    stateMachine.updateProgress(currentTime: 30, duration: 120, maxWatched: 30)
    
    #expect(stateMachine.currentState.progressPercentage == 0.25)
    #expect(stateMachine.shouldAllowSeek(to: 25) == true)
    
    // Test error handling
    let error = VimeoPlayerErrorFactory.seekError(
        requestedTime: 90,
        currentTime: 30,
        maxAllowed: 30,
        reason: .beyondWatchedContent
    )
    
    #expect(error.requiresUserIntervention == true)
    #expect(error.category == .playback)
}

// MARK: - Performance Tests

@Test("Performance - URL parsing")
func testURLParsingPerformance() async throws {
    let urls = Array(repeating: "https://vimeo.com/123456789/abcdef", count: 1000)
    
    let startTime = CFAbsoluteTimeGetCurrent()
    for url in urls {
        _ = VimeoURLParser.parse(url)
    }
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    
    #expect(timeElapsed < 1.0, "URL parsing should be fast")
}

@Test("Performance - State updates")
func testStateUpdatePerformance() async throws {
    var state = VimeoPlayerState()
    
    let startTime = CFAbsoluteTimeGetCurrent()
    for i in 0..<1000 {
        state.updateProgress(currentTime: TimeInterval(i), duration: 1000, maxWatched: TimeInterval(i))
    }
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    
    #expect(timeElapsed < 0.1, "State updates should be fast")
}

// MARK: - Edge Cases

@Test("Edge Cases - Empty and nil values")
func testEdgeCasesEmptyValues() async throws {
    // Test empty URL
    let emptyURLResult = VimeoURLParser.parse("")
    #expect(emptyURLResult == nil)
    
    // Test zero duration
    var state = VimeoPlayerState()
    state.updateProgress(currentTime: 0, duration: 0, maxWatched: 0)
    #expect(state.progressPercentage == 0.0)
}

@Test("Edge Cases - Large numbers")
func testEdgeCasesLargeNumbers() async throws {
    // Test very large time values
    let largeTime: TimeInterval = 999999
    let formatted = TimeFormatter.format(seconds: largeTime)
    #expect(formatted.contains(":"))
    
    // Test state with large values
    var state = VimeoPlayerState()
    state.updateProgress(currentTime: largeTime, duration: largeTime + 1000, maxWatched: largeTime)
    #expect(state.progressPercentage > 0.99)
}

@Test("Edge Cases - Invalid configurations")
func testEdgeCasesInvalidConfigurations() async throws {
    // Test configuration with invalid URL
    let config = VimeoPlayerConfiguration(videoURL: "not-a-valid-url")
    let isValid = VimeoURLParser.isValidVimeoURL(config.videoURL)
    #expect(isValid == false)
}

// MARK: - Mock Delegate for Testing

class MockVimeoPlayerDelegate: VimeoPlayerDelegate {
    var readyCallCount = 0
    var playCallCount = 0
    var pauseCallCount = 0
    var progressCallCount = 0
    var errorCallCount = 0
    var lastError: VimeoPlayerError?
    
    func vimeoPlayerDidBecomeReady(_ player: VimeoRestrictedPlayerViewController, duration: TimeInterval) {
        readyCallCount += 1
    }
    
    func vimeoPlayerDidStartPlaying(_ player: VimeoRestrictedPlayerViewController) {
        playCallCount += 1
    }
    
    func vimeoPlayerDidPause(_ player: VimeoRestrictedPlayerViewController) {
        pauseCallCount += 1
    }
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalDuration: TimeInterval) {
        progressCallCount += 1
    }
    
    func vimeoPlayer(_ player: VimeoRestrictedPlayerViewController, didEncounterError error: VimeoPlayerError) {
        errorCallCount += 1
        lastError = error
    }
}

// MARK: - Mock State Machine Delegate

class MockStateMachineDelegate: VimeoPlayerStateMachineDelegate {
    var transitionCallCount = 0
    var playbackStateChangeCallCount = 0
    var progressUpdateCallCount = 0
    var errorCallCount = 0
    
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didTransition from: VimeoPlayerState, to: VimeoPlayerState) {
        transitionCallCount += 1
    }
    
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didChangePlaybackState state: PlaybackState) {
        playbackStateChangeCallCount += 1
    }
    
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didUpdateProgress progress: ProgressInfo) {
        progressUpdateCallCount += 1
    }
    
    func stateMachine(_ stateMachine: VimeoPlayerStateMachine, didEncounterError error: VimeoPlayerError) {
        errorCallCount += 1
    }
}

// MARK: - Delegate Tests

@Test("Mock Delegate - Callback counts")
func testMockDelegateCallbacks() async throws {
    let delegate = MockVimeoPlayerDelegate()
    
    // Simulate delegate calls
    let config = VimeoPlayerConfiguration(videoURL: "https://vimeo.com/123/abc")
    let player = VimeoRestrictedPlayerViewController(configuration: config)
    
    delegate.vimeoPlayerDidBecomeReady(player, duration: 120)
    delegate.vimeoPlayerDidStartPlaying(player)
    delegate.vimeoPlayerDidPause(player)
    delegate.vimeoPlayer(player, didUpdateProgress: 30, totalDuration: 120)
    
    let error = VimeoPlayerError.networkError(.init(underlyingError: "Test"))
    delegate.vimeoPlayer(player, didEncounterError: error)
    
    #expect(delegate.readyCallCount == 1)
    #expect(delegate.playCallCount == 1)
    #expect(delegate.pauseCallCount == 1)
    #expect(delegate.progressCallCount == 1)
    #expect(delegate.errorCallCount == 1)
    #expect(delegate.lastError == error)
}

@Test("State Machine Delegate - Callback counts")
func testStateMachineDelegateCallbacks() async throws {
    let delegate = MockStateMachineDelegate()
    let stateMachine = VimeoPlayerStateMachine()
    stateMachine.delegate = delegate
    
    // Trigger state changes
    stateMachine.transition(to: .playing)
    stateMachine.updateProgress(currentTime: 30, duration: 120, maxWatched: 30)
    stateMachine.reportError(.unknown("Test error"))
    
    #expect(delegate.transitionCallCount > 0)
    #expect(delegate.playbackStateChangeCallCount > 0)
    #expect(delegate.progressUpdateCallCount > 0)
    #expect(delegate.errorCallCount > 0)
}
