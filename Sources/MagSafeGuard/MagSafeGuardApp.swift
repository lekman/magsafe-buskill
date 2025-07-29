//
//  MagSafeGuardApp.swift
//  MagSafe Guard
//
//  Created on 2025-07-24.
//

import AppKit
import SwiftUI
import UserNotifications

@main
struct MagSafeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Minimal initialization to get app running
        
        // Set a bundle identifier for development if needed
        if Bundle.main.bundleIdentifier == nil {
            print("Running in development mode without bundle identifier")
        }
    }

    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var windowDelegates: [NSWindow: WindowDelegate] = [:]
    // Re-enable core to test
    let core = AppDelegateCore()

    // MARK: - Constants

    private static let appName = "MagSafe Guard"

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        
        // Hide dock icon as this is a menu bar app
        NSApp.setActivationPolicy(.accessory)

        // Create the status item immediately for fast UI response
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Setup critical UI first
        setupCriticalUI()

        // Simple direct startup
        finishStartup()
    }

    private func setupCriticalUI() {
        // Ensure the status item is retained
        statusItem?.isVisible = true

        if let button = statusItem?.button {
            // Use preloaded icon for instant display
            if let icon = ResourcePreloader.shared.getDefaultIcon() {
                button.image = icon
                button.title = ""
            } else {
                // Fallback to text
                button.title = "MG"
            }

            button.action = #selector(statusItemClicked)
            button.target = self
            button.appearsDisabled = false
        } else {
            Log.fault("Failed to create status button", category: .ui)
        }

        // Create minimal loading menu
        let loadingMenu = NSMenu()
        loadingMenu.addItem(NSMenuItem(title: "MagSafe Guard is starting...", action: nil, keyEquivalent: ""))
        statusItem?.menu = loadingMenu
    }

    private func performAsyncStartup() {
        // Setup AppController callbacks
        setupAppControllerCallbacks()
        StartupMetrics.shared.recordMilestone("callbacks_setup")

        // Initialize core services (lazy initialization)
        _ = core.appController
        StartupMetrics.shared.recordMilestone("core_initialized")

        // Setup main UI on main thread
        DispatchQueue.main.async { [weak self] in
            self?.finishStartup()
        }
    }

    private func finishStartup() {
        // Setup the full menu
        setupMenu()
        
        // Update the status icon based on initial state
        updateStatusIcon()
        
        // Ensure proper activation
        NSApp.activate(ignoringOtherApps: true)
        
        // Configure accessibility features after startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupAccessibilityFeatures()
        }
        
        // Setup CloudKit notifications
        setupCloudKitNotifications()
        
        print("MagSafe Guard startup complete")
        StartupMetrics.shared.recordMilestone("startup_complete")
    }

    private func setupMenu() {
        let menu = core.createMenu()
        statusItem?.menu = menu
    }

    private func setupAccessibilityFeatures() {
        // Configure accessibility manager
        AccessibilityManager.shared.configureVoiceOverSupport()
        AccessibilityManager.shared.configureKeyboardNavigation()

        // Configure status item accessibility
        if let button = statusItem?.button {
            button.setAccessibilityLabel(AppDelegate.appName)
            button.setAccessibilityHelp("Click to open \(AppDelegate.appName) menu. Current status: \(core.appController.statusDescription)")
            button.setAccessibilityRole(.menuButton)
        }

        Log.info("Accessibility features configured", category: .general)
    }

    private func setupCloudKitNotifications() {
        // Listen for CloudKit initialization failures
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitInitializationFailure(_:)),
            name: Notification.Name("MagSafeGuardCloudKitInitializationFailed"),
            object: nil
        )

        // Listen for CloudKit permission issues
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitPermissionNeeded(_:)),
            name: Notification.Name("MagSafeGuardCloudKitPermissionNeeded"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitAccountNeeded(_:)),
            name: Notification.Name("MagSafeGuardCloudKitAccountNeeded"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitRestricted(_:)),
            name: Notification.Name("MagSafeGuardCloudKitRestricted"),
            object: nil
        )
    }

    private func setupAppControllerCallbacks() {
        // Handle state changes
        core.appController.onStateChange = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateStatusIcon()
                self?.setupMenu()
            }
        }

        // Handle notifications
        core.appController.onNotification = { [weak self] title, message in
            self?.showNotification(title: title, message: message)
        }
    }

    private func updateStatusIcon() {
        if let button = statusItem?.button {
            let iconName = core.statusIconName()
            let statusDescription = core.appController.statusDescription

            // Try preloaded icon first for instant update
            if let preloadedIcon = ResourcePreloader.shared.getIcon(named: iconName) {
                button.image = preloadedIcon
                button.title = ""
                Log.debug("Icon updated with preloaded: \(iconName)", category: .ui)
            } else {
                // Try loading fresh if not preloaded
                let image = NSImage(systemSymbolName: iconName, accessibilityDescription: AppDelegate.appName)

                if let image = image {
                    // Create a copy and set as template
                    guard let templateImage = image.copy() as? NSImage else { return }
                    templateImage.isTemplate = true
                    button.image = templateImage
                    button.title = ""
                    Log.debug("Icon updated: \(iconName)", category: .ui)
                } else {
                    // Fallback to text if icon fails
                    Log.warning("Failed to load SF Symbol '\(iconName)', using text fallback", category: .ui)
                    button.image = nil
                    button.title = core.isArmed ? "MG!" : "MG"
                }
            }

            // Ensure the icon uses system appearance and supports high contrast
            button.contentTintColor = nil

            // Update accessibility properties to reflect current state
            button.setAccessibilityLabel(AppDelegate.appName)
            button.setAccessibilityValue(statusDescription)
            button.setAccessibilityHelp("Click to open \(AppDelegate.appName) menu. Current status: \(statusDescription)")

            // Announce state changes if VoiceOver is enabled
            if AccessibilityManager.shared.isVoiceOverEnabled {
                AccessibilityAnnouncement.announceStateChange(component: "\(AppDelegate.appName) status", newState: statusDescription)
            }
        }
    }

    @objc private func statusItemClicked(_ sender: AnyObject?) {
        // Menu will show automatically when clicked
    }

    @objc func toggleArmed() {
        // DISABLED FOR DEBUGGING
        print("toggleArmed called - core disabled")
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )

            // Set minimum size to ensure navigation is always visible
            settingsWindow?.minSize = NSSize(width: 700, height: 500)

            settingsWindow?.title = "MagSafe Guard Settings"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.center()
            settingsWindow?.setFrameAutosaveName("SettingsWindow")

            // Clean up when window closes
            let delegate = WindowDelegate { [weak self] in
                self?.settingsWindow = nil
                if let window = self?.settingsWindow {
                    self?.windowDelegates.removeValue(forKey: window)
                }
            }
            settingsWindow?.delegate = delegate
            windowDelegates[settingsWindow!] = delegate
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                Log.info("Notification permissions granted", category: .ui)
            } else if let error = error {
                Log.error("Notification permission error", error: error, category: .ui)
            }
        }
    }

    private func showNotification(title: String, message: String) {
        let (notificationTitle, text, identifier) = core.createNotificationContent(title: title, message: message)

        // Check if we can use UNUserNotificationCenter
        guard Bundle.main.bundleIdentifier != nil else {
            // Fallback: Just print to console when running from Xcode
            Log.info("🔔 NOTIFICATION: \(notificationTitle) - \(text)", category: .ui)

            // Alternative: Show an alert window
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = notificationTitle
                alert.informativeText = text
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            return
        }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = text
        content.sound = UNNotificationSound.default

        // Trigger immediately
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        // Add the request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.error("Error showing notification", error: error, category: .ui)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Log application termination
        core.appController.logEvent(.applicationTerminating, details: "App terminating")

        // Save any pending state
        saveApplicationState()

        Log.info("Application terminating", category: .ui)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Refresh menu when app becomes active
        setupMenu()

        Log.info("Application became active", category: .ui)
    }

    func applicationDidResignActive(_ notification: Notification) {
        Log.info("Application resigned active", category: .ui)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Log.info("applicationShouldTerminate called", category: .ui)
        Log.info("Current state: \(core.appController.currentState)", category: .ui)

        // Check if we're in a critical state
        if core.appController.currentState == .gracePeriod {
            // Show alert asking user to confirm
            let alert = NSAlert()
            alert.messageText = "Security Action in Progress"
            alert.informativeText = "A security action is currently in progress. Are you sure you want to quit?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Quit Anyway")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                Log.info("User cancelled quit during grace period", category: .ui)
                return .terminateCancel
            }
        }

        Log.info("Allowing app termination", category: .ui)
        return .terminateNow
    }

    private func saveApplicationState() {
        // TODO: Implement state persistence
        // For now, just log the current state
        let state = core.appController.currentState
        let events = core.appController.getEventLog(limit: 10)

        Log.debug("Saving state: \(state.rawValue)", category: .ui)
        Log.debug("Recent events: \(events.count)", category: .ui)
    }

    // MARK: - CloudKit Notification Handlers

    @objc private func handleCloudKitInitializationFailure(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let title = userInfo["title"] as? String,
              let message = userInfo["message"] as? String else { return }

        // Show a non-blocking notification
        showNotification(title: title, message: message)

        // Log the error for debugging
        if let error = userInfo["error"] as? Error {
            Log.error("CloudKit initialization failed", error: error, category: .ui)
        }
    }

    @objc private func handleCloudKitPermissionNeeded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let title = userInfo["title"] as? String,
              let message = userInfo["message"] as? String else { return }

        showNotification(title: title, message: message)
    }

    @objc private func handleCloudKitAccountNeeded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let title = userInfo["title"] as? String,
              let message = userInfo["message"] as? String else { return }

        showNotification(title: title, message: message)
    }

    @objc private func handleCloudKitRestricted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let title = userInfo["title"] as? String,
              let message = userInfo["message"] as? String else { return }

        showNotification(title: title, message: message)
    }
}

// MARK: - Window Delegate

/// Simple window delegate to handle window close events
class WindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
