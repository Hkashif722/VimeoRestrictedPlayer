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
    
    // MARK: - Generate Vimeo HTML with Fixed Bookmark Support
    private func generateHTML() -> String {
        let lastWatched = configuration.lastWatchedDuration
        let autoplay = "false"
        let moduleStatus = configuration.isCompleted || configuration.allowsFullSeek
        let (videoID, hash) = VimeoURLParser.parse(configuration.videoURL) ?? ("", "")
        let videoTitle = configuration.videoTitle
        
        // Ensure maxAllowedSeekPosition is at least equal to lastWatched
        let maxAllowedSeek = max(lastWatched, 0)
        
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
                    var moduleStatus = '\(moduleStatus)';
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
                    var SEEK_TOLERANCE = 1.0;
                    var actualMaxWatchedPosition = \(maxAllowedSeek);
                    var pendingResumeAfterAlert = false;
                    var hasHandledInitialBookmark = false;
                    
                    // FIXED: Player ready event with automatic bookmark handling
                    player.ready().then(function() {
                        isVideoReady = true;
                        console.log('Player ready - lastWatchedTime:', lastWatchedTime, 'maxAllowedSeek:', maxAllowedSeek);
                        
                        // Get duration
                        player.getDuration().then(function(videoDuration) {
                            duration = videoDuration;
                            console.log('Video duration:', duration);
                            
                            // Send ready message
                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                type: 'ready',
                                duration: duration,
                                lastWatchedTime: lastWatchedTime,
                                maxAllowedSeek: maxAllowedSeek,
                                shouldShowResumeDialog: lastWatchedTime > 5
                            });
                            
                            // FIXED: Automatically handle bookmark if user has watched more than 5 seconds
                            if (lastWatchedTime > 5 && !hasHandledInitialBookmark) {
                                hasHandledInitialBookmark = true;
                                console.log('Handling initial bookmark - will wait for user choice in resume dialog');
                                // Don't automatically seek here - let the resume dialog handle it
                            }
                            
                            // Start monitoring
                            startRestrictionMonitoring();
                            
                        }).catch(function(error) {
                            console.log('Error getting duration:', error);
                            
                            // Still send ready message
                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                type: 'ready',
                                lastWatchedTime: lastWatchedTime,
                                maxAllowedSeek: maxAllowedSeek,
                                shouldShowResumeDialog: lastWatchedTime > 5
                            });
                            
                            startRestrictionMonitoring();
                        });
                    });
                    
                    // Continuous monitoring function
                    function startRestrictionMonitoring() {
                        if (restrictionCheckInterval) {
                            clearInterval(restrictionCheckInterval);
                        }
                        
                        restrictionCheckInterval = setInterval(function() {
                            if (isVideoReady && !isEnforcingRestriction && moduleStatus) {
                                player.getCurrentTime().then(function(time) {
                                    if (time > maxAllowedSeek + SEEK_TOLERANCE) {
                                        console.log('Restriction violation detected in monitoring:', time, 'max:', maxAllowedSeek);
                                        enforceRestrictionImmediate(time);
                                    }
                                }).catch(function(error) {
                                    console.log('Error getting current time in monitoring:', error);
                                });
                            }
                        }, 500);
                    }
                    
                    // Time update event
                    player.on('timeupdate', function(data) {
                        currentTime = data.seconds;
                        
                        // Continuous restriction check
                        if (!isEnforcingRestriction && isVideoReady && moduleStatus) {
                            if (currentTime > maxAllowedSeek + SEEK_TOLERANCE) {
                                console.log('Restriction violation in timeupdate:', currentTime, 'max:', maxAllowedSeek);
                                enforceRestrictionImmediate(currentTime);
                                return;
                            }
                        }
                        
                        // Update max allowed seek position
                        if (moduleStatus && !isEnforcingRestriction && !isUserSeeking) {
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
                        if (isEnforcingRestriction) {
                            return;
                        }
                        
                        if (violationTime <= maxAllowedSeek + 0.5) {
                            console.log('Violation within tolerance, ignoring');
                            return;
                        }
                        
                        var currentTimeRounded = Math.floor(violationTime);
                        if (Math.abs(currentTimeRounded - lastRestrictionTime) < 2) {
                            console.log('Recent restriction already applied');
                            return;
                        }
                        
                        lastRestrictionTime = currentTimeRounded;
                        isEnforcingRestriction = true;
                        console.log('Enforcing restriction for time:', violationTime);
                        
                        if (restrictionCorrectionTimeout) {
                            clearTimeout(restrictionCorrectionTimeout);
                        }
                        
                        player.getPaused().then(function(paused) {
                            wasPlayingBeforeSeek = !paused;
                            pendingResumeAfterAlert = wasPlayingBeforeSeek;
                            
                            player.pause().then(function() {
                                player.setCurrentTime(maxAllowedSeek).then(function() {
                                    console.log('Corrected to:', maxAllowedSeek);
                                    
                                    setTimeout(function() {
                                        player.getCurrentTime().then(function(verifyTime) {
                                            console.log('Position verified:', verifyTime);
                                            
                                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                                type: 'seekRestricted',
                                                attemptedTime: violationTime,
                                                maxAllowed: maxAllowedSeek,
                                                wasPlaying: wasPlayingBeforeSeek,
                                                actualPosition: verifyTime
                                            });
                                            
                                            isEnforcingRestriction = false;
                                            
                                        }).catch(function(error) {
                                            console.log('Error verifying position:', error);
                                            isEnforcingRestriction = false;
                                        });
                                    }, 100);
                                    
                                }).catch(function(error) {
                                    console.log('Error setting time:', error);
                                    isEnforcingRestriction = false;
                                });
                            }).catch(function(error) {
                                console.log('Error pausing:', error);
                                isEnforcingRestriction = false;
                            });
                        }).catch(function(error) {
                            console.log('Error getting paused state:', error);
                            isEnforcingRestriction = false;
                        });
                    }
                    
                    // Seeking event
                    player.on('seeking', function(data) {
                        console.log('Seeking event:', data.seconds);
                        
                        if (isEnforcingRestriction) {
                            return;
                        }
                        
                        isUserSeeking = true;
                        var seekTime = data.seconds;
                        
                        if (moduleStatus !== 'completed' && seekTime > maxAllowedSeek + 0.5) {
                            enforceRestrictionImmediate(seekTime);
                        }
                    });
                    
                    // Seeked event
                    player.on('seeked', function(data) {
                        console.log('Seeked event:', data.seconds);
                        
                        setTimeout(function() {
                            isUserSeeking = false;
                        }, 100);
                        
                        if (isEnforcingRestriction) {
                            return;
                        }
                        
                        var currentSeekTime = data.seconds;
                        
                        if (moduleStatus && currentSeekTime > maxAllowedSeek + 0.5) {
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
                            error: error.message
                        });
                    });
                    
                    // Function to restart video
                    function restartVideo() {
                        if (isVideoReady && !isEnforcingRestriction) {
                            console.log('Restarting video from beginning');
                            
                            actualMaxWatchedPosition = 0;
                            maxAllowedSeek = 0;
                            lastValidTime = 0;
                            
                            player.setCurrentTime(0).then(function() {
                                console.log('Video restarted');
                                currentTime = 0;
                                
                                // Optionally start playing
                                player.play().then(function() {
                                    console.log('Video playing from start');
                                }).catch(function(error) {
                                    console.log('Error playing after restart:', error);
                                });
                            }).catch(function(error) {
                                console.log('Error restarting video:', error);
                            });
                        }
                    }
                    
                    // FIXED: Enhanced setCurrentTime with bookmark support
                    function setCurrentTime(time, shouldPlay) {
                        shouldPlay = shouldPlay === undefined ? false : shouldPlay;
                        console.log('setCurrentTime called - time:', time, 'shouldPlay:', shouldPlay, 'isVideoReady:', isVideoReady);
                        
                        if (!isVideoReady) {
                            console.log('Video not ready yet');
                            return;
                        }
                        
                        if (isEnforcingRestriction) {
                            console.log('Cannot seek while enforcing restriction');
                            return;
                        }
                        
                        // For bookmark functionality, allow seeking to any previously watched position
                        var targetTime = time;
                        
                        // Only restrict if trying to seek beyond the maximum allowed position
                        if (moduleStatus && time > maxAllowedSeek + 0.5 && time > lastWatchedTime + 0.5) {
                            console.log('Seek beyond allowed position, using max allowed:', maxAllowedSeek);
                            targetTime = maxAllowedSeek;
                        }
                        
                        console.log('Setting current time to:', targetTime);
                        
                        player.setCurrentTime(targetTime).then(function(seconds) {
                            console.log('Successfully set time to:', seconds);
                            currentTime = targetTime;
                            
                            if (shouldPlay) {
                                player.play().then(function() {
                                    console.log('Video playing after seek');
                                }).catch(function(error) {
                                    console.log('Error playing after seek:', error);
                                });
                            }
                            
                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                type: 'seekCompleted',
                                time: targetTime,
                                wasRequested: time,
                                isPlaying: shouldPlay
                            });
                            
                        }).catch(function(error) {
                            console.log('Error setting time:', error);
                            
                            window.webkit.messageHandlers.vimeoPlayerHandler.postMessage({
                                type: 'seekError',
                                error: error.message,
                                requestedTime: time
                            });
                        });
                    }
                    
                    // FIXED: Resume from bookmark position
                    function resumeFromBookmark() {
                        if (isVideoReady && lastWatchedTime > 0) {
                            console.log('Resuming from bookmark position:', lastWatchedTime);
                            setCurrentTime(lastWatchedTime, false);
                        }
                    }
                    
                    // Play video
                    function playVideo() {
                        if (isVideoReady && !isEnforcingRestriction) {
                            player.play().catch(function(error) {
                                console.log('Error playing video:', error);
                            });
                        }
                    }
                    
                    // Pause video  
                    function pauseVideo() {
                        if (isVideoReady) {
                            player.pause().then(function() {
                                console.log('Video paused');
                            }).catch(function(error) {
                                console.log('Error pausing video:', error);
                            });
                        }
                    }
                    
                    // Update max allowed seek
                    function updateMaxAllowedSeek(newMax) {
                        console.log('Updating max allowed seek to:', newMax);
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
                        console.log('resumeVideoAfterAlert called - pendingResumeAfterAlert:', pendingResumeAfterAlert);
                        
                        if (!isVideoReady) {
                            return;
                        }
                        
                        player.getCurrentTime().then(function(time) {
                            console.log('Current position:', time, 'Max allowed:', maxAllowedSeek);
                            
                            if (time > maxAllowedSeek + 0.5) {
                                player.setCurrentTime(maxAllowedSeek).then(function() {
                                    console.log('Position corrected');
                                    
                                    if (pendingResumeAfterAlert) {
                                        player.play().then(function() {
                                            console.log('Video resumed');
                                            pendingResumeAfterAlert = false;
                                        }).catch(function(error) {
                                            console.log('Error resuming:', error);
                                        });
                                    }
                                }).catch(function(error) {
                                    console.log('Error correcting position:', error);
                                });
                            } else {
                                if (pendingResumeAfterAlert) {
                                    player.play().then(function() {
                                        console.log('Video resumed');
                                        pendingResumeAfterAlert = false;
                                    }).catch(function(error) {
                                        console.log('Error resuming:', error);
                                    });
                                }
                            }
                        }).catch(function(error) {
                            console.log('Error getting time:', error);
                        });
                    }
                    
                    // Cleanup
                    function cleanup() {
                        console.log('Cleanup called');
                        
                        if (isVideoReady) {
                            player.pause().catch(function(error) {
                                console.log('Error pausing during cleanup:', error);
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
                        
                        lastRestrictionTime = -1;
                        isEnforcingRestriction = false;
                        pendingResumeAfterAlert = false;
                        isVideoReady = false;
                        
                        console.log('Cleanup completed');
                    }
                </script>
            </body>
            </html>
            """
    }
}
