//
//  MagSafeGuardApp.swift
//  MagSafe Guard
//
//  Created on 2025-07-24.
//

import SwiftUI
import AppKit
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
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private var demoWindow: NSWindow?
    private let core = AppDelegateCore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon as this is a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
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
        
        // Start power monitoring
        startPowerMonitoring()
    }
    
    private func setupMenu() {
        let menu = core.createMenu()
        statusItem?.menu = menu
    }
    
    private func updateStatusIcon() {
        if let button = statusItem?.button {
            let iconName = core.statusIconName()
            let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "MagSafe Guard")
            
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
    
    private func startPowerMonitoring() {
        core.powerMonitor.startMonitoring { [weak self] powerInfo in
            guard let self = self else { return }
            
            // Update menu
            self.setupMenu()
            
            // Check if we should trigger security action
            if self.core.handlePowerStateChange(powerInfo) {
                self.triggerSecurityAction()
            }
        }
    }
    
    @objc private func statusItemClicked(_ sender: AnyObject?) {
        // Menu will show automatically when clicked
    }
    
    @objc func toggleArmed() {
        core.toggleArmedState()
        updateStatusIcon()
        core.updateMenuItems(in: statusItem?.menu ?? NSMenu())
        
        let message = core.isArmed ? "MagSafe Guard is now ARMED" : "MagSafe Guard is now DISARMED"
        showNotification(title: "MagSafe Guard", message: message)
    }
    
    @objc func showSettings() {
        // TODO: Implement settings window
        print("Settings clicked")
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
    
    private func triggerSecurityAction() {
        print("⚠️ SECURITY ALERT: Power disconnected while armed!")
        
        // For now, just lock the screen
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        task.launch()
        
        showNotification(
            title: "MagSafe Guard Alert",
            message: "Power adapter disconnected! Security action triggered."
        )
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
}