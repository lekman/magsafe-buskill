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
import MagSafeGuardCore
import Network

// Debug logging extension
extension Data {
  fileprivate func append(to url: URL) throws {
    if let fileHandle = FileHandle(forWritingAtPath: url.path) {
      defer { fileHandle.closeFile() }
      fileHandle.seekToEndOfFile()
      fileHandle.write(self)
    } else {
      try write(to: url)
    }
  }
}

/// Service responsible for syncing data with iCloud
///
/// This service handles:
/// - Settings synchronization across devices
/// - Evidence backup to iCloud
/// - Conflict resolution
/// - Sync status monitoring
public class SyncService: NSObject, ObservableObject, SyncServiceMonitorDelegate {

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
  private var retryTimer: Timer?
  private var cancellables = Set<AnyCancellable>()
  private var isCloudKitInitialized = false

  // Refactored components
  private let setupManager = SyncServiceSetup()
  private let monitor = SyncServiceMonitor()
  private var settingsSync: SyncServiceSettings?

  // Record types
  private let settingsRecordType = "Settings"
  private let evidenceRecordType = "Evidence"

  // Zone name
  private let customZoneName = "MagSafeGuardZone"
  private var customZone: CKRecordZone?

  // MARK: - Initialization

  public override init() {
    super.init()

    monitor.delegate = self

    if setupManager.isTestEnvironment {
      syncStatus = .unknown
      isAvailable = false
      return
    }

    // Defer initialization to avoid circular dependency
    // The UserDefaultsManager will call enableSync() if needed
    Log.info("SyncService created - waiting for explicit initialization", category: .general)
    syncStatus = .unknown
    isAvailable = false
  }

  // MARK: - Public Methods

  /// Enable CloudKit sync when user enables it in settings
  public func enableSync() {
    let logFile = URL(fileURLWithPath: "/tmp/magsafe-sync.log")
    let timestamp = Date().formatted(.iso8601)

    guard !isCloudKitInitialized else {
      Log.info("CloudKit already initialized", category: .general)
      try? Data("\(timestamp): CloudKit already initialized\n".utf8).append(to: logFile)
      return
    }

    Log.info("Enabling CloudKit sync", category: .general)
    try? Data("\(timestamp): Enabling CloudKit sync\n".utf8).append(to: logFile)
    initializeCloudKit()
  }

  /// Disable CloudKit sync when user disables it in settings
  public func disableSync() {
    Log.info("Disabling CloudKit sync", category: .general)

    // Stop monitoring
    monitor.stopMonitoring()

    // Stop timers
    syncTimer?.invalidate()
    syncTimer = nil
    retryTimer?.invalidate()
    retryTimer = nil

    // Reset state
    isCloudKitInitialized = false
    isAvailable = false
    syncStatus = .noAccount

    // Clear references
    container = nil
    privateDatabase = nil
    customZone = nil
    settingsSync = nil
  }

  // MARK: - CloudKit Initialization

  private func initializeCloudKit() {
    guard !isCloudKitInitialized else { return }

    // Use setupManager to initialize container
    guard let newContainer = setupManager.initializeContainer() else {
      syncStatus = .unknown
      isAvailable = false
      return
    }

    container = newContainer
    privateDatabase = newContainer.privateCloudDatabase
    isCloudKitInitialized = true

    // Initialize settings sync
    settingsSync = SyncServiceSettings(container: newContainer)

    // Continue with setup
    setupCloudKit()
    monitor.checkiCloudAvailability(container: newContainer)
    startPeriodicSync()
    monitor.startMonitoring()
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
          Log.warning(
            "Network unavailable for zone creation - will retry later", category: .general)
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

  // checkiCloudAvailability is now handled by SyncServiceMonitor

  // Network monitoring is now handled by SyncServiceMonitor

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
    // Check for cancellation
    try Task.checkCancellation()

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

    // Prevent concurrent syncs
    guard syncStatus != .syncing else {
      Log.debug("Sync already in progress", category: .general)
      return
    }

    syncStatus = .syncing
    syncError = nil

    do {
      // Check for cancellation before each operation
      try Task.checkCancellation()

      // Sync settings first
      try await withTaskCancellationHandler {
        try await syncSettings()
      } onCancel: {
        Log.info("Settings sync cancelled", category: .general)
      }

      // Check for cancellation between operations
      try Task.checkCancellation()

      // Then sync evidence
      try await withTaskCancellationHandler {
        try await syncEvidence()
      } onCancel: {
        Log.info("Evidence sync cancelled", category: .general)
      }

      syncStatus = .idle
      lastSyncDate = Date()
      Log.info("Sync completed successfully", category: .general)

    } catch is CancellationError {
      syncStatus = .idle
      Log.info("Sync cancelled", category: .general)
      throw CancellationError()

    } catch let error as CKError {
      // Handle specific CloudKit errors
      handleCloudKitError(error)

      // Only throw for non-recoverable errors
      switch error.code {
      case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
        // Don't throw - we'll retry later
        return
      default:
        throw error
      }

    } catch {
      syncStatus = .error
      syncError = error
      Log.error("Sync failed", error: error, category: .general)
      throw error
    }
  }

