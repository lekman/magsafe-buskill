//
//  iCloudSyncService.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Manages iCloud synchronization for settings and evidence data
//

import CloudKit
import Combine
import Foundation

/// Service responsible for syncing data with iCloud
///
/// This service handles:
/// - Settings synchronization across devices
/// - Evidence backup to iCloud
/// - Conflict resolution
/// - Sync status monitoring
public class iCloudSyncService: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Current sync status
    @Published public private(set) var syncStatus: SyncStatus = .unknown

    /// Whether iCloud is available
    @Published public private(set) var isAvailable = false

    /// Last successful sync timestamp
    @Published public private(set) var lastSyncDate: Date?

    /// Sync error if any
    @Published public private(set) var syncError: Error?

    // MARK: - Private Properties

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Record types
    private let settingsRecordType = "Settings"
    private let evidenceRecordType = "Evidence"

    // Zone name
    private let customZoneName = "MagSafeGuardZone"
    private var customZone: CKRecordZone?

    // MARK: - Initialization

    public override init() {
        // Initialize with specific container identifier
        // Use the app's bundle identifier as the base
        let containerIdentifier = "iCloud.com.lekman.magsafeguard"
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase

        super.init()

        setupCloudKit()
        checkiCloudAvailability()
        startPeriodicSync()
    }

    // MARK: - Setup

    private func setupCloudKit() {
        // Create custom zone for our data
        let zone = CKRecordZone(zoneName: customZoneName)
        customZone = zone

        privateDatabase.save(zone) { [weak self] _, error in
            if let error = error as? CKError, error.code == .zoneNotFound {
                // Zone doesn't exist, which is fine for first run
                Log.debug("Custom zone will be created on first save", category: .general)
            } else if let error = error {
                Log.error("Failed to create custom zone", error: error, category: .general)
                self?.syncError = error
            } else {
                Log.info("Custom zone ready for sync", category: .general)
            }
        }
    }

    private func checkiCloudAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isAvailable = true
                    self?.syncStatus = .idle
                    Log.info("iCloud is available", category: .general)
                case .noAccount:
                    self?.isAvailable = false
                    self?.syncStatus = .noAccount
                    Log.warning("No iCloud account configured", category: .general)
                case .restricted:
                    self?.isAvailable = false
                    self?.syncStatus = .restricted
                    Log.warning("iCloud access is restricted", category: .general)
                case .couldNotDetermine:
                    self?.isAvailable = false
                    self?.syncStatus = .unknown
                    Log.warning("Could not determine iCloud status", category: .general)
                case .temporarilyUnavailable:
                    self?.isAvailable = false
                    self?.syncStatus = .temporarilyUnavailable
                    Log.warning("iCloud is temporarily unavailable", category: .general)
                @unknown default:
                    self?.isAvailable = false
                    self?.syncStatus = .unknown
                }

                if let error = error {
                    self?.syncError = error
                    Log.error("Error checking iCloud status", error: error, category: .general)
                }
            }
        }
    }

    // MARK: - Sync Control

    /// Start periodic sync (every 5 minutes)
    private func startPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                try? await self?.syncAll()
            }
        }
    }

    /// Stop periodic sync
    public func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Public Sync Methods

    /// Sync all data with iCloud
    @MainActor
    public func syncAll() async throws {
        guard isAvailable else {
            Log.warning("Cannot sync - iCloud not available", category: .general)
            return
        }

        syncStatus = .syncing
        syncError = nil

        do {
            // Sync settings first
            try await syncSettings()

            // Then sync evidence
            try await syncEvidence()

            syncStatus = .idle
            lastSyncDate = Date()
            Log.info("Sync completed successfully", category: .general)
        } catch {
            syncStatus = .error
            syncError = error
            Log.error("Sync failed", error: error, category: .general)
        }
    }

    /// Force sync settings to iCloud
    @MainActor
    public func syncSettings() async throws {
        guard let zone = customZone else {
            throw SyncError.zoneNotReady
        }

        // Get current settings
        let settings = UserDefaults.standard.data(forKey: "com.lekman.magsafeguard.settings") ?? Data()

        // Create or update settings record
        let recordID = CKRecord.ID(recordName: "user-settings", zoneID: zone.zoneID)

        do {
            // Try to fetch existing record
            let existingRecord = try await privateDatabase.record(for: recordID)

            // Check if local is newer
            let localTimestamp = UserDefaults.standard.double(forKey: "settingsTimestamp")
            let remoteTimestamp = existingRecord["timestamp"] as? Double ?? 0

            if localTimestamp > remoteTimestamp {
                // Update remote with local
                existingRecord["data"] = settings
                existingRecord["timestamp"] = localTimestamp
                existingRecord["deviceName"] = ProcessInfo.processInfo.hostName

                try await privateDatabase.save(existingRecord)
                Log.info("Settings uploaded to iCloud", category: .general)
            } else if remoteTimestamp > localTimestamp {
                // Update local with remote
                if let remoteData = existingRecord["data"] as? Data {
                    UserDefaults.standard.set(remoteData, forKey: "com.lekman.magsafeguard.settings")
                    UserDefaults.standard.set(remoteTimestamp, forKey: "settingsTimestamp")

                    // Notify settings manager to reload
                    NotificationCenter.default.post(name: .settingsSyncedFromiCloud, object: nil)
                    Log.info("Settings downloaded from iCloud", category: .general)
                }
            }
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, create new one
            let newRecord = CKRecord(recordType: settingsRecordType, recordID: recordID)
            newRecord["data"] = settings
            newRecord["timestamp"] = Date().timeIntervalSince1970
            newRecord["deviceName"] = ProcessInfo.processInfo.hostName

            try await privateDatabase.save(newRecord)
            Log.info("Settings uploaded to iCloud (new record)", category: .general)
        }
    }

    /// Sync evidence data to iCloud
    @MainActor
    public func syncEvidence() async throws {
        guard let zone = customZone else {
            throw SyncError.zoneNotReady
        }

        // Get evidence directory
        let documentsDirectory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence", isDirectory: true)

        guard FileManager.default.fileExists(atPath: evidenceDirectory.path) else {
            Log.debug("No evidence to sync", category: .general)
            return
        }

        // Get all evidence files
        let files = try FileManager.default.contentsOfDirectory(at: evidenceDirectory, includingPropertiesForKeys: nil)
        let evidenceFiles = files.filter { $0.pathExtension == "encrypted" }

        for file in evidenceFiles {
            let evidenceID = file.deletingPathExtension().lastPathComponent

            // Check if already synced
            let syncedKey = "synced_\(evidenceID)"
            if UserDefaults.standard.bool(forKey: syncedKey) {
                continue
            }

            // Create evidence record
            let recordID = CKRecord.ID(recordName: evidenceID, zoneID: zone.zoneID)
            let record = CKRecord(recordType: evidenceRecordType, recordID: recordID)

            // Add encrypted data as asset
            let asset = CKAsset(fileURL: file)
            record["encryptedData"] = asset
            record["timestamp"] = Date()
            record["deviceName"] = ProcessInfo.processInfo.hostName

            do {
                try await privateDatabase.save(record)

                // Mark as synced
                UserDefaults.standard.set(true, forKey: syncedKey)
                Log.info("Evidence \(evidenceID) synced to iCloud", category: .general)
            } catch {
                Log.error("Failed to sync evidence \(evidenceID)", error: error, category: .general)
                throw error
            }
        }
    }

    /// Download evidence from iCloud
    @MainActor
    public func downloadEvidence() async throws {
        guard let zone = customZone else {
            throw SyncError.zoneNotReady
        }

        // Query for all evidence records
        let query = CKQuery(recordType: evidenceRecordType, predicate: NSPredicate(value: true))

        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query, inZoneWith: zone.zoneID, desiredKeys: nil, resultsLimit: 100)

            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    await processDownloadedEvidence(record)
                case .failure(let error):
                    Log.error("Failed to fetch evidence record", error: error, category: .general)
                }
            }
        } catch {
            Log.error("Failed to query evidence records", error: error, category: .general)
            throw error
        }
    }

    private func processDownloadedEvidence(_ record: CKRecord) async {
        guard let asset = record["encryptedData"] as? CKAsset,
              let fileURL = asset.fileURL else {
            Log.warning("Evidence record missing data", category: .general)
            return
        }

        let evidenceID = record.recordID.recordName

        // Get evidence directory
        guard let documentsDirectory = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }

        let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence", isDirectory: true)
        try? FileManager.default.createDirectory(at: evidenceDirectory, withIntermediateDirectories: true)

        let destinationURL = evidenceDirectory.appendingPathComponent("\(evidenceID).encrypted")

        // Don't download if already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return
        }

        do {
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
            Log.info("Evidence \(evidenceID) downloaded from iCloud", category: .general)
        } catch {
            Log.error("Failed to save downloaded evidence", error: error, category: .general)
        }
    }

    // MARK: - Delete from iCloud

    /// Delete evidence from iCloud
    public func deleteEvidence(evidenceID: String) async throws {
        guard let zone = customZone else {
            throw SyncError.zoneNotReady
        }

        let recordID = CKRecord.ID(recordName: evidenceID, zoneID: zone.zoneID)

        do {
            try await privateDatabase.deleteRecord(withID: recordID)

            // Remove synced flag
            UserDefaults.standard.removeObject(forKey: "synced_\(evidenceID)")

            Log.info("Evidence \(evidenceID) deleted from iCloud", category: .general)
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, which is fine
            Log.debug("Evidence \(evidenceID) not found in iCloud", category: .general)
        }
    }
}

