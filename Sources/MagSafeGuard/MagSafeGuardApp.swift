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
        // Set a bundle identifier for development if needed
        if Bundle.main.bundleIdentifier == nil {
            print("[MagSafeGuardApp] Running in development mode without bundle identifier")
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
    private var demoWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var windowDelegates: [NSWindow: WindowDelegate] = [:]
    let core = AppDelegateCore()

    // MARK: - Constants

    private static let appName = "MagSafe Guard"

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon as this is a menu bar app
        NSApp.setActivationPolicy(.accessory)

        // Setup AppController callbacks
        setupAppControllerCallbacks()

        // Only request notification permissions if we have a valid bundle
        if Bundle.main.bundleIdentifier != nil {
            requestNotificationPermissions()
        } else {
            print("[AppDelegate] Running without bundle identifier - notifications disabled")
            print("[AppDelegate] TIP: To see menu bar icon in Xcode:")
            print("[AppDelegate]   1. Product > Scheme > Edit Scheme")
            print("[AppDelegate]   2. Run > Options > Launch: Wait for executable to be launched")
            print("[AppDelegate]   3. Build and Run, then manually launch from build folder")
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
            print("[AppDelegate] Status button created: \(button)")
            print("[AppDelegate] Button frame: \(button.frame)")
            print("[AppDelegate] Button superview: \(button.superview?.description ?? "nil")")
            print("[AppDelegate] Button image: \(button.image?.description ?? "nil")")
            print("[AppDelegate] Button title: \(button.title)")
        } else {
            print("[AppDelegate] ERROR: Failed to create status button")
        }

        // Create menu
        setupMenu()

        // AppController now handles power monitoring internally
    }

    private func setupMenu() {
        let menu = core.createMenu()
        statusItem?.menu = menu
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
            let image = NSImage(systemSymbolName: iconName, accessibilityDescription: AppDelegate.appName)

            // If SF Symbol works, use it
            if let image = image {
                // Create a copy and set as template to ensure proper dark/light mode handling
                let templateImage = image.copy() as! NSImage
                templateImage.isTemplate = true
                button.image = templateImage
                // Clear the title when we have an icon
                button.title = ""

                print("[AppDelegate] Icon updated: \(iconName)")
            } else {
                // Fallback to text if icon fails
                print("[AppDelegate] WARNING: Failed to load SF Symbol '\(iconName)', using text fallback")
                button.image = nil
                button.title = core.isArmed ? "MG!" : "MG"
            }

            // Ensure the icon uses system appearance (no custom tint)
            button.contentTintColor = nil
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
                    self?.showNotification(title: AppDelegate.appName, message: "Failed to arm: \(error.localizedDescription)")
                }
            }
        } else {
            core.appController.disarm { [weak self] result in
                switch result {
                case .success:
                    // Notifications are handled by AppController callback
                    break
                case .failure(let error):
                    self?.showNotification(title: AppDelegate.appName, message: "Failed to disarm: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )

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

    @objc func showDemo() {
        if demoWindow == nil {
            let demoView = PowerMonitorDemoView()

            demoWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )

            demoWindow?.title = "Power Monitor Demo"
            demoWindow?.contentView = NSHostingView(rootView: demoView)
            demoWindow?.center()
        }

        demoWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("[AppDelegate] Notification permissions granted")
            } else if let error = error {
                print("[AppDelegate] Notification permission error: \(error)")
            }
        }
    }

    private func showNotification(title: String, message: String) {
        let (notificationTitle, text, identifier) = core.createNotificationContent(title: title, message: message)

        // Check if we can use UNUserNotificationCenter
        guard Bundle.main.bundleIdentifier != nil else {
            // Fallback: Just print to console when running from Xcode
            print("🔔 NOTIFICATION: \(notificationTitle) - \(text)")

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
                print("[AppDelegate] Error showing notification: \(error)")
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Log application termination
        core.appController.logEvent(.applicationTerminating, details: "App terminating")

        // Save any pending state
        saveApplicationState()

        print("[AppDelegate] Application terminating")
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Refresh menu when app becomes active
        setupMenu()

        print("[AppDelegate] Application became active")
    }

    func applicationDidResignActive(_ notification: Notification) {
        print("[AppDelegate] Application resigned active")
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

        print("[AppDelegate] Saving state: \(state.rawValue)")
        print("[AppDelegate] Recent events: \(events.count)")
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
