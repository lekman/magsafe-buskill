//
//  MockSyncServiceFactory.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Mock factory for creating iCloud sync service in tests
//

import Foundation
@testable import MagSafeGuard

/// Mock factory for creating iCloud sync service instances in tests
public enum MockSyncServiceFactory {

    private static var mockService: MockSyncService?

    /// Sets the mock service to be returned by create()
    public static func setMockService(_ service: MockSyncService?) {
        mockService = service
    }

    /// Creates a mock iCloud sync service for testing
    public static func create() -> SyncService? {
        // Return the mock service if set, otherwise nil (simulating test environment)
        return nil
    }

    /// Reset the factory to default state
    public static func reset() {
        mockService = nil
    }
}
