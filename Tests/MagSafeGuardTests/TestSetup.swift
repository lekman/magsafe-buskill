//
//  TestSetup.swift
//  MagSafe Guard Tests
//
//  Created on 2025-07-28.
//
//  Global test setup for disabling features that cause test crashes
//

import XCTest
@testable import MagSafeGuard

class TestSetup: NSObject {
    
    static let shared = TestSetup()
    
    override init() {
        super.init()
        setupTestEnvironment()
    }
    
    private func setupTestEnvironment() {
        // Disable iCloud sync for all tests
        SyncService.disableForTesting = true
        
        // Disable notifications for testing
        NotificationService.disableForTesting = true
        
        // Disable auto-arm for testing
        AppController.isTestEnvironment = true
    }
}

// Ensure test setup runs before any tests
private let _testSetup: TestSetup = {
    return TestSetup.shared
}()