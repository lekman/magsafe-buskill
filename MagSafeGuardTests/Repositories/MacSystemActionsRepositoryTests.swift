//
//  MacSystemActionsRepositoryTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//
//  Tests for MacSystemActionsRepository with resource protection.
//

@testable import MagSafeGuard
import MagSafeGuardDomain
import XCTest

final class MacSystemActionsRepositoryTests: XCTestCase {

    var sut: MacSystemActionsRepository!
    var mockSystemActions: MockSystemActions!

    override func setUp() {
        super.setUp()
        mockSystemActions = MockSystemActions()

        // Create test-friendly resource protection config
        let rateLimiterConfig = RateLimiterConfig(
            lockScreen: (capacity: 2, refillRate: 0.1),
            playAlarm: (capacity: 2, refillRate: 0.1),
            forceLogout: (capacity: 1, refillRate: 0.1),
            shutdown: (capacity: 1, refillRate: 0.1),
            executeScript: (capacity: 2, refillRate: 0.1)
        )

        let circuitBreakerConfig = CircuitBreakerConfig(
            lockScreen: (failures: 2, successes: 1, timeout: 0.2),
            playAlarm: (failures: 2, successes: 1, timeout: 0.2),
            forceLogout: (failures: 1, successes: 1, timeout: 0.2),
            shutdown: (failures: 1, successes: 1, timeout: 0.2),
            executeScript: (failures: 2, successes: 1, timeout: 0.2)
        )

        let protectorConfig = ResourceProtectorConfig(
            rateLimiter: rateLimiterConfig,
            circuitBreaker: circuitBreakerConfig,
            enableMetrics: true,
            enableLogging: true
        )

        sut = MacSystemActionsRepository(
            systemActions: mockSystemActions,
            resourceProtectorConfig: protectorConfig
        )
    }

    override func tearDown() {
        sut = nil
        mockSystemActions = nil
        super.tearDown()
    }

    // MARK: - Lock Screen Tests

    func testLockScreenSuccess() async throws {
        // Given
        mockSystemActions.lockScreenShouldSucceed = true

        // When
        try await sut.lockScreen()

        // Then
        XCTAssertTrue(mockSystemActions.lockScreenCalled)
    }

