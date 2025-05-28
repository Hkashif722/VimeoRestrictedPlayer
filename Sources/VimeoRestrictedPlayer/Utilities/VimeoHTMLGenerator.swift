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
                /* Custom title overlay if needed */
                .custom-title {
                    position: absolute;
                    top: 20px;
                    left: 20px;
                    color: white;
                    font-size: 18px;
                    font-weight: bold;
                    text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
                    z-index: 10;
                    display: none; /* Hidden by default */
                }
            </style>
        </head>
        <body>
            <div class="video-container">
               <!-- Optional custom title overlay -->
               <div class="custom-title" id="custom-title">\(videoTitle)</div>
               
               <iframe id="vimeo-player" 
                     src="https://player.vimeo.com/video/\(videoID)?h=\(hash)&autoplay=\(autoplay)&loop=false&title=true&byline=false&portrait=false&controls=true&playsinline=true"
                       frameborder="0" 
                       allow="autoplay; fullscreen; picture-in-picture" 
                       allowfullscreen>
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
                var restrictionCorrectionTimeout;
                var SEEK_TOLERANCE = \(seekTolerance);
                var actualMaxWatchedPosition = \(maxAllowedSeek);
                var pendingResumeAfterAlert = false;
                var hasHandledInitialBookmark = false;
                var isFullscreen = false;
                var lastScale = 1;
                
                // Safe message posting to avoid user interaction count issues
                function postMessageSafely(message) {
                    // Delay message posting to avoid interaction count issues
                    setTimeout(function() {
                        try {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.vimeoPlayerHandler) {
                                window.webkit.messageHandlers.vimeoPlayerHandler.postMessage(message);
                            }
                        } catch (error) {
                            console.log('[VimeoRestrictedPlayer] Error posting message:', error);
                        }
                    }, 0);
                }
                
                // Detect fullscreen changes
                document.addEventListener('fullscreenchange', handleFullscreenChange);
                document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
                
                function handleFullscreenChange() {
                    isFullscreen = !!(document.fullscreenElement || document.webkitFullscreenElement);
                    console.log('[VimeoRestrictedPlayer] Fullscreen:', isFullscreen);
                    
                    postMessageSafely({
                        type: 'fullscreenChange',
                        isFullscreen: isFullscreen
                    });
                    
                    if (isFullscreen && seekRestrictionEnabled && !isCompleted) {
                        // Increase monitoring frequency in fullscreen
                        startRestrictionMonitoring(250); // Check every 250ms instead of 500ms
                    } else if (!isFullscreen && seekRestrictionEnabled && !isCompleted) {
                        startRestrictionMonitoring(500); // Back to normal frequency
                    }
                }
                
                // Add iOS-specific viewport monitoring for pinch-to-zoom
                if (window.visualViewport) {
                    window.visualViewport.addEventListener('resize', function() {
                        var currentScale = window.visualViewport.scale;
                        if (currentScale !== lastScale && currentScale > 1.5) {
                            console.log('[VimeoRestrictedPlayer] Zoom detected, scale:', currentScale);
                            // Force a restriction check
                            if (seekRestrictionEnabled && !isCompleted && !isEnforcingRestriction) {
                                player.getCurrentTime().then(function(time) {
                                    if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                        enforceRestrictionImmediate(time);
                                    }
                                }).catch(function(error) {
                                    console.log('[VimeoRestrictedPlayer] Error checking time on zoom:', error);
                                });
                            }
                        }
                        lastScale = currentScale;
                    });
                }
                
                // Player ready event
                player.ready().then(function() {
                    isVideoReady = true;
                    console.log('[VimeoRestrictedPlayer] Player ready');
                    
                    // Get video metadata including title
                    Promise.all([
                        player.getDuration(),
                        player.getVideoTitle()
                    ]).then(function(results) {
                        duration = results[0];
                        var vimeoTitle = results[1];
                        
                        console.log('[VimeoRestrictedPlayer] Duration:', duration);
                        console.log('[VimeoRestrictedPlayer] Vimeo Title:', vimeoTitle);
                        
                        // Send ready message with title info
                        postMessageSafely({
                            type: 'ready',
                            duration: duration,
                            vimeoTitle: vimeoTitle,
                            configuredTitle: "\(videoTitle)",
                            lastWatchedTime: lastWatchedTime,
                            maxAllowedSeek: maxAllowedSeek,
                            shouldShowResumeDialog: lastWatchedTime > \(configuration.resumeOptions.minimumWatchedForResume)
                        });
                        
                        // Start monitoring if restrictions are enabled
                        if (seekRestrictionEnabled && !isCompleted) {
                            startRestrictionMonitoring();
                        }
                        
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error getting video info:', error);
                        
                        // Still send ready message
                        postMessageSafely({
                            type: 'ready',
                            lastWatchedTime: lastWatchedTime,
                            maxAllowedSeek: maxAllowedSeek,
                            shouldShowResumeDialog: lastWatchedTime > \(configuration.resumeOptions.minimumWatchedForResume)
                        });
                        
                        if (seekRestrictionEnabled && !isCompleted) {
                            startRestrictionMonitoring();
                        }
                    });
                }).catch(function(error) {
                    console.log('[VimeoRestrictedPlayer] Player ready error:', error);
                });
                
                // Continuous monitoring function with adjustable interval
                function startRestrictionMonitoring(interval) {
                    interval = interval || 500; // Default to 500ms
                    
                    if (restrictionCheckInterval) {
                        clearInterval(restrictionCheckInterval);
                    }
                    
                    restrictionCheckInterval = setInterval(function() {
                        if (isVideoReady && !isEnforcingRestriction && seekRestrictionEnabled && !isCompleted) {
                            player.getCurrentTime().then(function(time) {
                                if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                    console.log('[VimeoRestrictedPlayer] Restriction violation detected:', time, 'max:', maxAllowedSeek, 'fullscreen:', isFullscreen);
                                    enforceRestrictionImmediate(time);
                                }
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error in monitoring:', error);
                            });
                        }
                    }, interval);
                }
                
                // Time update event
                player.on('timeupdate', function(data) {
                    currentTime = data.seconds;
                    
                    // Continuous restriction check
                    if (!isEnforcingRestriction && isVideoReady && seekRestrictionEnabled && !isCompleted) {
                        if (currentTime > maxAllowedSeek + SEEK_TOLERANCE) {
                            console.log('[VimeoRestrictedPlayer] Restriction in timeupdate:', currentTime, 'max:', maxAllowedSeek);
                            enforceRestrictionImmediate(currentTime);
                            return;
                        }
                    }
                    
                    // Update max allowed seek position
                    if (!isCompleted && !isEnforcingRestriction && !isUserSeeking) {
                        if (currentTime > actualMaxWatchedPosition) {
                            actualMaxWatchedPosition = currentTime;
                            maxAllowedSeek = currentTime;
                            lastValidTime = currentTime;
                        }
                    }
                    
                    if (!isEnforcingRestriction) {
                        lastValidTime = currentTime;
                    }
                    
                    postMessageSafely({
                        type: 'timeUpdate',
                        currentTime: currentTime,
                        maxAllowed: maxAllowedSeek
                    });
                });
                
                // Restriction enforcement with better error handling
                function enforceRestrictionImmediate(violationTime) {
                    if (isEnforcingRestriction || !seekRestrictionEnabled || isCompleted) {
                        return;
                    }
                    
                    if (violationTime <= maxAllowedSeek + SEEK_TOLERANCE) {
                        console.log('[VimeoRestrictedPlayer] Within tolerance, ignoring');
                        return;
                    }
                   
                    isEnforcingRestriction = true;
                    console.log('[VimeoRestrictedPlayer] Enforcing restriction for time:', violationTime);
                    
                    if (restrictionCorrectionTimeout) {
                        clearTimeout(restrictionCorrectionTimeout);
                    }
                    
                    // Wrap the entire enforcement in try-catch
                    try {
                        player.getPaused().then(function(paused) {
                            wasPlayingBeforeSeek = !paused;
                            pendingResumeAfterAlert = wasPlayingBeforeSeek;
                            
                            return player.pause();
                        }).then(function() {
                            return player.setCurrentTime(maxAllowedSeek);
                        }).then(function() {
                            console.log('[VimeoRestrictedPlayer] Corrected to:', maxAllowedSeek);
                            
                            // Verify position after a delay
                            restrictionCorrectionTimeout = setTimeout(function() {
                                player.getCurrentTime().then(function(verifyTime) {
                                    console.log('[VimeoRestrictedPlayer] Position verified:', verifyTime);
                                    
                                    postMessageSafely({
                                        type: 'seekRestricted',
                                        attemptedTime: violationTime,
                                        maxAllowed: maxAllowedSeek,
                                        wasPlaying: wasPlayingBeforeSeek,
                                        actualPosition: verifyTime,
                                        isFullscreen: isFullscreen
                                    });
                                    
                                    isEnforcingRestriction = false;
                                    
                                }).catch(function(error) {
                                    console.log('[VimeoRestrictedPlayer] Error verifying position:', error);
                                    isEnforcingRestriction = false;
                                });
                            }, 100);
                            
                        }).catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error in enforcement chain:', error);
                            isEnforcingRestriction = false;
                        });
                    } catch (error) {
                        console.log('[VimeoRestrictedPlayer] Sync error in enforcement:', error);
                        isEnforcingRestriction = false;
                    }
                }
                
                // Seeking event
                player.on('seeking', function(data) {
                    console.log('[VimeoRestrictedPlayer] Seeking event:', data.seconds);
                    
                    if (isEnforcingRestriction) {
                        return;
                    }
                    
                    isUserSeeking = true;
                    var seekTime = data.seconds;
                    
                    if (seekRestrictionEnabled && !isCompleted && seekTime > maxAllowedSeek + SEEK_TOLERANCE) {
                        enforceRestrictionImmediate(seekTime);
                    }
                });
                
                // Seeked event
                player.on('seeked', function(data) {
                    console.log('[VimeoRestrictedPlayer] Seeked event:', data.seconds);
                    
                    setTimeout(function() {
                        isUserSeeking = false;
                    }, 100);
                    
                    if (isEnforcingRestriction) {
                        return;
                    }
                    
                    var currentSeekTime = data.seconds;
                    
                    if (seekRestrictionEnabled && !isCompleted && currentSeekTime > maxAllowedSeek + SEEK_TOLERANCE) {
                        enforceRestrictionImmediate(currentSeekTime);
                    }
                });
                
                // Other events with safe message posting
                player.on('play', function() {
                    postMessageSafely({ type: 'play' });
                });
                
                player.on('pause', function() {
                    postMessageSafely({ type: 'pause' });
                });
                
                player.on('ended', function() {
                    postMessageSafely({ type: 'ended' });
                });
                
                player.on('error', function(error) {
                    postMessageSafely({
                        type: 'error',
                        error: error.message || 'Unknown error'
                    });
                });
                
                // Function to restart video
                function restartVideo() {
                    if (isVideoReady && !isEnforcingRestriction) {
                        console.log('[VimeoRestrictedPlayer] Restarting video');
                        
                        actualMaxWatchedPosition = 0;
                        maxAllowedSeek = 0;
                        lastValidTime = 0;
                        
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
                
                // Set current time with bookmark support
                function setCurrentTime(time, shouldPlay) {
                    shouldPlay = shouldPlay === undefined ? false : shouldPlay;
                    console.log('[VimeoRestrictedPlayer] setCurrentTime:', time, 'shouldPlay:', shouldPlay);
                    
                    if (!isVideoReady) {
                        console.log('[VimeoRestrictedPlayer] Video not ready');
                        return;
                    }
                    
                    if (isEnforcingRestriction) {
                        console.log('[VimeoRestrictedPlayer] Cannot seek while enforcing restriction');
                        return;
                    }
                    
                    var targetTime = time;
                    
                    // Only restrict if trying to seek beyond the maximum allowed position
                    if (seekRestrictionEnabled && !isCompleted && time > maxAllowedSeek + 0.5 && time > lastWatchedTime + 0.5) {
                        console.log('[VimeoRestrictedPlayer] Seek beyond allowed, using max:', maxAllowedSeek);
                        targetTime = maxAllowedSeek;
                    }
                    
                    console.log('[VimeoRestrictedPlayer] Setting time to:', targetTime);
                    
                    player.setCurrentTime(targetTime).then(function(seconds) {
                        console.log('[VimeoRestrictedPlayer] Successfully set time to:', seconds);
                        currentTime = targetTime;
                        
                        if (shouldPlay) {
                            player.play().then(function() {
                                console.log('[VimeoRestrictedPlayer] Playing after seek');
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error playing after seek:', error);
                            });
                        }
                        
                        postMessageSafely({
                            type: 'seekCompleted',
                            time: targetTime,
                            wasRequested: time,
                            isPlaying: shouldPlay
                        });
                        
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error setting time:', error);
                        
                        postMessageSafely({
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
                        setCurrentTime(lastWatchedTime, false);
                    }
                }
                
                // Play video
                function playVideo() {
                    if (isVideoReady && !isEnforcingRestriction) {
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
                
                // Update max allowed seek
                function updateMaxAllowedSeek(newMax) {
                    console.log('[VimeoRestrictedPlayer] Updating max allowed seek to:', newMax);
                    if (newMax > maxAllowedSeek) {
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
                            isEnforcing: isEnforcingRestriction,
                            lastValid: lastValidTime,
                            pendingResume: pendingResumeAfterAlert,
                            lastWatchedTime: lastWatchedTime,
                            isFullscreen: isFullscreen
                        };
                    }
                    return null;
                }
                
                // Resume video after alert
                function resumeVideoAfterAlert() {
                    console.log('[VimeoRestrictedPlayer] Resume after alert - pending:', pendingResumeAfterAlert);
                    
                    if (!isVideoReady) {
                        return;
                    }
                    
                    player.getCurrentTime().then(function(time) {
                        console.log('[VimeoRestrictedPlayer] Current position:', time, 'Max allowed:', maxAllowedSeek);
                        
                        if (time > maxAllowedSeek + 0.5) {
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
                                setTimeout(function() {
                                    player.play().then(function() {
                                        console.log('[VimeoRestrictedPlayer] Video resumed');
                                        pendingResumeAfterAlert = false;
                                    }).catch(function(error) {
                                        console.log('[VimeoRestrictedPlayer] Error resuming:', error);
                                    });
                                }, 100);
                            }
                        }
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error getting time:', error);
                    });
                }
                
                // Cleanup
                function cleanup() {
                    console.log('[VimeoRestrictedPlayer] Cleanup called');
                    
                    try {
                        if (isVideoReady) {
                            player.pause().catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error pausing during cleanup:', error);
                            });
                        }
                        
                        if (restrictionCheckInterval) {
                            clearInterval(restrictionCheckInterval);
                            restrictionCheckInterval = null;
                        }
                        
                        if (restrictionCorrectionTimeout) {
                            clearTimeout(restrictionCorrectionTimeout);
                            restrictionCorrectionTimeout = null;
                        }
                        
                        // Remove event listeners
                        document.removeEventListener('fullscreenchange', handleFullscreenChange);
                        document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
                        
                        isEnforcingRestriction = false;
                        pendingResumeAfterAlert = false;
                        isVideoReady = false;
                        
                        console.log('[VimeoRestrictedPlayer] Cleanup completed');
                    } catch (error) {
                        console.log('[VimeoRestrictedPlayer] Error during cleanup:', error);
                    }
                }
                
                // Expose functions globally for iOS to call
                window.VimeoPlayer = {
                    restartVideo: restartVideo,
                    setCurrentTime: setCurrentTime,
                    resumeFromBookmark: resumeFromBookmark,
                    playVideo: playVideo,
                    pauseVideo: pauseVideo,
                    updateMaxAllowedSeek: updateMaxAllowedSeek,
                    getPlayerState: getPlayerState,
                    resumeVideoAfterAlert: resumeVideoAfterAlert,
                    cleanup: cleanup
                };
            </script>
        </body>
        </html>
        """
    }
}
