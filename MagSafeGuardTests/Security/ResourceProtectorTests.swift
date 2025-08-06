//
//  ResourceProtectorTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//
//  Tests for ResourceProtector coordinator.
//

@testable import MagSafeGuard
import MagSafeGuardDomain
import XCTest

final class ResourceProtectorTests: XCTestCase {

    var sut: ResourceProtector!

    override func setUp() {
        super.setUp()
        // Create with test-friendly configuration
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

        sut = ResourceProtector(
            rateLimiterConfig: rateLimiterConfig,
            circuitBreakerConfig: circuitBreakerConfig
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Protection Tests

    func testCheckActionAllowed() async throws {
        // When
        let result = try await sut.checkAction("lockScreen")

        // Then
        XCTAssertTrue(result, "Should allow initial action")
    }

    func testRateLimitingEnforced() async {
        // When - exceed rate limit
        _ = try? await sut.checkAction("forceLogout")

        // Then - second attempt should fail
        do {
            _ = try await sut.checkAction("forceLogout")
            XCTFail("Should throw rate limit error")
        } catch let error as ResourceProtectionError {
            if case .rateLimited = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCircuitBreakerEnforced() async {
        // Given - trigger circuit breaker
        await sut.recordFailure("shutdown")

        // When
        do {
            _ = try await sut.checkAction("shutdown")
            XCTFail("Should throw circuit open error")
        } catch let error as ResourceProtectionError {
            if case .circuitOpen = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Success/Failure Recording Tests

    func testRecordSuccess() async throws {
        // When
        _ = try await sut.checkAction("lockScreen")
        await sut.recordSuccess("lockScreen")

        // Then
        let metrics = await sut.getMetrics(for: "lockScreen")
        XCTAssertEqual(metrics["successfulExecutions"] as? Int, 1)
    }

    func testRecordFailure() async throws {
        // When
        _ = try await sut.checkAction("lockScreen")
        await sut.recordFailure("lockScreen")

        // Then - should still allow one more attempt before circuit opens
        let result = try await sut.checkAction("lockScreen")
        XCTAssertTrue(result)
    }

    // MARK: - Protected Execution Tests

    func testExecuteProtectedSuccess() async throws {
        // Given
        var executed = false

        // When
        let result = try await sut.executeProtected("lockScreen") {
            executed = true
            return "success"
        }

        // Then
        XCTAssertEqual(result, "success")
        XCTAssertTrue(executed)

        let metrics = await sut.getMetrics(for: "lockScreen")
        XCTAssertEqual(metrics["successfulExecutions"] as? Int, 1)
    }

    func testExecuteProtectedFailure() async {
        // Given
        enum TestError: Error {
            case intentional
        }

        // When
        do {
            _ = try await sut.executeProtected("lockScreen") {
                throw TestError.intentional
            }
            XCTFail("Should propagate error")
        } catch {
            // Then - failure should be recorded
            let metrics = await sut.getMetrics(for: "lockScreen")
            XCTAssertNotNil(metrics["lastFailureTime"])
        }
    }

    func testExecuteProtectedRateLimited() async throws {
        // Given - exhaust rate limit
        _ = try await sut.executeProtected("forceLogout") { "first" }

        // When
        do {
            _ = try await sut.executeProtected("forceLogout") { "second" }
            XCTFail("Should be rate limited")
        } catch let error as ResourceProtectionError {
            if case .rateLimited = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Metrics Tests

    func testMetricsTracking() async throws {
        // When
        _ = try await sut.checkAction("executeScript")
        await sut.recordSuccess("executeScript")
        _ = try await sut.checkAction("executeScript")
        await sut.recordFailure("executeScript")

        // Then
        let metrics = await sut.getMetrics(for: "executeScript")

        XCTAssertEqual(metrics["totalAttempts"] as? Int, 2)
        XCTAssertEqual(metrics["successfulExecutions"] as? Int, 1)
        XCTAssertNotNil(metrics["lastAttemptTime"])
        XCTAssertNotNil(metrics["lastSuccessTime"])
        XCTAssertNotNil(metrics["lastFailureTime"])

        let successRate = metrics["successRate"] as? Double ?? 0
        XCTAssertEqual(successRate, 0.5, accuracy: 0.01)
    }

    func testRateLimitedMetrics() async {
        // Given - exhaust rate limit
        _ = try? await sut.checkAction("shutdown")
        _ = try? await sut.checkAction("shutdown")

        // When
        let metrics = await sut.getMetrics(for: "shutdown")

        // Then
        XCTAssertEqual(metrics["rateLimitedAttempts"] as? Int, 1)
    }

    // MARK: - Reset Tests

    func testResetAction() async throws {
        // Given - exhaust rate limit and trigger circuit
        _ = try? await sut.checkAction("forceLogout")
        await sut.recordFailure("forceLogout")

        // When
        await sut.reset(action: "forceLogout")

        // Then
        let result = try await sut.checkAction("forceLogout")
        XCTAssertTrue(result, "Should allow action after reset")

        let metrics = await sut.getMetrics(for: "forceLogout")
        XCTAssertEqual(metrics["totalAttempts"] as? Int, 0)
    }

    // MARK: - Enable/Disable Tests

    func testDisableProtection() async {
        // When
        await sut.setEnabled(false)

        // Then
        do {
            _ = try await sut.checkAction("lockScreen")
            XCTFail("Should throw protection disabled error")
        } catch let error as ResourceProtectionError {
            if case .protectionDisabled = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReenableProtection() async throws {
        // Given
        await sut.setEnabled(false)

        // When
        await sut.setEnabled(true)

        // Then
        let result = try await sut.checkAction("lockScreen")
        XCTAssertTrue(result, "Should allow action when re-enabled")
    }

    // MARK: - Error Description Tests

    func testErrorDescriptions() {
        // Test each error type
        let rateLimited = ResourceProtectionError.rateLimited(action: "test", retryAfter: 5.0)
        XCTAssertTrue(rateLimited.errorDescription?.contains("rate limited") ?? false)

        let circuitOpen = ResourceProtectionError.circuitOpen(action: "test", state: .open)
        XCTAssertTrue(circuitOpen.errorDescription?.contains("Circuit breaker") ?? false)

        let exhausted = ResourceProtectionError.resourceExhausted(action: "test")
        XCTAssertTrue(exhausted.errorDescription?.contains("exhausted") ?? false)

        let disabled = ResourceProtectionError.protectionDisabled
        XCTAssertTrue(disabled.errorDescription?.contains("disabled") ?? false)
    }

    // MARK: - Integration Tests

    func testCombinedProtection() async throws {
        // Test that both rate limiting and circuit breaking work together

        // First: Use up rate limit
        _ = try await sut.checkAction("executeScript")
        _ = try await sut.checkAction("executeScript")

        // Should be rate limited now
        do {
            _ = try await sut.checkAction("executeScript")
            XCTFail("Should be rate limited")
        } catch let error as ResourceProtectionError {
            if case .rateLimited = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        }

        // Wait for rate limit refresh
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Now trigger circuit breaker
        _ = try await sut.checkAction("executeScript")
        await sut.recordFailure("executeScript")
        await sut.recordFailure("executeScript")

        // Should be circuit open now
        do {
            _ = try await sut.checkAction("executeScript")
            XCTFail("Should have open circuit")
        } catch let error as ResourceProtectionError {
            if case .circuitOpen = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
