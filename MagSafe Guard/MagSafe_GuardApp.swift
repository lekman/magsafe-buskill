//
//  MagSafe_GuardApp.swift
//  MagSafe Guard
//
//  Created by Tobias Lekman on 31/07/2025.
//

import AppKit
import SwiftUI
import UserNotifications

@main
struct MagSafe_GuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Configure crash reporting early
        configureCrashReporting()
        
        // Set a bundle identifier for development if needed
        if Bundle.main.bundleIdentifier == nil {
            Log.info("Running in development mode without bundle identifier")
        }
    }
    
    private func configureCrashReporting() {
        #if DEBUG
        // Configure debug crash handlers
        NSSetUncaughtExceptionHandler { exception in
            Log.critical("Uncaught exception: \(exception)")
            Log.critical("Reason: \(exception.reason ?? "Unknown")")
            Log.critical("Stack trace: \(exception.callStackSymbols)")
            
            // Save crash info for debugging
            let crashInfo = [
                "exception": exception.name.rawValue,
                "reason": exception.reason ?? "Unknown",
                "stackTrace": exception.callStackSymbols,
                "timestamp": Date().formatted(.iso8601)
            ]
            UserDefaults.standard.set(crashInfo, forKey: "lastCrashInfo")
        }
        #endif
    }

    var body: some Scene {
        // Menu bar apps don't use WindowGroup
        Settings {
            EmptyView()
        }
    }
}