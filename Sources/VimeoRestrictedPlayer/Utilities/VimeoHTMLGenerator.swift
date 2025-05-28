//
//  VimeoHTMLGenerator.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//

import Foundation

/// Generates HTML content for Vimeo player
internal class VimeoHTMLGenerator {
    
    private let configuration: VimeoPlayerConfiguration
    
    init(configuration: VimeoPlayerConfiguration) {
        self.configuration = configuration
    }
    
    func generateHTML() -> String {
        let (videoID, hash) = VimeoURLParser.parse(configuration.videoURL) ?? ("", "")
        let lastWatched = configuration.lastWatchedDuration
        let autoplay = configuration.autoplay ? "true" : "false"
        let isCompleted = configuration.isCompleted
        let videoTitle = configuration.videoTitle ?? "Video"
        let maxAllowedSeek = max(configuration.lastWatchedDuration, 0)
        let seekRestrictionEnabled = configuration.seekRestriction.enabled && !configuration.allowsFullSeek
        let seekTolerance = configuration.seekRestriction.seekTolerance
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    margin: 0; 
                    padding: 0; 
                    background: black;
                    overflow: hidden;
                }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100vh;
                }
                iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: none;
                }
                /* Overlay to intercept double-tap events */
                .tap-interceptor {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    z-index: 10;
                    pointer-events: none;
                }
                .tap-interceptor.active {
                    pointer-events: auto;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
              <iframe id="vimeo-player" 
                      src="https://player.vimeo.com/video/\(videoID)?h=\(hash)&autoplay=\(autoplay)&loop=false&title=true&byline=false&portrait=false&controls=true&playsinline=true&fullscreen=0"
                      frameborder="0" 
                      allow="autoplay; picture-in-picture">
              </iframe>
              <div id="tap-interceptor" class="tap-interceptor"></div>
            </div>
            
            <script src="https://player.vimeo.com/api/player.js"></script>
            <script>
                var iframe = document.querySelector('#vimeo-player');
                var player = new Vimeo.Player(iframe);
                var tapInterceptor = document.querySelector('#tap-interceptor');
                var isVideoReady = false;
                var maxAllowedSeek = \(maxAllowedSeek);
                var isCompleted = \(isCompleted ? "true" : "false");
                var seekRestrictionEnabled = \(seekRestrictionEnabled ? "true" : "false");
                var lastWatchedTime = \(lastWatched);
                var currentTime = 0;
                var duration = 0;
                var isUserSeeking = false;
                var wasPlayingBeforeSeek = false;
                var isEnforcingRestriction = false;
                var lastValidTime = 0;
                var restrictionCheckInterval;
                var SEEK_TOLERANCE = \(seekTolerance);
                var actualMaxWatchedPosition = \(maxAllowedSeek);
                var pendingResumeAfterAlert = false;
                var hasHandledInitialBookmark = false;
                
                // Enforcement queue to prevent race conditions
                var enforcementQueue = [];
                var isProcessingEnforcement = false;
                var lastEnforcementTime = 0;
                var ENFORCEMENT_DEBOUNCE = 50; // Reduced from 100ms for faster response
                var RAPID_SEEK_ENFORCEMENT_DEBOUNCE = 10; // Even faster for rapid seeks
                
                // Seek event tracking
                var seekEventTimestamps = [];
                var SEEK_EVENT_WINDOW = 1000; // Track seeks within 1 second
                
                // Double-tap detection
                var lastTapTime = 0;
                var tapTimeout = null;
                var DOUBLE_TAP_THRESHOLD = 300; // ms
                
                // State synchronization
                var stateVersion = 0;
                var pendingStateUpdates = {};
                
                // Position tracking for rapid changes
                var lastKnownPosition = 0;
                var positionCheckInterval;
                
                // Player ready event
                player.ready().then(function() {
                    isVideoReady = true;
                    console.log('[VimeoRestrictedPlayer] Player ready');
                    
                    // Get duration
                    player.getDuration().then(function(videoDuration) {
                        duration = videoDuration;
                        console.log('[VimeoRestrictedPlayer] Duration:', duration);
                        
                        // Send ready message
                        window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                            type: 'ready',
                            duration: duration,
                            lastWatchedTime: lastWatchedTime,
                            maxAllowedSeek: maxAllowedSeek,
                            shouldShowResumeDialog: lastWatchedTime > \(configuration.resumeOptions.minimumWatchedForResume)
                        });
                        
                        // Start monitoring if restrictions are enabled
                        if (seekRestrictionEnabled && !isCompleted) {
                            startRestrictionMonitoring();
                            startPositionTracking();
                            enableTapInterception();
                        }
                        
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error getting duration:', error);
                        
                        // Still send ready message
                        window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                            type: 'ready',
                            lastWatchedTime: lastWatchedTime,
                            maxAllowedSeek: maxAllowedSeek,
                            shouldShowResumeDialog: lastWatchedTime > \(configuration.resumeOptions.minimumWatchedForResume)
                        });
                        
                        if (seekRestrictionEnabled && !isCompleted) {
                            startRestrictionMonitoring();
                            startPositionTracking();
                            enableTapInterception();
                        }
                    });
                });
                
                // Enable tap interception for seek restriction
                function enableTapInterception() {
                    if (!seekRestrictionEnabled || isCompleted) return;
                    
                    tapInterceptor.classList.add('active');
                    
                    // Intercept touch events
                    tapInterceptor.addEventListener('touchstart', handleTouchStart, { passive: false });
                    tapInterceptor.addEventListener('click', handleClick, { passive: false });
                }
                
                // Handle touch start for double-tap detection
                function handleTouchStart(e) {
                    if (!seekRestrictionEnabled || isCompleted) {
                        // Pass through the event
                        tapInterceptor.classList.remove('active');
                        setTimeout(function() {
                            tapInterceptor.classList.add('active');
                        }, 100);
                        return;
                    }
                    
                    var currentTapTime = Date.now();
                    var tapDelta = currentTapTime - lastTapTime;
                    
                    // Check if this is a double-tap
                    if (tapDelta < DOUBLE_TAP_THRESHOLD && tapDelta > 0) {
                        // Double-tap detected
                        e.preventDefault();
                        e.stopPropagation();
                        
                        // Check which side was tapped
                        var tapX = e.touches[0].clientX;
                        var screenWidth = window.innerWidth;
                        
                        if (tapX > screenWidth * 0.6) {
                            // Right side - would normally fast forward
                            console.log('[VimeoRestrictedPlayer] Double-tap forward blocked');
                            
                            // Check current position and enforce if needed
                            player.getCurrentTime().then(function(time) {
                                if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                    queueEnforcement({
                                        time: time,
                                        source: 'double-tap-forward',
                                        timestamp: Date.now()
                                    });
                                }
                            });
                        } else if (tapX < screenWidth * 0.4) {
                            // Left side - rewind is usually allowed
                            // But still check if trying to go beyond allowed
                            temporarilyDisableInterception();
                        }
                        
                        clearTimeout(tapTimeout);
                        lastTapTime = 0;
                    } else {
                        // First tap
                        lastTapTime = currentTapTime;
                        
                        // Set timeout to reset tap detection
                        clearTimeout(tapTimeout);
                        tapTimeout = setTimeout(function() {
                            lastTapTime = 0;
                            // Single tap - allow it through
                            temporarilyDisableInterception();
                        }, DOUBLE_TAP_THRESHOLD);
                    }
                }
                
                // Handle click events (for desktop)
                function handleClick(e) {
                    // Similar logic for desktop double-clicks
                    if (!seekRestrictionEnabled || isCompleted) {
                        temporarilyDisableInterception();
                        return;
                    }
                }
                
                // Temporarily disable interception to allow legitimate interactions
                function temporarilyDisableInterception() {
                    tapInterceptor.classList.remove('active');
                    setTimeout(function() {
                        if (seekRestrictionEnabled && !isCompleted) {
                            tapInterceptor.classList.add('active');
                        }
                    }, 100);
                }
                
                // Enhanced position tracking for rapid changes
                function startPositionTracking() {
                    if (positionCheckInterval) {
                        clearInterval(positionCheckInterval);
                    }
                    
                    positionCheckInterval = setInterval(function() {
                        if (isVideoReady && !isProcessingEnforcement && seekRestrictionEnabled && !isCompleted) {
                            player.getCurrentTime().then(function(time) {
                                // Check for sudden jumps
                                var positionJump = Math.abs(time - lastKnownPosition);
                                
                                // If position jumped more than 2 seconds, it's likely a seek
                                if (positionJump > 2 && time > maxAllowedSeek + SEEK_TOLERANCE) {
                                    console.log('[VimeoRestrictedPlayer] Rapid position change detected:', lastKnownPosition, '->', time);
                                    trackSeekEvent();
                                    queueEnforcement({
                                        time: time,
                                        source: 'position-jump',
                                        timestamp: Date.now()
                                    });
                                }
                                
                                lastKnownPosition = time;
                            });
                        }
                    }, 50); // Check every 50ms for rapid changes
                }
                
                // Enhanced monitoring with debouncing
                function startRestrictionMonitoring() {
                    if (restrictionCheckInterval) {
                        clearInterval(restrictionCheckInterval);
                    }
                    
                    restrictionCheckInterval = setInterval(function() {
                        if (isVideoReady && !isProcessingEnforcement && seekRestrictionEnabled && !isCompleted) {
                            player.getCurrentTime().then(function(time) {
                                var now = Date.now();
                                
                                // Use appropriate debounce based on rapid seeking
                                var debounceTime = isRapidSeeking() ? RAPID_SEEK_ENFORCEMENT_DEBOUNCE : ENFORCEMENT_DEBOUNCE;
                                
                                // Skip if we recently enforced (unless rapid seeking)
                                if (!isRapidSeeking() && now - lastEnforcementTime < debounceTime) {
                                    return;
                                }
                                
                                // Check for violation with proper tolerance
                                if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                    console.log('[VimeoRestrictedPlayer] Monitoring: violation detected:', time, 'max:', maxAllowedSeek);
                                    queueEnforcement({
                                        time: time,
                                        source: 'monitoring',
                                        timestamp: now,
                                        priority: isRapidSeeking() ? 'high' : 'normal'
                                    });
                                }
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error in monitoring:', error);
                            });
                        }
                    }, 100); // Reduced from 250ms for better responsiveness
                }
                
                // Queue enforcement to prevent race conditions
                function queueEnforcement(violation) {
                    // For high priority (rapid seeking), clear queue and process immediately
                    if (violation.priority === 'high' || violation.source === 'double-tap-forward') {
                        console.log('[VimeoRestrictedPlayer] High priority enforcement');
                        enforcementQueue = [violation]; // Clear and replace queue
                        processEnforcementQueue();
                        return;
                    }
                    
                    // Check if we already have a similar violation queued
                    var isDuplicate = enforcementQueue.some(function(v) {
                        return Math.abs(v.time - violation.time) < 0.5 && 
                               (violation.timestamp - v.timestamp) < 100;
                    });
                    
                    if (!isDuplicate) {
                        enforcementQueue.push(violation);
                        processEnforcementQueue();
                    }
                }
                
                // Process enforcement queue
                function processEnforcementQueue() {
                    if (isProcessingEnforcement || enforcementQueue.length === 0) {
                        return;
                    }
                    
                    isProcessingEnforcement = true;
                    var violation = enforcementQueue.shift();
                    
                    // Immediate enforcement for high priority
                    if (violation.priority === 'high' || violation.source === 'double-tap-forward') {
                        enforceRestrictionSafe(violation);
                        return;
                    }
                    
                    // Double-check the violation is still valid
                    player.getCurrentTime().then(function(currentPos) {
                        if (currentPos > maxAllowedSeek + SEEK_TOLERANCE) {
                            enforceRestrictionSafe(violation);
                        } else {
                            console.log('[VimeoRestrictedPlayer] Violation resolved itself:', currentPos);
                            isProcessingEnforcement = false;
                            
                            // Process next in queue if any
                            if (enforcementQueue.length > 0) {
                                setTimeout(processEnforcementQueue, 50);
                            }
                        }
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error checking position:', error);
                        isProcessingEnforcement = false;
                    });
                }
                
                // Safe enforcement with state tracking
                function enforceRestrictionSafe(violation) {
                    if (!seekRestrictionEnabled || isCompleted) {
                        isProcessingEnforcement = false;
                        return;
                    }
                    
                    var enforcementVersion = ++stateVersion;
                    lastEnforcementTime = Date.now();
                    
                    console.log('[VimeoRestrictedPlayer] Enforcing restriction v' + enforcementVersion + ':', violation);
                    
                    // Track rapid seeks
                    trackSeekEvent();
                    
                    // For rapid seeks or double-tap, enforce immediately without checking pause state
                    if (violation.priority === 'high' || violation.source === 'double-tap-forward' || isRapidSeeking()) {
                        // Immediate enforcement
                        player.pause().then(function() {
                            return player.setCurrentTime(maxAllowedSeek);
                        }).then(function() {
                            console.log('[VimeoRestrictedPlayer] Rapid enforcement completed');
                            
                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                type: 'seekRestricted',
                                attemptedTime: violation.time,
                                maxAllowed: maxAllowedSeek,
                                wasPlaying: true,
                                actualPosition: maxAllowedSeek,
                                isRapidSeeking: true,
                                source: violation.source
                            });
                            
                            isProcessingEnforcement = false;
                            isEnforcingRestriction = false;
                            
                            // Process next in queue after a short delay
                            if (enforcementQueue.length > 0) {
                                setTimeout(processEnforcementQueue, 20);
                            }
                        }).catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error in rapid enforcement:', error);
                            isProcessingEnforcement = false;
                        });
                        
                        return;
                    }
                    
                    // Normal enforcement flow
                    player.getPaused().then(function(paused) {
                        wasPlayingBeforeSeek = !paused;
                        pendingResumeAfterAlert = wasPlayingBeforeSeek && !isRapidSeeking();
                        
                        // Pause first
                        return player.pause();
                    }).then(function() {
                        // Set to max allowed position
                        return player.setCurrentTime(maxAllowedSeek);
                    }).then(function() {
                        console.log('[VimeoRestrictedPlayer] Corrected to:', maxAllowedSeek);
                        
                        // Verify position after a delay
                        return new Promise(function(resolve) {
                            setTimeout(function() {
                                player.getCurrentTime().then(resolve);
                            }, 100);
                        });
                    }).then(function(verifyTime) {
                        console.log('[VimeoRestrictedPlayer] Position verified:', verifyTime);
                        
                        // Check if this enforcement is still the latest
                        if (enforcementVersion === stateVersion) {
                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                type: 'seekRestricted',
                                attemptedTime: violation.time,
                                maxAllowed: maxAllowedSeek,
                                wasPlaying: wasPlayingBeforeSeek,
                                actualPosition: verifyTime,
                                isRapidSeeking: isRapidSeeking(),
                                source: violation.source
                            });
                            
                            isProcessingEnforcement = false;
                            isEnforcingRestriction = false;
                            
                            // Process next in queue after a delay
                            if (enforcementQueue.length > 0) {
                                setTimeout(processEnforcementQueue, 100);
                            }
                        } else {
                            console.log('[VimeoRestrictedPlayer] Enforcement superseded');
                            isProcessingEnforcement = false;
                        }
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error in enforcement:', error);
                        isProcessingEnforcement = false;
                        isEnforcingRestriction = false;
                        
                        // Try to recover
                        if (enforcementQueue.length > 0) {
                            setTimeout(processEnforcementQueue, 200);
                        }
                    });
                }
                
                // Track seek events for rapid seek detection
                function trackSeekEvent() {
                    var now = Date.now();
                    seekEventTimestamps.push(now);
                    
                    // Clean old timestamps
                    seekEventTimestamps = seekEventTimestamps.filter(function(ts) {
                        return now - ts < SEEK_EVENT_WINDOW;
                    });
                }
                
                // Check if user is rapidly seeking
                function isRapidSeeking() {
                    return seekEventTimestamps.length > 2; // Reduced from 3 for quicker detection
                }
                
                // Time update event with debouncing
                var lastTimeUpdate = 0;
                player.on('timeupdate', function(data) {
                    currentTime = data.seconds;
                    var now = Date.now();
                    
                    // Debounce time updates (reduced for rapid seeks)
                    var debounceTime = isRapidSeeking() ? 20 : 50;
                    if (now - lastTimeUpdate < debounceTime) {
                        return;
                    }
                    lastTimeUpdate = now;
                    
                    // Check restriction
                    if (!isProcessingEnforcement && isVideoReady && seekRestrictionEnabled && !isCompleted) {
                        if (currentTime > maxAllowedSeek + SEEK_TOLERANCE) {
                            console.log('[VimeoRestrictedPlayer] Timeupdate violation:', currentTime, 'max:', maxAllowedSeek);
                            queueEnforcement({
                                time: currentTime,
                                source: 'timeupdate',
                                timestamp: now,
                                priority: isRapidSeeking() ? 'high' : 'normal'
                            });
                            return;
                        }
                    }
                    
                    // Update max allowed seek position
                    if (!isCompleted && !isProcessingEnforcement && !isUserSeeking) {
                        if (currentTime > actualMaxWatchedPosition) {
                            actualMaxWatchedPosition = currentTime;
                            maxAllowedSeek = currentTime;
                            lastValidTime = currentTime;
                        }
                    }
                    
                    if (!isProcessingEnforcement) {
                        lastValidTime = currentTime;
                    }
                    
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'timeUpdate',
                        currentTime: currentTime,
                        maxAllowed: maxAllowedSeek
                    });
                });
                
                // Seeking event with immediate check
                player.on('seeking', function(data) {
                    console.log('[VimeoRestrictedPlayer] Seeking event:', data.seconds);
                    
                    if (isProcessingEnforcement) {
                        return;
                    }
                    
                    isUserSeeking = true;
                    trackSeekEvent();
                    var seekTime = data.seconds;
                    
                    if (seekRestrictionEnabled && !isCompleted && seekTime > maxAllowedSeek + SEEK_TOLERANCE) {
                        queueEnforcement({
                            time: seekTime,
                            source: 'seeking',
                            timestamp: Date.now(),
                            priority: isRapidSeeking() ? 'high' : 'normal'
                        });
                    }
                });
                
                // Seeked event with verification
                player.on('seeked', function(data) {
                    console.log('[VimeoRestrictedPlayer] Seeked event:', data.seconds);
                    
                    // Reduced timeout for faster response
                    setTimeout(function() {
                        isUserSeeking = false;
                    }, 50);
                    
                    if (isProcessingEnforcement) {
                        return;
                    }
                    
                    var currentSeekTime = data.seconds;
                    
                    if (seekRestrictionEnabled && !isCompleted && currentSeekTime > maxAllowedSeek + SEEK_TOLERANCE) {
                        queueEnforcement({
                            time: currentSeekTime,
                            source: 'seeked',
                            timestamp: Date.now(),
                            priority: isRapidSeeking() ? 'high' : 'normal'
                        });
                    }
                });
                
                // Other events
                player.on('play', function() {
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'play'
                    });
                });
                
                player.on('pause', function() {
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'pause'
                    });
                });
                
                player.on('ended', function() {
                    // Clear any pending enforcements
                    enforcementQueue = [];
                    isProcessingEnforcement = false;
                    
                    // Disable tap interception
                    tapInterceptor.classList.remove('active');
                    
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'ended'
                    });
                });
                
                player.on('error', function(error) {
                    // Clear any pending enforcements on error
                    enforcementQueue = [];
                    isProcessingEnforcement = false;
                    
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'error',
                        error: error.message || 'Unknown error'
                    });
                });
                
                // Function to restart video
                function restartVideo() {
                    if (isVideoReady && !isProcessingEnforcement) {
                        console.log('[VimeoRestrictedPlayer] Restarting video');
                        
                        // Clear enforcement queue
                        enforcementQueue = [];
                        isUserSeeking = false;
                        
                        actualMaxWatchedPosition = 0;
                        maxAllowedSeek = 0;
                        lastValidTime = 0;
                        seekEventTimestamps = [];
                        lastKnownPosition = 0;
                        
                        player.setCurrentTime(0).then(function() {
                            console.log('[VimeoRestrictedPlayer] Video restarted');
                            currentTime = 0;
                            
                            // Optionally start playing
                            player.play().then(function() {
                                console.log('[VimeoRestrictedPlayer] Playing from start');
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error playing after restart:', error);
                            });
                        }).catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error restarting:', error);
                        });
                    }
                }
                
                // Set current time with proper validation
                function setCurrentTime(time, shouldPlay) {
                    shouldPlay = shouldPlay === undefined ? false : shouldPlay;
                    console.log('[VimeoRestrictedPlayer] setCurrentTime:', time, 'shouldPlay:', shouldPlay);
                    
                    if (!isVideoReady) {
                        console.log('[VimeoRestrictedPlayer] Video not ready');
                        return;
                    }
                    
                    if (isProcessingEnforcement) {
                        console.log('[VimeoRestrictedPlayer] Cannot seek while processing enforcement');
                        return;
                    }
                    
                    var targetTime = time;
                    
                    // Use consistent tolerance check
                    if (seekRestrictionEnabled && !isCompleted && time > maxAllowedSeek + SEEK_TOLERANCE && time > lastWatchedTime + SEEK_TOLERANCE) {
                        console.log('[VimeoRestrictedPlayer] Seek beyond allowed, using max:', maxAllowedSeek);
                        targetTime = maxAllowedSeek;
                    }
                    
                    console.log('[VimeoRestrictedPlayer] Setting time to:', targetTime);
                    
                    // Mark as programmatic seek
                    isUserSeeking = true;
                    
                    player.setCurrentTime(targetTime).then(function(seconds) {
                        console.log('[VimeoRestrictedPlayer] Successfully set time to:', seconds);
                        currentTime = targetTime;
                        lastKnownPosition = targetTime;
                        
                        setTimeout(function() {
                            isUserSeeking = false;
                        }, 200);
                        
                        if (shouldPlay) {
                            player.play().then(function() {
                                console.log('[VimeoRestrictedPlayer] Playing after seek');
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error playing after seek:', error);
                            });
                        }
                        
                        window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                            type: 'seekCompleted',
                            time: targetTime,
                            wasRequested: time,
                            isPlaying: shouldPlay
                        });
                        
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error setting time:', error);
                        isUserSeeking = false;
                        
                        window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                            type: 'seekError',
                            error: error.message,
                            requestedTime: time
                        });
                    });
                }
                
                // Resume from bookmark position
                function resumeFromBookmark() {
                    if (isVideoReady && lastWatchedTime > 0) {
                        console.log('[VimeoRestrictedPlayer] Resuming from bookmark:', lastWatchedTime);
                        hasHandledInitialBookmark = true;
                        setCurrentTime(lastWatchedTime, false);
                    }
                }
                
                // Play video
                function playVideo() {
                    if (isVideoReady && !isProcessingEnforcement) {
                        player.play().catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error playing:', error);
                        });
                    }
                }
                
                // Pause video  
                function pauseVideo() {
                    if (isVideoReady) {
                        player.pause().then(function() {
                            console.log('[VimeoRestrictedPlayer] Video paused');
                        }).catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error pausing:', error);
                        });
                    }
                }
                
                // Update max allowed seek safely
                function updateMaxAllowedSeek(newMax) {
                    console.log('[VimeoRestrictedPlayer] Updating max allowed seek to:', newMax);
                    if (newMax > maxAllowedSeek) {
                        // Increment state version to invalidate any pending enforcements
                        stateVersion++;
                        
                        maxAllowedSeek = newMax;
                        actualMaxWatchedPosition = newMax;
                        lastValidTime = Math.min(currentTime, maxAllowedSeek);
                        lastKnownPosition = Math.min(lastKnownPosition, maxAllowedSeek);
                    }
                }
                
                // Get player state
                function getPlayerState() {
                    if (isVideoReady) {
                        return {
                            currentTime: currentTime,
                            maxAllowed: maxAllowedSeek,
                            actualMaxWatched: actualMaxWatchedPosition,
                            isReady: isVideoReady,
                            isProcessingEnforcement: isProcessingEnforcement,
                            lastValid: lastValidTime,
                            pendingResume: pendingResumeAfterAlert,
                            lastWatchedTime: lastWatchedTime,
                            enforcementQueueSize: enforcementQueue.length,
                            isRapidSeeking: isRapidSeeking(),
                            stateVersion: stateVersion
                        };
                    }
                    return null;
                }
                
                // Resume video after alert with validation
                function resumeVideoAfterAlert() {
                    console.log('[VimeoRestrictedPlayer] Resume after alert - pending:', pendingResumeAfterAlert);
                    
                    if (!isVideoReady || isProcessingEnforcement) {
                        return;
                    }
                    
                    // Clear rapid seek tracking
                    seekEventTimestamps = [];
                    
                    player.getCurrentTime().then(function(time) {
                        console.log('[VimeoRestrictedPlayer] Current position:', time, 'Max allowed:', maxAllowedSeek);
                        
                        if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                            player.setCurrentTime(maxAllowedSeek).then(function() {
                                console.log('[VimeoRestrictedPlayer] Position corrected');
                                
                                if (pendingResumeAfterAlert) {
                                    setTimeout(function() {
                                        player.play().then(function() {
                                            console.log('[VimeoRestrictedPlayer] Video resumed');
                                            pendingResumeAfterAlert = false;
                                        }).catch(function(error) {
                                            console.log('[VimeoRestrictedPlayer] Error resuming:', error);
                                        });
                                    }, 100);
                                }
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error correcting position:', error);
                            });
                        } else {
                            if (pendingResumeAfterAlert) {
                                player.play().then(function() {
                                    console.log('[VimeoRestrictedPlayer] Video resumed');
                                    pendingResumeAfterAlert = false;
                                }).catch(function(error) {
                                    console.log('[VimeoRestrictedPlayer] Error resuming:', error);
                                });
                            }
                        }
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error getting time:', error);
                    });
                }
                
                // Enhanced cleanup
                function cleanup() {
                    console.log('[VimeoRestrictedPlayer] Cleanup called');
                    
                    // Clear all intervals and timeouts
                    if (restrictionCheckInterval) {
                        clearInterval(restrictionCheckInterval);
                        restrictionCheckInterval = null;
                    }
                    
                    if (positionCheckInterval) {
                        clearInterval(positionCheckInterval);
                        positionCheckInterval = null;
                    }
                    
                    if (tapTimeout) {
                        clearTimeout(tapTimeout);
                        tapTimeout = null;
                    }
                    
                    // Clear enforcement queue
                    enforcementQueue = [];
                    isProcessingEnforcement = false;
                    
                    // Disable tap interception
                    tapInterceptor.classList.remove('active');
                    
                    // Pause video if ready
                    if (isVideoReady) {
                        player.pause().catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error pausing during cleanup:', error);
                        });
                    }
                    
                    // Reset all state
                    isEnforcingRestriction = false;
                    pendingResumeAfterAlert = false;
                    isVideoReady = false;
                    isUserSeeking = false;
                    seekEventTimestamps = [];
                    stateVersion = 0;
                    lastKnownPosition = 0;
                    lastTapTime = 0;
                    
                    console.log('[VimeoRestrictedPlayer] Cleanup completed');
                }
                
                // Handle visibility changes to prevent background issues
                document.addEventListener('visibilitychange', function() {
                    if (document.hidden) {
                        console.log('[VimeoRestrictedPlayer] Page hidden, pausing monitoring');
                        if (restrictionCheckInterval) {
                            clearInterval(restrictionCheckInterval);
                        }
                        if (positionCheckInterval) {
                            clearInterval(positionCheckInterval);
                        }
                    } else {
                        console.log('[VimeoRestrictedPlayer] Page visible, resuming monitoring');
                        if (seekRestrictionEnabled && !isCompleted && isVideoReady) {
                            startRestrictionMonitoring();
                            startPositionTracking();
                        }
                    }
                });
                
                // Intercept keyboard events for arrow keys
                document.addEventListener('keydown', function(e) {
                    if (!seekRestrictionEnabled || isCompleted || !isVideoReady) return;
                    
                    // Right arrow (fast forward) or Left arrow (rewind)
                    if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
                        player.getCurrentTime().then(function(time) {
                            var seekAmount = e.shiftKey ? 10 : 5; // Shift+arrow = 10s, arrow = 5s
                            var targetTime = e.key === 'ArrowRight' ? time + seekAmount : time - seekAmount;
                            
                            if (e.key === 'ArrowRight' && targetTime > maxAllowedSeek + SEEK_TOLERANCE) {
                                e.preventDefault();
                                e.stopPropagation();
                                console.log('[VimeoRestrictedPlayer] Keyboard forward seek blocked');
                                
                                queueEnforcement({
                                    time: targetTime,
                                    source: 'keyboard-forward',
                                    timestamp: Date.now(),
                                    priority: 'high'
                                });
                            }
                        });
                    }
                }, true);
            </script>
        </body>
        </html>
        """
    }
}
