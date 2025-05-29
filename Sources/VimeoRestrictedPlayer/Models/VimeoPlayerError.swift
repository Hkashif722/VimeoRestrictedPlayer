//
//  VimeoPlayerError.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  VimeoPlayerError.swift
//  VimeoRestrictedPlayer
//
//  Created by Assistant on 28/05/25.
//

import Foundation

/// Comprehensive error types for VimeoRestrictedPlayer
public enum VimeoPlayerError: Error, Equatable, Codable {
    
    // MARK: - Configuration Errors
    case invalidURL(String)
    case invalidConfiguration(String)
    case missingVideoID
    case missingHash
    case unsupportedVideoFormat
    
    // MARK: - Network Errors
    case networkError(NetworkErrorInfo)
    case loadingFailed(LoadingErrorInfo)
    case connectionTimeout
    case serverError(Int, String?)
    case rateLimited
    case unauthorized
    case forbidden
    case notFound
    
    // MARK: - Playback Errors
    case playbackFailed(PlaybackErrorInfo)
    case seekFailed(SeekErrorInfo)
    case bufferingTimeout
    case codecNotSupported
    case drmError(String?)
    case videoUnavailable
    case geoblocked
    case domainRestricted
    
    // MARK: - JavaScript Bridge Errors
    case javascriptError(JavaScriptErrorInfo)
    case webViewError(WebViewErrorInfo)
    case bridgeNotReady
    case messageHandlingFailed(String)
    
    // MARK: - User Interaction Errors
    case seekRestricted(SeekRestrictionInfo)
    case controlsDisabled
    case userPermissionDenied(String)
    case backgroundPlaybackDisabled
    
    // MARK: - System Errors
    case memoryWarning
    case lowDiskSpace
    case deviceNotSupported
    case osVersionNotSupported(String)
    case appBackgrounded
    
    // MARK: - Custom Errors
    case custom(CustomErrorInfo)
    case unknown(String)
    
    // MARK: - Error Information Structs
    
    public struct NetworkErrorInfo: Codable, Equatable {
        public let underlyingError: String
        public let errorCode: Int?
        public let domain: String?
        public let isConnectivityIssue: Bool
        public let retryable: Bool
        
        public init(underlyingError: String, errorCode: Int? = nil, domain: String? = nil, isConnectivityIssue: Bool = false, retryable: Bool = true) {
            self.underlyingError = underlyingError
            self.errorCode = errorCode
            self.domain = domain
            self.isConnectivityIssue = isConnectivityIssue
            self.retryable = retryable
        }
        
        public init(from error: Error) {
            let nsError = error as NSError
            self.underlyingError = nsError.localizedDescription
            self.errorCode = nsError.code
            self.domain = nsError.domain
            self.isConnectivityIssue = nsError.domain == NSURLErrorDomain && [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorTimedOut
            ].contains(nsError.code)
            self.retryable = true
        }
    }
    
    public struct LoadingErrorInfo: Codable, Equatable {
        public let phase: LoadingPhase
        public let underlyingError: String
        public let resourceURL: String?
        public let httpStatusCode: Int?
        public let retryCount: Int
        
        public init(phase: LoadingPhase, underlyingError: String, resourceURL: String? = nil, httpStatusCode: Int? = nil, retryCount: Int = 0) {
            self.phase = phase
            self.underlyingError = underlyingError
            self.resourceURL = resourceURL
            self.httpStatusCode = httpStatusCode
            self.retryCount = retryCount
        }
    }
    
    public enum LoadingPhase: String, Codable, CaseIterable {
        case initialization = "initialization"
        case htmlLoading = "html_loading"
        case scriptLoading = "script_loading"
        case playerReady = "player_ready"
        case videoMetadata = "video_metadata"
    }
    
    public struct PlaybackErrorInfo: Codable, Equatable {
        public let errorType: PlaybackErrorType
        public let errorMessage: String
        public let currentTime: TimeInterval?
        public let duration: TimeInterval?
        public let quality: String?
        public let mediaSessionInfo: [String: String]?
        
        public init(errorType: PlaybackErrorType, errorMessage: String, currentTime: TimeInterval? = nil, duration: TimeInterval? = nil, quality: String? = nil, mediaSessionInfo: [String: String]? = nil) {
            self.errorType = errorType
            self.errorMessage = errorMessage
            self.currentTime = currentTime
            self.duration = duration
            self.quality = quality
            self.mediaSessionInfo = mediaSessionInfo
        }
    }
    
