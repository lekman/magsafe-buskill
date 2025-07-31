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

    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}
