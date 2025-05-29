//
//  VimeoPlayerTheme.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  VimeoPlayerTheme.swift
//  VimeoRestrictedPlayer
//
//  Created by Assistant on 28/05/25.
//

import UIKit

// MARK: - Enhanced Theme System

/// Comprehensive theme configuration for VimeoRestrictedPlayer
public struct VimeoPlayerTheme {
    
    // MARK: - Core Colors
    public var colors: ColorTheme
    
    // MARK: - Typography
    public var typography: TypographyTheme
    
    // MARK: - UI Components
    public var controls: ControlsTheme
    public var alerts: AlertTheme
    public var loading: LoadingTheme
    
    // MARK: - Animations
    public var animations: AnimationTheme
    
    // MARK: - Layout
    public var layout: LayoutTheme
    
    public init(
        colors: ColorTheme = .default,
        typography: TypographyTheme = .default,
        controls: ControlsTheme = .default,
        alerts: AlertTheme = .default,
        loading: LoadingTheme = .default,
        animations: AnimationTheme = .default,
        layout: LayoutTheme = .default
    ) {
        self.colors = colors
        self.typography = typography
        self.controls = controls
        self.alerts = alerts
        self.loading = loading
        self.animations = animations
        self.layout = layout
    }
    
    public static let `default` = VimeoPlayerTheme()
}

// MARK: - Color Theme

public struct ColorTheme {
    // Background colors
    public var primaryBackground: UIColor
    public var secondaryBackground: UIColor
    public var surfaceBackground: UIColor
    
    // Text colors
    public var primaryText: UIColor
    public var secondaryText: UIColor
    public var disabledText: UIColor
    
    // Accent colors
    public var accent: UIColor
    public var accentSecondary: UIColor
    public var error: UIColor
    public var warning: UIColor
    public var success: UIColor
    
    // Control colors
    public var controlsBackground: UIColor
    public var controlsTint: UIColor
    public var controlsDisabled: UIColor
    
    // Overlay colors
    public var overlayBackground: UIColor
    public var shadowColor: UIColor
    
    public init(
        primaryBackground: UIColor = .black,
        secondaryBackground: UIColor = UIColor.black.withAlphaComponent(0.8),
        surfaceBackground: UIColor = UIColor.white.withAlphaComponent(0.1),
        primaryText: UIColor = .white,
        secondaryText: UIColor = UIColor.white.withAlphaComponent(0.8),
        disabledText: UIColor = UIColor.white.withAlphaComponent(0.4),
        accent: UIColor = .systemBlue,
        accentSecondary: UIColor = .systemIndigo,
        error: UIColor = .systemRed,
        warning: UIColor = .systemYellow,
        success: UIColor = .systemGreen,
        controlsBackground: UIColor = UIColor.black.withAlphaComponent(0.5),
        controlsTint: UIColor = .white,
        controlsDisabled: UIColor = UIColor.white.withAlphaComponent(0.3),
        overlayBackground: UIColor = UIColor.black.withAlphaComponent(0.6),
        shadowColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    ) {
        self.primaryBackground = primaryBackground
        self.secondaryBackground = secondaryBackground
        self.surfaceBackground = surfaceBackground
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.disabledText = disabledText
        self.accent = accent
        self.accentSecondary = accentSecondary
        self.error = error
        self.warning = warning
        self.success = success
        self.controlsBackground = controlsBackground
        self.controlsTint = controlsTint
        self.controlsDisabled = controlsDisabled
        self.overlayBackground = overlayBackground
        self.shadowColor = shadowColor
    }
    
    public static let `default` = ColorTheme()
    
    // MARK: - Predefined Color Schemes
    
    public static let dark = ColorTheme()
    
    public static let light = ColorTheme(
        primaryBackground: .white,
        secondaryBackground: UIColor.white.withAlphaComponent(0.9),
        surfaceBackground: UIColor.black.withAlphaComponent(0.1),
        primaryText: .black,
        secondaryText: UIColor.black.withAlphaComponent(0.8),
        disabledText: UIColor.black.withAlphaComponent(0.4),
        controlsBackground: UIColor.white.withAlphaComponent(0.8),
        controlsTint: .black,
        controlsDisabled: UIColor.black.withAlphaComponent(0.3),
        overlayBackground: UIColor.white.withAlphaComponent(0.6),
        shadowColor: UIColor.black.withAlphaComponent(0.2)
    )
    
