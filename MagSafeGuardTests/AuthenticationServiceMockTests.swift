//
//  AuthenticationServiceMockTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  Tests for AuthenticationService using mock context to achieve 100% coverage
//

import LocalAuthentication
import XCTest

@testable import MagSafeGuard

final class AuthenticationServiceMockTests: XCTestCase {

  var service: AuthenticationService!
  var mockContext: MockAuthenticationContext!
  var mockFactory: MockAuthenticationContextFactory!

  override func setUp() {
    super.setUp()
    mockContext = MockAuthenticationContext()
    mockFactory = MockAuthenticationContextFactory(mockContext: mockContext)
    service = AuthenticationService(contextFactory: mockFactory)
    service.clearAuthenticationCache()
  }

  override func tearDown() {
    service.invalidateAuthentication()
    service = nil
    mockContext = nil
    mockFactory = nil
    super.tearDown()
  }

  // MARK: - Biometric Availability Tests

  func testBiometricAuthenticationAvailable() {
    mockContext.canEvaluatePolicyResult = true
    XCTAssertTrue(service.isBiometricAuthenticationAvailable())
    XCTAssertTrue(mockContext.canEvaluatePolicyCalled)
  }

  func testBiometricAuthenticationNotAvailable() {
    mockContext.canEvaluatePolicyResult = false
    mockContext.canEvaluatePolicyError = LAError(.biometryNotAvailable)
    XCTAssertFalse(service.isBiometricAuthenticationAvailable())
    XCTAssertTrue(mockContext.canEvaluatePolicyCalled)
  }

  func testBiometryType() {
    mockContext.mockBiometryType = .faceID
    XCTAssertEqual(service.biometryType, .faceID)

    mockContext.mockBiometryType = .touchID
    XCTAssertEqual(service.biometryType, .touchID)
  }

  // MARK: - Authentication Flow Tests

