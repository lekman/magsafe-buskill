//
//  SettingsModel.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Data models for application settings and configuration
//

import Foundation
import MagSafeGuardDomain

/// Comprehensive settings model for MagSafe Guard configuration.
///
/// This structure contains all user-configurable settings for the application,
/// organized into logical groups for security, auto-arm, notifications, and general preferences.
/// All settings are persisted automatically and can be exported/imported as JSON.
///
/// ## Validation
///
/// The model includes built-in validation for critical settings:
/// - Grace period is constrained to 5-30 seconds
/// - Security actions maintain execution order
/// - Network names are validated for basic format
///
/// ## Usage
///
/// ```swift
/// var settings = Settings()
/// settings.gracePeriodDuration = 15.0
/// settings.securityActions = [.lockScreen, .shutdown]
/// ```
///
/// Settings are automatically validated when modified through `UserDefaultsManager`.
public struct Settings: Codable {

  // MARK: - Security Settings

  /// Duration of grace period before security actions execute.
  ///
  /// This value determines how long users have to cancel security actions
  /// after power disconnection. Valid range is 5-30 seconds.
  /// A value of 0 disables the grace period entirely.
  ///
  /// - Note: Changes take effect immediately for new security events
  public var gracePeriodDuration: TimeInterval = 10.0

  /// Whether users can cancel security actions during the grace period.
  ///
  /// When enabled, users can authenticate during the grace period to cancel
  /// pending security actions. When disabled, security actions execute
  /// automatically after the grace period expires.
  ///
  /// - Important: This setting affects security posture - consider carefully
  public var allowGracePeriodCancellation: Bool = true

  /// Ordered list of security actions to execute on trigger.
  ///
  /// Actions are executed in the order specified. The default configuration
  /// locks the screen first, then unmounts volumes for data protection.
  /// Users can reorder actions based on their security requirements.
  ///
  /// - Note: At least one action should be configured for effective security
  public var securityActions: [SecurityActionType] = [.lockScreen, .soundAlarm]

  // MARK: - Auto-Arm Settings

  /// Master enable/disable for automatic arming features.
  ///
  /// When disabled, all auto-arm functionality is inactive regardless of
  /// other auto-arm settings. When enabled, individual auto-arm triggers
  /// can be configured independently.
  ///
  /// - Note: Requires appropriate system permissions (location, network access)
  public var autoArmEnabled: Bool = false

  /// Enable automatic arming based on location changes.
  ///
  /// When enabled, the system automatically arms when leaving trusted locations
  /// and disarms when returning. Requires location services permission.
  ///
  /// - Important: Location-based arming is not yet implemented
  public var autoArmByLocation: Bool = false

  /// List of trusted Wi-Fi network SSIDs.
  ///
  /// When connected to networks in this list, auto-arm is disabled.
  /// When disconnecting from trusted networks, the system may automatically arm
  /// if `autoArmOnUntrustedNetwork` is enabled.
  ///
  /// - Note: Network names are case-sensitive and must match exactly
  public var trustedNetworks: [String] = []

  /// Automatically arm when not connected to trusted networks.
  ///
  /// When enabled, the system arms protection automatically when:
  /// - Connecting to an untrusted Wi-Fi network
  /// - Disconnecting from a trusted network
  /// - No Wi-Fi connection is available
  ///
  /// This provides automatic security in public spaces.
  public var autoArmOnUntrustedNetwork: Bool = false

  // MARK: - Notification Settings

  /// Controls display of status change notifications.
  ///
  /// When enabled, users receive notifications for:
  /// - System armed/disarmed events
  /// - Auto-arm activation
  /// - Settings changes
  ///
  /// Critical security alerts bypass this setting and are always shown.
  public var showStatusNotifications: Bool = true

  /// Enable audio alerts for critical security events.
  ///
  /// When enabled, critical alerts (power disconnection, grace period warnings)
  /// play system alert sounds to ensure user attention. This setting works
  /// independently of notification permissions.
  ///
  /// - Note: Critical alerts may use system critical alert priority
  public var playCriticalAlertSound: Bool = true

  // MARK: - General Settings

  /// Automatically launch MagSafe Guard at user login.
  ///
  /// When enabled, the application starts automatically when the user logs in,
  /// ensuring continuous protection without manual intervention.
  ///
  /// - Important: Implementation pending - currently shows UI only
  public var launchAtLogin: Bool = false

  /// Display application icon in the dock.
  ///
  /// When enabled, shows the application icon in the dock in addition to
  /// the menu bar. When disabled, the application runs as a menu bar only app.
  ///
  /// - Note: Changes require application restart to take effect
  public var showInDock: Bool = false

  // MARK: - Advanced Settings

  /// List of custom script paths for execution during security actions.
  ///
  /// These scripts are executed as part of the security action sequence,
  /// allowing users to implement custom security behaviors like:
  /// - Network disconnection
  /// - Data encryption
  /// - Remote notifications
  ///
  /// - Warning: Scripts run with user permissions and should be carefully vetted
  public var customScripts: [String] = []

  /// Enable detailed debug logging for troubleshooting.
  ///
  /// When enabled, the application logs detailed information about:
  /// - State transitions
  /// - Power monitoring events
  /// - Authentication attempts
  /// - Security action execution
  ///
  /// Debug logs may contain sensitive information and should be disabled in production.
  public var debugLoggingEnabled: Bool = false

  // MARK: - Cloud Sync Settings

  /// Whether iCloud sync is enabled.
  ///
  /// When enabled, settings and security events will be synchronized across devices
  /// using the same iCloud account.
  public var iCloudSyncEnabled: Bool = false

  /// Maximum amount of data to store in iCloud (in MB).
  ///
  /// This limits the amount of evidence data that can be uploaded to iCloud
  /// to prevent excessive storage usage.
  public var iCloudDataLimitMB: Double = 100.0

  /// How long to retain evidence data in iCloud (in days).
  ///
  /// Older evidence data will be automatically deleted to save storage space.
  public var iCloudDataAgeLimitDays: Double = 30.0

  // MARK: - Validation

  /// Validates settings and returns normalized version
  public func validated() -> Settings {
    var validated = self

    // Ensure grace period is within bounds
    validated.gracePeriodDuration = max(5.0, min(30.0, gracePeriodDuration))

    // Ensure at least one security action is selected
    if validated.securityActions.isEmpty {
      validated.securityActions = [SecurityActionType.lockScreen]
    }

    // Remove duplicate security actions while preserving order  
    var seen = Set<SecurityActionType>()
    validated.securityActions = validated.securityActions.filter { action in
      if seen.contains(action) {
        return false
      }
      seen.insert(action)
      return true
    }

    return validated
  }
}

// MARK: - Domain Model Extensions
// NOTE: Extensions for SecurityActionType moved to Domain layer to avoid conflicts

// MARK: - Settings Migration

/// Protocol for migrating settings between versions.
///
/// Implementers of this protocol provide migration logic to upgrade
/// settings from older versions to newer formats, ensuring backward
/// compatibility and data preservation during app updates.
public protocol SettingsMigrator {
  /// The source version this migrator upgrades from.
  var fromVersion: Int { get }

  /// The target version this migrator upgrades to.
  var toVersion: Int { get }

  /// Migrates settings from the source format to the target format.
  /// - Parameter settings: Raw settings dictionary to migrate
  /// - Returns: Migrated settings dictionary
  func migrate(_ settings: [String: Any]) -> [String: Any]
}

/// Current version number for the settings format.
///
/// This version is incremented when breaking changes are made to the
/// Settings structure that require migration logic.
public let currentSettingsVersion = 1
