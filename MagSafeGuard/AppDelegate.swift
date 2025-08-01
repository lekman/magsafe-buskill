//
//  AppDelegate.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//

import AppKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var settingsHostingController: NSViewController?
    private var windowDelegates: [NSWindow: WindowDelegate] = [:]
    let core = AppDelegateCore()

    // MARK: - Constants

    private static let appName = "MagSafe Guard"

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Skip normal initialization during tests
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            Log.info("Running in test environment, skipping normal initialization", category: .app)
            return
        }
        
        // Check for previous crashes
        checkForPreviousCrashes()

        // Hide dock icon as this is a menu bar app
        NSApp.setActivationPolicy(.accessory)

        // Setup AppController callbacks
        setupAppControllerCallbacks()

        // Only request notification permissions if we have a valid bundle
        if Bundle.main.bundleIdentifier != nil {
            requestNotificationPermissions()
        } else {
            Log.warning("Running without bundle identifier - notifications disabled", category: .ui)
            Log.info("TIP: To see menu bar icon in Xcode:", category: .ui)
            Log.info("  1. Product > Scheme > Edit Scheme", category: .ui)
            Log.info("  2. Run > Options > Launch: Wait for executable to be launched", category: .ui)
            Log.info("  3. Build and Run, then manually launch from build folder", category: .ui)
        }

        // Create the status item - use a strong reference
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Ensure the status item is retained
        statusItem?.isVisible = true

        if let button = statusItem?.button {
            // Set a title first to ensure visibility
            button.title = "MG"

            // Then try to set the icon
            updateStatusIcon()
            button.action = #selector(statusItemClicked)
            button.target = self

            // Force the button to be visible
            button.appearsDisabled = false

            // Log status
            Log.debug("Status button created: \(button)", category: .ui)
            Log.debug("Button frame: \(button.frame)", category: .ui)
            Log.debug("Button superview: \(button.superview?.description ?? "nil")", category: .ui)
            Log.debug("Button image: \(button.image?.description ?? "nil")", category: .ui)
            Log.debug("Button title: \(button.title)", category: .ui)
        } else {
            Log.fault("Failed to create status button", category: .ui)
        }

        // Create menu
        setupMenu()

        // Configure accessibility features
        setupAccessibilityFeatures()

        // AppController now handles power monitoring internally
    }

    private func setupMenu() {
        let menu = core.createMenu(for: self)
        statusItem?.menu = menu
    }

    private func setupAccessibilityFeatures() {
        // Configure accessibility manager
        AccessibilityManager.shared.configureVoiceOverSupport()
        AccessibilityManager.shared.configureKeyboardNavigation()

        // Configure status item accessibility
        if let button = statusItem?.button {
            button.setAccessibilityLabel("MagSafe Guard")
            button.setAccessibilityHelp("Click to open MagSafe Guard menu. Current status: \(core.appController.statusDescription)")
            button.setAccessibilityRole(.menuButton)
        }

        Log.info("Accessibility features configured", category: .general)
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
            let image = NSImage(systemSymbolName: iconName, accessibilityDescription: AppDelegate.appName)

            // If SF Symbol works, use it
            if let image = image {
                // Create a copy and set as template to ensure proper dark/light mode handling
                guard let templateImage = image.copy() as? NSImage else { return }
                templateImage.isTemplate = true
                button.image = templateImage
                // Clear the title when we have an icon
                button.title = ""

                Log.debug("Icon updated: \(iconName)", category: .ui)
            } else {
                // Fallback to text if icon fails
                Log.warning("Failed to load SF Symbol '\(iconName)', using text fallback", category: .ui)
                button.image = nil
                button.title = core.isArmed ? "MG!" : "MG"
            }

            // Ensure the icon uses system appearance and supports high contrast
            button.contentTintColor = nil

            // Update accessibility properties to reflect current state
            button.setAccessibilityLabel("MagSafe Guard")
            button.setAccessibilityValue(statusDescription)
            button.setAccessibilityHelp("Click to open MagSafe Guard menu. Current status: \(statusDescription)")

            // Announce state changes if VoiceOver is enabled
            if AccessibilityManager.shared.isVoiceOverEnabled {
                AccessibilityAnnouncement.announceStateChange(component: "MagSafe Guard status", newState: statusDescription)
            }
        }
    }

    @objc private func statusItemClicked(_ sender: AnyObject?) {
        // Menu will show automatically when clicked
    }

    @objc func toggleArmed() {
        if core.appController.currentState == .disarmed {
            core.appController.arm { [weak self] result in
                switch result {
                case .success:
                    // Notifications are handled by AppController callback
                    break
                case .failure(let error):
                    self?.showNotification(
                        title: AppDelegate.appName,
                        message: "Failed to arm: \(error.localizedDescription)"
                    )
                }
            }
        } else {
            core.appController.disarm { [weak self] result in
                switch result {
                case .success:
                    // Notifications are handled by AppController callback
                    break
                case .failure(let error):
                    self?.showNotification(
                        title: AppDelegate.appName,
                        message: "Failed to disarm: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    @objc func showSettings() {
        Log.info("showSettings called", category: .ui)

        // Safe window management pattern
        if let existingWindow = settingsWindow {
            Log.info("Bringing existing settings window to front", category: .ui)
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        Log.info("Creating new settings window", category: .ui)

        // Create new window safely
        let settingsView = SettingsView()
            .environmentObject(UserDefaultsManager.shared)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "MagSafe Guard Settings"

        // Create and retain the hosting controller
        let hostingController = NSHostingController(rootView: settingsView)
        settingsHostingController = hostingController
        window.contentViewController = hostingController

        window.center()
        // Temporarily disable frame autosave to ensure window appears
        // window.setFrameAutosaveName("SettingsWindow")
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false  // Prevent window from being released

        // Clean up when window closes
        let delegate = WindowDelegate { [weak self] in
            Task { @MainActor in
                self?.windowDelegates.removeValue(forKey: window)
                window.contentViewController = nil
                self?.settingsWindow = nil
                self?.settingsHostingController = nil

                // Return to accessory mode if no windows are open
                if self?.settingsWindow == nil {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }

        window.delegate = delegate
        windowDelegates[window] = delegate
        settingsWindow = window

        // Temporarily make the app regular so it appears in Dock and Cmd+Tab
        NSApp.setActivationPolicy(.regular)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Force window to be visible
        window.orderFrontRegardless()
        window.setIsVisible(true)

        Log.info("Settings window created and shown successfully", category: .ui)
        Log.info("Window visible: \(window.isVisible), frame: \(window.frame)", category: .ui)
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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu bar apps should not quit when the last window is closed
        return false
    }

    // MARK: - Crash Reporting

    private func checkForPreviousCrashes() {
        #if DEBUG
        if let crashInfo = UserDefaults.standard.dictionary(forKey: "lastCrashInfo") {
            Log.warning("Previous crash detected:", category: .ui)
            Log.warning("  Exception: \(crashInfo["exception"] ?? "Unknown")", category: .ui)
            Log.warning("  Reason: \(crashInfo["reason"] ?? "Unknown")", category: .ui)
            Log.warning("  Time: \(crashInfo["timestamp"] ?? "Unknown")", category: .ui)

            // Clear the crash info
            UserDefaults.standard.removeObject(forKey: "lastCrashInfo")

            // Show alert if running in development
            if Bundle.main.bundleIdentifier == nil {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Previous Crash Detected"
                    alert.informativeText = "Exception: \(crashInfo["exception"] ?? "Unknown")\nReason: \(crashInfo["reason"] ?? "Unknown")"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
        #endif
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
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
                return .terminateCancel
            }
        }

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
