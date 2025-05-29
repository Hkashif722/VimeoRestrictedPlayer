//
//  VimeoPlayerWebViewBridgeDelegate.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  VimeoPlayerWebViewBridge.swift
//  VimeoRestrictedPlayer
//
//  Created by Assistant on 28/05/25.
//

import Foundation
import WebKit

/// Protocol for handling WebView bridge events
public protocol VimeoPlayerWebViewBridgeDelegate: AnyObject {
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didReceiveReady duration: TimeInterval, shouldShowResumeDialog: Bool)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didUpdateTime currentTime: TimeInterval, maxAllowed: TimeInterval)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didPlay: Void)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didPause: Void)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didEnd: Void)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didRestrictSeek attemptedTime: TimeInterval, maxAllowed: TimeInterval, wasPlaying: Bool, actualPosition: TimeInterval)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didCompleteSeek time: TimeInterval, wasRequested: TimeInterval, isPlaying: Bool)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didEncounterError error: VimeoPlayerError)
    func bridge(_ bridge: VimeoPlayerWebViewBridge, didSeekError error: String, requestedTime: TimeInterval)
}

/// Enhanced WebView bridge for robust JavaScript-Swift communication
public class VimeoPlayerWebViewBridge: NSObject {
    
    // MARK: - Properties
    
    public weak var delegate: VimeoPlayerWebViewBridgeDelegate?
    public private(set) var webView: WKWebView?
    public private(set) var isReady: Bool = false
    
    private var messageQueue: [String] = []
    private var jsExecutionQueue = DispatchQueue(label: "com.vimeo.jsexecution", qos: .userInitiated)
    
    // MARK: - Public Methods
    
    /// Setup the bridge with a WebView
    public func setupBridge(with webView: WKWebView) {
        self.webView = webView
        webView.configuration.userContentController.add(self, name: "vimeoPlayerHandler")
    }
    
