//
//  VimeoRestrictedPlayerViewController.swift (Enhanced)
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


import UIKit
import WebKit

/// Enhanced main view controller for playing Vimeo videos with restrictions
open class VimeoRestrictedPlayerViewController: UIViewController {
    
    // MARK: - Public Properties
    
    /// Delegate for receiving player events
    public weak var delegate: VimeoPlayerDelegate?
    
    /// Current configuration
    public private(set) var configuration: VimeoPlayerConfiguration {
        didSet { updateConfiguration() }
    }
    
    /// Current playback time
    public private(set) var currentTime: TimeInterval = 0
    
    /// Total video duration
    public private(set) var duration: TimeInterval = 0
    
    /// Current player state
    public private(set) var state: VimeoPlayerState = VimeoPlayerState() {
        didSet { handleStateChange(from: oldValue, to: state) }
    }
    
    /// Whether to show native overlay controls
    public var showsNativeControls: Bool = false {
        didSet { updateControlsVisibility() }
    }
    
    /// Whether to show the back button
    public var showsBackButton: Bool = true {
        didSet { updateBackButtonVisibility() }
    }
    
    /// Custom back button style
    public enum BackButtonStyle {
        case system
        case custom(image: UIImage?)
    }
    
    /// Back button style
    public var backButtonStyle: BackButtonStyle = .system {
        didSet { updateBackButtonStyle() }
    }
    
    // MARK: - Private Properties
    
    private var webView: WKWebView!
    private var webViewBridge: VimeoPlayerWebViewBridge!
    private var htmlGenerator: VimeoHTMLGenerator!
    private var nativeControls: VimeoPlayerControls?
    
    private var currentWatchedDuration: TimeInterval = 0
    private var maxAllowedSeekPosition: TimeInterval = 0
    private var isVideoReady = false
    private var hasShownResumeDialog = false
    private var lastRestrictionAlertTime: TimeInterval = 0
    private var isPendingSeek = false
    private var pendingSeekTime: TimeInterval = 0
    
    // Enhanced error handling
    private var retryCount = 0
    private let maxRetryAttempts = 3
    private var networkMonitor: NetworkMonitor?
    