  private func handleCloudKitError(_ error: CKError) {
    switch error.code {
    case .networkUnavailable, .networkFailure:
      syncStatus = .temporarilyUnavailable
      Log.warning("Network unavailable for iCloud sync", category: .general)
      scheduleRetry()
    case .serviceUnavailable, .requestRateLimited:
      syncStatus = .temporarilyUnavailable
      Log.warning("iCloud service temporarily unavailable", category: .general)
      scheduleRetry()
    case .quotaExceeded:
      syncStatus = .error
      syncError = error
      Log.error("iCloud quota exceeded", error: error, category: .general)
    default:
      syncStatus = .error
      syncError = error
      Log.error("Sync failed", error: error, category: .general)
    }
  }

  /// Force sync settings to iCloud
  @MainActor
  public func syncSettings() async throws {
    // Check for cancellation
    try Task.checkCancellation()

    guard let settingsSync = settingsSync else {
      throw SyncError.notAvailable
    }

    try await settingsSync.syncSettings()
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
    let files = try FileManager.default.contentsOfDirectory(
      at: evidenceDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
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
        Log.debug(
          "Skipping evidence \(evidenceID) - older than \(maxAgeDays) days", category: .general)
        continue
      }

      // Skip if we've exceeded the size limit
      if totalSyncedSize + fileSize > maxSizeBytes {
        Log.warning(
          "Reached iCloud size limit (\(maxSizeMB) MB) - skipping remaining evidence",
          category: .general)
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
        Log.info(
          "Evidence \(evidenceID) synced to iCloud (\(fileSize / 1024) KB)", category: .general)
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
      let (matchResults, _) = try await database.records(
        matching: query, inZoneWith: zone.zoneID, desiredKeys: nil, resultsLimit: 100)

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
      let fileURL = asset.fileURL
    else {
      Log.warning("Evidence record missing data", category: .general)
      return
    }

    let evidenceID = record.recordID.recordName

    // Get evidence directory
    guard
      let documentsDirectory = try? FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
      )
    else { return }

    let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: evidenceDirectory, withIntermediateDirectories: true)

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
      let (matchResults, _) = try await database.records(
        matching: query, inZoneWith: zone.zoneID, desiredKeys: ["creationDate"], resultsLimit: 100)

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
    Log.info(
      "Scheduling iCloud sync retry #\(retryCount) in \(retryDelay) seconds", category: .general)

    retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
      guard let self = self, let container = self.container else { return }
      // Use monitor to check availability again
      self.monitor.checkiCloudAvailability(container: container)
    }
  }

  // MARK: - User Notifications

  private func notifyUserAboutPermissions() {
    NotificationCenter.default.post(
      name: Notification.Name("MagSafeGuardCloudKitPermissionNeeded"),
      object: nil,
      userInfo: [
        "title": "iCloud Permission Required",
        "message":
          "MagSafe Guard needs permission to sync your settings and logs to iCloud. Please check System Settings > Privacy & Security > iCloud."
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

// MARK: - SyncServiceMonitorDelegate Implementation

extension SyncService {
  func syncServiceMonitor(
    _ monitor: SyncServiceMonitor, didUpdateAvailability isAvailable: Bool, status: SyncStatus
  ) {
    self.isAvailable = isAvailable
    self.syncStatus = status

    if isAvailable && status == .idle {
      // Perform initial sync
      Task {
        try? await syncAll()
      }
    }
  }

  func syncServiceMonitor(_ monitor: SyncServiceMonitor, didEncounterError error: Error) {
    self.syncError = error
    self.syncStatus = .error
    self.isAvailable = false
  }

  func syncServiceMonitorRequiresPermissions(_ monitor: SyncServiceMonitor) {
    notifyUserAboutPermissions()
  }

  func syncServiceMonitorRequiresiCloudAccount(_ monitor: SyncServiceMonitor) {
    notifyUserAboutiCloudAccount()
  }

  func syncServiceMonitorRequiresRestrictionHandling(_ monitor: SyncServiceMonitor) {
    notifyUserAboutRestrictions()
  }

  func syncServiceMonitorNetworkBecameAvailable(_ monitor: SyncServiceMonitor) {
    if wasOffline {
      Log.info("Network connection restored - attempting iCloud sync", category: .general)
      wasOffline = false
      retryCount = 0

      // Check iCloud availability again
      if let container = container {
        monitor.checkiCloudAvailability(container: container)
      }
    }
  }

  func syncServiceMonitorNetworkBecameUnavailable(_ monitor: SyncServiceMonitor) {
    Log.warning("Network connection lost - iCloud sync paused", category: .general)
    wasOffline = true
    syncStatus = .temporarilyUnavailable
  }
}

// MARK: - Private Properties for network monitoring

private var wasOfflineKey: UInt8 = 0
private var retryCountKey: UInt8 = 0

extension SyncService {
  private var wasOffline: Bool {
    get {
      return objc_getAssociatedObject(self, &wasOfflineKey) as? Bool ?? false
    }
    set {
      objc_setAssociatedObject(self, &wasOfflineKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  private var retryCount: Int {
    get {
      return objc_getAssociatedObject(self, &retryCountKey) as? Int ?? 0
    }
    set {
      objc_setAssociatedObject(self, &retryCountKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  private var maxRetries: Int {
    return 3
  }

  private var retryDelay: TimeInterval {
    return 30.0
  }
}

// MARK: - Notifications

/// Notification names for sync events
extension Notification.Name {
  /// Posted when settings are synced from iCloud
  public static let settingsSyncedFromiCloud = Notification.Name("settingsSyncedFromiCloud")
}
