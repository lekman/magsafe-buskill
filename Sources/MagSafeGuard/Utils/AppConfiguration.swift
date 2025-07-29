//
//  AppConfiguration.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Application configuration constants and environment variables
//

import Foundation

/// Application configuration with customizable parameters
public enum AppConfiguration {

    // MARK: - URLs

    /// Base URL for Google Maps
    public static let googleMapsBaseURL = ProcessInfo.processInfo.environment["MAGSAFE_GOOGLE_MAPS_URL"] ?? "https://maps.google.com/"

    /// Format for Google Maps coordinate queries
    public static let googleMapsQueryFormat = "?q=%@,%@"

    // MARK: - System Paths

    /// Base path for system binaries
    public static let systemBinPath = ProcessInfo.processInfo.environment["MAGSAFE_BASH_BASE_PATH"] ?? "/bin"

    // MARK: - Helper Methods

    /// Constructs a Google Maps URL for the given coordinates
    /// - Parameters:
    ///   - latitude: The latitude coordinate
    ///   - longitude: The longitude coordinate
    /// - Returns: A formatted Google Maps URL
    public static func googleMapsURL(latitude: Double, longitude: Double) -> String {
        return googleMapsBaseURL + String(format: googleMapsQueryFormat, "\(latitude)", "\(longitude)")
    }
}
