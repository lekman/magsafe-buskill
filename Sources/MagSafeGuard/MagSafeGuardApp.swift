//
//  MagSafeGuardApp.swift
//  MagSafe Guard
//
//  Created on 2025-07-24.
//

import SwiftUI

@main
struct MagSafeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private let powerMonitor = PowerMonitorService.shared
    private var isArmed = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon as this is a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateStatusIcon()
            button.action = #selector(statusItemClicked)
        }
        
        // Create menu
        setupMenu()
        
        // Start power monitoring
        startPowerMonitoring()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Armed/Disarmed status
        let statusMenuItem = NSMenuItem(title: isArmed ? "Armed" : "Disarmed", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Arm/Disarm toggle
        menu.addItem(NSMenuItem(title: isArmed ? "Disarm" : "Arm", action: #selector(toggleArmed), keyEquivalent: "a"))
        
        menu.addItem(NSMenuItem.separator())
        
        // Power status
        let powerInfo = powerMonitor.getCurrentPowerInfo()
        let powerStatus = powerInfo?.state == .connected ? "Power Connected" : "Power Disconnected"
        menu.addItem(NSMenuItem(title: powerStatus, action: nil, keyEquivalent: ""))
        
        if let battery = powerInfo?.batteryLevel {
            menu.addItem(NSMenuItem(title: "Battery: \(battery)%", action: nil, keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit MagSafe Guard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func updateStatusIcon() {
        if let button = statusItem?.button {
            let iconName = isArmed ? "lock.shield.fill" : "lock.shield"
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "MagSafe Guard")
            
            // Color the icon based on armed state
            if isArmed {
                button.contentTintColor = .systemRed
            } else {
                button.contentTintColor = nil
            }
        }
    }
    
    private func startPowerMonitoring() {
        powerMonitor.startMonitoring { [weak self] powerInfo in
            guard let self = self else { return }
            
            print("[AppDelegate] Power state: \(powerInfo.state.description)")
            
            // Update menu
            self.setupMenu()
            
            // Check if we should trigger security action
            if self.isArmed && powerInfo.state == .disconnected {
                self.triggerSecurityAction()
            }
        }
    }
    
    @objc private func statusItemClicked() {
        // Menu will show automatically
    }
    
    @objc private func toggleArmed() {
        isArmed.toggle()
        updateStatusIcon()
        setupMenu()
        
        let message = isArmed ? "MagSafe Guard is now ARMED" : "MagSafe Guard is now DISARMED"
        showNotification(title: "MagSafe Guard", message: message)
    }
    
    @objc private func showSettings() {
        // TODO: Implement settings window
        print("Settings clicked")
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
    
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}