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
import Combine

/// Core logic for AppDelegate that can be tested without NSApp dependencies
public class AppDelegateCore {
    
    // MARK: - Properties
    
    public let appController: AppController
    private var cancellables = Set<AnyCancellable>()
    
    // For backward compatibility
    public var isArmed: Bool {
        appController.currentState == .armed || appController.currentState == .gracePeriod
    }
    
    public var powerMonitor: PowerMonitorService {
        PowerMonitorService.shared
    }
    
    public var securityActions: SecurityActionsService {
        SecurityActionsService.shared
    }
    
    // MARK: - Initialization
    
    public init() {
        self.appController = AppController()
        setupBindings()
    }
    
    /// Initialize with custom app controller (for testing)
    public init(appController: AppController) {
        self.appController = appController
        setupBindings()
    }
    
    /// Initialize with custom services (for testing)
    public init(authService: AuthenticationService, securityActions: SecurityActionsService) {
        self.appController = AppController(
            authService: authService,
            securityActions: securityActions
        )
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // You can add any reactive bindings here if needed
    }
    
    // MARK: - Menu Configuration
    
    /// Creates the menu structure for the status item
    public func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Status item (disabled)
        let statusItem = NSMenuItem(title: appController.statusDescription, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Arm/Disarm item
        let armItem = NSMenuItem(title: appController.armDisarmMenuTitle, action: #selector(AppDelegate.toggleArmed), keyEquivalent: "a")
        menu.addItem(armItem)
        
        // Cancel grace period item (if in grace period)
        if appController.isInGracePeriod && appController.allowGracePeriodCancellation {
            let cancelItem = NSMenuItem(title: "Cancel Security Action", action: #selector(AppDelegate.cancelGracePeriod), keyEquivalent: "c")
            menu.addItem(cancelItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Power status
        let powerStatus = appController.lastPowerState == .connected ? "Power Connected" : "Running on Battery"
        let powerItem = NSMenuItem(title: powerStatus, action: nil, keyEquivalent: "")
        powerItem.isEnabled = false
        menu.addItem(powerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings item
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(AppDelegate.showSettings), keyEquivalent: ",")
        menu.addItem(settingsItem)
        
        // Demo item
        let demoItem = NSMenuItem(title: "Run Demo...", action: #selector(AppDelegate.showDemo), keyEquivalent: "d")
        menu.addItem(demoItem)
        
        // Event log item
        let logItem = NSMenuItem(title: "View Event Log...", action: #selector(AppDelegate.showEventLog), keyEquivalent: "l")
        menu.addItem(logItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit MagSafe Guard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        return menu
    }
    
    /// Updates the menu item states based on current status
    public func updateMenuItems(in menu: NSMenu) {
        // The menu is recreated each time, so this is not needed anymore
        // But kept for backward compatibility
    }
    
    // MARK: - Status Icon
    
    /// Determines the appropriate status icon based on armed state
    public func statusIconName() -> String {
        return appController.statusIconName
    }
    
    // MARK: - Power Monitoring
    
    /// Handles power state changes (for backward compatibility)
    public func handlePowerStateChange(_ powerInfo: PowerMonitorService.PowerInfo) -> Bool {
        // The AppController now handles this internally
        return false
    }
    
    // MARK: - Actions
    
    /// Toggles the armed state
    public func toggleArmedState() {
        // This is now handled by arm/disarm methods in AppController
        // This method is kept for backward compatibility
        if appController.currentState == .disarmed {
            appController.arm { _ in }
        } else {
            appController.disarm { _ in }
        }
    }
    
    /// Cancels grace period
    public func cancelGracePeriod() {
        appController.cancelGracePeriodWithAuth { _ in }
    }
    
    // MARK: - Notifications
    
    /// Creates notification content
    public func createNotificationContent(title: String, message: String) -> (title: String, informativeText: String, identifier: String) {
        let identifier = "MagSafeGuard-\(UUID().uuidString)"
        return (title, message, identifier)
    }
    
    /// Validates bundle identifier for notifications
    public func shouldRequestNotificationPermissions() -> Bool {
        return Bundle.main.bundleIdentifier != nil
    }
}

// MARK: - AppDelegate Extension

extension AppDelegate {
    @objc func cancelGracePeriod() {
        core.cancelGracePeriod()
    }
    
    @objc func showEventLog() {
        // TODO: Implement event log window
        let events = core.appController.getEventLog(limit: 50)
        print("=== Event Log ===")
        for event in events {
            print("[\(event.timestamp)] \(event.event.rawValue) - \(event.details ?? "No details")")
        }
    }
}