//
//  VimeoPlayerControlsDelegate.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  VimeoPlayerControls.swift
//  VimeoRestrictedPlayer
//
//  Created by Assistant on 28/05/25.
//

import UIKit

/// Protocol for handling player control events
public protocol VimeoPlayerControlsDelegate: AnyObject {
    func controlsDidTapPlay()
    func controlsDidTapPause()
    func controlsDidTapBack()
    func controlsDidSeek(to time: TimeInterval)
    func controlsDidTapFullscreen()
    func controlsDidChangeVolume(to level: Float)
    func controlsDidToggleControlsVisibility(visible: Bool)
}

/// Native overlay controls for VimeoRestrictedPlayer
public class VimeoPlayerControls: UIView {
    
    // MARK: - Properties
    
    public weak var delegate: VimeoPlayerControlsDelegate?
    public var theme: VimeoPlayerTheme = .default {
        didSet { applyTheme() }
    }
    
    public var isVisible: Bool = true {
        didSet { setControlsVisibility(isVisible, animated: true) }
    }
    
    public var autoHideEnabled: Bool = true
    public var autoHideDelay: TimeInterval = 3.0
    
    // Player state
    public var isPlaying: Bool = false {
        didSet { updatePlayPauseButton() }
    }
    
    public var currentTime: TimeInterval = 0 {
        didSet { updateProgress() }
    }
    
    public var duration: TimeInterval = 0 {
        didSet { updateProgress() }
    }
    
    public var maxAllowedSeekTime: TimeInterval = 0 {
        didSet { updateProgress() }
    }
    
    public var allowsFullSeek: Bool = true {
        didSet { updateSeekConstraints() }
    }
    
    // MARK: - UI Elements
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var topControlsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = theme.colors.overlayBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var bottomControlsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = theme.colors.overlayBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var centerControlsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Top Controls
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = theme.typography.titleFont
        label.textColor = theme.colors.primaryText
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Center Controls
    private lazy var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Bottom Controls
    private lazy var progressSlider: VimeoProgressSlider = {
        let slider = VimeoProgressSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(progressSliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(progressSliderTouchUp), for: [.touchUpInside, .touchUpOutside])
        return slider
    }()
    
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = theme.typography.timerFont
        label.textColor = theme.colors.primaryText
        label.text = "0:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.font = theme.typography.timerFont
        label.textColor = theme.colors.secondaryText
        label.text = "0:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var fullscreenButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(fullscreenButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Private Properties
    
    private var isUserSeeking = false
    private var autoHideTimer: Timer?
    private var lastTapTime: TimeInterval = 0
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
        applyTheme()
        scheduleAutoHide()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGestures()
        applyTheme()
        scheduleAutoHide()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(topControlsContainer)
        containerView.addSubview(centerControlsContainer)
        containerView.addSubview(bottomControlsContainer)
        
        // Setup top controls
        topControlsContainer.addSubview(backButton)
        topControlsContainer.addSubview(titleLabel)
        
        // Setup center controls
        centerControlsContainer.addSubview(playPauseButton)
        
        // Setup bottom controls
        bottomControlsContainer.addSubview(progressSlider)
        bottomControlsContainer.addSubview(currentTimeLabel)
        bottomControlsContainer.addSubview(durationLabel)
        bottomControlsContainer.addSubview(fullscreenButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            // Top controls container
            topControlsContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            topControlsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topControlsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topControlsContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Back button
            backButton.leadingAnchor.constraint(equalTo: topControlsContainer.leadingAnchor, constant: theme.layout.margins.left),
            backButton.centerYAnchor.constraint(equalTo: topControlsContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: theme.controls.backButton.size.width),
            backButton.heightAnchor.constraint(equalToConstant: theme.controls.backButton.size.height),
            
            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: topControlsContainer.trailingAnchor, constant: -theme.layout.margins.right),
            titleLabel.centerYAnchor.constraint(equalTo: topControlsContainer.centerYAnchor),
            
