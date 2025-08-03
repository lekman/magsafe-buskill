//
//  MockSyncService.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Mock implementation of iCloud sync service for testing
//

import Combine
import Foundation

@testable import MagSafeGuard

/// Mock implementation of iCloud sync service for testing
public class MockSyncService: ObservableObject {

  // MARK: - Published Properties

  /// Current sync status
  @Published public private(set) var syncStatus: SyncStatus = .idle
  /// Whether sync service is available
  @Published public private(set) var isAvailable = true
  /// Date of last successful sync
  @Published public private(set) var lastSyncDate: Date?
  /// Last sync error if any
  @Published public private(set) var syncError: Error?

  // MARK: - Test Control Properties

  /// Controls whether sync operations should fail
  public var shouldFailSync = false
  /// Delay to simulate async operations
  public var syncDelay: TimeInterval = 0
  /// Number of times sync was called
  public var syncCallCount = 0
  /// Number of times syncSettings was called
  public var syncSettingsCallCount = 0
  /// Number of times syncEvidence was called
  public var syncEvidenceCallCount = 0
  /// Number of times deleteEvidence was called
  public var deleteEvidenceCallCount = 0

  // MARK: - Initialization

  /// Initializes a new mock sync service
  public init() {}

  // MARK: - Public Methods

  /// Stops periodic sync (no-op in mock)
  public func stopPeriodicSync() {
    // No-op for mock
  }

  /// Syncs all data types
  @MainActor
  public func syncAll() async throws {
    syncCallCount += 1

    if shouldFailSync {
      syncStatus = .error
      syncError = SyncError.notAvailable
      throw SyncError.notAvailable
    }

    syncStatus = .syncing

    if syncDelay > 0 {
      try await Task.sleep(nanoseconds: UInt64(syncDelay * 1_000_000_000))
    }

    try await syncSettings()
    try await syncEvidence()

    syncStatus = .idle
    lastSyncDate = Date()
    syncError = nil
  }

  /// Syncs settings to cloud
  @MainActor
  public func syncSettings() async throws {
    syncSettingsCallCount += 1

    if shouldFailSync {
      throw SyncError.notAvailable
    }

    // Simulate successful sync
    await Task.yield()
  }

  /// Syncs evidence files to cloud
  @MainActor
  public func syncEvidence() async throws {
    syncEvidenceCallCount += 1

    if shouldFailSync {
      throw SyncError.notAvailable
    }

    // Simulate successful sync
    await Task.yield()
  }

  /// Deletes evidence from cloud
  public func deleteEvidence(evidenceID: String) async throws {
    deleteEvidenceCallCount += 1

    if shouldFailSync {
      throw SyncError.notAvailable
    }

    // Simulate successful deletion
    await Task.yield()
  }

  /// Downloads evidence from cloud
  @MainActor
  public func downloadEvidence() async throws {
    if shouldFailSync {
      throw SyncError.notAvailable
    }

    // Simulate successful download
    await Task.yield()
  }
}
