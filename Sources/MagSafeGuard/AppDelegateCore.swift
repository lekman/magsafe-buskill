//
//  AppDelegateCore.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  This file contains the testable core logic extracted from AppDelegate
//  to enable better unit testing without NSApp dependencies.
//

import Foundation
import AppKit

/// Core logic for AppDelegate that can be tested without NSApp dependencies
public class AppDelegateCore {
    
    // MARK: - Properties
    
    public var isArmed = false
    public let powerMonitor: PowerMonitorService
    public let securityActions: SecurityActionsService
    
    // MARK: - Initialization
    
    public init() {
        // Default initializer - uses shared instances
        self.powerMonitor = PowerMonitorService.shared
        self.securityActions = SecurityActionsService.shared
    }
    
    /// Initialize with custom services (for testing)
    public init(powerMonitor: PowerMonitorService = PowerMonitorService.shared,
                securityActions: SecurityActionsService) {
        self.powerMonitor = powerMonitor
        self.securityActions = securityActions
    }
    
    // MARK: - Menu Configuration
    
    /// Creates the menu structure for the status item
    public func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Arm/Disarm item
        let armItem = NSMenuItem(title: "Arm Protection", action: #selector(AppDelegate.toggleArmed), keyEquivalent: "")
        armItem.state = isArmed ? NSControl.StateValue.on : NSControl.StateValue.off
        menu.addItem(armItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings item
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(AppDelegate.showSettings), keyEquivalent: ",")
        menu.addItem(settingsItem)
        
        // Demo item
        let demoItem = NSMenuItem(title: "Run Demo...", action: #selector(AppDelegate.showDemo), keyEquivalent: "d")
        menu.addItem(demoItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        return menu
    }
    
    /// Updates the menu item states based on current status
    public func updateMenuItems(in menu: NSMenu) {
        if let armItem = menu.items.first(where: { $0.title == "Arm Protection" }) {
            armItem.state = isArmed ? NSControl.StateValue.on : NSControl.StateValue.off
        }
    }
    
    // MARK: - Status Icon
    
    /// Determines the appropriate status icon based on armed state
    public func statusIconName() -> String {
        // Use more basic SF Symbols that are available on older macOS versions
        return isArmed ? "lock.fill" : "lock"
    }
    
    // MARK: - Power Monitoring
    
    /// Handles power state changes
    public func handlePowerStateChange(_ powerInfo: PowerMonitorService.PowerInfo) -> Bool {
        print("[PowerMonitor] State: \(powerInfo.state.rawValue)")
        
        if powerInfo.state == .disconnected && isArmed {
            print("[PowerMonitor] ⚠️ Power disconnected while armed!")
            
            // Execute security actions
            securityActions.executeActions { result in
                if result.allSucceeded {
                    print("[PowerMonitor] All security actions executed successfully")
                } else {
                    print("[PowerMonitor] Some security actions failed:")
                    for (action, error) in result.failedActions {
                        print("  - \(action.displayName): \(error.localizedDescription)")
                    }
                }
            }
            
            return true // Security action triggered
        }
        
        return false
    }
    
    // MARK: - Security Actions
    
    /// Determines if authentication should be attempted
    public func shouldAuthenticate() -> Bool {
        return isArmed
    }
    
    /// Creates notification content
    public func createNotificationContent(title: String, message: String) -> (title: String, informativeText: String, identifier: String) {
        let identifier = "MagSafeGuard-\(UUID().uuidString)"
        return (title, message, identifier)
    }
    
    // MARK: - State Management
    
    /// Toggles the armed state
    public func toggleArmedState() {
        isArmed.toggle()
    }
    
    /// Validates bundle identifier for notifications
    public func shouldRequestNotificationPermissions() -> Bool {
        return Bundle.main.bundleIdentifier != nil
    }
}