//
//  SyncService.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Manages iCloud synchronization for settings and evidence data
//

import CloudKit
import Combine
import Foundation
import Network

/// Service responsible for syncing data with iCloud
///
/// This service handles:
/// - Settings synchronization across devices
/// - Evidence backup to iCloud
/// - Conflict resolution
/// - Sync status monitoring
public class SyncService: NSObject, ObservableObject {

    // MARK: - Testing Support

    /// Disable CloudKit initialization for testing
    public static var disableForTesting = false

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

    private var container: CKContainer?
    private var privateDatabase: CKDatabase?
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var retryTimer: Timer?
    private var retryCount = 0
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 30.0
    private var isCloudKitInitialized = false

    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.magsafeguard.network")
    private var wasOffline = false

    // Record types
    private let settingsRecordType = "Settings"
    private let evidenceRecordType = "Evidence"

    // Zone name
    private let customZoneName = "MagSafeGuardZone"
    private var customZone: CKRecordZone?

    // MARK: - Initialization

    public override init() {
        super.init()

        // Check if we're in a test environment
        let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                               Self.disableForTesting ||
                               NSClassFromString("XCTest") != nil ||
                               ProcessInfo.processInfo.environment["CI"] != nil

        if isTestEnvironment {
            Log.debug("Running in test environment - CloudKit disabled", category: .general)
            syncStatus = .unknown
            isAvailable = false
            return
        }

        // Disable CloudKit by default to prevent crashes
        // CloudKit requires proper provisioning and container setup
        #if DEBUG
        Log.info("CloudKit sync disabled by default - enable via iCloudSyncEnabled setting", category: .general)
        syncStatus = .noAccount
        isAvailable = false
        #else
        // Only initialize CloudKit if explicitly enabled in production
        if UserDefaults.standard.bool(forKey: "com.lekman.magsafeguard.cloudkit.enabled") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.initializeCloudKit()
            }
        } else {
            syncStatus = .noAccount
            isAvailable = false
        }
        #endif
    }

    // MARK: - CloudKit Initialization

    private func initializeCloudKit() {
        guard !isCloudKitInitialized else { return }

        // Try to initialize CloudKit container
        let containerIdentifier = determineContainerIdentifier()

        Log.info("Initializing CloudKit with container: \(containerIdentifier)", category: .general)

        // Create container - CloudKit will handle errors internally
        container = CKContainer(identifier: containerIdentifier)
        privateDatabase = container?.privateCloudDatabase

        isCloudKitInitialized = true

        // Continue with setup
        setupCloudKit()
        checkiCloudAvailability()
        startPeriodicSync()
        setupNetworkMonitoring()
    }

    private func determineContainerIdentifier() -> String {
        // First try to use the configured container from entitlements
        let primaryIdentifier = "iCloud.com.lekman.magsafeguard"

        // Check if we have a valid bundle identifier
        if let bundleId = Bundle.main.bundleIdentifier {
            // In development/debug builds, the bundle ID might be different
            if bundleId.contains("xcode") || bundleId.contains("lldb") {
                Log.warning("Running with development bundle ID: \(bundleId)", category: .general)
                // Try default container as fallback
                return "iCloud." + bundleId
            }
        }

        return primaryIdentifier
    }

    // MARK: - Setup

    private func setupCloudKit() {
        guard let database = privateDatabase else {
            Log.warning("CloudKit database not available", category: .general)
            return
        }

        // Create custom zone for our data
        let zone = CKRecordZone(zoneName: customZoneName)
        customZone = zone

        database.save(zone) { [weak self] _, error in
            if let error = error as? CKError {
                switch error.code {
                case .zoneNotFound:
                    // Zone doesn't exist, which is fine for first run
                    Log.debug("Custom zone will be created on first save", category: .general)
                case .networkUnavailable, .networkFailure:
                    Log.warning("Network unavailable for zone creation - will retry later", category: .general)
                    self?.scheduleRetry()
                case .permissionFailure, .notAuthenticated:
                    Log.error("CloudKit permission denied", error: error, category: .general)
                    self?.handlePermissionError(error)
                default:
                    Log.error("Failed to create custom zone", error: error, category: .general)
                    self?.syncError = error
                }
            } else if let error = error {
                Log.error("Failed to create custom zone", error: error, category: .general)
                self?.syncError = error
            } else {
                Log.info("Custom zone ready for sync", category: .general)
            }
        }
    }

    private func handlePermissionError(_ error: CKError) {
        syncStatus = .error
        syncError = error
        isAvailable = false

        // More specific error handling
        switch error.code {
        case .notAuthenticated:
            notifyUserAboutiCloudAccount()
        case .permissionFailure:
            notifyUserAboutPermissions()
        default:
            break
        }
    }

    private func checkiCloudAvailability() {
        guard let container = container else {
            Log.warning("CloudKit container not available", category: .general)
            syncStatus = .error
            isAvailable = false
            return
        }

        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    Log.error("Failed to check iCloud account status", error: error, category: .general)
                    self?.isAvailable = false
                    self?.syncStatus = .error
                    self?.syncError = error

                    // If it's a permission error, notify user
                    if let ckError = error as? CKError {
                        switch ckError.code {
                        case .notAuthenticated, .permissionFailure:
                            self?.notifyUserAboutPermissions()
                        default:
                            break
                        }
                    }
                    return
                }

                switch status {
                case .available:
                    self?.isAvailable = true
                    self?.syncStatus = .idle
                    Log.info("iCloud is available", category: .general)
                    // Perform initial sync
                    Task {
                        try? await self?.syncAll()
                    }
                case .noAccount:
                    self?.isAvailable = false
                    self?.syncStatus = .noAccount
                    Log.warning("No iCloud account configured", category: .general)
                    self?.notifyUserAboutiCloudAccount()
                case .restricted:
                    self?.isAvailable = false
                    self?.syncStatus = .restricted
                    Log.warning("iCloud access is restricted", category: .general)
                    self?.notifyUserAboutRestrictions()
                case .couldNotDetermine:
                    self?.isAvailable = false
                    self?.syncStatus = .unknown
                    Log.warning("Could not determine iCloud status", category: .general)
                    // Schedule a retry
                    self?.scheduleRetry()
                case .temporarilyUnavailable:
                    self?.isAvailable = false
                    self?.syncStatus = .temporarilyUnavailable
                    Log.warning("iCloud is temporarily unavailable", category: .general)
                    // Schedule a retry
                    self?.scheduleRetry()
                @unknown default:
                    self?.isAvailable = false
                    self?.syncStatus = .unknown
                }

                if let error = error as? CKError {
                    self?.syncError = error
                    if error.code == .networkUnavailable || error.code == .networkFailure {
                        Log.warning("Network unavailable for iCloud check", category: .general)
                        self?.scheduleRetry()
                    } else {
                        Log.error("Error checking iCloud status", error: error, category: .general)
                    }
                } else if let error = error {
                    self?.syncError = error
                    Log.error("Error checking iCloud status", error: error, category: .general)
                }
            }
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if self?.wasOffline == true {
                        Log.info("Network connection restored - attempting iCloud sync", category: .general)
                        self?.wasOffline = false
                        self?.retryCount = 0 // Reset retry count on network restoration

                        // Check iCloud availability again
                        self?.checkiCloudAvailability()
                    }
                } else {
                    Log.warning("Network connection lost - iCloud sync paused", category: .general)
                    self?.wasOffline = true
                    self?.syncStatus = .temporarilyUnavailable
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    // MARK: - Sync Control

    /// Start periodic sync (every 5 minutes)
    private func startPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            // Check if sync is enabled before running periodic sync
            guard UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") else {
                return
            }

            Task {
                try? await self?.syncAll()
                // Run cleanup every sync cycle
                try? await self?.cleanupOldEvidence()
            }
        }
    }

    /// Stop periodic sync
    public func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        retryTimer?.invalidate()
        retryTimer = nil
    }
}