            // Center controls container
            centerControlsContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerControlsContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            centerControlsContainer.widthAnchor.constraint(equalToConstant: 100),
            centerControlsContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Play/Pause button
            playPauseButton.centerXAnchor.constraint(equalTo: centerControlsContainer.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: centerControlsContainer.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: theme.controls.playButton.size.width),
            playPauseButton.heightAnchor.constraint(equalToConstant: theme.controls.playButton.size.height),
            
            // Bottom controls container
            bottomControlsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomControlsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomControlsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomControlsContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Current time label
            currentTimeLabel.leadingAnchor.constraint(equalTo: bottomControlsContainer.leadingAnchor, constant: theme.layout.margins.left),
            currentTimeLabel.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 50),
            
            // Progress slider
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
            progressSlider.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor),
            
            // Duration label
            durationLabel.leadingAnchor.constraint(equalTo: progressSlider.trailingAnchor, constant: 8),
            durationLabel.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 50),
            
            // Fullscreen button
            fullscreenButton.leadingAnchor.constraint(equalTo: durationLabel.trailingAnchor, constant: 8),
            fullscreenButton.trailingAnchor.constraint(equalTo: bottomControlsContainer.trailingAnchor, constant: -theme.layout.margins.right),
            fullscreenButton.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor),
            fullscreenButton.widthAnchor.constraint(equalToConstant: theme.controls.fullscreenButton.size.width),
            fullscreenButton.heightAnchor.constraint(equalToConstant: theme.controls.fullscreenButton.size.height)
        ])
    }
    
    private func setupGestures() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func applyTheme() {
        // Apply theme to containers
        topControlsContainer.backgroundColor = theme.colors.overlayBackground
        bottomControlsContainer.backgroundColor = theme.colors.overlayBackground
        
        // Apply theme to buttons
        theme.applyButtonStyle(to: backButton, style: theme.controls.backButton)
        theme.applyButtonStyle(to: playPauseButton, style: BackButtonTheme(
            size: theme.controls.playButton.size,
            cornerRadius: theme.controls.playButton.cornerRadius,
            backgroundColor: theme.controls.playButton.backgroundColor,
            image: theme.controls.playButton.playImage
        ))
        
        fullscreenButton.setImage(theme.controls.fullscreenButton.enterImage, for: .normal)
        fullscreenButton.tintColor = theme.colors.controlsTint
        
        // Apply theme to labels
        titleLabel.font = theme.typography.titleFont
        titleLabel.textColor = theme.colors.primaryText
        
        currentTimeLabel.font = theme.typography.timerFont
        currentTimeLabel.textColor = theme.colors.primaryText
        
        durationLabel.font = theme.typography.timerFont
        durationLabel.textColor = theme.colors.secondaryText
        
        // Apply theme to progress slider
        progressSlider.applyTheme(theme.controls.progressBar)
    }
    
    // MARK: - Public Methods
    
    public func setTitle(_ title: String?) {
        titleLabel.text = title
    }
    
    public func setControlsVisibility(_ visible: Bool, animated: Bool) {
        let duration = animated ? theme.animations.controlsFadeInDuration : 0
        
        UIView.animate(withDuration: duration) {
            self.containerView.alpha = visible ? 1.0 : 0.0
        }
        
        if visible {
            scheduleAutoHide()
        } else {
            cancelAutoHide()
        }
        
        delegate?.controlsDidToggleControlsVisibility(visible: visible)
    }
    
    public func scheduleAutoHide() {
        guard autoHideEnabled else { return }
        
        cancelAutoHide()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDelay, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }
    
    public func cancelAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
    
    public func showControls() {
        setControlsVisibility(true, animated: true)
    }
    
    public func hideControls() {
        setControlsVisibility(false, animated: true)
    }
    
    public func updatePlaybackState(isPlaying: Bool, currentTime: TimeInterval, duration: TimeInterval, maxAllowedSeek: TimeInterval) {
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.maxAllowedSeekTime = maxAllowedSeek
    }
    
    // MARK: - Private Methods
    
    private func updatePlayPauseButton() {
        let image = isPlaying ? theme.controls.playButton.pauseImage : theme.controls.playButton.playImage
        playPauseButton.setImage(image, for: .normal)
    }
    
    private func updateProgress() {
        guard duration > 0 else { return }
        
        if !isUserSeeking {
            progressSlider.setValue(Float(currentTime / duration), animated: false)
            progressSlider.setMaxAllowedValue(Float(maxAllowedSeekTime / duration))
        }
        
        currentTimeLabel.text = TimeFormatter.format(seconds: currentTime)
        durationLabel.text = TimeFormatter.format(seconds: duration)
    }
    
    private func updateSeekConstraints() {
        progressSlider.isSeekRestricted = !allowsFullSeek
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        delegate?.controlsDidTapBack()
        scheduleAutoHide()
    }
    
    @objc private func playPauseButtonTapped() {
        if isPlaying {
            delegate?.controlsDidTapPause()
        } else {
            delegate?.controlsDidTapPlay()
        }
        scheduleAutoHide()
    }
    
    @objc private func fullscreenButtonTapped() {
        delegate?.controlsDidTapFullscreen()
        scheduleAutoHide()
    }
    
    @objc private func progressSliderTouchDown() {
        isUserSeeking = true
        cancelAutoHide()
    }
    
    @objc private func progressSliderChanged() {
        guard duration > 0 else { return }
        let seekTime = TimeInterval(progressSlider.value) * duration
        delegate?.controlsDidSeek(to: seekTime)
    }
    
    @objc private func progressSliderTouchUp() {
        isUserSeeking = false
        scheduleAutoHide()
    }
    
    @objc private func viewTapped() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let timeSinceLastTap = currentTime - lastTapTime
        lastTapTime = currentTime
        
        // Double tap to play/pause
        if timeSinceLastTap < 0.3 {
            playPauseButtonTapped()
        } else {
            // Single tap to toggle controls
            isVisible.toggle()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension VimeoPlayerControls: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't handle taps on interactive controls
        let touchPoint = touch.location(in: self)
        let hitView = hitTest(touchPoint, with: nil)
        
        return hitView == self || hitView == containerView
    }
}

