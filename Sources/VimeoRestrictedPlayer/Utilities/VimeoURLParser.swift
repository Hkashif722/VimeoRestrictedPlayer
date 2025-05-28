//
//  VimeoURLParser.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


import Foundation

/// Utility for parsing Vimeo URLs
internal struct VimeoURLParser {
    
    /// Parse a Vimeo URL to extract video ID and hash
    /// - Parameter urlString: The Vimeo URL string
    /// - Returns: Tuple containing video ID and hash, or nil if parsing fails
    static func parse(_ urlString: String) -> (videoId: String, hash: String)? {
        // Remove common URL prefixes
        let cleanedURL = urlString
            .replacingOccurrences(of: "https://vimeo.com/", with: "")
            .replacingOccurrences(of: "http://vimeo.com/", with: "")
            .replacingOccurrences(of: "https://www.vimeo.com/", with: "")
            .replacingOccurrences(of: "http://www.vimeo.com/", with: "")
            .replacingOccurrences(of: "vimeo.com/", with: "")
            .replacingOccurrences(of: "www.vimeo.com/", with: "")
        
        // Split by '/' to get components
        let components = cleanedURL.components(separatedBy: "/")
        
        // Standard Vimeo URL format: VIDEO_ID/HASH
        if components.count == 2,
           !components[0].isEmpty,
           !components[1].isEmpty {
            return (videoId: components[0], hash: components[1])
        }
        
        // Try parsing with URL components
        if let url = URL(string: urlString) {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            
            if pathComponents.count >= 2 {
                let videoId = pathComponents[0]
                let hash = pathComponents[1]
                
                // Validate that video ID is numeric
                if videoId.allSatisfy({ $0.isNumber }) {
                    return (videoId: videoId, hash: hash)
                }
            }
            
            // Check for video ID in different positions
            for (index, component) in pathComponents.enumerated() {
                if component.allSatisfy({ $0.isNumber }) && index + 1 < pathComponents.count {
                    return (videoId: component, hash: pathComponents[index + 1])
                }
            }
        }
        
        return nil
    }
    
    /// Validate if a string is a valid Vimeo URL
    /// - Parameter urlString: The URL string to validate
    /// - Returns: True if valid, false otherwise
    static func isValidVimeoURL(_ urlString: String) -> Bool {
        return parse(urlString) != nil
    }
    
    /// Extract video ID from a Vimeo URL
    /// - Parameter urlString: The Vimeo URL string
    /// - Returns: Video ID or nil if not found
    static func extractVideoID(from urlString: String) -> String? {
        return parse(urlString)?.videoId
    }
    
    /// Extract hash from a Vimeo URL
    /// - Parameter urlString: The Vimeo URL string
    /// - Returns: Hash or nil if not found
    static func extractHash(from urlString: String) -> String? {
        return parse(urlString)?.hash
    }
    
    /// Construct a Vimeo embed URL from components
    /// - Parameters:
    ///   - videoId: The video ID
    ///   - hash: The video hash
    ///   - parameters: Additional query parameters
    /// - Returns: Constructed embed URL
    static func constructEmbedURL(videoId: String, hash: String, parameters: [String: String] = [:]) -> String {
        var urlString = "https://player.vimeo.com/video/\(videoId)?h=\(hash)"
        
        // Add default parameters
        var allParameters = [
            "title": "true",
            "byline": "false",
            "portrait": "false",
            "controls": "true",
            "playsinline": "true"
        ]
        
        // Merge with custom parameters
        allParameters.merge(parameters) { (_, new) in new }
        
        // Build query string
        let queryString = allParameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        if !queryString.isEmpty {
            urlString += "&\(queryString)"
        }
        
        return urlString
    }
}
