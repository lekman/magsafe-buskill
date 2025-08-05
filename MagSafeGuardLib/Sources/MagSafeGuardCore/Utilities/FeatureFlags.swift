//
//  FeatureFlags.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Feature flag management system for progressive rollout and debugging
//

import Foundation

/// Centralized feature flag management
public final class FeatureFlags: @unchecked Sendable {
  /// Shared instance for feature flag management
  public static let shared = FeatureFlags()

  /// Available feature flags
  public enum Flag: String, CaseIterable, Codable {
    // Core Services
    /// Power adapter monitoring (core functionality)
    case powerMonitoring = "FEATURE_POWER_MONITORING"
    /// Accessibility permissions for system actions
    case accessibilityManager = "FEATURE_ACCESSIBILITY"
    /// System notifications
    case notificationService = "FEATURE_NOTIFICATIONS"
    /// Authentication service for app security
    case authenticationService = "FEATURE_AUTHENTICATION"
    /// Auto-arm feature based on location or schedule
    case autoArmManager = "FEATURE_AUTO_ARM"
    /// Location-based features
    case locationManager = "FEATURE_LOCATION"
    /// Network connectivity monitoring
    case networkMonitor = "FEATURE_NETWORK_MONITOR"
    /// Security evidence collection
    case securityEvidence = "FEATURE_SECURITY_EVIDENCE"
    /// Cloud synchronization features
    case cloudSync = "FEATURE_CLOUD_SYNC"

    // Telemetry
    /// Sentry error reporting enabled
    case sentryEnabled = "SENTRY_ENABLED"
    /// Sentry debug mode
    case sentryDebug = "SENTRY_DEBUG"
    /// Performance metrics collection
    case performanceMetrics = "FEATURE_PERFORMANCE_METRICS"

    // Debug Features
    /// Verbose logging for debugging
    case verboseLogging = "DEBUG_VERBOSE_LOGGING"
    /// Use mock services instead of real implementations
    case mockServices = "DEBUG_MOCK_SERVICES"
    /// Disable sandbox restrictions (development only)
    case disableSandbox = "DEBUG_DISABLE_SANDBOX"

    var defaultValue: Bool {
      // All features enabled by default in this version
      return true
    }

    var description: String {
      switch self {
      case .powerMonitoring:
        return "Power adapter monitoring (core functionality)"
      case .accessibilityManager:
        return "Accessibility permissions for system actions"
      case .notificationService:
        return "System notifications"
      case .authenticationService:
        return "Touch ID/password authentication"
      case .autoArmManager:
        return "Automatic arming based on conditions"
      case .locationManager:
        return "Location-based features"
      case .networkMonitor:
        return "Network-based auto-arm"
      case .securityEvidence:
        return "Security evidence collection"
      case .cloudSync:
        return "iCloud sync functionality"
      case .sentryEnabled:
        return "Sentry crash reporting and telemetry"
      case .sentryDebug:
        return "Sentry debug mode"
      case .performanceMetrics:
        return "Performance metrics tracking"
      case .verboseLogging:
        return "Verbose debug logging"
      case .mockServices:
        return "Use mock services for testing"
      case .disableSandbox:
        return "Disable app sandbox (development only)"
      }
    }
  }

  private var flags: [Flag: Bool] = [:]
  private let queue = DispatchQueue(label: "com.magsafeguard.featureflags")
  private let jsonFileName = "feature-flags.json"

  private init() {
    loadFlags()
  }

  /// Load flags from JSON file, environment variables, and defaults
  private func loadFlags() {
    queue.sync {
      // First, set default values (all enabled)
      for flag in Flag.allCases {
        flags[flag] = flag.defaultValue
      }

      // Then, load from JSON file if it exists
      loadJSONFile()

      // Finally, override with environment variables (highest priority)
      for flag in Flag.allCases {
        if let envValue = ProcessInfo.processInfo.environment[flag.rawValue] {
          flags[flag] = (envValue.lowercased() == "true" || envValue == "1")
        }
      }

      #if DEBUG
        Log.debug("Feature flags loaded: \(flags)", category: .general)
      #endif
    }
  }

  /// Load flags from JSON file
  private func loadJSONFile() {
    let fileManager = FileManager.default

    // Try multiple locations for the JSON file
    let searchPaths = [
      // Current directory
      fileManager.currentDirectoryPath,
      // Bundle resources
      Bundle.main.resourcePath ?? "" as Any,
      // User's home directory
      NSHomeDirectory(),
      // Application Support directory
      fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? ""
    ].compactMap { $0 as? String }

    for basePath in searchPaths {
      let jsonPath = "\(basePath)/\(jsonFileName)"

      if fileManager.fileExists(atPath: jsonPath) {
        do {
          let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
          let jsonFlags = try JSONDecoder().decode([String: Bool].self, from: data)

          // Apply JSON flags
          for (key, value) in jsonFlags {
            if let flag = Flag(rawValue: key) {
              flags[flag] = value
            }
          }

          Log.info("Loaded feature flags from: \(jsonPath)", category: .general)
          return
        } catch {
          Log.error(
            "Failed to load feature flags from \(jsonPath)", error: error, category: .general)
        }
      }
    }

    // If no JSON file found, that's OK - we'll use defaults
    Log.debug("No feature flags JSON file found, using defaults", category: .general)
  }

