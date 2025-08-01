//
//  MagSafeGuardApp.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//

import AppKit
import SwiftUI
import UserNotifications

@main
struct MagSafeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Skip normal app initialization in test environment
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // We're running tests, minimize initialization
            NSApplication.shared.setActivationPolicy(.prohibited)
        }
    }

    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}
