//
//  SettingsModel.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Data models for application settings and configuration
//

import Foundation

/// Model representing all user-configurable settings
public struct Settings: Codable, Equatable {
    
    // MARK: - Security Settings
    
    /// Grace period duration in seconds (5-30)
    public var gracePeriodDuration: TimeInterval = 10.0
    
    /// Whether to allow grace period cancellation
    public var allowGracePeriodCancellation: Bool = true
    
    /// Selected security actions in order of execution
    public var securityActions: [SecurityActionType] = [.lockScreen, .unmountVolumes]
    
    // MARK: - Auto-Arm Settings
    
    /// Whether auto-arm is enabled
    public var autoArmEnabled: Bool = false
    
    /// Auto-arm based on location
    public var autoArmByLocation: Bool = false
    
    /// List of trusted Wi-Fi network SSIDs
    public var trustedNetworks: [String] = []
    
    /// Auto-arm when not connected to trusted networks
    public var autoArmOnUntrustedNetwork: Bool = false
    
    // MARK: - Notification Settings
    
    /// Show notifications for arm/disarm events
    public var showStatusNotifications: Bool = true
    
    /// Play sound for critical alerts
    public var playCriticalAlertSound: Bool = true
    
    // MARK: - General Settings
    
    /// Launch at login
    public var launchAtLogin: Bool = false
    
    /// Show in dock (vs menu bar only)
    public var showInDock: Bool = false
    
    // MARK: - Advanced Settings
    
    /// Custom script paths for security actions
    public var customScripts: [String] = []
    
    /// Enable debug logging
    public var debugLoggingEnabled: Bool = false
    
    // MARK: - Validation
    
    /// Validates settings and returns normalized version
    public func validated() -> Settings {
        var validated = self
        
        // Ensure grace period is within bounds
        validated.gracePeriodDuration = max(5.0, min(30.0, gracePeriodDuration))
        
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

/// Types of security actions that can be configured
public enum SecurityActionType: String, Codable, CaseIterable {
    case lockScreen = "lock_screen"
    case logOut = "log_out"
    case shutdown = "shutdown"
    case unmountVolumes = "unmount_volumes"
    case clearClipboard = "clear_clipboard"
    case customScript = "custom_script"
    
    /// Display name for the action
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
    
    /// Description of what the action does
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
    
    /// SF Symbol name for the action
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

/// Protocol for settings migration
public protocol SettingsMigrator {
    var fromVersion: Int { get }
    var toVersion: Int { get }
    func migrate(_ settings: [String: Any]) -> [String: Any]
}

/// Current settings version
public let currentSettingsVersion = 1