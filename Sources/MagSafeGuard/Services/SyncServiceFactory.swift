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
            Log.debug("Test environment detected - sync service disabled", category: .general)
            return nil
        }
        
        // In DEBUG mode, only create sync service if explicitly enabled
        if !UserDefaults.standard.bool(forKey: "com.lekman.magsafeguard.cloudkit.debug.enabled") {
            Log.info("CloudKit sync disabled in DEBUG mode - set com.lekman.magsafeguard.cloudkit.debug.enabled to enable", category: .general)
            return nil
        }
        #endif

        // Check if app bundle identifier is available (optional check for Xcode)
        if Bundle.main.bundleIdentifier == nil {
            Log.warning("No bundle identifier found - sync service may have limited functionality", category: .general)
        }

        // Create sync service - it will handle initialization errors gracefully
        let syncService = SyncService()
        Log.info("Sync service created (CloudKit initialization deferred)", category: .general)
        return syncService
    }
}