    public static let cinema = ColorTheme(
        primaryBackground: UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0),
        accent: UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
    )
}

// MARK: - Typography Theme

public struct TypographyTheme {
    public var titleFont: UIFont
    public var bodyFont: UIFont
    public var captionFont: UIFont
    public var buttonFont: UIFont
    public var timerFont: UIFont
    
    public init(
        titleFont: UIFont = .systemFont(ofSize: 18, weight: .semibold),
        bodyFont: UIFont = .systemFont(ofSize: 16, weight: .regular),
        captionFont: UIFont = .systemFont(ofSize: 14, weight: .regular),
        buttonFont: UIFont = .systemFont(ofSize: 16, weight: .medium),
        timerFont: UIFont = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    ) {
        self.titleFont = titleFont
        self.bodyFont = bodyFont
        self.captionFont = captionFont
        self.buttonFont = buttonFont
        self.timerFont = timerFont
    }
    
    public static let `default` = TypographyTheme()
}

// MARK: - Controls Theme

public struct ControlsTheme {
    // Back button
    public var backButton: BackButtonTheme
    
    // Play/Pause button
    public var playButton: PlayButtonTheme
    
    // Progress bar
    public var progressBar: ProgressBarTheme
    
    // Volume controls
    public var volumeControls: VolumeControlsTheme
    
    // Fullscreen controls
    public var fullscreenButton: FullscreenButtonTheme
    
    public init(
        backButton: BackButtonTheme = .default,
        playButton: PlayButtonTheme = .default,
        progressBar: ProgressBarTheme = .default,
        volumeControls: VolumeControlsTheme = .default,
        fullscreenButton: FullscreenButtonTheme = .default
    ) {
        self.backButton = backButton
        self.playButton = playButton
        self.progressBar = progressBar
        self.volumeControls = volumeControls
        self.fullscreenButton = fullscreenButton
    }
    
    public static let `default` = ControlsTheme()
}

public struct BackButtonTheme {
    public var size: CGSize
    public var cornerRadius: CGFloat
    public var backgroundColor: UIColor
    public var image: UIImage?
    public var position: BackButtonPosition
    public var shadow: ShadowStyle?
    
    public init(
        size: CGSize = CGSize(width: 40, height: 40),
        cornerRadius: CGFloat = 20,
        backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5),
        image: UIImage? = UIImage(systemName: "chevron.left"),
        position: BackButtonPosition = .topLeft(),
        shadow: ShadowStyle? = ShadowStyle.default
    ) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.image = image
        self.position = position
        self.shadow = shadow
    }
    
    public static let `default` = BackButtonTheme()
}

public struct PlayButtonTheme {
    public var size: CGSize
    public var cornerRadius: CGFloat
    public var backgroundColor: UIColor
    public var playImage: UIImage?
    public var pauseImage: UIImage?
    public var shadow: ShadowStyle?
    
    public init(
        size: CGSize = CGSize(width: 60, height: 60),
        cornerRadius: CGFloat = 30,
        backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7),
        playImage: UIImage? = UIImage(systemName: "play.fill"),
        pauseImage: UIImage? = UIImage(systemName: "pause.fill"),
        shadow: ShadowStyle? = ShadowStyle.default
    ) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.playImage = playImage
        self.pauseImage = pauseImage
        self.shadow = shadow
    }
    
    public static let `default` = PlayButtonTheme()
}

public struct ProgressBarTheme {
    public var height: CGFloat
    public var trackColor: UIColor
    public var progressColor: UIColor
    public var watchedColor: UIColor
    public var thumbColor: UIColor
    public var thumbSize: CGSize
    public var cornerRadius: CGFloat
    
    public init(
        height: CGFloat = 4,
        trackColor: UIColor = UIColor.white.withAlphaComponent(0.3),
        progressColor: UIColor = .white,
        watchedColor: UIColor = UIColor.white.withAlphaComponent(0.6),
        thumbColor: UIColor = .white,
        thumbSize: CGSize = CGSize(width: 16, height: 16),
        cornerRadius: CGFloat = 2
    ) {
        self.height = height
        self.trackColor = trackColor
        self.progressColor = progressColor
        self.watchedColor = watchedColor
        self.thumbColor = thumbColor
        self.thumbSize = thumbSize
        self.cornerRadius = cornerRadius
    }
    
