//
//  Logger.swift
//  MagSafe Guard
//
//  Created on 2025-07-27.
//
//  Unified logging system for MagSafe Guard using os.log
//

import Foundation
import os

/// Shared logging system for MagSafe Guard
///
/// This logger provides:
/// - Unified logging using Apple's os.log system
/// - File logging for errors (stored in ~/Library/Logs/MagSafeGuard/)
/// - Privacy-aware logging with automatic redaction of sensitive data
/// - Category-based organization for easy filtering
///
/// Usage:
/// ```swift
/// Log.info("Power adapter connected")
/// Log.error("Authentication failed", error: error)
/// Log.debug("Settings updated", category: .settings)
/// ```
public struct Log {

  // MARK: - Constants

  fileprivate static let defaultBundleIdentifier = "com.lekman.MagSafeGuard"

  // MARK: - Private Properties

  private static let fileLogger: FileLogger? = {
    // Skip file logging in test environment to prevent crashes
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
      return nil
    }
    return FileLogger()
  }()

  // MARK: - Public Methods

  /// Log debug information (only visible with debug flag)
  /// - Parameters:
  ///   - message: The message to log (treated as public by default)
  ///   - category: The log category
  public static func debug(_ message: String, category: LogCategory = .general) {
    category.logger.debug("\(message, privacy: .public)")
  }

  /// Log debug information with sensitive data
  /// - Parameters:
  ///   - message: The public message prefix
  ///   - sensitiveValue: The sensitive value to log (will be redacted in logs)
  ///   - category: The log category
  public static func debugSensitive(
    _ message: String, value: String, category: LogCategory = .general
  ) {
    category.logger.debug("\(message, privacy: .public): \(value, privacy: .private)")
  }

  /// Log general information
  /// - Parameters:
  ///   - message: The message to log (treated as public by default)
  ///   - category: The log category
  public static func info(_ message: String, category: LogCategory = .general) {
    category.logger.info("\(message, privacy: .public)")
  }

  /// Log information with sensitive data
  /// - Parameters:
  ///   - message: The public message prefix
  ///   - sensitiveValue: The sensitive value to log (will be redacted in logs)
  ///   - category: The log category
  public static func infoSensitive(
    _ message: String, value: String, category: LogCategory = .general
  ) {
    category.logger.info("\(message, privacy: .public): \(value, privacy: .private)")
  }

  /// Log normal but significant events (default level)
  /// - Parameters:
  ///   - message: The message to log (treated as public by default)
  ///   - category: The log category
  public static func notice(_ message: String, category: LogCategory = .general) {
    category.logger.notice("\(message, privacy: .public)")
  }

  /// Log notice with sensitive data
  /// - Parameters:
  ///   - message: The public message prefix
  ///   - sensitiveValue: The sensitive value to log (will be redacted in logs)
  ///   - category: The log category
  public static func noticeSensitive(
    _ message: String, value: String, category: LogCategory = .general
  ) {
    category.logger.notice("\(message, privacy: .public): \(value, privacy: .private)")
  }

  /// Log warnings
  public static func warning(_ message: String, category: LogCategory = .general) {
    category.logger.warning("\(message, privacy: .public)")
  }

  /// Log errors (also saved to file)
  public static func error(_ message: String, error: Error? = nil, category: LogCategory = .general)
  {
    let fullMessage: String
    if let error = error {
      fullMessage = "\(message): \(error.localizedDescription)"
      category.logger.error("\(message, privacy: .public): \(error)")
    } else {
      fullMessage = message
      category.logger.error("\(message, privacy: .public)")
    }

    // Also log errors to file
    fileLogger?.logError(fullMessage, category: category)
  }

  /// Log critical failures (also saved to file)
  public static func critical(
    _ message: String, error: Error? = nil, category: LogCategory = .general
  ) {
    let fullMessage: String
    if let error = error {
      fullMessage = "\(message): \(error.localizedDescription)"
      category.logger.critical("\(message, privacy: .public): \(error)")
    } else {
      fullMessage = message
      category.logger.critical("\(message, privacy: .public)")
    }

    // Also log critical errors to file
    fileLogger?.logError(fullMessage, category: category, level: "CRITICAL")
  }

  /// Log faults/crashes (also saved to file)
  public static func fault(_ message: String, category: LogCategory = .general) {
    category.logger.fault("\(message, privacy: .public)")
    fileLogger?.logError(message, category: category, level: "FAULT")
  }

  // MARK: - Privacy-Aware Logging

  /// Log with automatic privacy for user data
  public static func infoPrivate(
    _ message: String, privateData: String, category: LogCategory = .general
  ) {
    category.logger.info("\(message, privacy: .public): \(privateData, privacy: .private)")
  }

  /// Log with mixed public and private data
  public static func debugMixed(
    publicMessage: String, privateData: String, category: LogCategory = .general
  ) {
    category.logger.debug("\(publicMessage, privacy: .public) - \(privateData, privacy: .private)")
  }
}

