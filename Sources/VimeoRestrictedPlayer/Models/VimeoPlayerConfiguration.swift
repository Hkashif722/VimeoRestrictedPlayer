//
//  VimeoPlayerConfiguration.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


import UIKit

/// Configuration object for VimeoRestrictedPlayer
public struct VimeoPlayerConfiguration {
    
    // MARK: - Basic Configuration
    
    /// The Vimeo video URL (format: https://vimeo.com/VIDEO_ID/HASH)
    public let videoURL: String
    
    /// Optional title for the video
    public var videoTitle: String?
    
    /// Last watched duration in seconds
    public var lastWatchedDuration: TimeInterval
    
    /// Whether the video has been completed
    public var isCompleted: Bool
    
    /// Whether to allow seeking beyond watched content
    public var allowsFullSeek: Bool
    
    /// Unique identifier for tracking (optional)
    public var videoID: String?
    
    // MARK: - UI Configuration
    
    /// Theme configuration
    public var theme: VimeoPlayerTheme
    
    /// Resume dialog options
    public var resumeOptions: ResumeOptions
    
    /// Seek restriction settings
    public var seekRestriction: SeekRestrictionOptions
    
    /// Localization strings
    public var localization: VimeoPlayerLocalization
    
    /// Whether to show the back button
    public var showsBackButton: Bool
    
    /// Whether to autoplay the video
    public var autoplay: Bool
    
    /// Whether to autoplay the video
    public var referrer : String?
    
    // MARK: - Initialization
    
    public init(
        videoURL: String,
        videoTitle: String? = nil,
        lastWatchedDuration: TimeInterval = 0,
        isCompleted: Bool = false,
        allowsFullSeek: Bool = true,
        videoID: String? = nil,
        referrer: String? = nil
    ) {
        self.videoURL = videoURL
        self.videoTitle = videoTitle
        self.lastWatchedDuration = lastWatchedDuration
        self.isCompleted = isCompleted
        self.allowsFullSeek = allowsFullSeek
        self.videoID = videoID
        self.referrer = referrer
        
        // Set defaults
        self.theme = .default
        self.resumeOptions = .default
        self.seekRestriction = .default
        self.localization = .default
        self.showsBackButton = true
        self.autoplay = false
    }
}

// MARK: - Resume Options

public struct ResumeOptions {
    /// Whether to show resume dialog
    public var showResumeDialog: Bool
    
    /// Minimum watched duration to show resume dialog (in seconds)
    public var minimumWatchedForResume: TimeInterval
    
    /// Resume dialog title
    public var resumeDialogTitle: String
    
    /// Resume dialog message (use {TIME} as placeholder for formatted time)
    public var resumeDialogMessage: String
    
    /// Continue button title
    public var continueButtonTitle: String
    
    /// Start over button title
    public var startOverButtonTitle: String
    
    public init(
        showResumeDialog: Bool = true,
        minimumWatchedForResume: TimeInterval = 5.0,
        resumeDialogTitle: String = "Resume Video",
        resumeDialogMessage: String = "Do you want to continue from where you left off ({TIME}) or start over?",
        continueButtonTitle: String = "Continue",
        startOverButtonTitle: String = "Start Over"
    ) {
        self.showResumeDialog = showResumeDialog
        self.minimumWatchedForResume = minimumWatchedForResume
        self.resumeDialogTitle = resumeDialogTitle
        self.resumeDialogMessage = resumeDialogMessage
        self.continueButtonTitle = continueButtonTitle
        self.startOverButtonTitle = startOverButtonTitle
    }
    
    public static let `default` = ResumeOptions()
}

// MARK: - Seek Restriction Options

public struct SeekRestrictionOptions {
    /// Whether seek restriction is enabled
    public var enabled: Bool
    
    /// Allow seeking to any previously watched position
    public var allowSeekToWatchedPosition: Bool
    
    /// Show alert when seek is restricted
    public var showAlertOnRestriction: Bool
    
    /// Alert title for seek restriction
    public var restrictionAlertTitle: String
    
    /// Alert message for seek restriction
    public var restrictionMessage: String
    
    /// Tolerance for seek restriction (in seconds)
    public var seekTolerance: TimeInterval
    
    public init(
        enabled: Bool = true,
        allowSeekToWatchedPosition: Bool = true,
        showAlertOnRestriction: Bool = true,
        restrictionAlertTitle: String = "Seek Restricted",
        restrictionMessage: String = "You can only seek up to the furthest point you've watched",
        seekTolerance: TimeInterval = 1.0
    ) {
        self.enabled = enabled
        self.allowSeekToWatchedPosition = allowSeekToWatchedPosition
        self.showAlertOnRestriction = showAlertOnRestriction
        self.restrictionAlertTitle = restrictionAlertTitle
        self.restrictionMessage = restrictionMessage
        self.seekTolerance = seekTolerance
    }
    