// MARK: - Public Sync Methods

extension SyncService {
    /// Sync all data with iCloud
    @MainActor
    public func syncAll() async throws {
        // Check if sync is enabled
        guard UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") else {
            Log.debug("iCloud sync is disabled by user", category: .general)
            syncStatus = .idle
            return
        }

        guard isAvailable else {
            Log.warning("Cannot sync - iCloud not available", category: .general)
            syncStatus = .noAccount
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
        } catch let error as CKError {
            // Handle specific CloudKit errors
            switch error.code {
            case .networkUnavailable, .networkFailure:
                syncStatus = .temporarilyUnavailable
                Log.warning("Network unavailable for iCloud sync", category: .general)
                scheduleRetry()
                // Don't throw - we'll retry later
                return
            case .serviceUnavailable, .requestRateLimited:
                syncStatus = .temporarilyUnavailable
                Log.warning("iCloud service temporarily unavailable", category: .general)
                scheduleRetry()
                // Don't throw - we'll retry later
                return
            case .quotaExceeded:
                syncStatus = .error
                syncError = error
                Log.error("iCloud quota exceeded", error: error, category: .general)
                throw error
            default:
                syncStatus = .error
                syncError = error
                Log.error("Sync failed", error: error, category: .general)
                throw error
            }
        } catch {
            syncStatus = .error
            syncError = error
            Log.error("Sync failed", error: error, category: .general)
            throw error
        }
    }

    /// Force sync settings to iCloud
    @MainActor
    public func syncSettings() async throws {
        guard let zone = customZone, let database = privateDatabase else {
            throw SyncError.zoneNotReady
        }

        // Get current settings
        let settings = UserDefaults.standard.data(forKey: "com.lekman.magsafeguard.settings") ?? Data()

        // Create or update settings record
        let recordID = CKRecord.ID(recordName: "user-settings", zoneID: zone.zoneID)

        do {
            // Try to fetch existing record
            let existingRecord = try await database.record(for: recordID)

            // Check if local is newer
            let localTimestamp = UserDefaults.standard.double(forKey: "settingsTimestamp")
            let remoteTimestamp = existingRecord["timestamp"] as? Double ?? 0

            if localTimestamp > remoteTimestamp {
                // Update remote with local
                existingRecord["data"] = settings
                existingRecord["timestamp"] = localTimestamp
                existingRecord["deviceName"] = ProcessInfo.processInfo.hostName

                try await database.save(existingRecord)
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

            try await database.save(newRecord)
            Log.info("Settings uploaded to iCloud (new record)", category: .general)
        } catch let error as CKError {
            // Handle specific CloudKit errors
            switch error.code {
            case .networkUnavailable, .networkFailure:
                Log.warning("Network unavailable - settings will sync when connection restored", category: .general)
                throw error
            case .serviceUnavailable:
                Log.warning("iCloud temporarily unavailable - settings will sync later", category: .general)
                throw error
            default:
                throw error
            }
        }
    }

    /// Sync evidence data to iCloud
    @MainActor
    public func syncEvidence() async throws {
        guard let zone = customZone, let database = privateDatabase else {
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
        let files = try FileManager.default.contentsOfDirectory(at: evidenceDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
        let evidenceFiles = files.filter { $0.pathExtension == "encrypted" }

        // Get size and age limits from settings
        let maxSizeMB = UserDefaults.standard.double(forKey: "iCloudDataLimitMB")
        let maxAgeDays = UserDefaults.standard.double(forKey: "iCloudDataAgeLimitDays")
        let maxSizeBytes = Int64(maxSizeMB * 1024 * 1024)
        let maxAge = TimeInterval(maxAgeDays * 24 * 60 * 60)
        let cutoffDate = Date().addingTimeInterval(-maxAge)

        var totalSyncedSize: Int64 = 0

        for file in evidenceFiles {
            let evidenceID = file.deletingPathExtension().lastPathComponent

            // Check if already synced
            let syncedKey = "synced_\(evidenceID)"
            if UserDefaults.standard.bool(forKey: syncedKey) {
                continue
            }

            // Check file size
            let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            let fileSize = Int64(resourceValues.fileSize ?? 0)
            let creationDate = resourceValues.creationDate ?? Date()

            // Skip if file is too old
            if creationDate < cutoffDate {
                Log.debug("Skipping evidence \(evidenceID) - older than \(maxAgeDays) days", category: .general)
                continue
            }

            // Skip if we've exceeded the size limit
            if totalSyncedSize + fileSize > maxSizeBytes {
                Log.warning("Reached iCloud size limit (\(maxSizeMB) MB) - skipping remaining evidence", category: .general)
                break
            }

            // Create evidence record
            let recordID = CKRecord.ID(recordName: evidenceID, zoneID: zone.zoneID)
            let record = CKRecord(recordType: evidenceRecordType, recordID: recordID)

            // Add encrypted data as asset
            let asset = CKAsset(fileURL: file)
            record["encryptedData"] = asset
            record["timestamp"] = Date()
            record["deviceName"] = ProcessInfo.processInfo.hostName
            record["fileSize"] = fileSize
            record["creationDate"] = creationDate

            do {
                try await database.save(record)

                // Mark as synced
                UserDefaults.standard.set(true, forKey: syncedKey)
                totalSyncedSize += fileSize
                Log.info("Evidence \(evidenceID) synced to iCloud (\(fileSize / 1024) KB)", category: .general)
            } catch {
                Log.error("Failed to sync evidence \(evidenceID)", error: error, category: .general)
                throw error
            }
        }
    }

    /// Download evidence from iCloud
    @MainActor
    public func downloadEvidence() async throws {
        guard let zone = customZone, let database = privateDatabase else {
            throw SyncError.zoneNotReady
        }

        // Query for all evidence records
        let query = CKQuery(recordType: evidenceRecordType, predicate: NSPredicate(value: true))

        do {
            let (matchResults, _) = try await database.records(matching: query, inZoneWith: zone.zoneID, desiredKeys: nil, resultsLimit: 100)

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
}

// MARK: - Cleanup

extension SyncService {
    /// Remove old evidence from iCloud based on age limit
    @MainActor
    public func cleanupOldEvidence() async throws {
        guard let zone = customZone, let database = privateDatabase else {
            throw SyncError.zoneNotReady
        }

        let maxAgeDays = UserDefaults.standard.double(forKey: "iCloudDataAgeLimitDays")
        let maxAge = TimeInterval(maxAgeDays * 24 * 60 * 60)
        let cutoffDate = Date().addingTimeInterval(-maxAge)

        // Query for all evidence records
        let query = CKQuery(recordType: evidenceRecordType, predicate: NSPredicate(value: true))

        do {
            let (matchResults, _) = try await database.records(matching: query, inZoneWith: zone.zoneID, desiredKeys: ["creationDate"], resultsLimit: 100)

            var deletedCount = 0
            for (recordID, result) in matchResults {
                switch result {
                case .success(let record):
                    if let creationDate = record["creationDate"] as? Date, creationDate < cutoffDate {
                        try await database.deleteRecord(withID: recordID)
                        deletedCount += 1
                        Log.info("Deleted old evidence from iCloud: \(recordID.recordName)", category: .general)
                    }
                case .failure(let error):
                    Log.error("Failed to fetch evidence record for cleanup", error: error, category: .general)
                }
            }

            if deletedCount > 0 {
                Log.info("Cleaned up \(deletedCount) old evidence records from iCloud", category: .general)
            }
        } catch {
            Log.error("Failed to cleanup old evidence", error: error, category: .general)
            throw error
        }
    }

}

// MARK: - Retry Logic

extension SyncService {
    private func scheduleRetry() {
        // Cancel existing retry timer
        retryTimer?.invalidate()

        // Only retry if we haven't exceeded max retries
        guard retryCount < maxRetries else {
            Log.warning("Max retry attempts reached for iCloud sync", category: .general)
            retryCount = 0
            return
        }

        retryCount += 1
        Log.info("Scheduling iCloud sync retry #\(retryCount) in \(retryDelay) seconds", category: .general)

        retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
            Task {
                do {
                    try await self?.syncAll()
                    self?.retryCount = 0 // Reset on success
                } catch {
                    // Will be handled by syncAll
                }
            }
        }
    }

    // MARK: - User Notifications

    private func notifyUserAboutPermissions() {
        NotificationCenter.default.post(
            name: Notification.Name("MagSafeGuardCloudKitPermissionNeeded"),
            object: nil,
            userInfo: [
                "title": "iCloud Permission Required",
                "message": "MagSafe Guard needs permission to sync your settings and logs to iCloud. Please check System Settings > Privacy & Security > iCloud."
            ]
        )
    }

    private func notifyUserAboutiCloudAccount() {
        NotificationCenter.default.post(
            name: Notification.Name("MagSafeGuardCloudKitAccountNeeded"),
            object: nil,
            userInfo: [
                "title": "iCloud Account Required",
                "message": "Please sign in to iCloud in System Settings to enable sync features."
            ]
        )
    }

    private func notifyUserAboutRestrictions() {
        NotificationCenter.default.post(
            name: Notification.Name("MagSafeGuardCloudKitRestricted"),
            object: nil,
            userInfo: [
                "title": "iCloud Access Restricted",
                "message": "iCloud access is restricted on this device. Contact your administrator."
            ]
        )
    }

}

// MARK: - Delete Operations

extension SyncService {
    /// Delete evidence from iCloud
    public func deleteEvidence(evidenceID: String) async throws {
        guard let zone = customZone, let database = privateDatabase else {
            throw SyncError.zoneNotReady
        }

        let recordID = CKRecord.ID(recordName: evidenceID, zoneID: zone.zoneID)

        do {
            try await database.deleteRecord(withID: recordID)

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
    /// Status is unknown
    case unknown
    /// Sync is idle and up to date
    case idle
    /// Currently syncing data
    case syncing
    /// Sync encountered an error
    case error
    /// No iCloud account configured
    case noAccount
    /// iCloud access is restricted
    case restricted
    /// iCloud is temporarily unavailable
    case temporarilyUnavailable

    /// Human-readable display text for the status
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

    /// SF Symbol name for the status
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
    /// CloudKit zone is not ready
    case zoneNotReady
    /// iCloud sync is not available
    case notAvailable
    /// Sync is already in progress
    case syncInProgress

    /// Localized error description
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

/// Notification names for sync events
public extension Notification.Name {
    /// Posted when settings are synced from iCloud
    static let settingsSyncedFromiCloud = Notification.Name("settingsSyncedFromiCloud")
}