// MARK: - Log Categories

/// Log categories for organizing and filtering logs
public enum LogCategory {
  /// General application logs
  case general
  /// Power monitoring and battery state logs
  case powerMonitor
  /// Authentication and biometric logs
  case authentication
  /// Settings and configuration logs
  case settings
  /// Security actions and protection logs
  case security
  /// User interface and interaction logs
  case ui
  /// Auto-arm feature logs
  case autoArm
  /// Network connectivity and monitoring logs
  case network
  /// Location services and geofencing logs
  case location

  /// The os.Logger instance for this category
  var logger: Logger {
    Logger(subsystem: Self.subsystem, category: self.categoryName)
  }

  /// The category name used in logs
  var categoryName: String {
    switch self {
    case .general: return "General"
    case .powerMonitor: return "PowerMonitor"
    case .authentication: return "Authentication"
    case .settings: return "Settings"
    case .security: return "Security"
    case .ui: return "UI"
    case .autoArm: return "AutoArm"
    case .network: return "Network"
    case .location: return "Location"
    }
  }

  /// The app's subsystem identifier
  private static let subsystem: String = {
    // Use a safe default during testing
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
      return "\(Log.defaultBundleIdentifier).test"
    }
    return Bundle.main.bundleIdentifier ?? Log.defaultBundleIdentifier
  }()
}

// MARK: - File Logger

/// Handles writing error logs to the file system
private class FileLogger {
  private let logFileURL: URL
  private let dateFormatter: DateFormatter
  private let queue = DispatchQueue(label: "com.magsafeguard.filelogger", qos: .utility)

  init?() {
    // Create logs directory
    let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Logs")
      .appendingPathComponent("MagSafeGuard")

    do {
      try FileManager.default.createDirectory(
        at: logsDir, withIntermediateDirectories: true, attributes: nil)
    } catch {
      // If we can't create the directory, logging is not available
      // Using os.Logger for system messages since file logging isn't available yet
      os.Logger(subsystem: Log.defaultBundleIdentifier, category: "System").error(
        "Cannot create log directory: \(error)")
      return nil
    }

    // Create log file with date - use a date formatter that doesn't include path delimiters
    let filenameDateFormatter = DateFormatter()
    filenameDateFormatter.dateFormat = "dd-MM-yyyy"
    let fileName = "errors-\(filenameDateFormatter.string(from: Date())).log"
    logFileURL = logsDir.appendingPathComponent(fileName)

    // Configure date formatter
    dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

    // Clean up old log files (keep last 7 days)
    cleanupOldLogs(in: logsDir)
  }

  func logError(_ message: String, category: LogCategory, level: String = "ERROR") {
    queue.async { [weak self] in
      guard let self = self else { return }

      let timestamp = self.dateFormatter.string(from: Date())
      let logLine = "[\(timestamp)] [\(level)] [\(category.categoryName)] \(message)\n"

      if let data = logLine.data(using: .utf8) {
        do {
          if FileManager.default.fileExists(atPath: self.logFileURL.path) {
            let fileHandle = try FileHandle(forWritingTo: self.logFileURL)
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
          } else {
            try data.write(to: self.logFileURL, options: .atomic)
          }
        } catch {
          // If we can't write to the log file, use os.Logger as fallback
          os.Logger(subsystem: Log.defaultBundleIdentifier, category: "System").log(
            "\(logLine.trimmingCharacters(in: .newlines))")
        }
      }
    }
  }

  private func cleanupOldLogs(in directory: URL) {
    let fileManager = FileManager.default
    let calendar = Calendar.current
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

    do {
      let files = try fileManager.contentsOfDirectory(
        at: directory, includingPropertiesForKeys: [.creationDateKey])

      for file in files where file.pathExtension == "log" {
        if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
          let creationDate = attributes[.creationDate] as? Date,
          creationDate < sevenDaysAgo
        {
          try? fileManager.removeItem(at: file)
        }
      }
    } catch {
      // Ignore cleanup errors
    }
  }
}

// MARK: - Convenience Extensions

/// Extension for logging in DEBUG builds only
#if DEBUG
  extension Log {
    /// Log verbose debug information (only in DEBUG builds)
    public static func verbose(_ message: String, category: LogCategory = .general) {
      debug("🔍 \(message)", category: category)
    }
  }
#endif