    // UI Elements
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: configuration.theme.loading.style)
        indicator.color = configuration.theme.loading.color
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var errorView: ErrorDisplayView = {
        let view = ErrorDisplayView(theme: configuration.theme)
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    
    public init(configuration: VimeoPlayerConfiguration) {
        self.configuration = configuration
        self.maxAllowedSeekPosition = configuration.lastWatchedDuration
        self.currentWatchedDuration = configuration.lastWatchedDuration
        self.htmlGenerator = VimeoHTMLGenerator(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        
        setupNetworkMonitoring()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        setupWebViewBridge()
        setupNativeControls()
        loadVimeoPlayer()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        networkMonitor?.startMonitoring()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // Pause playback gracefully
        webViewBridge?.pause { _, _ in }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        networkMonitor?.stopMonitoring()
        cleanup()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = configuration.theme.colors.primaryBackground
        
        // Add subviews
        view.addSubview(loadingIndicator)
        view.addSubview(errorView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        loadingIndicator.startAnimating()
        state.updateLoadingState(.loading)
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Enhanced preferences for better video playback
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.backgroundColor = configuration.theme.colors.primaryBackground
        webView.isOpaque = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        view.insertSubview(webView, at: 0)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupWebViewBridge() {
        webViewBridge = VimeoPlayerWebViewBridge()
        webViewBridge.delegate = self
        webViewBridge.setupBridge(with: webView)
    }
    
    private func setupNativeControls() {
        guard showsNativeControls else { return }
        
        nativeControls = VimeoPlayerControls()
        nativeControls!.delegate = self
        nativeControls!.theme = configuration.theme
        nativeControls!.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(nativeControls!)
        
        NSLayoutConstraint.activate([
            nativeControls!.topAnchor.constraint(equalTo: webView.topAnchor),
            nativeControls!.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            nativeControls!.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            nativeControls!.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        ])
        
        nativeControls!.setTitle(configuration.videoTitle)
    }
    
    private func setupBackButton() {
        guard !showsNativeControls else { return } // Native controls handle back button
        
        view.addSubview(backButton)
        backButton.isHidden = !showsBackButton
        
        switch configuration.theme.controls.backButton.position {
        case .topLeft(let insets):
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insets.top),
                backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
                backButton.widthAnchor.constraint(equalToConstant: configuration.theme.controls.backButton.size.width),
                backButton.heightAnchor.constraint(equalToConstant: configuration.theme.controls.backButton.size.height)
            ])
        case .topRight(let insets):
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insets.top),
                backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
                backButton.widthAnchor.constraint(equalToConstant: configuration.theme.controls.backButton.size.width),
                backButton.heightAnchor.constraint(equalToConstant: configuration.theme.controls.backButton.size.height)
            ])
        case .custom(let frame):
            backButton.frame = frame
        }
        
        updateBackButtonStyle()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor = NetworkMonitor { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.handleNetworkChange(isConnected: isConnected)
            }
        }
    }
    
    // MARK: - Configuration Updates
    
    private func updateConfiguration() {
        htmlGenerator = VimeoHTMLGenerator(configuration: configuration)
        
        // Update UI elements
        view.backgroundColor = configuration.theme.colors.primaryBackground
        webView?.backgroundColor = configuration.theme.colors.primaryBackground
        loadingIndicator.style = configuration.theme.loading.style
        
        // Update native controls
        nativeControls?.theme = configuration.theme
        nativeControls?.setTitle(configuration.videoTitle)
        nativeControls?.allowsFullSeek = configuration.allowsFullSeek
        
        // Update error view
        errorView.theme = configuration.theme
        
        updateBackButtonStyle()
    }
    
    private func updateControlsVisibility() {
        if showsNativeControls && nativeControls == nil {
            setupNativeControls()
        } else if !showsNativeControls && nativeControls != nil {
            nativeControls?.removeFromSuperview()
            nativeControls = nil
            setupBackButton()
        }
    }
    
    private func updateBackButtonVisibility() {
        if showsNativeControls {
            // Native controls don't have a backButton property, so we need to handle this differently
            // For now, we'll just ignore this for native controls
        } else {
            backButton.isHidden = !showsBackButton
        }
    }
    
    private func updateBackButtonStyle() {
        let buttonToUpdate = showsNativeControls ? nil : backButton
        guard let button = buttonToUpdate else { return }
        
        switch backButtonStyle {
        case .system:
            button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        case .custom(let image):
            button.setImage(image, for: .normal)
        }
        
        configuration.theme.applyButtonStyle(to: button, style: configuration.theme.controls.backButton)
    }
    
    // MARK: - Player Control Methods
    
    /// Play the video
    public func play() {
        webViewBridge?.play { [weak self] success, error in
            if let error = error {
                self?.handleError(VimeoPlayerErrorFactory.playbackError(type: .generic, message: error.localizedDescription))
            }
        }
    }
    
    /// Pause the video
    public func pause() {
        webViewBridge?.pause { success, error in
            if let error = error {
                print("[VimeoRestrictedPlayer] Error pausing: \(error)")
            }
        }
    }
    
    /// Seek to specific time
    /// - Parameter time: Time to seek to in seconds
    public func seek(to time: TimeInterval) {
        let seekTime = configuration.allowsFullSeek ? time : min(time, maxAllowedSeekPosition)
        webViewBridge?.seekTo(seekTime) { [weak self] success, error in
            if let error = error {
                self?.handleError(VimeoPlayerErrorFactory.playbackError(type: .generic, message: error.localizedDescription))
            }
        }
    }
    
    /// Restart video from beginning
    public func restart() {
        maxAllowedSeekPosition = 0
        currentWatchedDuration = 0
        webViewBridge?.restart { [weak self] success, error in
            if let error = error {
                self?.handleError(VimeoPlayerErrorFactory.playbackError(type: .generic, message: error.localizedDescription))
            }
        }
    }
    
    /// Update the maximum allowed seek position
    /// - Parameter time: New maximum allowed seek time
    public func updateMaxAllowedSeekTime(_ time: TimeInterval) {
        maxAllowedSeekPosition = max(maxAllowedSeekPosition, time)
        webViewBridge?.updateMaxAllowedSeek(maxAllowedSeekPosition) { [weak self] success, error in
            if let error = error {
                print("[VimeoRestrictedPlayer] Error updating max seek: \(error)")
            }
        }
    }
    
    /// Check if video is playing
    public var isPlaying: Bool {
        return state.isPlaying
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: VimeoPlayerError) {
        state.updateError(error)
        state.updatePlaybackState(.error)
        
        errorView.showError(error, canRetry: error.isRetryable && retryCount < maxRetryAttempts)
        errorView.isHidden = false
        loadingIndicator.stopAnimating()
        
        delegate?.vimeoPlayer(self, didEncounterError: error)
    }
    
    private func retryLoad() {
        guard retryCount < maxRetryAttempts else {
            handleError(.unknown("Maximum retry attempts exceeded"))
            return
        }
        
        retryCount += 1
        errorView.isHidden = true
        loadingIndicator.startAnimating()
        state.updateLoadingState(.loading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadVimeoPlayer()
        }
    }
    
    private func handleNetworkChange(isConnected: Bool) {
        if !isConnected && state.isLoading {
            handleError(.networkError(VimeoPlayerError.NetworkErrorInfo(
                underlyingError: "No internet connection",
                isConnectivityIssue: true
            )))
        } else if isConnected && state.hasError {
            // Automatically retry if we regain connection
            retryLoad()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadVimeoPlayer() {
        guard VimeoURLParser.isValidVimeoURL(configuration.videoURL) else {
            handleError(.invalidURL(configuration.videoURL))
            return
        }
        
        let htmlContent = htmlGenerator.generateHTML()
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    private func cleanup() {
        webViewBridge?.cleanup()
        networkMonitor?.stopMonitoring()
        nativeControls?.cancelAutoHide()
    }
    
    private func handleStateChange(from oldState: VimeoPlayerState, to newState: VimeoPlayerState) {
        switch newState.playbackState {
        case .idle:
            if newState.isReady {
                loadingIndicator.stopAnimating()
                errorView.isHidden = true
                retryCount = 0
            }
            
        case .playing:
            delegate?.vimeoPlayerDidStartPlaying(self)
            nativeControls?.isPlaying = true
            
        case .paused:
            delegate?.vimeoPlayerDidPause(self)
            nativeControls?.isPlaying = false
            
        case .ended:
            delegate?.vimeoPlayer(self, didCompleteWithDuration: currentWatchedDuration)
            nativeControls?.isPlaying = false
            if configuration.isCompleted {
                showCompletionAlert()
            }
            
        case .error:
            loadingIndicator.stopAnimating()
            if let error = newState.errorState?.error {
                delegate?.vimeoPlayer(self, didEncounterError: error)
            }
            
        default:
            break
        }
    }
    
    private func showResumeDialog() {
        let lastWatched = configuration.lastWatchedDuration
        guard lastWatched > configuration.resumeOptions.minimumWatchedForResume && !hasShownResumeDialog else {
            hasShownResumeDialog = true
            return
        }
        hasShownResumeDialog = true
        
        let formattedTime = TimeFormatter.format(seconds: lastWatched)
        let message = configuration.resumeOptions.resumeDialogMessage.replacingOccurrences(of: "{TIME}", with: formattedTime)
        
        let alert = UIAlertController(
            title: configuration.resumeOptions.resumeDialogTitle,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: configuration.resumeOptions.continueButtonTitle, style: .default) { _ in
            self.webViewBridge?.resumeFromBookmark { success, error in
                if success {
                    self.delegate?.vimeoPlayer(self, didResumeFromTime: lastWatched)
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: configuration.resumeOptions.startOverButtonTitle, style: .default) { _ in
            self.restart()
            self.delegate?.vimeoPlayerDidStartOver(self)
        })
        
        present(alert, animated: true)
    }
    
    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: configuration.localization.completionTitle,
            message: configuration.localization.completionMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: configuration.localization.completionButtonTitle, style: .default) { _ in
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showSeekRestrictedAlert(attemptedTime: TimeInterval, maxAllowed: TimeInterval, wasPlaying: Bool) {
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastRestrictionAlertTime < 3.0 {
            return
        }
        
        if abs(attemptedTime - maxAllowed) < 1.0 {
            return
        }
        
        lastRestrictionAlertTime = currentTime
        
        let formattedTime = TimeFormatter.format(seconds: maxAllowed)
        let message = String(format: configuration.localization.seekRestrictionMessage, formattedTime)
        
        let alert = UIAlertController(
            title: configuration.localization.seekRestrictionTitle,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.webViewBridge?.resumeVideoAfterAlert { _, _ in }
        })
        
        present(alert, animated: true)
        delegate?.vimeoPlayer(self, didRestrictSeekFrom: attemptedTime, to: maxAllowed)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        pause()
        
        let alert = UIAlertController(
            title: configuration.localization.exitConfirmationTitle,
            message: configuration.localization.exitConfirmationMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: configuration.localization.exitButtonTitle, style: .destructive) { _ in
            self.delegate?.vimeoPlayer(self, didExitAtTime: self.currentWatchedDuration)
            self.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: configuration.localization.cancelButtonTitle, style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - VimeoPlayerWebViewBridgeDelegate

extension VimeoRestrictedPlayerViewController: VimeoPlayerWebViewBridgeDelegate {
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didReceiveReady duration: TimeInterval, shouldShowResumeDialog: Bool) {
        isVideoReady = true
        self.duration = duration
        state.updateReadinessState(.ready)
        state.updateLoadingState(.loaded)
        
        delegate?.vimeoPlayerDidBecomeReady(self, duration: duration)
        
        if !configuration.isCompleted && configuration.resumeOptions.showResumeDialog && shouldShowResumeDialog {
            showResumeDialog()
        }
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didUpdateTime currentTime: TimeInterval, maxAllowed: TimeInterval) {
        if !configuration.isCompleted {
            self.currentTime = currentTime
            self.currentWatchedDuration = currentTime
            self.maxAllowedSeekPosition = max(maxAllowedSeekPosition, maxAllowed)
            
            state.updateProgress(currentTime: currentTime, duration: duration, maxWatched: maxAllowedSeekPosition)
            
            // Update native controls
            nativeControls?.updatePlaybackState(
                isPlaying: state.isPlaying,
                currentTime: currentTime,
                duration: duration,
                maxAllowedSeek: maxAllowedSeekPosition
            )
            
            delegate?.vimeoPlayer(self, didUpdateProgress: currentTime, totalDuration: duration)
        }
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didPlay: Void) {
        state.updatePlaybackState(.playing)
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didPause: Void) {
        state.updatePlaybackState(.paused)
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didEnd: Void) {
        state.updatePlaybackState(.ended)
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didRestrictSeek attemptedTime: TimeInterval, maxAllowed: TimeInterval, wasPlaying: Bool, actualPosition: TimeInterval) {
        if !configuration.isCompleted && configuration.seekRestriction.showAlertOnRestriction {
            showSeekRestrictedAlert(attemptedTime: attemptedTime, maxAllowed: maxAllowed, wasPlaying: wasPlaying)
        }
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didCompleteSeek time: TimeInterval, wasRequested: TimeInterval, isPlaying: Bool) {
        currentTime = time
        currentWatchedDuration = time
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didEncounterError error: VimeoPlayerError) {
        handleError(error)
    }
    
    public func bridge(_ bridge: VimeoPlayerWebViewBridge, didSeekError error: String, requestedTime: TimeInterval) {
        print("[VimeoRestrictedPlayer] Seek error: \(error)")
    }
}

// MARK: - VimeoPlayerControlsDelegate

extension VimeoRestrictedPlayerViewController: VimeoPlayerControlsDelegate {
    
    public func controlsDidTapPlay() {
        play()
    }
    
    public func controlsDidTapPause() {
        pause()
    }
    
    public func controlsDidTapBack() {
        backButtonTapped()
    }
    
    public func controlsDidSeek(to time: TimeInterval) {
        seek(to: time)
    }
    
    public func controlsDidTapFullscreen() {
        // Implement fullscreen functionality
        // This would typically involve presenting the player modally or transitioning to landscape
    }
    
    public func controlsDidChangeVolume(to level: Float) {
        // Implement volume control if needed
    }
    
    public func controlsDidToggleControlsVisibility(visible: Bool) {
        // Handle controls visibility changes if needed
    }
}

// MARK: - ErrorDisplayViewDelegate

extension VimeoRestrictedPlayerViewController: ErrorDisplayViewDelegate {
    
    public func errorDisplayViewDidTapRetry(_ view: ErrorDisplayView) {
        retryLoad()
    }
    
    public func errorDisplayViewDidTapDismiss(_ view: ErrorDisplayView) {
        delegate?.vimeoPlayer(self, didExitAtTime: currentWatchedDuration)
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension VimeoRestrictedPlayerViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(VimeoPlayerErrorFactory.loadingError(phase: .htmlLoading, error: error))
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(VimeoPlayerErrorFactory.networkError(from: error))
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Web view has finished loading, but video player may not be ready yet
        print("[VimeoRestrictedPlayer] WebView finished loading")
    }
}

// MARK: - Supporting Protocols

public protocol ErrorDisplayViewDelegate: AnyObject {
    func errorDisplayViewDidTapRetry(_ view: ErrorDisplayView)
    func errorDisplayViewDidTapDismiss(_ view: ErrorDisplayView)
}

// MARK: - Supporting Classes

/// Error display view for user-friendly error messages
public class ErrorDisplayView: UIView {
    
    public weak var delegate: ErrorDisplayViewDelegate?
    public var theme: VimeoPlayerTheme = .default {
        didSet { applyTheme() }
    }
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    public convenience init(theme: VimeoPlayerTheme) {
        self.init(frame: .zero)
        self.theme = theme
        applyTheme()
    }
    
    private func setupUI() {
        backgroundColor = theme.colors.primaryBackground
        
        // Setup container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Setup icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Setup labels
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Setup buttons
        retryButton.setTitle("Retry", for: .normal)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(retryButton)
        
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dismissButton)
        
        setupConstraints()
        applyTheme()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            retryButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.widthAnchor.constraint(equalToConstant: 120),
            
            dismissButton.topAnchor.constraint(equalTo: retryButton.bottomAnchor, constant: 8),
            dismissButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),
            dismissButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func applyTheme() {
        backgroundColor = theme.colors.primaryBackground
        
        titleLabel.font = theme.typography.titleFont
        titleLabel.textColor = theme.colors.primaryText
        
        messageLabel.font = theme.typography.bodyFont
        messageLabel.textColor = theme.colors.secondaryText
        
        retryButton.backgroundColor = theme.colors.accent
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        
        dismissButton.setTitleColor(theme.colors.secondaryText, for: .normal)
    }
    
    public func showError(_ error: VimeoPlayerError, canRetry: Bool) {
        iconImageView.image = UIImage(systemName: "exclamationmark.triangle")
        iconImageView.tintColor = theme.colors.error
        
        titleLabel.text = "Playback Error"
        messageLabel.text = error.localizedDescription
        
        retryButton.isHidden = !canRetry
    }
    
    @objc private func retryTapped() {
        delegate?.errorDisplayViewDidTapRetry(self)
    }
    
    @objc private func dismissTapped() {
        delegate?.errorDisplayViewDidTapDismiss(self)
    }
}

/// Network monitoring utility
private class NetworkMonitor {
    private let callback: (Bool) -> Void
    private var isMonitoring = false
    
    init(callback: @escaping (Bool) -> Void) {
        self.callback = callback
    }
    
    func startMonitoring() {
        isMonitoring = true
        // Implementation would use Network framework or Reachability
        // For now, assume we're always connected
        callback(true)
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
}