    public enum PlaybackErrorType: String, Codable, CaseIterable {
        case mediaLoadFailed = "media_load_failed"
        case decodingError = "decoding_error"
        case sourceError = "source_error"
        case networkStall = "network_stall"
        case aborted = "aborted"
        case generic = "generic"
    }
    
    public struct SeekErrorInfo: Codable, Equatable {
        public let requestedTime: TimeInterval
        public let currentTime: TimeInterval
        public let maxAllowedTime: TimeInterval?
        public let restrictionReason: SeekRestrictionReason
        public let isUserInitiated: Bool
        
        public init(requestedTime: TimeInterval, currentTime: TimeInterval, maxAllowedTime: TimeInterval? = nil, restrictionReason: SeekRestrictionReason, isUserInitiated: Bool = true) {
            self.requestedTime = requestedTime
            self.currentTime = currentTime
            self.maxAllowedTime = maxAllowedTime
            self.restrictionReason = restrictionReason
            self.isUserInitiated = isUserInitiated
        }
    }
    
    public struct SeekRestrictionInfo: Codable, Equatable {
        public let attemptedTime: TimeInterval
        public let maxAllowedTime: TimeInterval
        public let currentTime: TimeInterval
        public let restrictionType: SeekRestrictionType
        public let message: String?
        
        public init(attemptedTime: TimeInterval, maxAllowedTime: TimeInterval, currentTime: TimeInterval, restrictionType: SeekRestrictionType, message: String? = nil) {
            self.attemptedTime = attemptedTime
            self.maxAllowedTime = maxAllowedTime
            self.currentTime = currentTime
            self.restrictionType = restrictionType
            self.message = message
        }
    }
    
    public enum SeekRestrictionType: String, Codable, CaseIterable {
        case watchProgress = "watch_progress"
        case contentLock = "content_lock"
        case timeLimit = "time_limit"
        case subscription = "subscription"
        case custom = "custom"
    }
    
    public enum SeekRestrictionReason: String, Codable, CaseIterable {
        case beyondWatchedContent = "beyond_watched_content"
        case invalidTime = "invalid_time"
        case playerNotReady = "player_not_ready"
        case technicalError = "technical_error"
        case userPermission = "user_permission"
    }
    
    public struct JavaScriptErrorInfo: Codable, Equatable {
        public let errorMessage: String
        public let scriptFunction: String?
        public let lineNumber: Int?
        public let stackTrace: String?
        public let errorType: JavaScriptErrorType
        
        public init(errorMessage: String, scriptFunction: String? = nil, lineNumber: Int? = nil, stackTrace: String? = nil, errorType: JavaScriptErrorType = .runtime) {
            self.errorMessage = errorMessage
            self.scriptFunction = scriptFunction
            self.lineNumber = lineNumber
            self.stackTrace = stackTrace
            self.errorType = errorType
        }
    }
    
    public enum JavaScriptErrorType: String, Codable, CaseIterable {
        case syntax = "syntax"
        case runtime = "runtime"
        case network = "network"
        case permission = "permission"
        case vimeoAPI = "vimeo_api"
    }
    
    public struct WebViewErrorInfo: Codable, Equatable {
        public let errorDescription: String
        public let errorCode: Int?
        public let failingURL: String?
        public let isProvisionalNavigation: Bool
        
        public init(errorDescription: String, errorCode: Int? = nil, failingURL: String? = nil, isProvisionalNavigation: Bool = false) {
            self.errorDescription = errorDescription
            self.errorCode = errorCode
            self.failingURL = failingURL
            self.isProvisionalNavigation = isProvisionalNavigation
        }
        
        public init(from error: Error, failingURL: String? = nil, isProvisionalNavigation: Bool = false) {
            let nsError = error as NSError
            self.errorDescription = nsError.localizedDescription
            self.errorCode = nsError.code
            self.failingURL = failingURL
            self.isProvisionalNavigation = isProvisionalNavigation
        }
    }
    
    public struct CustomErrorInfo: Codable, Equatable {
        public let code: String
        public let message: String
        public let context: [String: String]?
        public let userInfo: [String: String]?
        public let severity: ErrorSeverity
        public let isRecoverable: Bool
        
        public init(code: String, message: String, context: [String: String]? = nil, userInfo: [String: String]? = nil, severity: ErrorSeverity = .error, isRecoverable: Bool = true) {
            self.code = code
            self.message = message
            self.context = context
            self.userInfo = userInfo
            self.severity = severity
            self.isRecoverable = isRecoverable
        }
    }
    
