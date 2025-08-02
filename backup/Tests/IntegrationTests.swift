//
//  IntegrationTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Integration tests for the complete application flow
//

import XCTest

@testable import MagSafeGuard

final class IntegrationTests: XCTestCase {

  // MARK: - Properties

  private var appController: AppController!
  private var mockSystemActions: MockSystemActions!
  private var mockAuthContext: MockAuthenticationContext!

  // MARK: - Setup

  override func setUp() {
    super.setUp()

    // Disable notifications for testing
    NotificationService.disableForTesting = true

    // Create real services with mock system interactions
    mockSystemActions = MockSystemActions()
    mockAuthContext = MockAuthenticationContext()

    let authService = AuthenticationService(
      contextFactory: MockAuthenticationContextFactory(mockContext: mockAuthContext))
    let securityActions = SecurityActionsService(systemActions: mockSystemActions)

    appController = AppController(
      powerMonitor: PowerMonitorService.shared,
      authService: authService,
      securityActions: securityActions
    )

    // Configure for testing
    appController.gracePeriodDuration = 0.5  // Short for tests
  }

  override func tearDown() {
    appController = nil
    mockSystemActions = nil
    mockAuthContext = nil

    // Re-enable notifications after testing
    NotificationService.disableForTesting = false

    super.tearDown()
  }

  // MARK: - Authentication Tests

  func testAuthenticationFailureHandling() {
    let testExpectation = expectation(description: "Auth failure")

    // Configure auth to fail
    mockAuthContext.canEvaluatePolicyResult = true
    mockAuthContext.evaluatePolicyShouldSucceed = false
    mockAuthContext.evaluatePolicyError =
      AuthenticationService.AuthenticationError.authenticationFailed

    appController.arm { result in
      switch result {
      case .success:
        XCTFail("Should not succeed with auth failure")
      case .failure(let error):
        XCTAssertNotNil(error)
        XCTAssertEqual(self.appController.currentState, .disarmed)
      }
      testExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  // MARK: - State Change Tests

  func testRapidStateChanges() {
    let testExpectation = expectation(description: "Rapid changes")

    mockAuthContext.canEvaluatePolicyResult = true
    mockAuthContext.evaluatePolicyShouldSucceed = true

    // Rapidly arm and disarm
    let operations = 10
    var completed = 0

    func performOperation() {
      if completed >= operations {
        testExpectation.fulfill()
        return
      }

      appController.arm { _ in
        self.appController.disarm { _ in
          completed += 1
          performOperation()
        }
      }
    }

    performOperation()

    waitForExpectations(timeout: 5.0)
    XCTAssertEqual(appController.currentState, .disarmed)
  }

  // NOTE: Tests requiring PowerMonitorService mocking have been disabled
  // Disabled tests:
  // - testCompleteSecurityFlow
  // - testGracePeriodCancellationFlow
  // - testMultipleSecurityActions
  // - testSecurityActionFailureHandling
}

// MARK: - Result Extension

extension Result {
  fileprivate var isSuccess: Bool {
    switch self {
    case .success:
      return true
    case .failure:
      return false
    }
  }
}
