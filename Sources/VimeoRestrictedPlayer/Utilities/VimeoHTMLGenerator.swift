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
                     src="https://player.vimeo.com/video/\(videoID)?h=\(hash)&autoplay=\(autoplay)&loop=false&title=false&byline=false&portrait=false&controls=true&playsinline=true"
                       frameborder="0" 
                       allow="autoplay; fullscreen" 
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
                
                // Continuous monitoring function
                function startRestrictionMonitoring() {
                    if (restrictionCheckInterval) {
                        clearInterval(restrictionCheckInterval);
                    }
                    
                    restrictionCheckInterval = setInterval(function() {
                        if (isVideoReady && !isEnforcingRestriction && seekRestrictionEnabled && !isCompleted) {
                            player.getCurrentTime().then(function(time) {
                                if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                    console.log('[VimeoRestrictedPlayer] Restriction violation detected:', time, 'max:', maxAllowedSeek);
                                    enforceRestrictionImmediate(time);
                                }
                            }).catch(function(error) {
                                console.log('[VimeoRestrictedPlayer] Error in monitoring:', error);
                            });
                        }
                    }, 500);
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
                    
                    window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                        type: 'timeUpdate',
                        currentTime: currentTime,
                        maxAllowed: maxAllowedSeek
                    });
                });
                
                // Restriction enforcement
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
                    
                    player.getPaused().then(function(paused) {
                        wasPlayingBeforeSeek = !paused;
                        pendingResumeAfterAlert = wasPlayingBeforeSeek;
                        
                        player.pause().then(function() {
                            player.setCurrentTime(maxAllowedSeek).then(function() {
                                console.log('[VimeoRestrictedPlayer] Corrected to:', maxAllowedSeek);
                                
                                setTimeout(function() {
                                    player.getCurrentTime().then(function(verifyTime) {
                                        console.log('[VimeoRestrictedPlayer] Position verified:', verifyTime);
                                        
                                        window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                            type: 'seekRestricted',
                                            attemptedTime: violationTime,
                                            maxAllowed: maxAllowedSeek,
                                            wasPlaying: wasPlayingBeforeSeek,
                                            actualPosition: verifyTime
                                        });
                                        
                                        isEnforcingRestriction = false;
                                        
                                    }).catch(function(error) {
                                        console.log('[VimeoRestrictedPlayer] Error verifying position:', error);
                                        isEnforcingRestriction = false;
                                    });
                                }, 100);
                                
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
                        
                        window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                            type: 'seekCompleted',
                            time: targetTime,
                            wasRequested: time,
                            isPlaying: shouldPlay
                        });
                        
                    }).catch(function(error) {
                        console.log('[VimeoRestrictedPlayer] Error setting time:', error);
                        
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
                            lastWatchedTime: lastWatchedTime
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
                                    player.play().then(function() {
                                        console.log('[VimeoRestrictedPlayer] Video resumed');
                                        pendingResumeAfterAlert = false;
                                    }).catch(function(error) {
                                        console.log('[VimeoRestrictedPlayer] Error resuming:', error);
                                    });
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
                
                // Cleanup
                function cleanup() {
                    console.log('[VimeoRestrictedPlayer] Cleanup called');
                    
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
                    

                    isEnforcingRestriction = false;
                    pendingResumeAfterAlert = false;
                    isVideoReady = false;
                    
                    console.log('[VimeoRestrictedPlayer] Cleanup completed');
                }
            </script>
        </body>
        </html>
        """
    }
}