    public enum ErrorSeverity: String, Codable, CaseIterable {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case critical = "critical"
    }
}

// MARK: - LocalizedError Conformance

extension VimeoPlayerError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        // Configuration Errors
        case .invalidURL(let url):
            return "Invalid Vimeo URL: \(url). Please provide a valid Vimeo video URL."
        case .invalidConfiguration(let details):
            return "Invalid player configuration: \(details)"
        case .missingVideoID:
            return "Video ID is missing from the URL. Please check the Vimeo URL format."
        case .missingHash:
            return "Video hash is missing from the URL. This video may require authentication."
        case .unsupportedVideoFormat:
            return "This video format is not supported on this device."
            
        // Network Errors
        case .networkError(let info):
            return info.isConnectivityIssue ? "No internet connection available. Please check your network settings." : "Network error: \(info.underlyingError)"
        case .loadingFailed(let info):
            return "Failed to load video during \(info.phase.rawValue): \(info.underlyingError)"
        case .connectionTimeout:
            return "Connection timed out. Please check your internet connection and try again."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown server error")"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .unauthorized:
            return "This video requires authentication. Please log in to view this content."
        case .forbidden:
            return "You don't have permission to view this video."
        case .notFound:
            return "Video not found. The video may have been removed or the URL is incorrect."
            
        // Playback Errors
        case .playbackFailed(let info):
            return "Playback failed: \(info.errorMessage)"
        case .seekFailed(let info):
            return "Seek failed: Cannot seek to \(TimeFormatter.format(seconds: info.requestedTime))"
        case .bufferingTimeout:
            return "Video buffering timed out. Please check your internet connection."
        case .codecNotSupported:
            return "Video codec not supported on this device."
        case .drmError(let details):
            return "DRM error: \(details ?? "Unknown DRM error")"
        case .videoUnavailable:
            return "This video is currently unavailable."
        case .geoblocked:
            return "This video is not available in your region."
        case .domainRestricted:
            return "This video cannot be played on this domain."
            
        // JavaScript Bridge Errors
        case .javascriptError(let info):
            return "JavaScript error: \(info.errorMessage)"
        case .webViewError(let info):
            return "WebView error: \(info.errorDescription)"
        case .bridgeNotReady:
            return "Player bridge is not ready. Please wait for the player to initialize."
        case .messageHandlingFailed(let details):
            return "Message handling failed: \(details)"
            
        // User Interaction Errors
        case .seekRestricted(let info):
            return info.message ?? "Seeking is restricted. You can only seek to previously watched content."
        case .controlsDisabled:
            return "Player controls are currently disabled."
        case .userPermissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .backgroundPlaybackDisabled:
            return "Background playback is not supported for this content."
            
        // System Errors
        case .memoryWarning:
            return "Low memory warning. The video may pause or stop to preserve system performance."
        case .lowDiskSpace:
            return "Insufficient storage space for video playback."
        case .deviceNotSupported:
            return "This device is not supported for video playback."
        case .osVersionNotSupported(let version):
            return "iOS \(version) or later is required for video playback."
        case .appBackgrounded:
            return "Video playback paused because the app moved to background."
            
        // Custom and Unknown Errors
        case .custom(let info):
            return info.message
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkError(let info) where info.isConnectivityIssue:
            return "No internet connection"
        case .loadingFailed(let info):
            return "Loading failed during \(info.phase.rawValue)"
        case .playbackFailed(let info):
            return "Playback error: \(info.errorType.rawValue)"
        case .seekRestricted(let info):
            return "Seek restricted: \(info.restrictionType.rawValue)"
        case .javascriptError(let info):
            return "JavaScript \(info.errorType.rawValue) error"
        default:
            return nil
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError(let info) where info.retryable:
            return "Check your internet connection and try again."
        case .loadingFailed(let info) where info.retryCount < 3:
            return "Try reloading the video."
        case .connectionTimeout:
            return "Check your internet connection and try again."
        case .bufferingTimeout:
            return "Try lowering the video quality or check your internet connection."
        case .seekRestricted:
            return "Watch more of the video to unlock additional content."
        case .unauthorized:
            return "Please log in to access this content."
        case .notFound:
            return "Check the video URL and try again."
        case .custom(let info) where info.isRecoverable:
            return "Try again or contact support if the problem persists."
        default:
            return "Try restarting the video or contact support if the problem persists."
        }
    }
}

// MARK: - Error Analysis and Utilities

extension VimeoPlayerError {
    