  func testSuccessfulAuthentication() {
    let expectation = self.expectation(description: "Authentication completes")
    mockContext.canEvaluatePolicyResult = true
    mockContext.evaluatePolicyShouldSucceed = true

    service.authenticate(reason: "Test authentication", policy: .allowPasswordFallback) { result in
      switch result {
      case .success:
        XCTAssertTrue(self.mockContext.evaluatePolicyCalled)
        XCTAssertEqual(self.mockContext.evaluatePolicyReason, "Test authentication")
      case .failure, .cancelled:
        XCTFail("Authentication should succeed")
      }
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testFailedAuthentication() {
    let expectation = self.expectation(description: "Authentication fails")
    mockContext.canEvaluatePolicyResult = true
    mockContext.evaluatePolicyShouldSucceed = false
    mockContext.evaluatePolicyError = LAError(.authenticationFailed)

    service.authenticate(reason: "Test authentication", policy: .biometricOnly) { result in
      switch result {
      case .success:
        XCTFail("Authentication should fail")
      case .failure(let error):
        if let authError = error as? AuthenticationService.AuthenticationError {
          XCTAssertEqual(authError, .authenticationFailed)
        } else {
          XCTFail("Wrong error type")
        }
      case .cancelled:
        XCTFail("Should not be cancelled")
      }
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testCancelledAuthentication() {
    let expectation = self.expectation(description: "Authentication cancelled")
    mockContext.canEvaluatePolicyResult = true
    mockContext.evaluatePolicyShouldSucceed = false
    mockContext.evaluatePolicyError = LAError(.userCancel)

    service.authenticate(reason: "Test authentication") { result in
      switch result {
      case .success:
        XCTFail("Authentication should be cancelled")
      case .failure:
        XCTFail("Should be cancelled, not failed")
      case .cancelled:
        XCTAssertTrue(self.mockContext.evaluatePolicyCalled)
      }
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  // MARK: - Policy Evaluation Tests

  func testCannotEvaluatePolicy() {
    let expectation = self.expectation(description: "Policy evaluation fails")
    mockContext.canEvaluatePolicyResult = false
    mockContext.canEvaluatePolicyError = LAError(.biometryNotEnrolled)

    service.authenticate(reason: "Test") { result in
      switch result {
      case .success:
        XCTFail("Should not succeed when policy cannot be evaluated")
      case .failure(let error):
        if let authError = error as? AuthenticationService.AuthenticationError {
          XCTAssertEqual(authError, .biometryNotEnrolled)
        }
      case .cancelled:
        XCTFail("Should not be cancelled")
      }
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  // MARK: - Rate Limiting Tests

  func testRateLimiting() {
    // Reset attempts first
    service.resetAuthenticationAttempts()

    // Simulate multiple failed attempts
    mockContext.canEvaluatePolicyResult = true
    mockContext.evaluatePolicyShouldSucceed = false
    mockContext.evaluatePolicyError = LAError(.authenticationFailed)

    let expectations = (0..<4).map { index in
      self.expectation(description: "Attempt \(index + 1)")
    }

    // First 3 attempts should proceed
    for index in 0..<3 {
      service.authenticate(reason: "Test \(index + 1)") { result in
        if case .failure = result {
          expectations[index].fulfill()
        }
      }
    }

    // 4th attempt should be rate limited
    service.authenticate(reason: "Test 4") { result in
      if case .failure(let error) = result,
        let authError = error as? AuthenticationService.AuthenticationError,
        case .authenticationFailed = authError {
        // Rate limiting returns authentication failed
        expectations[3].fulfill()
      }
    }

    waitForExpectations(timeout: 5, handler: nil)
  }

  // MARK: - Caching Tests

  func testAuthenticationCaching() {
    // First successful authentication
    let expectation1 = self.expectation(description: "First authentication")
    mockContext.canEvaluatePolicyResult = true
    mockContext.evaluatePolicyShouldSucceed = true

    service.authenticate(reason: "Test 1") { _ in
      XCTAssertTrue(self.mockContext.evaluatePolicyCalled)
      expectation1.fulfill()
    }

    waitForExpectations(timeout: 2)

    // Reset mock
    mockContext.reset()

    // Second authentication within cache period should skip evaluation
    let expectation2 = self.expectation(description: "Cached authentication")
    service.authenticate(
      reason: "Test 2", policy: [.allowPasswordFallback, .requireRecentAuthentication]
    ) { _ in
      // Should not call evaluate since it's cached
      XCTAssertFalse(self.mockContext.evaluatePolicyCalled)
      expectation2.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testClearAuthenticationCache() {
    // Set up cached authentication
    service.lastAuthenticationTime = Date()

    // Clear cache
    service.clearAuthenticationCache()

    // Wait for async operation
    let expectation = self.expectation(description: "Cache cleared")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      XCTAssertNil(self.service.lastAuthenticationTime)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  // MARK: - Invalidation Tests

  func testInvalidateAuthentication() {
    // Trigger authentication to create context
    mockContext.canEvaluatePolicyResult = true
    _ = service.isBiometricAuthenticationAvailable()

    // Invalidate
    service.invalidateAuthentication()

    // Wait for async operation
    let expectation = self.expectation(description: "Context invalidated")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      // Next call should create new context
      self.mockContext.reset()
      _ = self.service.isBiometricAuthenticationAvailable()
      XCTAssertTrue(self.mockContext.canEvaluatePolicyCalled)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  // MARK: - Error Mapping Tests

  func testErrorMapping() {
    let testCases: [(LAError.Code, AuthenticationService.AuthenticationError)] = [
      (.biometryNotAvailable, .biometryNotAvailable),
      (.biometryNotEnrolled, .biometryNotEnrolled),
      (.biometryLockout, .biometryLockout),
      (.userCancel, .userCancel),
      (.userFallback, .userFallback),
      (.systemCancel, .systemCancel),
      (.passcodeNotSet, .passcodeNotSet),
      (.authenticationFailed, .authenticationFailed)
    ]

    for (laErrorCode, expectedError) in testCases {
      let error = service.mapLAError(NSError(domain: LAErrorDomain, code: laErrorCode.rawValue))
      XCTAssertEqual(error, expectedError)
    }

    // Test unknown error
    let unknownError = NSError(domain: "Unknown", code: 999)
    let mappedError = service.mapLAError(unknownError)
    if case .unknown = mappedError {
      // Success
    } else {
      XCTFail("Should map to unknown error")
    }

    // Test nil error
    let nilError = service.mapLAError(nil)
    if case .unknown = nilError {
      // Success
    } else {
      XCTFail("Nil should map to unknown error")
    }
  }

  // MARK: - Authentication Policy Tests

  func testAuthenticationPolicyOptions() {
    XCTAssertTrue(AuthenticationService.AuthenticationPolicy.biometricOnly.contains(.biometricOnly))
    XCTAssertFalse(
      AuthenticationService.AuthenticationPolicy.biometricOnly.contains(.allowPasswordFallback))

    let combined: AuthenticationService.AuthenticationPolicy = [
      .biometricOnly, .allowPasswordFallback
    ]
    XCTAssertTrue(combined.contains(.biometricOnly))
    XCTAssertTrue(combined.contains(.allowPasswordFallback))
  }

  // MARK: - Input Validation Tests

  func testEmptyReasonValidation() {
    let expectation = self.expectation(description: "Empty reason rejected")

    service.authenticate(reason: "") { result in
      if case .failure(let error) = result,
        let authError = error as? AuthenticationService.AuthenticationError,
        case .authenticationFailed = authError {
        expectation.fulfill()
      } else {
        XCTFail("Empty reason should be rejected")
      }
    }

    waitForExpectations(timeout: 2)
  }

  func testLongReasonValidation() {
    let longReason = String(repeating: "a", count: 300)
    let expectation = self.expectation(description: "Long reason rejected")

    service.authenticate(reason: longReason) { result in
      if case .failure(let error) = result,
        let authError = error as? AuthenticationService.AuthenticationError,
        case .authenticationFailed = authError {
        expectation.fulfill()
      } else {
        XCTFail("Long reason should be rejected")
      }
    }

    waitForExpectations(timeout: 2)
  }
}
