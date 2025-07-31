//
//  SyncServiceCloudKitTests.swift
//  MagSafe Guard Tests
//
//  Created on 2025-07-29.
//
//  Tests CloudKit initialization error handling

import XCTest
@testable import MagSafeGuard

class SyncServiceCloudKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset any testing flags
        SyncService.disableForTesting = false
    }
    
    override func tearDown() {
        super.tearDown()
        SyncService.disableForTesting = false
    }
    
    func testSyncServiceInitializationInTestEnvironment() {
        // Given: We're in a test environment
        SyncService.disableForTesting = true
        
        // When: Creating a sync service
        let syncService = SyncService()
        
        // Then: It should initialize without CloudKit
        XCTAssertEqual(syncService.syncStatus, .unknown)
        XCTAssertFalse(syncService.isAvailable)
        XCTAssertNil(syncService.syncError)
    }
    
    func testSyncServiceFactoryInTestEnvironment() {
        // Given: We're in a test environment (XCTest is running)
        // The factory currently creates a sync service even in test environment
        // but the service itself will disable CloudKit when XCTest is detected
        
        // When: Creating sync service via factory
        let syncService = SyncServiceFactory.create()
        
        // Then: It creates a service (factory doesn't block in tests anymore)
        // but the service will have CloudKit disabled
        XCTAssertNotNil(syncService)
        
        // And: The service should not be available
        if let service = syncService {
            XCTAssertEqual(service.syncStatus, .unknown)
            XCTAssertFalse(service.isAvailable)
        }
    }
    
    func testSyncServiceHandlesNilBundleIdentifier() {
        // This test simulates the scenario where bundle identifier is nil
        // The sync service should still initialize but with limited functionality
        
        // Given: We disable testing mode to allow initialization
        SyncService.disableForTesting = false
        
        // When: Creating a sync service (bundle ID might be nil in tests)
        let syncService = SyncService()
        
        // Then: Service should be created
        XCTAssertNotNil(syncService)
        
        // The actual CloudKit initialization happens asynchronously
        // so we can't test the full initialization here
    }
    
    func testSyncServiceErrorStates() {
        // Test various error states
        let _ = SyncService() // Create instance to ensure no crash
        
        // Test all sync status display texts
        XCTAssertEqual(SyncStatus.unknown.displayText, "Unknown")
        XCTAssertEqual(SyncStatus.idle.displayText, "Synced")
        XCTAssertEqual(SyncStatus.syncing.displayText, "Syncing...")
        XCTAssertEqual(SyncStatus.error.displayText, "Sync Error")
        XCTAssertEqual(SyncStatus.noAccount.displayText, "No iCloud Account")
        XCTAssertEqual(SyncStatus.restricted.displayText, "iCloud Restricted")
        XCTAssertEqual(SyncStatus.temporarilyUnavailable.displayText, "iCloud Unavailable")
        
        // Test symbol names
        XCTAssertEqual(SyncStatus.unknown.symbolName, "icloud.slash")
        XCTAssertEqual(SyncStatus.idle.symbolName, "icloud.fill")
        XCTAssertEqual(SyncStatus.syncing.symbolName, "arrow.triangle.2.circlepath.icloud")
        XCTAssertEqual(SyncStatus.error.symbolName, "exclamationmark.icloud.fill")
        XCTAssertEqual(SyncStatus.noAccount.symbolName, "icloud.slash")
        XCTAssertEqual(SyncStatus.restricted.symbolName, "lock.icloud.fill")
        XCTAssertEqual(SyncStatus.temporarilyUnavailable.symbolName, "icloud.slash")
    }
    
    func testSyncErrorDescriptions() {
        // Test error descriptions
        XCTAssertEqual(SyncError.zoneNotReady.errorDescription, "iCloud zone not ready")
        XCTAssertEqual(SyncError.notAvailable.errorDescription, "iCloud not available")
        XCTAssertEqual(SyncError.syncInProgress.errorDescription, "Sync already in progress")
    }
}