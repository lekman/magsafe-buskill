//
//  AppDelegateCore.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  This file contains the testable core logic extracted from AppDelegate
//  to enable better unit testing without NSApp dependencies.
//

import AppKit
import Combine
import Foundation

/// Core logic for AppDelegate that can be tested without NSApp dependencies.
///
/// AppDelegateCore contains the testable business logic extracted from AppDelegate,
/// enabling comprehensive unit testing without requiring NSApplication or system
/// integration. It manages the interface between the menu system and the core
/// application controller.
///
/// ## Architecture
///
/// The core provides:
/// - **Menu Construction**: Dynamic menu building based on application state
/// - **Action Coordination**: Bridging menu actions to controller methods
/// - **Status Management**: Icon and status text generation
/// - **Backward Compatibility**: Legacy API support for gradual migration
///
/// ## Usage
///
/// ```swift
/// let core = AppDelegateCore()
/// let menu = core.createMenu()
/// statusItem.menu = menu
/// ```
///
/// ## Thread Safety
///
/// All methods are safe to call from the main queue. The core coordinates
/// with AppController which handles its own thread safety.
public class AppDelegateCore {

    // MARK: - Properties

    /// The main application controller managing security state.
    ///
    /// Provides access to the core application logic including arming/disarming,
    /// grace period management, and security action execution.
    public let appController: AppController
    private var cancellables = Set<AnyCancellable>()

    /// Whether the security system is currently armed.
    ///
    /// Legacy property for backward compatibility. Returns true if the system
    /// is in armed or grace period state. New code should observe
    /// `appController.currentState` directly.
    public var isArmed: Bool {
        appController.currentState == .armed || appController.currentState == .gracePeriod
    }

    /// Shared power monitoring service.
    ///
    /// Legacy property providing access to the power monitor.
    /// New code should access PowerMonitorService.shared directly.
    public var powerMonitor: PowerMonitorService {
        PowerMonitorService.shared
    }

    /// Shared security actions service.
    ///
    /// Legacy property providing access to security actions.
    /// New code should access SecurityActionsService.shared directly.
    public var securityActions: SecurityActionsService {
        SecurityActionsService.shared
    }

    // MARK: - Initialization

    /// Initialize with default dependencies.
    ///
    /// Creates a new core with a standard AppController using shared services.
    /// This is the typical initialization for production use.
    public init() {
        self.appController = AppController()
        setupBindings()
    }

    /// Initialize with custom app controller.
    ///
    /// Allows dependency injection of a custom AppController for testing
    /// or specialized configurations.
    ///
    /// - Parameter appController: Custom controller instance to use
    public init(appController: AppController) {
        self.appController = appController
        setupBindings()
    }

    /// Initialize with custom services.
    ///
    /// Creates an AppController with custom service dependencies for testing
    /// or specialized configurations.
    ///
    /// - Parameters:
    ///   - authService: Custom authentication service
    ///   - securityActions: Custom security actions service
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

    /// Creates the menu structure for the status item.
    ///
    /// Builds a complete NSMenu with all menu items based on the current
    /// application state. The menu is dynamically updated to show relevant
    /// options like grace period cancellation when appropriate.
    ///
    /// - Returns: Configured NSMenu ready for display
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

    /// Updates the menu item states based on current status.
    ///
    /// Legacy method maintained for backward compatibility. The current
    /// implementation recreates the menu each time rather than updating
    /// existing items, making this method unnecessary.
    ///
    /// - Parameter menu: Menu to update (parameter ignored)
    public func updateMenuItems(in _: NSMenu) {
        // The menu is recreated each time, so this is not needed anymore
        // But kept for backward compatibility
    }

    // MARK: - Status Icon

    /// Determines the appropriate status icon based on armed state.
    ///
    /// Returns the SF Symbols icon name that represents the current security
    /// system state for display in the menu bar status item.
    ///
    /// - Returns: SF Symbols icon name (e.g., "shield.fill", "shield")
    public func statusIconName() -> String {
        return appController.statusIconName
    }

    // MARK: - Power Monitoring

    /// Handles power state changes.
    ///
    /// Legacy method maintained for backward compatibility. Power state
    /// changes are now handled internally by AppController.
    ///
    /// - Parameter powerInfo: Power state information (ignored)
    /// - Returns: Always false (no action taken)
    public func handlePowerStateChange(_ _: PowerMonitorService.PowerInfo) -> Bool {
        // The AppController now handles this internally
        return false
    }

    // MARK: - Actions

    /// Toggles the armed state of the security system.
    ///
    /// Switches between armed and disarmed states with proper authentication.
    /// This is a legacy method that delegates to AppController's arm/disarm
    /// methods which handle authentication and error reporting.
    public func toggleArmedState() {
        // This is now handled by arm/disarm methods in AppController
        // This method is kept for backward compatibility
        if appController.currentState == .disarmed {
            appController.arm { _ in
                // Empty completion - errors are handled internally by AppController
                // which shows authentication dialogs and notifications to the user
            }
        } else {
            appController.disarm { _ in
                // Empty completion - errors are handled internally by AppController
                // which shows authentication dialogs and notifications to the user
            }
        }
    }

    /// Cancels the active grace period with authentication.
    ///
    /// Attempts to cancel pending security actions during the grace period.
    /// Requires user authentication and respects configuration settings.
    public func cancelGracePeriod() {
        appController.cancelGracePeriodWithAuth { _ in
            // Empty completion - errors are handled internally by AppController
            // which shows authentication dialogs and notifications to the user
        }
    }

    // MARK: - Notifications

    /// Creates notification content with unique identifier.
    ///
    /// Generates a notification content tuple with a unique identifier
    /// for tracking and managing notifications.
    ///
    /// - Parameters:
    ///   - title: Notification title
    ///   - message: Notification message
    /// - Returns: Tuple containing title, message, and unique identifier
    public func createNotificationContent(title: String, message: String) -> (title: String, informativeText: String, identifier: String) {
        let identifier = "MagSafeGuard-\(UUID().uuidString)"
        return (title, message, identifier)
    }

    /// Validates bundle identifier for notifications.
    ///
    /// Determines if the application should request notification permissions
    /// based on whether it has a valid bundle identifier (indicating it's
    /// running as a proper application bundle).
    ///
    /// - Returns: True if notification permissions should be requested
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