    public static let `default` = ProgressBarTheme()
}

public struct VolumeControlsTheme {
    public var buttonSize: CGSize
    public var sliderHeight: CGFloat
    public var trackColor: UIColor
    public var volumeColor: UIColor
    public var muteImage: UIImage?
    public var volumeImage: UIImage?
    
    public init(
        buttonSize: CGSize = CGSize(width: 30, height: 30),
        sliderHeight: CGFloat = 4,
        trackColor: UIColor = UIColor.white.withAlphaComponent(0.3),
        volumeColor: UIColor = .white,
        muteImage: UIImage? = UIImage(systemName: "speaker.slash.fill"),
        volumeImage: UIImage? = UIImage(systemName: "speaker.wave.2.fill")
    ) {
        self.buttonSize = buttonSize
        self.sliderHeight = sliderHeight
        self.trackColor = trackColor
        self.volumeColor = volumeColor
        self.muteImage = muteImage
        self.volumeImage = volumeImage
    }
    
    public static let `default` = VolumeControlsTheme()
}

public struct FullscreenButtonTheme {
    public var size: CGSize
    public var enterImage: UIImage?
    public var exitImage: UIImage?
    
    public init(
        size: CGSize = CGSize(width: 30, height: 30),
        enterImage: UIImage? = UIImage(systemName: "arrow.up.left.and.arrow.down.right"),
        exitImage: UIImage? = UIImage(systemName: "arrow.down.right.and.arrow.up.left")
    ) {
        self.size = size
        self.enterImage = enterImage
        self.exitImage = exitImage
    }
    
    public static let `default` = FullscreenButtonTheme()
}

// MARK: - Alert Theme

public struct AlertTheme {
    public var backgroundColor: UIColor
    public var cornerRadius: CGFloat
    public var borderWidth: CGFloat
    public var borderColor: UIColor
    public var shadow: ShadowStyle?
    public var animation: AlertAnimationStyle
    
    public init(
        backgroundColor: UIColor = UIColor.systemBackground,
        cornerRadius: CGFloat = 12,
        borderWidth: CGFloat = 0,
        borderColor: UIColor = .clear,
        shadow: ShadowStyle? = ShadowStyle.medium,
        animation: AlertAnimationStyle = .fade
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.shadow = shadow
        self.animation = animation
    }
    
    public static let `default` = AlertTheme()
}

public enum AlertAnimationStyle {
    case fade
    case slide
    case bounce
    case scale
}

// MARK: - Loading Theme

public struct LoadingTheme {
    public var style: UIActivityIndicatorView.Style
    public var color: UIColor
    public var backgroundColor: UIColor?
    public var size: LoadingSize
    public var animation: LoadingAnimationStyle
    
    public init(
        style: UIActivityIndicatorView.Style = .large,
        color: UIColor = .white,
        backgroundColor: UIColor? = nil,
        size: LoadingSize = .medium,
        animation: LoadingAnimationStyle = .fade
    ) {
        self.style = style
        self.color = color
        self.backgroundColor = backgroundColor
        self.size = size
        self.animation = animation
    }
    
    public static let `default` = LoadingTheme()
}

public enum LoadingSize {
    case small
    case medium
    case large
    case custom(CGSize)
    
    public var size: CGSize {
        switch self {
        case .small: return CGSize(width: 20, height: 20)
        case .medium: return CGSize(width: 40, height: 40)
        case .large: return CGSize(width: 60, height: 60)
        case .custom(let size): return size
        }
    }
}

public enum LoadingAnimationStyle {
    case fade
    case pulse
    case rotate
    case bounce
}

// MARK: - Animation Theme

public struct AnimationTheme {
    public var controlsFadeInDuration: TimeInterval
    public var controlsFadeOutDuration: TimeInterval
    public var controlsAnimationDelay: TimeInterval
    public var progressUpdateInterval: TimeInterval
    public var seekAnimationDuration: TimeInterval
    public var alertAnimationDuration: TimeInterval
    
