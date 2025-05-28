//
//  VimeoURLParser.swift
//  VimeoRestrictedPlayer
//
//  Created by Kashif Hussain on 28/05/25.
//


import Foundation

/// Utility for parsing Vimeo URLs
internal struct VimeoURLParser {
    
    /// Parse a Vimeo URL to extract video ID and hash.
    ///
    /// It handles URLs with or without a scheme, with various Vimeo domains (including player),
    /// and paths that might include other segments before the video ID.
    /// The hash is considered optional; if not present, an empty string is returned for the hash.
    ///
    /// - Parameter urlString: The Vimeo URL string.
    /// - Returns: A tuple containing the `videoId` (String) and `hash` (String, empty if not found),
    ///            or `nil` if a numeric video ID cannot be parsed.
    static func parse(_ urlString: String) -> (videoId: String, hash: String)? {
        // MARK: - Primary Parsing using URLComponents
        // This method is generally more robust for well-formed URLs and complex paths.
        if let url = URL(string: urlString) {
            // url.pathComponents can include "/" and empty strings, filter them out.
            // e.g., "https://vimeo.com/123/abc" -> pathComponents: ["/", "123", "abc"]
            // e.g., "vimeo.com/123/abc" (no scheme) -> pathComponents: ["/", "vimeo.com", "123", "abc"]
            let components = url.pathComponents.filter { !$0.isEmpty && $0 != "/" }
            
            // Find the first purely numeric component in the path. This is assumed to be the videoId.
            // This handles paths like "/channels/foo/123456789/hash" or just "/123456789".
            if let videoIdIndex = components.firstIndex(where: { $0.allSatisfy({ char in char.isNumber }) && !$0.isEmpty }) {
                let videoId = components[videoIdIndex]
                
                // Check if a hash component exists immediately after the videoId.
                if videoIdIndex + 1 < components.count {
                    let hashValue = components[videoIdIndex + 1]
                    // A hash value should not be an empty string if the component exists.
                    if !hashValue.isEmpty {
                        return (videoId: videoId, hash: hashValue)
                    } else {
                        // If the next component is empty (e.g., from a URL like "vimeo.com/123//"),
                        // treat it as if there's no hash.
                        return (videoId: videoId, hash: "")
                    }
                } else {
                    // No component follows the videoId, so no hash is present.
                    return (videoId: videoId, hash: "")
                }
            }
        }
        
        // MARK: - Fallback Parsing using String Manipulation
        // This handles simpler cases, URLs that URL(string:) might fail to parse,
        // or when the URLComponents method doesn't find a numeric ID (e.g. if the string is just "123/hash").
        let cleanedURL = urlString
            .replacingOccurrences(of: "https://vimeo.com/", with: "")
            .replacingOccurrences(of: "http://vimeo.com/", with: "")
            .replacingOccurrences(of: "https://www.vimeo.com/", with: "")
            .replacingOccurrences(of: "http://www.vimeo.com/", with: "")
            .replacingOccurrences(of: "player.vimeo.com/video/", with: "") // Handle player URLs
            .replacingOccurrences(of: "vimeo.com/", with: "") // Generic vimeo.com prefix
            .replacingOccurrences(of: "www.vimeo.com/", with: "") // Generic www.vimeo.com prefix
        // Remove query parameters and fragments which might interfere with path splitting
            .components(separatedBy: "?").first?
            .components(separatedBy: "#").first ?? ""
        
        // Split the cleaned string by "/" and remove any empty components that might result
        // (e.g., from trailing slashes or consecutive slashes).
        let components = cleanedURL.components(separatedBy: "/").filter { !$0.isEmpty }
        
        // After cleaning, if the first component is numeric, it's considered the video ID.
        if let firstComponent = components.first,
           firstComponent.allSatisfy({ char in char.isNumber }),
           !firstComponent.isEmpty {
            
            let videoId = firstComponent
            // If there's a second component, it's treated as the hash.
            if components.count >= 2 {
                let hashValue = components[1]
                // Ensure the hash component itself is not empty.
                if !hashValue.isEmpty {
                    return (videoId: videoId, hash: hashValue)
                } else {
                    // e.g., if cleanedURL was "12345/", components would be ["12345"],
                    // but if it was "12345//hash", filter { !$0.isEmpty } would handle it.
                    // This case handles if components[1] was explicitly an empty string segment somehow.
                    return (videoId: videoId, hash: "")
                }
            } else {
                // Only one component (the videoId) was found; no hash.
                return (videoId: videoId, hash: "")
            }
        }
        
        // If neither parsing method succeeds in finding a numeric video ID.
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
