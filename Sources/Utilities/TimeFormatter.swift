//
//  for.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


//
//  TimeFormatter.swift
//  VimeoRestrictedPlayer
//
//  Utility for formatting time values
//

import Foundation

/// Utility class for formatting time values
internal struct TimeFormatter {
    
    /// Format seconds into a readable time string
    /// - Parameter seconds: Time in seconds
    /// - Returns: Formatted time string (e.g., "2:45" or "1:02:30")
    static func format(seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    /// Format seconds into a verbose time string
    /// - Parameter seconds: Time in seconds
    /// - Returns: Verbose formatted time string (e.g., "2 minutes 45 seconds")
    static func formatVerbose(seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        var components: [String] = []
        
        if hours > 0 {
            components.append(hours == 1 ? "1 hour" : "\(hours) hours")
        }
        
        if minutes > 0 {
            components.append(minutes == 1 ? "1 minute" : "\(minutes) minutes")
        }
        
        if remainingSeconds > 0 || components.isEmpty {
            components.append(remainingSeconds == 1 ? "1 second" : "\(remainingSeconds) seconds")
        }
        
        if components.count == 1 {
            return components[0]
        } else if components.count == 2 {
            return "\(components[0]) and \(components[1])"
        } else {
            let last = components.removeLast()
            return "\(components.joined(separator: ", ")), and \(last)"
        }
    }
    
    /// Parse a time string into seconds
    /// - Parameter timeString: Time string (e.g., "2:45" or "1:02:30")
    /// - Returns: Time in seconds, or nil if parsing fails
    static func parse(timeString: String) -> TimeInterval? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        
        switch components.count {
        case 1:
            // Just seconds
            return TimeInterval(components[0])
        case 2:
            // Minutes:seconds
            return TimeInterval(components[0] * 60 + components[1])
        case 3:
            // Hours:minutes:seconds
            return TimeInterval(components[0] * 3600 + components[1] * 60 + components[2])
        default:
            return nil
        }
    }
}