  /// Save current flags to JSON file
  public func saveToJSON(at path: String? = nil) throws {
    let savePath = path ?? "\(FileManager.default.currentDirectoryPath)/\(jsonFileName)"

    let jsonFlags = queue.sync { () -> [String: Bool] in
      var result: [String: Bool] = [:]
      for flag in Flag.allCases {
        result[flag.rawValue] = flags[flag] ?? flag.defaultValue
      }
      return result
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(jsonFlags)

    try data.write(to: URL(fileURLWithPath: savePath))
    Log.info("Saved feature flags to: \(savePath)", category: .general)
  }

  /// Check if a feature flag is enabled
  public func isEnabled(_ flag: Flag) -> Bool {
    queue.sync {
      return flags[flag] ?? flag.defaultValue
    }
  }

  /// Set a feature flag value (for testing)
  public func setFlag(_ flag: Flag, enabled: Bool) {
    queue.sync {
      flags[flag] = enabled
    }
  }

  /// Get all current flag states
  public func allFlags() -> [Flag: Bool] {
    queue.sync {
      return flags
    }
  }

  /// Reload flags from disk
  public func reload() {
    loadFlags()
  }

  /// Export current flags to dictionary
  public func export() -> [String: Any] {
    queue.sync {
      var result: [String: Any] = [:]

      // Metadata
      result["_metadata"] = [
        "version": "1.0",
        "generated": ISO8601DateFormatter().string(from: Date()),
        "description": "MagSafe Guard Feature Flags Configuration"
      ]

      // Core features
      var coreFeatures: [String: Bool] = [:]
      for flag in Flag.allCases
      where flag.rawValue.hasPrefix("FEATURE_") && !flag.rawValue.contains("DEBUG") {
        coreFeatures[flag.rawValue] = flags[flag] ?? flag.defaultValue
      }
      result["core_features"] = coreFeatures

      // Telemetry
      var telemetry: [String: Bool] = [:]
      for flag in Flag.allCases
      where flag.rawValue.contains("SENTRY") || flag.rawValue.contains("METRICS") {
        telemetry[flag.rawValue] = flags[flag] ?? flag.defaultValue
      }
      result["telemetry"] = telemetry

      // Debug options
      var debugOptions: [String: Bool] = [:]
      for flag in Flag.allCases where flag.rawValue.hasPrefix("DEBUG_") {
        debugOptions[flag.rawValue] = flags[flag] ?? flag.defaultValue
      }
      result["debug_options"] = debugOptions

      return result
    }
  }

  /// Convenience method for checking multiple flags
  public func areEnabled(_ flags: Flag...) -> Bool {
    return flags.allSatisfy { isEnabled($0) }
  }

  /// Convenience method for checking if any flag is enabled
  public func isAnyEnabled(_ flags: Flag...) -> Bool {
    return flags.contains { isEnabled($0) }
  }
}

// MARK: - Convenience Extensions

/// Convenience properties for common feature flag checks
extension FeatureFlags {
  /// Quick access to common flag states

  /// Returns true if power monitoring feature is enabled
  public var isPowerMonitoringEnabled: Bool { isEnabled(.powerMonitoring) }

  /// Returns true if accessibility manager is enabled
  public var isAccessibilityEnabled: Bool { isEnabled(.accessibilityManager) }

  /// Returns true if notification service is enabled
  public var isNotificationsEnabled: Bool { isEnabled(.notificationService) }

  /// Returns true if authentication service is enabled
  public var isAuthenticationEnabled: Bool { isEnabled(.authenticationService) }

  /// Returns true if auto-arm manager is enabled
  public var isAutoArmEnabled: Bool { isEnabled(.autoArmManager) }

  /// Returns true if location manager is enabled
  public var isLocationEnabled: Bool { isEnabled(.locationManager) }

  /// Returns true if network monitor is enabled
  public var isNetworkMonitorEnabled: Bool { isEnabled(.networkMonitor) }

  /// Returns true if security evidence collection is enabled
  public var isSecurityEvidenceEnabled: Bool { isEnabled(.securityEvidence) }

  /// Returns true if cloud sync is enabled
  public var isCloudSyncEnabled: Bool { isEnabled(.cloudSync) }

  /// Returns true if Sentry error reporting is enabled
  public var isSentryEnabled: Bool { isEnabled(.sentryEnabled) }

  /// Returns true if performance metrics collection is enabled
  public var isPerformanceMetricsEnabled: Bool { isEnabled(.performanceMetrics) }

  /// Returns true if verbose logging is enabled
  public var isVerboseLoggingEnabled: Bool { isEnabled(.verboseLogging) }
}
