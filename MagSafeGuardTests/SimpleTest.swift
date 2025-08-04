//
//  SimpleTest.swift
//  MagSafe Guard Tests
//
//  Created on 2025-08-03.
//

import Testing
import Foundation
@testable import MagSafeGuardDomain
@testable import MagSafeGuardCore

/// Minimal test to verify SPM test execution works
@Suite("Simple Tests")
struct SimpleTest {
    
    @Test("Basic SecurityActionType test")
    func testSecurityActionType() async throws {
        let action: SecurityActionType = .lockScreen
        #expect(action.displayName == "Lock Screen")
        #expect(action.symbolName == "lock.fill")
    }
    
    @Test("Settings model basic functionality")
    func testSettingsBasics() async throws {
        let settings = Settings()
        #expect(settings.gracePeriodDuration == 10.0)
        #expect(settings.securityActions.contains(.lockScreen))
    }
}