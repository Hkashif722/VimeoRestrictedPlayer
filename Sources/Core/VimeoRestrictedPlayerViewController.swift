//
//  VimeoRestrictedPlayerViewController.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


import UIKit
import WebKit

/// Main view controller for playing Vimeo videos with restrictions
open class VimeoRestrictedPlayerViewController: UIViewController {
    
    // MARK: - Public Properties
    
    /// Delegate for receiving player events
    public weak var delegate: VimeoPlayerDelegate?
    
    /// Current configuration
    public private(set) var configuration: VimeoPlayerConfiguration
    
    /// Current playback time
    public private(set) var currentTime: TimeInterval = 0
    
    /// Total video duration
    public private(set) var duration: TimeInterval = 0
    
    /// Current player state
    public private(set) var state: VimeoPlayerState = .idle {
        didSet {
            handleStateChange(from: oldValue, to: state)
        }
    }
    
    /// Whether to show the back button
    public var showsBackButton: Bool = true {
        didSet {
            backButton.isHidden = !showsBackButton
        }
    }
    
    /// Custom back button style
    public enum BackButtonStyle {
        case system
        case custom(image: UIImage?)
    }
    
    /// Back button style
    public var backButtonStyle: BackButtonStyle = .system {
        didSet {
            updateBackButtonStyle()
        }
    }
    
    // MARK: - Private Properties
    
    private var webView: WKWebView!
    private var htmlGenerator: VimeoHTMLGenerator!
    private var currentWatchedDuration: TimeInterval = 0
    private var maxAllowedSeekPosition: TimeInterval = 0
    private var isVideoReady = false
    private var hasShownResumeDialog = false
    private var lastRestrictionAlertTime: TimeInterval = 0
    private var isPendingSeek = false
    private var pendingSeekTime: TimeInterval = 0
    
