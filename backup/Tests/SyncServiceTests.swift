//
//  SyncServiceTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Tests for the iCloud sync functionality
//

import XCTest

@testable import MagSafeGuard

class SyncServiceTests: XCTestCase {

  var mockSyncService: MockSyncService!

  override func setUp() {
    super.setUp()
    mockSyncService = MockSyncService()
  }

  override func tearDown() {
    mockSyncService = nil
    super.tearDown()
  }

  // MARK: - Tests

  func testSyncServiceInitialization() {
    // Test that sync service initializes with correct default state
    XCTAssertEqual(mockSyncService.syncStatus, .idle)
    XCTAssertNil(mockSyncService.lastSyncDate)
    XCTAssertNil(mockSyncService.syncError)
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
    mockSyncService.stopPeriodicSync()

    // Since timer is private, we can only verify the method doesn't crash
    XCTAssertNotNil(mockSyncService)
  }

  func testSyncAllSuccess() async throws {
    // Test successful sync
    mockSyncService.shouldFailSync = false

    try await mockSyncService.syncAll()

    XCTAssertEqual(mockSyncService.syncStatus, .idle)
    XCTAssertNotNil(mockSyncService.lastSyncDate)
    XCTAssertNil(mockSyncService.syncError)
    XCTAssertEqual(mockSyncService.syncCallCount, 1)
    XCTAssertEqual(mockSyncService.syncSettingsCallCount, 1)
    XCTAssertEqual(mockSyncService.syncEvidenceCallCount, 1)
  }

  func testSyncAllFailure() async {
    // Test sync failure
    mockSyncService.shouldFailSync = true

    do {
      try await mockSyncService.syncAll()
      XCTFail("Sync should have failed")
    } catch {
      XCTAssertEqual(mockSyncService.syncStatus, .error)
      XCTAssertNotNil(mockSyncService.syncError)
      XCTAssertEqual(mockSyncService.syncCallCount, 1)
    }
  }

  func testDeleteEvidence() async throws {
    // Test deleting evidence
    mockSyncService.shouldFailSync = false

    try await mockSyncService.deleteEvidence(evidenceID: "test-id")

    XCTAssertEqual(mockSyncService.deleteEvidenceCallCount, 1)
  }
}