    public init(
        controlsFadeInDuration: TimeInterval = 0.3,
        controlsFadeOutDuration: TimeInterval = 0.3,
        controlsAnimationDelay: TimeInterval = 3.0,
        progressUpdateInterval: TimeInterval = 0.1,
        seekAnimationDuration: TimeInterval = 0.2,
        alertAnimationDuration: TimeInterval = 0.3
    ) {
        self.controlsFadeInDuration = controlsFadeInDuration
        self.controlsFadeOutDuration = controlsFadeOutDuration
        self.controlsAnimationDelay = controlsAnimationDelay
        self.progressUpdateInterval = progressUpdateInterval
        self.seekAnimationDuration = seekAnimationDuration
        self.alertAnimationDuration = alertAnimationDuration
    }
    
    public static let `default` = AnimationTheme()
}

// MARK: - Layout Theme

public struct LayoutTheme {
    public var margins: UIEdgeInsets
    public var controlsSpacing: CGFloat
    public var minimumTapArea: CGSize
    public var safeAreaInsets: UIEdgeInsets
    
    public init(
        margins: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
        controlsSpacing: CGFloat = 16,
        minimumTapArea: CGSize = CGSize(width: 44, height: 44),
        safeAreaInsets: UIEdgeInsets = .zero
    ) {
        self.margins = margins
        self.controlsSpacing = controlsSpacing
        self.minimumTapArea = minimumTapArea
        self.safeAreaInsets = safeAreaInsets
    }
    
    public static let `default` = LayoutTheme()
}

// MARK: - Supporting Types

public struct ShadowStyle {
    public var color: UIColor
    public var offset: CGSize
    public var radius: CGFloat
    public var opacity: Float
    
    public init(color: UIColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        self.color = color
        self.offset = offset
        self.radius = radius
        self.opacity = opacity
    }
    
    public static let `default` = ShadowStyle(
        color: .black,
        offset: CGSize(width: 0, height: 2),
        radius: 4,
        opacity: 0.3
    )
    
    public static let medium = ShadowStyle(
        color: .black,
        offset: CGSize(width: 0, height: 4),
        radius: 8,
        opacity: 0.3
    )
    
    public static let large = ShadowStyle(
        color: .black,
        offset: CGSize(width: 0, height: 8),
        radius: 16,
        opacity: 0.3
    )
}

// MARK: - Theme Extensions

extension VimeoPlayerTheme {
    
    /// Apply shadow to a view
    public func applyShadow(_ shadow: ShadowStyle?, to view: UIView) {
        guard let shadow = shadow else {
            view.layer.shadowOpacity = 0
            return
        }
        
        view.layer.shadowColor = shadow.color.cgColor
        view.layer.shadowOffset = shadow.offset
        view.layer.shadowRadius = shadow.radius
        view.layer.shadowOpacity = shadow.opacity
    }
    
    /// Apply theme to a button
    public func applyButtonStyle(to button: UIButton, style: BackButtonTheme) {
        button.backgroundColor = style.backgroundColor
        button.layer.cornerRadius = style.cornerRadius
        button.setImage(style.image, for: .normal)
        button.tintColor = colors.controlsTint
        
        if let shadow = style.shadow {
            applyShadow(shadow, to: button)
        }
    }
}

// MARK: - Backward Compatibility

extension VimeoPlayerTheme {
    
    /// Legacy properties for backward compatibility
    public var backgroundColor: UIColor {
        get { colors.primaryBackground }
        set { colors.primaryBackground = newValue }
    }
    
    public var controlsTintColor: UIColor {
        get { colors.controlsTint }
        set { colors.controlsTint = newValue }
    }
    
    public var loadingIndicatorStyle: UIActivityIndicatorView.Style {
        get { loading.style }
        set { loading.style = newValue }
    }
    
    public var backButtonImage: UIImage? {
        get { controls.backButton.image }
        set { controls.backButton.image = newValue }
    }
    
    public var backButtonBackgroundColor: UIColor {
        get { controls.backButton.backgroundColor }
        set { controls.backButton.backgroundColor = newValue }
    }
    
    public var backButtonSize: CGSize {
        get { controls.backButton.size }
        set { controls.backButton.size = newValue }
    }
    
    public var backButtonCornerRadius: CGFloat {
        get { controls.backButton.cornerRadius }
        set { controls.backButton.cornerRadius = newValue }
    }
    
    public var backButtonPosition: BackButtonPosition {
        get { controls.backButton.position }
        set { controls.backButton.position = newValue }
    }
}