    // UI Elements
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: configuration.theme.loadingIndicatorStyle)
        indicator.color = configuration.theme.controlsTintColor
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(configuration.theme.backButtonImage, for: .normal)
        button.tintColor = configuration.theme.controlsTintColor
        button.backgroundColor = configuration.theme.backButtonBackgroundColor
        button.layer.cornerRadius = configuration.theme.backButtonCornerRadius
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
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        loadVimeoPlayer()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // Stop video playback before cleanup
        webView.evaluateJavaScript("pauseVideo()") { _, _ in
            self.webView.evaluateJavaScript("cleanup()") { _, error in
                if let error = error {
                    print("[VimeoRestrictedPlayer] Error during cleanup: \(error)")
                }
            }
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pause()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = configuration.theme.backgroundColor
        
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.startAnimating()
        state = .loading
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "vimeoPlayerHandler")
        config.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.backgroundColor = configuration.theme.backgroundColor
        webView.isOpaque = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        setupBackButton()
    }
    
    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.isHidden = !showsBackButton
        
        switch configuration.theme.backButtonPosition {
        case .topLeft(let insets):
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insets.top),
                backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
                backButton.widthAnchor.constraint(equalToConstant: configuration.theme.backButtonSize.width),
                backButton.heightAnchor.constraint(equalToConstant: configuration.theme.backButtonSize.height)
            ])
        case .topRight(let insets):
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insets.top),
                backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
                backButton.widthAnchor.constraint(equalToConstant: configuration.theme.backButtonSize.width),
                backButton.heightAnchor.constraint(equalToConstant: configuration.theme.backButtonSize.height)
            ])
        case .custom(let frame):
            backButton.frame = frame
        }
    }
    
    private func updateBackButtonStyle() {
        switch backButtonStyle {
        case .system:
            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        case .custom(let image):
            backButton.setImage(image, for: .normal)
        }
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
    
    // MARK: - Public Methods
    
    /// Play the video
    public func play() {
        guard isVideoReady else { return }
        webView.evaluateJavaScript("playVideo()") { _, error in
            if let error = error {
                print("[VimeoRestrictedPlayer] Error playing video: \(error)")
            }
        }
    }
    
    /// Pause the video
    public func pause() {
        guard isVideoReady else { return }
        webView.evaluateJavaScript("pauseVideo()") { _, error in
            if let error = error {
                print("[VimeoRestrictedPlayer] Error pausing video: \(error)")
            }
        }
    }
    
    /// Seek to specific time
    /// - Parameter time: Time to seek to in seconds
    public func seek(to time: TimeInterval) {
        guard isVideoReady else { return }
        let seekTime = configuration.allowsFullSeek ? time : min(time, maxAllowedSeekPosition)
        webView.evaluateJavaScript("setCurrentTime(\(seekTime))") { _, error in
            if let error = error {
                print("[VimeoRestrictedPlayer] Error seeking: \(error)")
            }
        }
    }
    
    /// Restart video from beginning
    public func restart() {
        guard isVideoReady else { return }
        maxAllowedSeekPosition = 0
        currentWatchedDuration = 0
        webView.evaluateJavaScript("restartVideo()") { _, error in
            if let error = error {
                print("[VimeoRestrictedPlayer] Error restarting: \(error)")
            }
        }
    }
    
    /// Update the maximum allowed seek position
    /// - Parameter time: New maximum allowed seek time
    public func updateMaxAllowedSeekTime(_ time: TimeInterval) {
        maxAllowedSeekPosition = max(maxAllowedSeekPosition, time)
        webView.evaluateJavaScript("updateMaxAllowedSeek(\(maxAllowedSeekPosition))") { _, error in
            if let error = error {
                print("[VimeoRestrictedPlayer] Error updating max seek: \(error)")
            }
        }
    }
    
    /// Check if video is playing
    public var isPlaying: Bool {
        return state.isPlaying
    }
    
    // MARK: - Private Methods
    
    private func loadVimeoPlayer() {
        let htmlContent = htmlGenerator.generateHTML()
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    private func handleStateChange(from oldState: VimeoPlayerState, to newState: VimeoPlayerState) {
        switch newState {
        case .ready:
            loadingIndicator.stopAnimating()
        case .playing:
            delegate?.vimeoPlayerDidStartPlaying(self)
        case .paused:
            delegate?.vimeoPlayerDidPause(self)
        case .ended:
            delegate?.vimeoPlayer(self, didCompleteWithDuration: currentWatchedDuration)
            if configuration.isCompleted {
                showCompletionAlert()
            }
        case .error(let error):
            loadingIndicator.stopAnimating()
            delegate?.vimeoPlayer(self, didEncounterError: error)
            showErrorAlert(error: error)
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
            self.webView.evaluateJavaScript("resumeFromBookmark()") { _, error in
                if let error = error {
                    print("[VimeoRestrictedPlayer] Error resuming: \(error)")
                } else {
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
    
    private func showErrorAlert(error: VimeoPlayerError) {
        let alert = UIAlertController(
            title: configuration.localization.errorTitle,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: configuration.localization.errorCancelButton, style: .cancel) { _ in
            self.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: configuration.localization.errorRetryButton, style: .default) { _ in
            self.loadVimeoPlayer()
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
            self.webView.evaluateJavaScript("resumeVideoAfterAlert()") { _, _ in }
        })
        
        present(alert, animated: true)
        
        delegate?.vimeoPlayer(self, didRestrictSeekFrom: attemptedTime, to: maxAllowed)
    }
}

// MARK: - WKScriptMessageHandler

extension VimeoRestrictedPlayerViewController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let type = messageBody["type"] as? String else {
            return
        }
        
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
            state = .playing
            
        case "pause":
            state = .paused
            
        case "ended":
            state = .ended
            
        case "error":
            handleErrorMessage(messageBody)
            
        default:
            print("[VimeoRestrictedPlayer] Unknown message type: \(type)")
        }
    }
    
    private func handleReadyMessage(_ message: [String: Any]) {
        isVideoReady = true
        state = .ready
        
        if let videoDuration = message["duration"] as? TimeInterval {
            duration = videoDuration
            delegate?.vimeoPlayerDidBecomeReady(self, duration: videoDuration)
        }
        
        if !configuration.isCompleted && configuration.resumeOptions.showResumeDialog {
            if let shouldShowResumeDialog = message["shouldShowResumeDialog"] as? Bool,
               shouldShowResumeDialog {
                showResumeDialog()
            }
        }
        
        if let lastWatchedTime = message["lastWatchedTime"] as? TimeInterval,
           let maxAllowed = message["maxAllowedSeek"] as? TimeInterval {
            maxAllowedSeekPosition = maxAllowed
        }
    }
    
    private func handleTimeUpdateMessage(_ message: [String: Any]) {
        if !configuration.isCompleted {
            if let time = message["currentTime"] as? TimeInterval {
                currentTime = time
                currentWatchedDuration = time
                
                if let maxAllowed = message["maxAllowed"] as? TimeInterval {
                    maxAllowedSeekPosition = max(maxAllowedSeekPosition, maxAllowed)
                }
                
                delegate?.vimeoPlayer(self, didUpdateProgress: time, totalDuration: duration)
            }
        }
    }
    
    private func handleSeekCompletedMessage(_ message: [String: Any]) {
        if let time = message["time"] as? TimeInterval {
            isPendingSeek = false
            currentTime = time
            currentWatchedDuration = time
        }
    }
    
    private func handleSeekErrorMessage(_ message: [String: Any]) {
        if let errorMessage = message["error"] as? String {
            print("[VimeoRestrictedPlayer] Seek error: \(errorMessage)")
            isPendingSeek = false
        }
    }
    
    private func handleSeekRestrictedMessage(_ message: [String: Any]) {
        if !configuration.isCompleted && configuration.seekRestriction.showAlertOnRestriction {
            if let attemptedTime = message["attemptedTime"] as? TimeInterval,
               let maxAllowed = message["maxAllowed"] as? TimeInterval {
                let wasPlaying = message["wasPlaying"] as? Bool ?? false
                showSeekRestrictedAlert(attemptedTime: attemptedTime, maxAllowed: maxAllowed, wasPlaying: wasPlaying)
            }
        }
    }
    
    private func handleErrorMessage(_ message: [String: Any]) {
        if let errorMessage = message["error"] as? String {
            state = .error(.playbackFailed(errorMessage))
        }
    }
}

// MARK: - WKNavigationDelegate

extension VimeoRestrictedPlayerViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        state = .error(.loadingFailed(error))
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        state = .error(.networkError(error))
    }
}
