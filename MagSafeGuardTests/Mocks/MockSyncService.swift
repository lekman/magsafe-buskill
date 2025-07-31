//
//  MockSyncService.swift
//  MagSafe Guard Tests
//
//  Created on 2025-07-28.
//
//  Mock implementation of iCloud sync service for testing
//

import Foundation
import Combine
@testable import MagSafeGuard

/// Mock implementation of iCloud sync service for testing
public class MockSyncService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var syncStatus: SyncStatus = .idle
    @Published public private(set) var isAvailable = true
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var syncError: Error?
    
    // MARK: - Test Control Properties
    
    public var shouldFailSync = false
    public var syncDelay: TimeInterval = 0
    public var syncCallCount = 0
    public var syncSettingsCallCount = 0
    public var syncEvidenceCallCount = 0
    public var deleteEvidenceCallCount = 0
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    public func stopPeriodicSync() {
        // No-op for mock
    }
    
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
    
    @MainActor
    public func syncSettings() async throws {
        syncSettingsCallCount += 1
        
        if shouldFailSync {
            throw SyncError.notAvailable
        }
        
        // Simulate successful sync
        await Task.yield()
    }
    
    @MainActor
    public func syncEvidence() async throws {
        syncEvidenceCallCount += 1
        
        if shouldFailSync {
            throw SyncError.notAvailable
        }
        
        // Simulate successful sync
        await Task.yield()
    }
    
    public func deleteEvidence(evidenceID: String) async throws {
        deleteEvidenceCallCount += 1
        
        if shouldFailSync {
            throw SyncError.notAvailable
        }
        
        // Simulate successful deletion
        await Task.yield()
    }
    
    @MainActor
    public func downloadEvidence() async throws {
        if shouldFailSync {
            throw SyncError.notAvailable
        }
        
        // Simulate successful download
        await Task.yield()
    }
}