    /// Cleanup the bridge
    public func cleanup() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "vimeoPlayerHandler")
        isReady = false
        messageQueue.removeAll()
        webView = nil
    }
    
    // MARK: - JavaScript Execution Methods
    
    /// Execute JavaScript with completion handler
    public func executeJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        guard let webView = webView else {
            completion?(nil, VimeoPlayerError.javascriptError("WebView not available"))
            return
        }
        
        jsExecutionQueue.async {
            DispatchQueue.main.async {
                webView.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        print("[VimeoPlayerBridge] JS Error: \(error.localizedDescription)")
                        completion?(nil, VimeoPlayerError.javascriptError(error.localizedDescription))
                    } else {
                        completion?(result, nil)
                    }
                }
            }
        }
    }
    
    /// Execute JavaScript when ready or queue if not ready
    public func executeWhenReady(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        if isReady {
            executeJavaScript(script, completion: completion)
        } else {
            messageQueue.append(script)
            if let completion = completion {
                // Execute queued completion after a delay to allow message to be processed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion(nil, VimeoPlayerError.javascriptError("Player not ready"))
                }
            }
        }
    }
    
    // MARK: - Player Control Methods
    
    public func play(completion: ((Bool, Error?) -> Void)? = nil) {
        executeWhenReady("playVideo()") { _, error in
            completion?(error == nil, error)
        }
    }
    
    public func pause(completion: ((Bool, Error?) -> Void)? = nil) {
        executeWhenReady("pauseVideo()") { _, error in
            completion?(error == nil, error)
        }
    }
    
    public func seekTo(_ time: TimeInterval, shouldPlay: Bool = false, completion: ((Bool, Error?) -> Void)? = nil) {
        let script = "setCurrentTime(\(time), \(shouldPlay))"
        executeWhenReady(script) { _, error in
            completion?(error == nil, error)
        }
    }
    
    public func restart(completion: ((Bool, Error?) -> Void)? = nil) {
        executeWhenReady("restartVideo()") { _, error in
            completion?(error == nil, error)
        }
    }
    
    public func resumeFromBookmark(completion: ((Bool, Error?) -> Void)? = nil) {
        executeWhenReady("resumeFromBookmark()") { _, error in
            completion?(error == nil, error)
        }
    }
    
    public func updateMaxAllowedSeek(_ time: TimeInterval, completion: ((Bool, Error?) -> Void)? = nil) {
        let script = "updateMaxAllowedSeek(\(time))"
        executeWhenReady(script) { _, error in
            completion?(error == nil, error)
        }
    }
    
    public func resumeVideoAfterAlert(completion: ((Bool, Error?) -> Void)? = nil) {
        executeWhenReady("resumeVideoAfterAlert()") { _, error in
            completion?(error == nil, error)
        }
    }
    
    // MARK: - State Query Methods
    
    public func getCurrentTime(completion: @escaping (TimeInterval?, Error?) -> Void) {
        executeWhenReady("player.getCurrentTime()") { result, error in
            if let time = result as? TimeInterval {
                completion(time, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    public func getDuration(completion: @escaping (TimeInterval?, Error?) -> Void) {
        executeWhenReady("player.getDuration()") { result, error in
            if let duration = result as? TimeInterval {
                completion(duration, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    public func getPlayerState(completion: @escaping ([String: Any]?, Error?) -> Void) {
        executeWhenReady("getPlayerState()") { result, error in
            if let state = result as? [String: Any] {
                completion(state, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    public func isPaused(completion: @escaping (Bool?, Error?) -> Void) {
        executeWhenReady("player.getPaused()") { result, error in
            if let paused = result as? Bool {
                completion(paused, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func processQueuedMessages() {
        guard isReady else { return }
        
        for script in messageQueue {
            executeJavaScript(script)
        }
        messageQueue.removeAll()
    }
    
    private func handleReadyMessage(_ data: [String: Any]) {
        isReady = true
        
        let duration = data["duration"] as? TimeInterval ?? 0
        let shouldShowResumeDialog = data["shouldShowResumeDialog"] as? Bool ?? false
        
        delegate?.bridge(self, didReceiveReady: duration, shouldShowResumeDialog: shouldShowResumeDialog)
        
        // Process any queued messages
        processQueuedMessages()
    }
    
    private func handleTimeUpdateMessage(_ data: [String: Any]) {
        guard let currentTime = data["currentTime"] as? TimeInterval,
              let maxAllowed = data["maxAllowed"] as? TimeInterval else {
            return
        }
        
        delegate?.bridge(self, didUpdateTime: currentTime, maxAllowed: maxAllowed)
    }
    
    private func handleSeekRestrictedMessage(_ data: [String: Any]) {
        guard let attemptedTime = data["attemptedTime"] as? TimeInterval,
              let maxAllowed = data["maxAllowed"] as? TimeInterval else {
            return
        }
        
        let wasPlaying = data["wasPlaying"] as? Bool ?? false
        let actualPosition = data["actualPosition"] as? TimeInterval ?? maxAllowed
        
        delegate?.bridge(self, didRestrictSeek: attemptedTime, maxAllowed: maxAllowed, wasPlaying: wasPlaying, actualPosition: actualPosition)
    }
    
    private func handleSeekCompletedMessage(_ data: [String: Any]) {
        guard let time = data["time"] as? TimeInterval,
              let wasRequested = data["wasRequested"] as? TimeInterval else {
            return
        }
        
        let isPlaying = data["isPlaying"] as? Bool ?? false
        
        delegate?.bridge(self, didCompleteSeek: time, wasRequested: wasRequested, isPlaying: isPlaying)
    }
    
    private func handleSeekErrorMessage(_ data: [String: Any]) {
        let error = data["error"] as? String ?? "Unknown seek error"
        let requestedTime = data["requestedTime"] as? TimeInterval ?? 0
        
        delegate?.bridge(self, didSeekError: error, requestedTime: requestedTime)
    }
    
    private func handleErrorMessage(_ data: [String: Any]) {
        let errorMessage = data["error"] as? String ?? "Unknown error"
        let error = VimeoPlayerError.playbackFailed(errorMessage)
        
        delegate?.bridge(self, didEncounterError: error)
    }
}

// MARK: - WKScriptMessageHandler

extension VimeoPlayerWebViewBridge: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let type = messageBody["type"] as? String else {
            print("[VimeoPlayerBridge] Invalid message format")
            return
        }
        
        print("[VimeoPlayerBridge] Received message: \(type)")
        
        switch type {
        case "ready":
            handleReadyMessage(messageBody)
            
        case "timeUpdate":
            handleTimeUpdateMessage(messageBody)
            
        case "seekCompleted":
            handleSeekCompletedMessage(messageBody)
            
        case "seekError":
            handleSeekErrorMessage(messageBody)
            
        case "seekRestricted":
            handleSeekRestrictedMessage(messageBody)
            
        case "play":
            delegate?.bridge(self, didPlay: ())
            
        case "pause":
            delegate?.bridge(self, didPause: ())
            
        case "ended":
            delegate?.bridge(self, didEnd: ())
            
        case "error":
            handleErrorMessage(messageBody)
            
        default:
            print("[VimeoPlayerBridge] Unknown message type: \(type)")
        }
    }
}