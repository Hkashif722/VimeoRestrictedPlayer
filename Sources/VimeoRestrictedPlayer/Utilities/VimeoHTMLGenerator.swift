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
            </style>
        </head>
        <body>
            <div class="video-container">
              <iframe id="vimeo-player" 
                      src="https://player.vimeo.com/video/\(videoID)?h=\(hash)&autoplay=\(autoplay)&loop=false&title=true&byline=false&portrait=false&controls=true&playsinline=true&fullscreen=0"
                      frameborder="0" 
                      allow="autoplay; picture-in-picture">
              </iframe>
            </div>
            
            <script src="https://player.vimeo.com/api/player.js"></script>
            <script>
                var iframe = document.querySelector('#vimeo-player');
                var player = new Vimeo.Player(iframe);
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
                var ENFORCEMENT_DEBOUNCE = 100; // ms
                
                // Seek event tracking
                var seekEventTimestamps = [];
                var SEEK_EVENT_WINDOW = 1000; // Track seeks within 1 second
                
                // State synchronization
                var stateVersion = 0;
                var pendingStateUpdates = {};
                
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
                        }
                    });
                });
                
                // Enhanced monitoring with debouncing
                function startRestrictionMonitoring() {
                    if (restrictionCheckInterval) {
                        clearInterval(restrictionCheckInterval);
                    }
                    
                    restrictionCheckInterval = setInterval(function() {
                        if (isVideoReady && !isProcessingEnforcement && seekRestrictionEnabled && !isCompleted) {
                            player.getCurrentTime().then(function(time) {
                                var now = Date.now();
                                
                                // Skip if we recently enforced
                                if (now - lastEnforcementTime < ENFORCEMENT_DEBOUNCE) {
                                    return;
                                }
                                
                                // Check for violation with proper tolerance
                                if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                    console.log('[VimeoRestrictedPlayer] Monitoring: violation detected:', time, 'max:', maxAllowedSeek);
                                    queueEnforcement({
                                        time: time,
                                        source: 'monitoring',
                                        timestamp: now
                                    });
                                }
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error in monitoring:', error);
                            });
                        }
                    }, 250); // Reduced interval for better responsiveness
                }
                
                // Queue enforcement to prevent race conditions
                function queueEnforcement(violation) {
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
                                isRapidSeeking: isRapidSeeking()
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
                    return seekEventTimestamps.length > 3;
                }
                
                // Time update event with debouncing
                var lastTimeUpdate = 0;
                player.on('timeupdate', function(data) {
                    currentTime = data.seconds;
                    var now = Date.now();
                    
                    // Debounce time updates
                    if (now - lastTimeUpdate < 50) {
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
                                timestamp: now
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
                            timestamp: Date.now()
                        });
                    }
                });
                
                // Seeked event with verification
                player.on('seeked', function(data) {
                    console.log('[VimeoRestrictedPlayer] Seeked event:', data.seconds);
                    
                    setTimeout(function() {
                        isUserSeeking = false;
                    }, 150);
                    
                    if (isProcessingEnforcement) {
                        return;
                    }
                    
                    var currentSeekTime = data.seconds;
                    
                    if (seekRestrictionEnabled && !isCompleted && currentSeekTime > maxAllowedSeek + SEEK_TOLERANCE) {
                        queueEnforcement({
                            time: currentSeekTime,
                            source: 'seeked',
                            timestamp: Date.now()
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
                    
                    // Clear enforcement queue
                    enforcementQueue = [];
                    isProcessingEnforcement = false;
                    
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
                    
                    console.log('[VimeoRestrictedPlayer] Cleanup completed');
                }
                
                // Handle visibility changes to prevent background issues
                document.addEventListener('visibilitychange', function() {
                    if (document.hidden) {
                        console.log('[VimeoRestrictedPlayer] Page hidden, pausing monitoring');
                        if (restrictionCheckInterval) {
                            clearInterval(restrictionCheckInterval);
                        }
                    } else {
                        console.log('[VimeoRestrictedPlayer] Page visible, resuming monitoring');
                        if (seekRestrictionEnabled && !isCompleted && isVideoReady) {
                            startRestrictionMonitoring();
                        }
                    }
                });
            </script>
        </body>
        </html>
        """
    }
}
