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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon as this is a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "MagSafe Guard")
            button.action = #selector(togglePopover)
        }
    }
    
    @objc func togglePopover() {
        // TODO: Implement popover toggle
        print("MagSafe Guard clicked")
    }
}