// MARK: - Supporting Types

/// Sync status states
public enum SyncStatus {
    case unknown
    case idle
    case syncing
    case error
    case noAccount
    case restricted
    case temporarilyUnavailable

    public var displayText: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .idle:
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .error:
            return "Sync Error"
        case .noAccount:
            return "No iCloud Account"
        case .restricted:
            return "iCloud Restricted"
        case .temporarilyUnavailable:
            return "iCloud Unavailable"
        }
    }

    public var symbolName: String {
        switch self {
        case .unknown:
            return "icloud.slash"
        case .idle:
            return "icloud.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .error:
            return "exclamationmark.icloud.fill"
        case .noAccount:
            return "icloud.slash"
        case .restricted:
            return "lock.icloud.fill"
        case .temporarilyUnavailable:
            return "icloud.slash"
        }
    }
}

/// Sync errors
public enum SyncError: LocalizedError {
    case zoneNotReady
    case notAvailable
    case syncInProgress

    public var errorDescription: String? {
        switch self {
        case .zoneNotReady:
            return "iCloud zone not ready"
        case .notAvailable:
            return "iCloud not available"
        case .syncInProgress:
            return "Sync already in progress"
        }
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let settingsSyncedFromiCloud = Notification.Name("settingsSyncedFromiCloud")
}
