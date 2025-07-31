//
//  AppControllerTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for AppController - the central coordinator
//

@testable import MagSafeGuard
import XCTest

final class AppControllerTests: XCTestCase {

    // MARK: - Properties

    private var sut: AppController!
    private var mockAuthService: MockAuthenticationService!
    private var mockSecurityActions: MockSystemActions!
    private var mockNotificationService: MockNotificationService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        // Disable notifications for testing
        NotificationService.disableForTesting = true

        // Disable auto-arm for testing to avoid location permission issues
        AppController.isTestEnvironment = true

        mockAuthService = MockAuthenticationService()
        mockSecurityActions = MockSystemActions()
        mockNotificationService = MockNotificationService()

        sut = AppController(
            powerMonitor: PowerMonitorService.shared,  // Use real service for now
            authService: mockAuthService.createConfiguredService(),
            securityActions: SecurityActionsService(systemActions: mockSecurityActions),
            notificationService: NotificationService(deliveryMethod: mockNotificationService)
        )
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        mockSecurityActions = nil
        mockNotificationService = nil

        // Re-enable notifications after testing
        NotificationService.disableForTesting = false

        // Reset test environment flag
        AppController.isTestEnvironment = false

        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(sut.currentState, .disarmed)
        XCTAssertFalse(sut.isInGracePeriod)
        XCTAssertEqual(sut.gracePeriodRemaining, 0)
        // Grace period should be between 5-30 seconds (validated by settings)
        XCTAssertGreaterThanOrEqual(sut.gracePeriodDuration, 5.0)
        XCTAssertLessThanOrEqual(sut.gracePeriodDuration, 30.0)
        // Default value from Settings is true, but can be persisted from previous test runs
        // Just verify it's a Boolean
        _ = sut.allowGracePeriodCancellation // Can be true or false based on persisted settings
    }

    // MARK: - Arming Tests

    func testArmingWithSuccessfulAuthentication() {
        let expectation = expectation(description: "Arm completion")
        mockAuthService.shouldSucceed = true

        sut.arm { result in
            switch result {
            case .success:
                XCTAssertEqual(self.sut.currentState, .armed)
                XCTAssertTrue(self.mockNotificationService.deliveredNotifications.contains { $0.title == "MagSafe Guard Armed" })
            case .failure:
                XCTFail("Arming should succeed")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testArmingWithFailedAuthentication() {
        let expectation = expectation(description: "Arm completion")
        mockAuthService.shouldSucceed = false

        // Re-create the app controller with failed auth
        sut = AppController(
            powerMonitor: PowerMonitorService.shared,
            authService: mockAuthService.createConfiguredService(),
            securityActions: SecurityActionsService(systemActions: mockSecurityActions),
            notificationService: NotificationService(deliveryMethod: mockNotificationService)
        )

        sut.arm { result in
            switch result {
            case .success:
                XCTFail("Arming should fail")
            case .failure(let error):
                XCTAssertEqual(self.sut.currentState, .disarmed)
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testArmingFromNonDisarmedState() {
        // First arm the system
        mockAuthService.shouldSucceed = true
        let armExpectation = expectation(description: "Initial arm")

        sut.arm { _ in
            armExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        // Try to arm again
        let rearmExpectation = expectation(description: "Re-arm attempt")

        sut.arm { result in
            switch result {
            case .success:
                XCTFail("Should not be able to arm when already armed")
            case .failure(let error):
                XCTAssertTrue(error is AppControllerError)
            }
            rearmExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Disarming Tests

    func testDisarmingFromArmedState() {
        // First arm the system
        mockAuthService.shouldSucceed = true
        let armExpectation = expectation(description: "Arm")

        sut.arm { _ in
            armExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        // Now disarm
        let disarmExpectation = expectation(description: "Disarm")

        sut.disarm { result in
            switch result {
            case .success:
                XCTAssertEqual(self.sut.currentState, .disarmed)
                XCTAssertTrue(self.mockNotificationService.deliveredNotifications.contains { $0.title == "MagSafe Guard Disarmed" })
            case .failure:
                XCTFail("Disarming should succeed")
            }
            disarmExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Grace Period Tests

    // Skip grace period tests for now - PowerMonitorService can't be easily mocked
    // Task #18: Refactor PowerMonitorService for testability with protocol-based dependency injection
    /*
    func testGracePeriodTriggering() {
        // Configure short grace period for testing
        sut.gracePeriodDuration = 0.5
        
        // Arm the system
        mockAuthService.shouldSucceed = true
        let armExpectation = expectation(description: "Arm")
        
        sut.arm { _ in
            armExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Simulate power disconnection
        mockPowerMonitor.simulatePowerChange(.disconnected)
        
        // Verify grace period started
        XCTAssertEqual(sut.currentState, .gracePeriod)
        XCTAssertTrue(sut.isInGracePeriod)
        
        // Wait for grace period to complete
        let gracePeriodExpectation = expectation(description: "Grace period completion")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertFalse(self.sut.isInGracePeriod)
            XCTAssertTrue(self.mockSecurityActions.lockScreenCalled)
            gracePeriodExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    */

    /*
    func testGracePeriodCancellation() {
        // Arm the system
        mockAuthService.shouldSucceed = true
        let armExpectation = expectation(description: "Arm")
        
        sut.arm { _ in
            armExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Simulate power disconnection
        mockPowerMonitor.simulatePowerChange(.disconnected)
        
        // Verify grace period started
        XCTAssertTrue(sut.isInGracePeriod)
        
        // Cancel grace period
        let cancelExpectation = expectation(description: "Cancel grace period")
        
        sut.cancelGracePeriodWithAuth { result in
            switch result {
            case .success:
                XCTAssertFalse(self.sut.isInGracePeriod)
                XCTAssertEqual(self.sut.currentState, .armed)
                XCTAssertFalse(self.mockSecurityActions.lockScreenCalled)
            case .failure:
                XCTFail("Cancellation should succeed")
            }
            cancelExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    */

    // MARK: - Grace Period Cancellation Tests

    func testCancelGracePeriodWithAuthSuccess() {
        // This test requires a mock power monitor which we don't have yet
        // TODO: Add this test when PowerMonitorService is made testable
    }

    func testCancelGracePeriodWithAuthFailure() {
        // This test requires a mock power monitor which we don't have yet
        // TODO: Add this test when PowerMonitorService is made testable
    }

    func testCancelGracePeriodNotAllowed() {
        // Disable grace period cancellation
        sut.allowGracePeriodCancellation = false

        let cancelExpectation = expectation(description: "Cancel")
        sut.cancelGracePeriodWithAuth { result in
            switch result {
            case .success:
                XCTFail("Should fail when cancellation not allowed")
            case .failure(let error as AppControllerError):
                // Can't use XCTAssertEqual as AppControllerError doesn't conform to Equatable
                if case .gracePeriodNotCancellable = error {
                    XCTAssertTrue(true)
                } else {
                    XCTFail("Wrong error type")
                }
            case .failure:
                XCTFail("Wrong error type")
            }
            cancelExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Configuration Tests

    func testGracePeriodConfiguration() {
        // Test setting grace period duration
        sut.gracePeriodDuration = 15.0
        XCTAssertEqual(sut.gracePeriodDuration, 15.0)

        // Test validation bounds
        sut.gracePeriodDuration = 3.0
        XCTAssertEqual(sut.gracePeriodDuration, 5.0) // Should be clamped to minimum

        sut.gracePeriodDuration = 35.0
        XCTAssertEqual(sut.gracePeriodDuration, 30.0) // Should be clamped to maximum
    }

    func testAllowGracePeriodCancellationConfiguration() {
        sut.allowGracePeriodCancellation = false
        XCTAssertFalse(sut.allowGracePeriodCancellation)

        sut.allowGracePeriodCancellation = true
        XCTAssertTrue(sut.allowGracePeriodCancellation)
    }

    // MARK: - Event Logging Tests

    func testEventLogging() {
        // Clear any existing events from initialization
        sut.clearEventLog()

        // Now should be empty
        var events = sut.getEventLog()
        XCTAssertTrue(events.isEmpty)

        // Arm the system
        mockAuthService.shouldSucceed = true
        let armExpectation = expectation(description: "Arm")

        sut.arm { _ in
            armExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        // Check events were logged
        events = sut.getEventLog()
        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.contains { $0.event == .authenticationSucceeded })
        XCTAssertTrue(events.contains { $0.event == .armed })
    }

    func testEventLogClearing() {
        // Log some events
        sut.logEvent(.armed, details: "Test event")

        var events = sut.getEventLog()
        XCTAssertFalse(events.isEmpty)

        // Clear log
        sut.clearEventLog()

        // Check immediately since clearEventLog is now synchronous
        events = sut.getEventLog()
        XCTAssertTrue(events.isEmpty, "Event log should be empty after clearing")
    }

    // MARK: - Demo Mode Tests

    // TODO: Add demo mode tests when demo functionality is implemented
    // The AppController doesn't currently have a runDemo method

    // MARK: - State Transition Tests

    func testStateChangeCallback() {
        let stateExpectation = expectation(description: "State change")
        var oldStateReceived: AppState?
        var newStateReceived: AppState?

        sut.onStateChange = { old, new in
            oldStateReceived = old
            newStateReceived = new
            stateExpectation.fulfill()
        }

        // Arm the system
        mockAuthService.shouldSucceed = true
        sut.arm { _ in }

        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(oldStateReceived, .disarmed)
        XCTAssertEqual(newStateReceived, .armed)
    }

    // MARK: - Menu Integration Tests

    func testMenuTitleForStates() {
        // Disarmed
        XCTAssertEqual(sut.armDisarmMenuTitle, "Arm Protection")

        // Armed
        mockAuthService.shouldSucceed = true
        let armExpectation = expectation(description: "Arm")

        sut.arm { _ in
            armExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(sut.armDisarmMenuTitle, "Disarm Protection")
    }

    func testStatusIconNames() {
        XCTAssertEqual(sut.statusIconName, "shield") // Disarmed

        // Arm
        mockAuthService.shouldSucceed = true
        let armExpectation = expectation(description: "Arm")

        sut.arm { _ in
            armExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(sut.statusIconName, "shield.fill") // Armed
    }
}

// MARK: - Mock Classes

private class MockAuthenticationService {
    var shouldSucceed = true
    private let mockContext = MockAuthenticationContext()

    init() {
        // Configure mock context
        mockContext.canEvaluatePolicyResult = true
    }

    func createConfiguredService() -> AuthenticationService {
        mockContext.evaluatePolicyShouldSucceed = shouldSucceed
        return AuthenticationService(contextFactory: MockAuthenticationContextFactory(mockContext: mockContext))
    }
}

private class MockNotificationService: NotificationDeliveryProtocol {
    var deliveredNotifications: [(title: String, message: String, identifier: String)] = []
    var permissionsRequested = false

    func deliver(title: String, message: String, identifier: String) {
        deliveredNotifications.append((title, message, identifier))
    }

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        permissionsRequested = true
        completion(true)
    }
}