    /// Whether this error can be automatically retried
    public var isRetryable: Bool {
        switch self {
        case .networkError(let info):
            return info.retryable
        case .loadingFailed(let info):
            return info.retryCount < 3
        case .connectionTimeout, .bufferingTimeout, .serverError:
            return true
        case .custom(let info):
            return info.isRecoverable
        case .memoryWarning, .appBackgrounded:
            return true
        default:
            return false
        }
    }
    
    /// Whether this error requires user intervention
    public var requiresUserIntervention: Bool {
        switch self {
        case .unauthorized, .forbidden, .userPermissionDenied, .seekRestricted:
            return true
        case .invalidURL, .invalidConfiguration, .missingVideoID, .missingHash:
            return true
        case .custom(let info):
            return !info.isRecoverable
        default:
            return false
        }
    }
    
    /// Error severity level
    public var severity: ErrorSeverity {
        switch self {
        case .memoryWarning, .appBackgrounded:
            return .warning
        case .bufferingTimeout, .seekRestricted:
            return .info
        case .deviceNotSupported, .osVersionNotSupported, .codecNotSupported:
            return .critical
        case .custom(let info):
            return info.severity
        default:
            return .error
        }
    }
    
    /// Error category for analytics and debugging
    public var category: ErrorCategory {
        switch self {
        case .invalidURL, .invalidConfiguration, .missingVideoID, .missingHash, .unsupportedVideoFormat:
            return .configuration
        case .networkError, .loadingFailed, .connectionTimeout, .serverError, .rateLimited, .unauthorized, .forbidden, .notFound:
            return .network
        case .playbackFailed, .seekFailed, .bufferingTimeout, .codecNotSupported, .drmError, .videoUnavailable, .geoblocked, .domainRestricted:
            return .playback
        case .javascriptError, .webViewError, .bridgeNotReady, .messageHandlingFailed:
            return .javascript
        case .seekRestricted, .controlsDisabled, .userPermissionDenied, .backgroundPlaybackDisabled:
            return .userInteraction
        case .memoryWarning, .lowDiskSpace, .deviceNotSupported, .osVersionNotSupported, .appBackgrounded:
            return .system
        case .custom, .unknown:
            return .custom
        }
    }
    
    /// Error code for logging and analytics
    public var errorCode: String {
        switch self {
        case .invalidURL: return "VPE001"
        case .invalidConfiguration: return "VPE002"
        case .missingVideoID: return "VPE003"
        case .missingHash: return "VPE004"
        case .unsupportedVideoFormat: return "VPE005"
        case .networkError: return "VPE101"
        case .loadingFailed: return "VPE102"
        case .connectionTimeout: return "VPE103"
        case .serverError: return "VPE104"
        case .rateLimited: return "VPE105"
        case .unauthorized: return "VPE106"
        case .forbidden: return "VPE107"
        case .notFound: return "VPE108"
        case .playbackFailed: return "VPE201"
        case .seekFailed: return "VPE202"
        case .bufferingTimeout: return "VPE203"
        case .codecNotSupported: return "VPE204"
        case .drmError: return "VPE205"
        case .videoUnavailable: return "VPE206"
        case .geoblocked: return "VPE207"
        case .domainRestricted: return "VPE208"
        case .javascriptError: return "VPE301"
        case .webViewError: return "VPE302"
        case .bridgeNotReady: return "VPE303"
        case .messageHandlingFailed: return "VPE304"
        case .seekRestricted: return "VPE401"
        case .controlsDisabled: return "VPE402"
        case .userPermissionDenied: return "VPE403"
        case .backgroundPlaybackDisabled: return "VPE404"
        case .memoryWarning: return "VPE501"
        case .lowDiskSpace: return "VPE502"
        case .deviceNotSupported: return "VPE503"
        case .osVersionNotSupported: return "VPE504"
        case .appBackgrounded: return "VPE505"
        case .custom(let info): return "VPE900_\(info.code)"
        case .unknown: return "VPE999"
        }
    }
}

public enum ErrorCategory: String, Codable, CaseIterable {
    case configuration = "configuration"
    case network = "network"
    case playback = "playback"
    case javascript = "javascript"
    case userInteraction = "user_interaction"
    case system = "system"
    case custom = "custom"
}

// MARK: - Error Factory

public struct VimeoPlayerErrorFactory {
    
    public static func networkError(from error: Error) -> VimeoPlayerError {
        let networkInfo = VimeoPlayerError.NetworkErrorInfo(from: error)
        return .networkError(networkInfo)
    }
    