    func testLockScreenRateLimited() async throws {
        // Given
        mockSystemActions.lockScreenShouldSucceed = true

        // When - exhaust rate limit
        try await sut.lockScreen()
        try await sut.lockScreen()

        // Then - third attempt should fail
        do {
            try await sut.lockScreen()
            XCTFail("Should be rate limited")
        } catch let error as SecurityActionError {
            if case .actionFailed(let type, let reason) = error {
                XCTAssertEqual(type, .customScript)
                XCTAssertTrue(reason.contains("Rate limited"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testLockScreenCircuitBreaker() async throws {
        // Given
        mockSystemActions.lockScreenShouldSucceed = false

        // When - trigger circuit breaker
        _ = try? await sut.lockScreen()
        _ = try? await sut.lockScreen()

        // Reset mock to succeed
        mockSystemActions.lockScreenShouldSucceed = true

        // Then - circuit should be open
        do {
            try await sut.lockScreen()
            XCTFail("Circuit should be open")
        } catch let error as SecurityActionError {
            if case .actionFailed(_, let reason) = error {
                XCTAssertTrue(reason.contains("Circuit"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Play Alarm Tests

    func testPlayAlarmSuccess() async throws {
        // Given
        mockSystemActions.playAlarmShouldSucceed = true
        let volume: Float = 0.8

        // When
        try await sut.playAlarm(volume: volume)

        // Then
        XCTAssertTrue(mockSystemActions.playAlarmCalled)
        XCTAssertEqual(mockSystemActions.lastAlarmVolume, volume)
    }

    func testStopAlarm() async {
        // When
        await sut.stopAlarm()

        // Then
        XCTAssertTrue(mockSystemActions.stopAlarmCalled)
    }

    // MARK: - Force Logout Tests

    func testForceLogoutRateLimited() async throws {
        // Given
        mockSystemActions.forceLogoutShouldSucceed = true

        // When - exhaust single-use rate limit
        try await sut.forceLogout()

        // Then - second attempt should fail
        do {
            try await sut.forceLogout()
            XCTFail("Should be rate limited")
        } catch let error as SecurityActionError {
            if case .actionFailed(_, let reason) = error {
                XCTAssertTrue(reason.contains("Rate limited"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Shutdown Tests

    func testScheduleShutdownSuccess() async throws {
        // Given
        mockSystemActions.scheduleShutdownShouldSucceed = true
        let delay: TimeInterval = 60

        // When
        try await sut.scheduleShutdown(afterSeconds: delay)

        // Then
        XCTAssertTrue(mockSystemActions.scheduleShutdownCalled)
        XCTAssertEqual(mockSystemActions.lastShutdownDelay, delay)
    }

    func testShutdownStrictRateLimit() async throws {
        // Given
        mockSystemActions.scheduleShutdownShouldSucceed = true

        // When
        try await sut.scheduleShutdown(afterSeconds: 60)

        // Then - immediate retry should fail
        do {
            try await sut.scheduleShutdown(afterSeconds: 60)
            XCTFail("Should be rate limited")
        } catch let error as SecurityActionError {
            if case .actionFailed(_, let reason) = error {
                XCTAssertTrue(reason.contains("Rate limited"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Execute Script Tests

    func testExecuteScriptValidation() async {
        // Test invalid paths
        let invalidPaths = [
            "relative/path.sh",           // Not absolute
            "/path/../dangerous.sh",       // Contains ../
            "/path/with$(command).sh",     // Contains command substitution
            "/path/with`command`.sh",      // Contains backticks
            "/path/with${var}.sh",         // Contains variable expansion
            "~/user/script.sh"             // Contains ~
        ]

        for path in invalidPaths {
            do {
                try await sut.executeScript(at: path)
                XCTFail("Should reject invalid path: \(path)")
            } catch let error as SecurityActionError {
                if case .actionFailed(let type, let reason) = error {
                    XCTAssertEqual(type, .customScript)
                    XCTAssertTrue(reason.contains("Invalid script path"))
                } else {
                    XCTFail("Wrong error for path \(path): \(error)")
                }
            } catch {
                XCTFail("Unexpected error for path \(path): \(error)")
            }
        }
    }

    func testExecuteScriptWithValidPath() async throws {
        // Given - create a temporary test script
        let tempDir = FileManager.default.temporaryDirectory
        let scriptPath = tempDir.appendingPathComponent("test_script.sh").path
        try "#!/bin/bash\necho 'test'".write(toFile: scriptPath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: scriptPath) }

        mockSystemActions.executeScriptShouldSucceed = true

        // When
        try await sut.executeScript(at: scriptPath)

        // Then
        XCTAssertTrue(mockSystemActions.executeScriptCalled)
        XCTAssertEqual(mockSystemActions.lastScriptPath, scriptPath)
    }

    // MARK: - Metrics Tests

    func testGetMetrics() async throws {
        // Given
        mockSystemActions.lockScreenShouldSucceed = true
        try await sut.lockScreen()

        // When
        let metrics = await sut.getMetrics(for: .lockScreen)

        // Then
        XCTAssertNotNil(metrics["totalAttempts"])
        XCTAssertNotNil(metrics["successfulExecutions"])
        XCTAssertEqual(metrics["totalAttempts"] as? Int, 1)
        XCTAssertEqual(metrics["successfulExecutions"] as? Int, 1)
    }

    func testResetProtection() async throws {
        // Given - exhaust rate limit
        mockSystemActions.forceLogoutShouldSucceed = true
        try await sut.forceLogout()

        // When
        await sut.resetProtection(for: .forceLogout)

        // Then - should work again
        try await sut.forceLogout()
        XCTAssertEqual(mockSystemActions.forceLogoutCallCount, 2)
    }

    // MARK: - Error Mapping Tests

    func testSystemErrorMapping() async {
        // Test each system error type
        mockSystemActions.lockScreenError = SystemActionError.permissionDenied

        do {
            try await sut.lockScreen()
            XCTFail("Should throw error")
        } catch let error as SecurityActionError {
            if case .permissionDenied(let action) = error {
                XCTAssertEqual(action, .lockScreen)
            } else {
                XCTFail("Wrong error mapping: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Concurrency Tests

    func testConcurrentAccess() async throws {
        // Given
        mockSystemActions.lockScreenShouldSucceed = true
        let iterations = 5

        // When - concurrent access
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    do {
                        try await self.sut.lockScreen()
                        return true
                    } catch {
                        return false
                    }
                }
            }

            // Then - rate limiting should apply
            var successCount = 0
            for await success in group {
                successCount += success ? 1 : 0
            }

            // Should only allow 2 due to rate limit
            XCTAssertEqual(successCount, 2)
        }
    }
}