// MARK: - Custom Progress Slider

public class VimeoProgressSlider: UISlider {
    
    // MARK: - Properties
    
    public var maxAllowedValue: Float = 1.0 {
        didSet { setNeedsDisplay() }
    }
    
    public var isSeekRestricted: Bool = false
    
    private var theme: ProgressBarTheme = .default
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSlider()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSlider()
    }
    
    private func setupSlider() {
        minimumValue = 0
        maximumValue = 1
        isContinuous = true
    }
    
    public func applyTheme(_ progressTheme: ProgressBarTheme) {
        self.theme = progressTheme
        
        minimumTrackTintColor = progressTheme.progressColor
        maximumTrackTintColor = progressTheme.trackColor
        thumbTintColor = progressTheme.thumbColor
        
        // Custom thumb
        setThumbImage(createThumbImage(size: progressTheme.thumbSize, color: progressTheme.thumbColor), for: .normal)
        setThumbImage(createThumbImage(size: progressTheme.thumbSize, color: progressTheme.thumbColor.withAlphaComponent(0.8)), for: .highlighted)
    }
    
    private func createThumbImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.fillEllipse(in: rect)
        }
    }
    
    public override func setValue(_ value: Float, animated: Bool) {
        if isSeekRestricted && value > maxAllowedValue {
            super.setValue(maxAllowedValue, animated: animated)
        } else {
            super.setValue(value, animated: animated)
        }
    }
    
    public func setMaxAllowedValue(_ value: Float) {
        maxAllowedValue = min(1.0, max(0.0, value))
        setNeedsDisplay()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Draw watched portion if different from current progress
        if maxAllowedValue < 1.0 && maxAllowedValue > value {
            let trackRect = trackRect(forBounds: bounds)
            let watchedWidth = trackRect.width * CGFloat(maxAllowedValue)
            let currentWidth = trackRect.width * CGFloat(value)
            
            if watchedWidth > currentWidth {
                let watchedRect = CGRect(
                    x: trackRect.minX + currentWidth,
                    y: trackRect.minY,
                    width: watchedWidth - currentWidth,
                    height: trackRect.height
                )
                
                theme.watchedColor.setFill()
                UIBezierPath(roundedRect: watchedRect, cornerRadius: theme.cornerRadius).fill()
            }
        }
    }
}
