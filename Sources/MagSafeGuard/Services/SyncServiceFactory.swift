//
//  SyncServiceFactory.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Factory for creating iCloud sync service based on environment
//

import Foundation

/// Factory for creating iCloud sync service instances
public enum SyncServiceFactory {

    /// Creates an iCloud sync service if not in test environment
    public static func create() -> SyncService? {
        #if DEBUG
        // Check if running in test environment
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return nil
        }
        #endif
        
        // Check if app bundle identifier is available
        guard Bundle.main.bundleIdentifier != nil else {
            Log.warning("No bundle identifier found - sync service disabled", category: .general)
            return nil
        }
        
        // Create sync service (will handle errors gracefully)
        return SyncService()
    }
}