    public static let `default` = SeekRestrictionOptions()
}

// MARK: - Theme Configuration

public struct VimeoPlayerTheme {
    /// Background color of the player
    public var backgroundColor: UIColor
    
    /// Tint color for controls
    public var controlsTintColor: UIColor
    
    /// Loading indicator style
    public var loadingIndicatorStyle: UIActivityIndicatorView.Style
    
    /// Back button image
    public var backButtonImage: UIImage?
    
    /// Back button background color
    public var backButtonBackgroundColor: UIColor
    
    /// Back button size
    public var backButtonSize: CGSize
    
    /// Back button corner radius
    public var backButtonCornerRadius: CGFloat
    
    /// Back button position
    public var backButtonPosition: BackButtonPosition
    
    public init(
        backgroundColor: UIColor = .black,
        controlsTintColor: UIColor = .white,
        loadingIndicatorStyle: UIActivityIndicatorView.Style = .large,
        backButtonImage: UIImage? = nil,
        backButtonBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5),
        backButtonSize: CGSize = CGSize(width: 40, height: 40),
        backButtonCornerRadius: CGFloat = 20,
        backButtonPosition: BackButtonPosition = .topLeft()
    ) {
        self.backgroundColor = backgroundColor
        self.controlsTintColor = controlsTintColor
        self.loadingIndicatorStyle = loadingIndicatorStyle
        self.backButtonImage = backButtonImage ?? UIImage(systemName: "chevron.left")
        self.backButtonBackgroundColor = backButtonBackgroundColor
        self.backButtonSize = backButtonSize
        self.backButtonCornerRadius = backButtonCornerRadius
        self.backButtonPosition = backButtonPosition
    }
    
    public static let `default` = VimeoPlayerTheme()
}

// MARK: - Back Button Position

public enum BackButtonPosition {
    case topLeft(insets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 0))
    case topRight(insets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 16))
    case custom(frame: CGRect)
}

// MARK: - Localization

public struct VimeoPlayerLocalization {
    // Resume dialog
    public var resumeDialogTitle: String
    public var resumeDialogMessage: String
    public var continueButtonTitle: String
    public var startOverButtonTitle: String
    
    // Seek restriction
    public var seekRestrictionTitle: String
    public var seekRestrictionMessage: String
    
    // Exit confirmation
    public var exitConfirmationTitle: String
    public var exitConfirmationMessage: String
    public var exitButtonTitle: String
    public var cancelButtonTitle: String
    
    // Completion
    public var completionTitle: String
    public var completionMessage: String
    public var completionButtonTitle: String
    
    // Errors
    public var errorTitle: String
    public var errorRetryButton: String
    public var errorCancelButton: String
    
    public init(
        resumeDialogTitle: String = "Resume Video",
        resumeDialogMessage: String = "Do you want to continue from where you left off (%@) or start over?",
        continueButtonTitle: String = "Continue",
        startOverButtonTitle: String = "Start Over",
        seekRestrictionTitle: String = "Seek Restricted",
        seekRestrictionMessage: String = "You can only seek up to the furthest point you've watched (%@)",
        exitConfirmationTitle: String = "Exit Video?",
        exitConfirmationMessage: String = "Do you want to exit the video?",
        exitButtonTitle: String = "Exit",
        cancelButtonTitle: String = "Cancel",
        completionTitle: String = "Video Completed",
        completionMessage: String = "Congratulations! You have completed this video.",
        completionButtonTitle: String = "OK",
        errorTitle: String = "Error",
        errorRetryButton: String = "Retry",
        errorCancelButton: String = "Cancel"
    ) {
        self.resumeDialogTitle = resumeDialogTitle
        self.resumeDialogMessage = resumeDialogMessage
        self.continueButtonTitle = continueButtonTitle
        self.startOverButtonTitle = startOverButtonTitle
        self.seekRestrictionTitle = seekRestrictionTitle
        self.seekRestrictionMessage = seekRestrictionMessage
        self.exitConfirmationTitle = exitConfirmationTitle
        self.exitConfirmationMessage = exitConfirmationMessage
        self.exitButtonTitle = exitButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.completionTitle = completionTitle
        self.completionMessage = completionMessage
        self.completionButtonTitle = completionButtonTitle
        self.errorTitle = errorTitle
        self.errorRetryButton = errorRetryButton
        self.errorCancelButton = errorCancelButton
    }
    
    public static let `default` = VimeoPlayerLocalization()
}
