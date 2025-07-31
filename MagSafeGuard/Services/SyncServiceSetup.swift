//
//  SyncServiceSetup.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//

import CloudKit
import Foundation

/// Handles CloudKit initialization and setup for sync service
final class SyncServiceSetup {
    private let logFile = URL(fileURLWithPath: "/tmp/magsafe-sync.log")

    /// Check if running in test environment
    var isTestEnvironment: Bool {
        return AppController.isTestEnvironment ||
               ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
               ProcessInfo.processInfo.environment["CI"] != nil
    }

    /// Initialize CloudKit container
    func initializeContainer() -> CKContainer? {
        let timestamp = Date().formatted(.iso8601)

        if isTestEnvironment {
            Log.debug("Running in test environment - CloudKit disabled", category: .general)
            try? Data("\(timestamp): Running in test environment - CloudKit disabled\n".utf8).append(to: logFile)
            return nil
        }

        Log.info("Initializing CloudKit with default container", category: .general)
        try? Data("\(timestamp): Initializing CloudKit with default container\n".utf8).append(to: logFile)

        let container = CKContainer.default()

        #if DEBUG
        // Log container info for debugging
        let containerID = container.containerIdentifier ?? "Unknown"
        Log.debug("Container identifier: \(containerID)", category: .general)
        try? Data("\(timestamp): Container ID: \(containerID)\n".utf8).append(to: logFile)
        #endif

        return container
    }

    /// Setup database and permissions
    func setupDatabase(for container: CKContainer) async throws {
        // Request permissions for the private database
        let database = container.privateCloudDatabase

        // Verify we can access the database
        let query = CKQuery(recordType: "Settings", predicate: NSPredicate(value: true))
        query.resultsLimit = 1

        do {
            _ = try await database.records(matching: query)
            Log.info("CloudKit database access verified", category: .general)
        } catch {
            Log.error("Failed to access CloudKit database", error: error, category: .general)
            throw error
        }
    }
}
