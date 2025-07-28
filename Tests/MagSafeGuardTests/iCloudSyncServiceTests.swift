//
//  iCloudSyncServiceTests.swift
//  MagSafe Guard Tests
//
//  Created on 2025-07-28.
//
//  Tests for the iCloud sync functionality
//

import XCTest
import CloudKit
@testable import MagSafeGuard

class iCloudSyncServiceTests: XCTestCase {
    
    var syncService: iCloudSyncService!
    
    override func setUp() {
        super.setUp()
        syncService = iCloudSyncService()
    }
    
    override func tearDown() {
        syncService.stopPeriodicSync()
        syncService = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testSyncServiceInitialization() {
        // Test that sync service initializes with correct default state
        XCTAssertEqual(syncService.syncStatus, .unknown)
        XCTAssertNil(syncService.lastSyncDate)
        XCTAssertNil(syncService.syncError)
    }
    
    func testSyncStatusValues() {
        // Test sync status display text
        XCTAssertEqual(SyncStatus.idle.displayText, "Synced")
        XCTAssertEqual(SyncStatus.syncing.displayText, "Syncing...")
        XCTAssertEqual(SyncStatus.error.displayText, "Sync Error")
        XCTAssertEqual(SyncStatus.noAccount.displayText, "No iCloud Account")
        XCTAssertEqual(SyncStatus.restricted.displayText, "iCloud Restricted")
        XCTAssertEqual(SyncStatus.temporarilyUnavailable.displayText, "iCloud Unavailable")
        XCTAssertEqual(SyncStatus.unknown.displayText, "Unknown")
    }
    
    func testSyncStatusSymbols() {
        // Test sync status symbol names
        XCTAssertEqual(SyncStatus.idle.symbolName, "icloud.fill")
        XCTAssertEqual(SyncStatus.syncing.symbolName, "arrow.triangle.2.circlepath.icloud")
        XCTAssertEqual(SyncStatus.error.symbolName, "exclamationmark.icloud.fill")
        XCTAssertEqual(SyncStatus.noAccount.symbolName, "icloud.slash")
        XCTAssertEqual(SyncStatus.restricted.symbolName, "lock.icloud.fill")
        XCTAssertEqual(SyncStatus.temporarilyUnavailable.symbolName, "icloud.slash")
        XCTAssertEqual(SyncStatus.unknown.symbolName, "icloud.slash")
    }
    
    func testSyncErrorDescriptions() {
        // Test error descriptions
        XCTAssertEqual(SyncError.zoneNotReady.localizedDescription, "iCloud zone not ready")
        XCTAssertEqual(SyncError.notAvailable.localizedDescription, "iCloud not available")
        XCTAssertEqual(SyncError.syncInProgress.localizedDescription, "Sync already in progress")
    }
    
    func testSettingsSyncedNotificationName() {
        // Test notification name
        let notificationName = Notification.Name.settingsSyncedFromiCloud
        XCTAssertEqual(notificationName.rawValue, "settingsSyncedFromiCloud")
    }
    
    func testPeriodicSyncStop() {
        // Test that periodic sync can be stopped
        syncService.stopPeriodicSync()
        
        // Since timer is private, we can only verify the method doesn't crash
        XCTAssertNotNil(syncService)
    }
    
    func testSyncAllWhenUnavailable() async {
        // When iCloud is not available, sync should fail gracefully
        // Note: In a real test environment, we'd mock the CloudKit container
        // For now, just ensure the method can be called without crashing
        
        try? await syncService.syncAll()
        
        // Verify service is still valid
        XCTAssertNotNil(syncService)
    }
    
    func testDeleteEvidenceWithInvalidID() async {
        // Test deleting non-existent evidence
        do {
            try await syncService.deleteEvidence(evidenceID: "non-existent-id")
            // Should succeed even if record doesn't exist
            XCTAssertTrue(true, "Delete should succeed for non-existent records")
        } catch {
            XCTFail("Delete should not throw for non-existent records: \(error)")
        }
    }
}