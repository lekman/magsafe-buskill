//
//  TestSetup.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//
//  Global test setup
//

import Foundation

@testable import MagSafeGuard

/// Global test setup class that runs before all tests
class TestSetup: NSObject {
  override init() {
    super.init()

    // Set test environment flag before any app code runs
    AppController.isTestEnvironment = true

    // Disable features that might trigger permission dialogs
    if ProcessInfo.processInfo.environment["CI"] != nil {
      // In CI, disable location-dependent features
      UserDefaults.standard.set(false, forKey: "FEATURE_LOCATION")
      UserDefaults.standard.set(false, forKey: "FEATURE_AUTO_ARM")
    }
  }
}

// Create a global instance to ensure it runs
private let testSetup = TestSetup()
