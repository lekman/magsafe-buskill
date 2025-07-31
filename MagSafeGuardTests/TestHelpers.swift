//
//  TestHelpers.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//
//  Common test utilities and helpers
//

import Foundation
import XCTest

/// Utilities for test environment detection
enum TestEnvironment {
    /// Check if running in CI environment
    static var isCI: Bool {
        // Check common CI environment variables
        return ProcessInfo.processInfo.environment["CI"] != nil ||
               ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] != nil ||
               ProcessInfo.processInfo.environment["BITRISE_IO"] != nil ||
               ProcessInfo.processInfo.environment["JENKINS_URL"] != nil ||
               ProcessInfo.processInfo.environment["TRAVIS"] != nil ||
               ProcessInfo.processInfo.environment["CIRCLECI"] != nil
    }

    /// Check if running on macOS (not iOS simulator)
    static var isMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

/// Skip test in CI environments
func skipIfCI(_ testCase: XCTestCase, file: StaticString = #filePath, line: UInt = #line) throws {
    if TestEnvironment.isCI {
        throw XCTSkip("Skipping test in CI environment", file: file, line: line)
    }
}

/// Skip tests that require user interaction
func skipIfNoUserInteraction(_ testCase: XCTestCase, file: StaticString = #filePath, line: UInt = #line) throws {
    if TestEnvironment.isCI {
        throw XCTSkip("Skipping test that requires user interaction in CI", file: file, line: line)
    }
}

/// Skip tests that require location permissions
func skipIfLocationPermissionRequired(_ testCase: XCTestCase, file: StaticString = #filePath, line: UInt = #line) throws {
    if TestEnvironment.isCI {
        throw XCTSkip("Skipping location permission test in CI", file: file, line: line)
    }
}
