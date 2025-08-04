//
//  SyncServiceMonitor.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//

import CloudKit
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

/// Handles iCloud availability monitoring and network status
final class SyncServiceMonitor {
  private let logFile = URL(fileURLWithPath: "/tmp/magsafe-sync.log")
  private var networkMonitor: NWPathMonitor?
  private let networkQueue = DispatchQueue(label: "com.magsafeguard.network")
  private var retryTimer: Timer?

  weak var delegate: SyncServiceMonitorDelegate?

  deinit {
    networkMonitor?.cancel()
    retryTimer?.invalidate()
  }

  /// Start monitoring network and iCloud availability
  func startMonitoring() {
    setupNetworkMonitoring()
  }

  /// Stop all monitoring
  func stopMonitoring() {
    networkMonitor?.cancel()
    networkMonitor = nil
    retryTimer?.invalidate()
    retryTimer = nil
  }

  /// Check iCloud account status
  func checkiCloudAvailability(container: CKContainer) {
    let timestamp = Date().formatted(.iso8601)

    Log.info("Checking iCloud availability...", category: .general)
    try? Data("\(timestamp): Checking iCloud availability...\n".utf8).append(to: logFile)

    container.accountStatus { [weak self] status, error in
      self?.handleAccountStatus(status, error: error, container: container)
    }
  }

  // MARK: - Private Methods

  private func handleAccountStatus(_ status: CKAccountStatus, error: Error?, container: CKContainer) {
    let statusTimestamp = Date().formatted(.iso8601)

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      if let error = error {
        self.handleAccountError(error, timestamp: statusTimestamp)
        return
      }

      switch status {
      case .available:
        self.delegate?.syncServiceMonitor(self, didUpdateAvailability: true, status: .idle)
        Log.info("iCloud is available", category: .general)
        try? Data("\(statusTimestamp): iCloud is available\n".utf8).append(to: self.logFile)

      case .noAccount:
        self.delegate?.syncServiceMonitor(self, didUpdateAvailability: false, status: .noAccount)
        Log.warning("No iCloud account configured", category: .general)
        try? Data("\(statusTimestamp): No iCloud account configured\n".utf8).append(
          to: self.logFile)
        self.delegate?.syncServiceMonitorRequiresiCloudAccount(self)

      case .restricted:
        self.delegate?.syncServiceMonitor(self, didUpdateAvailability: false, status: .restricted)
        Log.warning("iCloud access is restricted", category: .general)
        try? Data("\(statusTimestamp): iCloud access is restricted\n".utf8).append(to: self.logFile)
        self.delegate?.syncServiceMonitorRequiresRestrictionHandling(self)

      case .couldNotDetermine:
        self.delegate?.syncServiceMonitor(self, didUpdateAvailability: false, status: .unknown)
        Log.warning("Could not determine iCloud status", category: .general)
        try? Data("\(statusTimestamp): Could not determine iCloud status\n".utf8).append(
          to: self.logFile)
        self.scheduleRetry(container: container)

      case .temporarilyUnavailable:
        self.delegate?.syncServiceMonitor(
          self, didUpdateAvailability: false, status: .temporarilyUnavailable)
        Log.warning("iCloud is temporarily unavailable", category: .general)
        try? Data("\(statusTimestamp): iCloud is temporarily unavailable\n".utf8).append(
          to: self.logFile)
        self.scheduleRetry(container: container)

      @unknown default:
        self.delegate?.syncServiceMonitor(self, didUpdateAvailability: false, status: .unknown)
        try? Data("\(statusTimestamp): Unknown iCloud status\n".utf8).append(to: self.logFile)
      }
    }
  }

  private func handleAccountError(_ error: Error, timestamp: String) {
    Log.error("Failed to check iCloud account status", error: error, category: .general)
    try? Data("\(timestamp): Failed to check iCloud account status: \(error)\n".utf8).append(
      to: logFile)

    delegate?.syncServiceMonitor(self, didEncounterError: error)

    // Handle specific CloudKit errors
    if let ckError = error as? CKError {
      switch ckError.code {
      case .notAuthenticated, .permissionFailure:
        delegate?.syncServiceMonitorRequiresPermissions(self)
      case .networkUnavailable, .networkFailure:
        Log.warning("Network unavailable for iCloud check", category: .general)
      // Will retry when network becomes available
      default:
        break
      }
    }
  }

  private func setupNetworkMonitoring() {
    networkMonitor = NWPathMonitor()
    networkMonitor?.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        if path.status == .satisfied {
          Log.info("Network became available", category: .general)
          self?.delegate?.syncServiceMonitorNetworkBecameAvailable(self!)
        } else {
          Log.warning("Network became unavailable", category: .general)
          self?.delegate?.syncServiceMonitorNetworkBecameUnavailable(self!)
        }
      }
    }
    networkMonitor?.start(queue: networkQueue)
  }

  private func scheduleRetry(container: CKContainer) {
    retryTimer?.invalidate()
    retryTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
      self?.checkiCloudAvailability(container: container)
    }
  }
}

// MARK: - Delegate Protocol

protocol SyncServiceMonitorDelegate: AnyObject {
  func syncServiceMonitor(
    _ monitor: SyncServiceMonitor, didUpdateAvailability isAvailable: Bool, status: SyncStatus)
  func syncServiceMonitor(_ monitor: SyncServiceMonitor, didEncounterError error: Error)
  func syncServiceMonitorRequiresPermissions(_ monitor: SyncServiceMonitor)
  func syncServiceMonitorRequiresiCloudAccount(_ monitor: SyncServiceMonitor)
  func syncServiceMonitorRequiresRestrictionHandling(_ monitor: SyncServiceMonitor)
  func syncServiceMonitorNetworkBecameAvailable(_ monitor: SyncServiceMonitor)
  func syncServiceMonitorNetworkBecameUnavailable(_ monitor: SyncServiceMonitor)
}
