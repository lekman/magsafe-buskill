//
//  CircuitBreakerTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//
//  Tests for CircuitBreaker actor implementation.
//

@testable import MagSafeGuard
import MagSafeGuardDomain
import XCTest

final class CircuitBreakerTests: XCTestCase {

    var sut: CircuitBreaker!

    override func setUp() {
        super.setUp()
        sut = CircuitBreaker(
            failureThreshold: 2,
            successThreshold: 2,
            timeout: 0.2 // Short timeout for testing
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - State Transition Tests

    func testInitialStateClosed() async {
        // When
        let state = await sut.getState("test")
        let canExecute = await sut.canExecute("test")

        // Then
        XCTAssertEqual(state, .closed, "Initial state should be closed")
        XCTAssertTrue(canExecute, "Should allow execution in closed state")
    }

    func testTransitionToOpenOnFailures() async {
        // When - record failures up to threshold
        await sut.recordFailure("test")
        let stateAfterFirst = await sut.getState("test")

        await sut.recordFailure("test")
        let stateAfterSecond = await sut.getState("test")
        let canExecute = await sut.canExecute("test")

        // Then
        XCTAssertEqual(stateAfterFirst, .closed, "Should remain closed after first failure")
        XCTAssertEqual(stateAfterSecond, .open, "Should open after reaching threshold")
        XCTAssertFalse(canExecute, "Should deny execution in open state")
    }

    func testTransitionToHalfOpenAfterTimeout() async {
        // Given - open the circuit
        await sut.recordFailure("test")
        await sut.recordFailure("test")

        // When - wait for timeout
        try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
        let state = await sut.getState("test")
        let canExecute = await sut.canExecute("test")

        // Then
        XCTAssertEqual(state, .halfOpen, "Should transition to half-open after timeout")
        XCTAssertTrue(canExecute, "Should allow execution in half-open state")
    }

    func testTransitionFromHalfOpenToClosed() async {
        // Given - circuit in half-open state
        await sut.recordFailure("test")
        await sut.recordFailure("test")
        try? await Task.sleep(nanoseconds: 250_000_000)

        // When - record successes
        await sut.recordSuccess("test")
        await sut.recordSuccess("test")
        let state = await sut.getState("test")

        // Then
        XCTAssertEqual(state, .closed, "Should close after success threshold in half-open")
    }

    func testTransitionFromHalfOpenToOpen() async {
        // Given - circuit in half-open state
        await sut.recordFailure("test")
        await sut.recordFailure("test")
        try? await Task.sleep(nanoseconds: 250_000_000)

        // When - record failure in half-open
        await sut.recordFailure("test")
        let state = await sut.getState("test")

        // Then
        XCTAssertEqual(state, .open, "Should reopen on failure in half-open state")
    }

    // MARK: - Success Recording Tests

    func testSuccessInClosedState() async {
        // Given - some failures but not at threshold
        await sut.recordFailure("test")

        // When
        await sut.recordSuccess("test")
        await sut.recordFailure("test")
        let state = await sut.getState("test")

        // Then
        XCTAssertEqual(state, .closed, "Success should reset failure count in closed state")
    }

    func testSuccessInOpenState() async {
        // Given - open circuit
        await sut.recordFailure("test")
        await sut.recordFailure("test")

        // When
        await sut.recordSuccess("test")
        let state = await sut.getState("test")

        // Then
        XCTAssertEqual(state, .open, "Success in open state should not change state")
    }

    // MARK: - Reset Tests

    func testReset() async {
        // Given - open circuit
        await sut.recordFailure("test")
        await sut.recordFailure("test")

        // When
        await sut.reset(action: "test")
        let state = await sut.getState("test")
        let canExecute = await sut.canExecute("test")

        // Then
        XCTAssertEqual(state, .closed, "Reset should return to closed state")
        XCTAssertTrue(canExecute, "Should allow execution after reset")
    }

    // MARK: - Configuration Tests

    func testCustomConfiguration() async {
        // When
        await sut.configure(
            action: "custom",
            failureThreshold: 1,
            successThreshold: 1,
            timeout: 0.1
        )

        // Then - should open after 1 failure
        await sut.recordFailure("custom")
        let state = await sut.getState("custom")

        XCTAssertEqual(state, .open, "Should open after configured threshold")
    }

    func testIndependentCircuits() async {
        // When
        await sut.recordFailure("action1")
        await sut.recordFailure("action1")

        let state1 = await sut.getState("action1")
        let state2 = await sut.getState("action2")

        // Then
        XCTAssertEqual(state1, .open, "action1 should be open")
        XCTAssertEqual(state2, .closed, "action2 should remain closed")
    }

    // MARK: - Circuit Breaker Config Tests

    func testDefaultConfig() {
        // Given
        let config = CircuitBreakerConfig.defaultConfig

        // Then
        XCTAssertEqual(config.lockScreen.failures, 3)
        XCTAssertEqual(config.lockScreen.successes, 2)
        XCTAssertEqual(config.lockScreen.timeout, 30.0)
        XCTAssertEqual(config.shutdown.failures, 2)
        XCTAssertEqual(config.shutdown.timeout, 120.0)
    }

    func testResilientConfig() {
        // Given
        let config = CircuitBreakerConfig.resilient

        // Then
        XCTAssertEqual(config.lockScreen.failures, 5)
        XCTAssertEqual(config.lockScreen.successes, 3)
        XCTAssertEqual(config.lockScreen.timeout, 20.0)
    }

    // MARK: - Concurrency Tests

    func testConcurrentStateChanges() async {
        // Given
        let iterations = 10
        let expectation = XCTestExpectation(description: "Concurrent state changes")
        expectation.expectedFulfillmentCount = iterations

        // When - concurrent failures
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<iterations {
                group.addTask {
                    if index % 2 == 0 {
                        await self.sut.recordFailure("concurrent")
                    } else {
                        await self.sut.recordSuccess("concurrent")
                    }
                    expectation.fulfill()
                }
            }
        }

        // Then - state should be consistent
        let finalState = await sut.getState("concurrent")
        XCTAssertNotNil(finalState, "State should be valid after concurrent access")

        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
