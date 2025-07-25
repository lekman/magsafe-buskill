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
        }
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateStatusIcon()
            button.action = #selector(statusItemClicked)
            button.target = self
            
            // Log status
            print("[AppDelegate] Status button created: \(button)")
            print("[AppDelegate] Button image: \(button.image?.description ?? "nil")")
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
            
            // If SF Symbol fails, try a fallback
            if image == nil {
                print("[AppDelegate] WARNING: Failed to load SF Symbol '\(iconName)', using fallback")
                // Create a simple circle as fallback
                let fallbackImage = NSImage(size: NSSize(width: 18, height: 18))
                fallbackImage.lockFocus()
                let path = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 14))
                if core.isArmed {
                    NSColor.systemRed.setFill()
                } else {
                    NSColor.labelColor.setFill()
                }
                path.fill()
                fallbackImage.unlockFocus()
                button.image = fallbackImage
            } else {
                button.image = image
                // Make it a template image so it adapts to menu bar appearance
                button.image?.isTemplate = true
            }
            
            // Color the icon based on armed state
            if core.isArmed {
                button.contentTintColor = .systemRed
            } else {
                button.contentTintColor = nil
            }
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