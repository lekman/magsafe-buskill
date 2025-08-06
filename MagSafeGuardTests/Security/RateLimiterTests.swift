//
//  RateLimiterTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//
//  Tests for RateLimiter actor implementation.
//

@testable import MagSafeGuard
import MagSafeGuardDomain
import XCTest

final class RateLimiterTests: XCTestCase {

    var sut: RateLimiter!

    override func setUp() {
        super.setUp()
        sut = RateLimiter(defaultCapacity: 3, defaultRefillRate: 0.1) // Fast refill for testing
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testInitialTokensAvailable() async {
        // When
        let result = await sut.allowAction("test")

        // Then
        XCTAssertTrue(result, "Should allow first action")
    }

    func testTokenConsumption() async {
        // When - consume all tokens
        let result1 = await sut.allowAction("test")
        let result2 = await sut.allowAction("test")
        let result3 = await sut.allowAction("test")
        let result4 = await sut.allowAction("test")

        // Then
        XCTAssertTrue(result1, "Should allow first action")
        XCTAssertTrue(result2, "Should allow second action")
        XCTAssertTrue(result3, "Should allow third action")
        XCTAssertFalse(result4, "Should deny fourth action (tokens exhausted)")
    }

    func testTokenRefill() async {
        // Given - consume all tokens
        for _ in 0..<3 {
            _ = await sut.allowAction("test")
        }

        // When - wait for refill
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        let result = await sut.allowAction("test")

        // Then
        XCTAssertTrue(result, "Should allow action after refill")
    }

    func testResetAction() async {
        // Given - consume all tokens
        for _ in 0..<3 {
            _ = await sut.allowAction("test")
        }

        // When
        await sut.reset(action: "test")
        let result = await sut.allowAction("test")

        // Then
        XCTAssertTrue(result, "Should allow action after reset")
    }

    func testResetAll() async {
        // Given - consume tokens for multiple actions
        for _ in 0..<3 {
            _ = await sut.allowAction("action1")
            _ = await sut.allowAction("action2")
        }

        // When
        await sut.resetAll()
        let result1 = await sut.allowAction("action1")
        let result2 = await sut.allowAction("action2")

        // Then
        XCTAssertTrue(result1, "Should allow action1 after reset")
        XCTAssertTrue(result2, "Should allow action2 after reset")
    }

    // MARK: - Configuration Tests

    func testCustomConfiguration() async {
        // When
        await sut.configure(action: "custom", capacity: 5, refillRate: 0.05)

        // Then - should be able to consume 5 tokens
        var successCount = 0
        for _ in 0..<6 {
            let allowed = await sut.allowAction("custom")
            successCount += allowed ? 1 : 0
        }

        XCTAssertEqual(successCount, 5, "Should allow exactly 5 actions")
    }

    func testIndependentBuckets() async {
        // When - consume tokens for different actions
        let action1Result1 = await sut.allowAction("action1")
        let action2Result1 = await sut.allowAction("action2")

        // Exhaust action1
        for _ in 0..<3 {
            _ = await sut.allowAction("action1")
        }

        let action1Result2 = await sut.allowAction("action1")
        let action2Result2 = await sut.allowAction("action2")

        // Then
        XCTAssertTrue(action1Result1, "Should allow action1 initially")
        XCTAssertTrue(action2Result1, "Should allow action2 initially")
        XCTAssertFalse(action1Result2, "Should deny action1 when exhausted")
        XCTAssertTrue(action2Result2, "Should still allow action2")
    }

    // MARK: - Rate Limiter Config Tests

    func testDefaultConfig() {
        // Given
        let config = RateLimiterConfig.defaultConfig

        // Then
        XCTAssertEqual(config.lockScreen.capacity, 5)
        XCTAssertEqual(config.lockScreen.refillRate, 2.0)
        XCTAssertEqual(config.playAlarm.capacity, 3)
        XCTAssertEqual(config.playAlarm.refillRate, 5.0)
        XCTAssertEqual(config.forceLogout.capacity, 2)
        XCTAssertEqual(config.forceLogout.refillRate, 30.0)
        XCTAssertEqual(config.shutdown.capacity, 1)
        XCTAssertEqual(config.shutdown.refillRate, 60.0)
        XCTAssertEqual(config.executeScript.capacity, 3)
        XCTAssertEqual(config.executeScript.refillRate, 10.0)
    }

    func testStrictConfig() {
        // Given
        let config = RateLimiterConfig.strict

        // Then
        XCTAssertEqual(config.lockScreen.capacity, 3)
        XCTAssertEqual(config.lockScreen.refillRate, 5.0)
        XCTAssertEqual(config.shutdown.capacity, 1)
        XCTAssertEqual(config.shutdown.refillRate, 300.0)
    }

    // MARK: - Concurrency Tests

    func testConcurrentAccess() async {
        // Given
        let iterations = 10
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = iterations

        // When - multiple concurrent accesses
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    let result = await self.sut.allowAction("concurrent")
                    expectation.fulfill()
                    return result
                }
            }

            // Then - should handle concurrent access safely
            var successCount = 0
            for await result in group {
                successCount += result ? 1 : 0
            }

            XCTAssertLessThanOrEqual(successCount, 3, "Should not exceed capacity")
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