    public static func loadingError(phase: VimeoPlayerError.LoadingPhase, error: Error, retryCount: Int = 0) -> VimeoPlayerError {
        let loadingInfo = VimeoPlayerError.LoadingErrorInfo(
            phase: phase,
            underlyingError: error.localizedDescription,
            retryCount: retryCount
        )
        return .loadingFailed(loadingInfo)
    }
    
    public static func playbackError(type: VimeoPlayerError.PlaybackErrorType, message: String, currentTime: TimeInterval? = nil) -> VimeoPlayerError {
        let playbackInfo = VimeoPlayerError.PlaybackErrorInfo(
            errorType: type,
            errorMessage: message,
            currentTime: currentTime
        )
        return .playbackFailed(playbackInfo)
    }
    
    public static func seekError(requestedTime: TimeInterval, currentTime: TimeInterval, maxAllowed: TimeInterval?, reason: VimeoPlayerError.SeekRestrictionReason) -> VimeoPlayerError {
        let seekInfo = VimeoPlayerError.SeekErrorInfo(
            requestedTime: requestedTime,
            currentTime: currentTime,
            maxAllowedTime: maxAllowed,
            restrictionReason: reason
        )
        return .seekFailed(seekInfo)
    }
    
    public static func javascriptError(message: String, function: String? = nil, type: VimeoPlayerError.JavaScriptErrorType = .runtime) -> VimeoPlayerError {
        let jsInfo = VimeoPlayerError.JavaScriptErrorInfo(
            errorMessage: message,
            scriptFunction: function,
            errorType: type
        )
        return .javascriptError(jsInfo)
    }
    
    public static func webViewError(from error: Error, failingURL: String? = nil, isProvisional: Bool = false) -> VimeoPlayerError {
        let webViewInfo = VimeoPlayerError.WebViewErrorInfo(
            from: error,
            failingURL: failingURL,
            isProvisionalNavigation: isProvisional
        )
        return .webViewError(webViewInfo)
    }
    
    public static func seekRestrictionError(attempted: TimeInterval, maxAllowed: TimeInterval, current: TimeInterval, type: VimeoPlayerError.SeekRestrictionType = .watchProgress) -> VimeoPlayerError {
        let restrictionInfo = VimeoPlayerError.SeekRestrictionInfo(
            attemptedTime: attempted,
            maxAllowedTime: maxAllowed,
            currentTime: current,
            restrictionType: type
        )
        return .seekRestricted(restrictionInfo)
    }
    
    public static func customError(code: String, message: String, severity: VimeoPlayerError.ErrorSeverity = .error, recoverable: Bool = true, context: [String: String]? = nil) -> VimeoPlayerError {
        let customInfo = VimeoPlayerError.CustomErrorInfo(
            code: code,
            message: message,
            context: context,
            severity: severity,
            isRecoverable: recoverable
        )
        return .custom(customInfo)
    }
}

// MARK: - Error Logging and Analytics

public protocol VimeoPlayerErrorReporter {
    func reportError(_ error: VimeoPlayerError, context: [String: Any]?)
    func reportErrorRecovery(_ error: VimeoPlayerError, recoveryMethod: String, success: Bool)
}

public class VimeoPlayerErrorLogger {
    
    private let reporter: VimeoPlayerErrorReporter?
    private var errorHistory: [VimeoPlayerError] = []
    private let maxHistorySize = 50
    
    public init(reporter: VimeoPlayerErrorReporter? = nil) {
        self.reporter = reporter
    }
    
    public func log(_ error: VimeoPlayerError, context: [String: Any]? = nil) {
        // Add to history
        errorHistory.append(error)
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst()
        }
        
        // Report to analytics
        reporter?.reportError(error, context: context)
        
        // Log to console in debug builds
        #if DEBUG
        print("🔴 VimeoPlayerError [\(error.errorCode)]: \(error.localizedDescription)")
        if let context = context {
            print("📋 Context: \(context)")
        }
        #endif
    }
    
    public func logRecovery(_ error: VimeoPlayerError, method: String, success: Bool) {
        reporter?.reportErrorRecovery(error, recoveryMethod: method, success: success)
        
        #if DEBUG
        let status = success ? "✅" : "❌"
        print("\(status) Recovery attempt for [\(error.errorCode)] using \(method): \(success ? "Success" : "Failed")")
        #endif
    }
    
    public func getErrorHistory() -> [VimeoPlayerError] {
        return errorHistory
    }
    
    public func clearHistory() {
        errorHistory.removeAll()
    }
}