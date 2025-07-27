//
//  SettingsModel.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Data models for application settings and configuration
//

import Foundation

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
public struct Settings: Codable, Equatable {

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
    public var securityActions: [SecurityActionType] = [.lockScreen, .unmountVolumes]

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

    // MARK: - Evidence Collection Settings

    /// Whether evidence collection is enabled.
    ///
    /// When enabled, the system will capture location data and photos when
    /// a theft is detected. This requires camera and location permissions.
    public var evidenceCollectionEnabled: Bool = false

    /// Email address for evidence backup.
    ///
    /// If configured, collected evidence will be sent to this email address
    /// in addition to being stored locally.
    public var backupEmailAddress: String = ""

    // MARK: - Validation

    /// Validates settings and returns normalized version
    public func validated() -> Settings {
        var validated = self

        // Ensure grace period is within bounds (0-30 seconds)
        validated.gracePeriodDuration = max(0.0, min(30.0, gracePeriodDuration))

        // Ensure at least one security action is selected
        if validated.securityActions.isEmpty {
            validated.securityActions = [.lockScreen]
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

/// Security actions that can be executed when power is disconnected.
///
/// Each action represents a specific security measure that helps protect
/// the system and data when a theft attempt is detected. Actions are executed
/// in the order configured by the user, allowing for layered security approaches.
///
/// ## Security Considerations
///
/// Actions are ordered by severity:
/// - **Immediate**: Lock screen, clear clipboard
/// - **Moderate**: Unmount volumes, log out
/// - **Severe**: Shutdown, custom scripts
///
/// Users should consider the impact of each action on their workflow and
/// data integrity when configuring security actions.
///
/// ## Implementation Status
///
/// - ✅ Lock Screen: Fully implemented
/// - ✅ Unmount Volumes: Fully implemented  
/// - 🚧 Log Out: Basic implementation
/// - 🚧 Shutdown: Basic implementation
/// - 🚧 Clear Clipboard: Basic implementation
/// - ❌ Custom Script: UI only, execution pending
public enum SecurityActionType: String, Codable, CaseIterable {
    /// Immediately lock the screen requiring authentication
    case lockScreen = "lock_screen"
    /// Log out the current user session
    case logOut = "log_out"
    /// Shut down the system completely
    case shutdown = "shutdown"
    /// Unmount all external volumes and drives
    case unmountVolumes = "unmount_volumes"
    /// Clear system clipboard contents
    case clearClipboard = "clear_clipboard"
    /// Execute a user-defined custom script
    case customScript = "custom_script"

    /// Human-readable name for the security action.
    ///
    /// These names are displayed in the settings UI and should be
    /// clear and understandable to end users.
    public var displayName: String {
        switch self {
        case .lockScreen:
            return "Lock Screen"
        case .logOut:
            return "Log Out"
        case .shutdown:
            return "Shut Down"
        case .unmountVolumes:
            return "Unmount External Volumes"
        case .clearClipboard:
            return "Clear Clipboard"
        case .customScript:
            return "Run Custom Script"
        }
    }

    /// Detailed description of the security action's behavior.
    ///
    /// These descriptions explain the specific security measure taken
    /// and help users understand the impact of each action.
    public var description: String {
        switch self {
        case .lockScreen:
            return "Locks the screen immediately, requiring password to unlock"
        case .logOut:
            return "Logs out the current user session"
        case .shutdown:
            return "Shuts down the system completely"
        case .unmountVolumes:
            return "Unmounts all external drives and volumes"
        case .clearClipboard:
            return "Clears clipboard contents to prevent data theft"
        case .customScript:
            return "Executes a custom shell script"
        }
    }

    /// SF Symbols icon name for visual representation.
    ///
    /// These symbols are used throughout the UI to provide visual
    /// identification of each security action type.
    public var symbolName: String {
        switch self {
        case .lockScreen:
            return "lock.fill"
        case .logOut:
            return "arrow.right.square.fill"
        case .shutdown:
            return "power"
        case .unmountVolumes:
            return "externaldrive.fill"
        case .clearClipboard:
            return "doc.on.clipboard"
        case .customScript:
            return "terminal.fill"
        }
    }
}

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
