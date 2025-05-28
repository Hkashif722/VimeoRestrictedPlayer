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
                var lastRestrictionTime = -1;
                var SEEK_TOLERANCE = \(seekTolerance);
                var actualMaxWatchedPosition = \(maxAllowedSeek);
                var pendingResumeAfterAlert = false;
                var bookmarkPending = false;
                var bookmarkTime = lastWatchedTime;
                
                // Player ready event
                player.ready().then(function() {
                    isVideoReady = true;
                    console.log('[VimeoRestrictedPlayer] Player ready');
                    
                    // Get duration
                    player.getDuration().then(function(videoDuration) {
                        duration = videoDuration;
                        console.log('[VimeoRestrictedPlayer] Duration:', duration);
                        
                        // Clamp max allowed seek to duration
                        maxAllowedSeek = Math.min(maxAllowedSeek, duration);
                        actualMaxWatchedPosition = Math.min(actualMaxWatchedPosition, duration);
                        
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
                        
                        // Handle pending bookmark
                        if (bookmarkPending) {
                            console.log('[VimeoRestrictedPlayer] Applying pending bookmark');
                            applyBookmark();
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
                        
                        // Handle pending bookmark
                        if (bookmarkPending) {
                            console.log('[VimeoRestrictedPlayer] Applying pending bookmark after duration error');
                            applyBookmark();
                        }
                    });
                });
                
                // Continuous monitoring function
                function startRestrictionMonitoring() {
                    if (restrictionCheckInterval) {
                        clearInterval(restrictionCheckInterval);
                    }
                    
                    restrictionCheckInterval = setInterval(function() {
                        if (isVideoReady && !isEnforcingRestriction && seekRestrictionEnabled && !isCompleted) {
                            player.getCurrentTime().then(function(time) {
                                // Check if we need to enforce restriction
                                if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                    console.log('[VimeoRestrictedPlayer] Restriction violation detected:', time, 'max:', maxAllowedSeek);
                                    enforceRestrictionImmediate(time);
                                }
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error in monitoring:', error);
                            });
                        }
                    }, 50); // 50ms monitoring interval
                }
                
                // Time update event
                player.on('timeupdate', function(data) {
                    currentTime = data.seconds;
                    
                    // Update max allowed position during normal playback
                    if (!isEnforcingRestriction && !isUserSeeking && currentTime > actualMaxWatchedPosition) {
                        actualMaxWatchedPosition = currentTime;
                        maxAllowedSeek = currentTime;
                    }
                    
                    // Immediate restriction check in timeupdate
                    if (!isEnforcingRestriction && isVideoReady && seekRestrictionEnabled && !isCompleted) {
                        if (currentTime > maxAllowedSeek + SEEK_TOLERANCE) {
                            console.log('[VimeoRestrictedPlayer] Restriction in timeupdate:', currentTime, 'max:', maxAllowedSeek);
                            enforceRestrictionImmediate(currentTime);
                            return;
                        }
                    }
                    
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'timeUpdate',
                        currentTime: currentTime,
                        maxAllowed: maxAllowedSeek
                    });
                });
                
                // Enhanced restriction enforcement
                function enforceRestrictionImmediate(violationTime) {
                    if (isEnforcingRestriction || !seekRestrictionEnabled || isCompleted) {
                        return;
                    }
                    
                    // Skip if within tolerance
                    if (violationTime <= maxAllowedSeek + SEEK_TOLERANCE) {
                        return;
                    }
                    
                    isEnforcingRestriction = true;
                    console.log('[VimeoRestrictedPlayer] Enforcing restriction for time:', violationTime);
                    
                    // Clear any pending timeouts
                    if (restrictionCorrectionTimeout) {
                        clearTimeout(restrictionCorrectionTimeout);
                    }
                    
                    // Store playback state before enforcement
                    player.getPaused().then(function(paused) {
                        wasPlayingBeforeSeek = !paused;
                        pendingResumeAfterAlert = wasPlayingBeforeSeek;
                        
                        // Pause immediately
                        player.pause().then(function() {
                            // Calculate target time (clamped to duration)
                            var targetTime = Math.min(maxAllowedSeek, duration || maxAllowedSeek);
                            
                            // Set to safe position
                            player.setCurrentTime(targetTime).then(function() {
                                console.log('[VimeoRestrictedPlayer] Corrected to:', targetTime);
                                
                                // Verify after short delay
                                restrictionCorrectionTimeout = setTimeout(function() {
                                    player.getCurrentTime().then(function(verifyTime) {
                                        console.log('[VimeoRestrictedPlayer] Position verified:', verifyTime);
                                        
                                        // Report restriction event
                                        window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                            type: 'seekRestricted',
                                            attemptedTime: violationTime,
                                            maxAllowed: maxAllowedSeek,
                                            wasPlaying: wasPlayingBeforeSeek,
                                            actualPosition: verifyTime
                                        });
                                        
                                        isEnforcingRestriction = false;
                                        currentTime = verifyTime;
                                        
                                    }).catch(function(error) {
                                        console.log('[VimeoRestrictedPlayer] Error verifying position:', error);
                                        isEnforcingRestriction = false;
                                    });
                                }, 300); // 300ms verification delay
                                
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error setting time:', error);
                                isEnforcingRestriction = false;
                            });
                        }).catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error pausing:', error);
                            isEnforcingRestriction = false;
                        });
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error getting paused state:', error);
                        isEnforcingRestriction = false;
                    });
                }
                
                // Seeking event - FIXED sequential seek handling
                player.on('seeking', function(data) {
                    console.log('[VimeoRestrictedPlayer] Seeking event:', data.seconds);
                    isUserSeeking = true;
                    
                    if (isEnforcingRestriction) {
                        return;
                    }
                    
                    var seekTime = data.seconds;
                    if (seekRestrictionEnabled && !isCompleted && seekTime > maxAllowedSeek + SEEK_TOLERANCE) {
                        console.log('[VimeoRestrictedPlayer] Seeking beyond allowed point');
                        enforceRestrictionImmediate(seekTime);
                    }
                });
                
                // Seeked event - FIXED sequential seek handling
                player.on('seeked', function(data) {
                    console.log('[VimeoRestrictedPlayer] Seeked event:', data.seconds);
                    
                    // Delay clearing seeking flag to catch sequential seeks
                    setTimeout(function() {
                        isUserSeeking = false;
                    }, 300);
                    
                    if (isEnforcingRestriction) {
                        return;
                    }
                    
                    var currentSeekTime = data.seconds;
                    if (seekRestrictionEnabled && !isCompleted && currentSeekTime > maxAllowedSeek + SEEK_TOLERANCE) {
                        console.log('[VimeoRestrictedPlayer] Seeked beyond allowed point');
                        enforceRestrictionImmediate(currentSeekTime);
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
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'ended'
                    });
                });
                
                player.on('error', function(error) {
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'error',
                        error: error.message || 'Unknown error'
                    });
                });
                
                // Bookmark application
                function applyBookmark() {
                    if (!isVideoReady) {
                        console.log('[VimeoRestrictedPlayer] Player not ready for bookmark');
                        bookmarkPending = true;
                        return;
                    }
                    
                    console.log('[VimeoRestrictedPlayer] Applying bookmark at:', bookmarkTime);
                    player.setCurrentTime(bookmarkTime).then(function() {
                        console.log('[VimeoRestrictedPlayer] Bookmark applied');
                        currentTime = bookmarkTime;
                        lastValidTime = bookmarkTime;
                        bookmarkPending = false;
                        
                        // Update max allowed to at least the bookmark position
                        if (bookmarkTime > actualMaxWatchedPosition) {
                            actualMaxWatchedPosition = bookmarkTime;
                            maxAllowedSeek = bookmarkTime;
                        }
                        
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error applying bookmark:', error);
                        bookmarkPending = false;
                    });
                }
                
                // Restart video
                function restartVideo() {
                    if (isVideoReady && !isEnforcingRestriction) {
                        console.log('[VimeoRestrictedPlayer] Restarting video');
                        
                        actualMaxWatchedPosition = 0;
                        maxAllowedSeek = 0;
                        
                        player.setCurrentTime(0).then(function() {
                            console.log('[VimeoRestrictedPlayer] Video restarted');
                            
                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                type: 'restartCompleted'
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
                    
                    if (!isVideoReady || isEnforcingRestriction) {
                        console.log('[VimeoRestrictedPlayer] Player not ready or enforcing restriction');
                        return;
                    }
                    
                    var targetTime = time;
                    
                    // Apply restriction if needed
                    if (seekRestrictionEnabled && !isCompleted && time > maxAllowedSeek + SEEK_TOLERANCE) {
                        console.log('[VimeoRestrictedPlayer] Seek beyond allowed, using max:', maxAllowedSeek);
                        targetTime = maxAllowedSeek;
                    }
                    
                    // Clamp to duration
                    if (duration > 0 && targetTime > duration) {
                        targetTime = duration;
                    }
                    
                    player.setCurrentTime(targetTime).then(function(seconds) {
                        console.log('[VimeoRestrictedPlayer] Successfully set time to:', seconds);
                        currentTime = seconds;
                        lastValidTime = seconds;
                        
                        if (shouldPlay) {
                            player.play().catch(function(error) {
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
                    });
                }
                
                // Resume from bookmark position - FIXED
                function resumeFromBookmark() {
                    console.log('[VimeoRestrictedPlayer] Resuming from bookmark:', lastWatchedTime);
                    bookmarkTime = lastWatchedTime;
                    applyBookmark();
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
                        player.pause().catch(function(error) {
                            console.log('[VimeoRestrictedPlayer] Error pausing:', error);
                        });
                    }
                }
                
                // Update max allowed seek
                function updateMaxAllowedSeek(newMax) {
                    console.log('[VimeoRestrictedPlayer] Updating max allowed seek to:', newMax);
                    
                    // Clamp to duration if available
                    if (duration > 0) {
                        newMax = Math.min(newMax, duration);
                    }
                    
                    if (newMax > maxAllowedSeek) {
                        maxAllowedSeek = newMax;
                        actualMaxWatchedPosition = newMax;
                    }
                }
                
                // Resume video after alert
                function resumeVideoAfterAlert() {
                    console.log('[VimeoRestrictedPlayer] Resume after alert - pending:', pendingResumeAfterAlert);
                    
                    if (!isVideoReady) {
                        return;
                    }
                    
                    player.getCurrentTime().then(function(time) {
                        // Correct position if needed
                        if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                            player.setCurrentTime(maxAllowedSeek).then(function() {
                                if (pendingResumeAfterAlert) {
                                    player.play();
                                }
                            });
                        } else if (pendingResumeAfterAlert) {
                            player.play();
                        }
                        
                        pendingResumeAfterAlert = false;
                    });
                }
                
                // Cleanup
                function cleanup() {
                    console.log('[VimeoRestrictedPlayer] Cleanup called');
                    
                    if (restrictionCheckInterval) {
                        clearInterval(restrictionCheckInterval);
                    }
                    
                    if (restrictionCorrectionTimeout) {
                        clearTimeout(restrictionCorrectionTimeout);
                    }
                    
                    isEnforcingRestriction = false;
                    pendingResumeAfterAlert = false;
                }
            </script>
        </body>
        </html>
        """
    }
}
