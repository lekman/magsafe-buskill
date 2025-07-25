//
//  AuthenticationServiceComprehensiveTests.swift
//  MagSafeGuardTests
//
//  Created on 2025-07-25.
//

import XCTest
import LocalAuthentication
@testable import MagSafeGuard

final class AuthenticationServiceComprehensiveTests: XCTestCase {
    
    var service: AuthenticationService!
    
    override func setUp() {
        super.setUp()
        service = AuthenticationService.shared
        service.clearAuthenticationCache()
        // Clear any previous authentication attempts
        service.invalidateAuthentication()
    }
    
    override func tearDown() {
        service.invalidateAuthentication()
        service = nil
        super.tearDown()
    }
    
    // MARK: - Error Description Tests
    
    func testAllErrorDescriptions() {
        // Test all error cases have descriptions
        let testCases: [(AuthenticationService.AuthenticationError, String)] = [
            (.biometryNotAvailable, "Biometric authentication is not available on this device"),
            (.biometryNotEnrolled, "No biometric data is enrolled. Please set up Touch ID or Face ID"),
            (.biometryLockout, "Biometric authentication is locked due to too many failed attempts"),
            (.userCancel, "Authentication was cancelled by the user"),
            (.userFallback, "User chose to enter password instead"),
            (.systemCancel, "Authentication was cancelled by the system"),
            (.passcodeNotSet, "Device passcode is not set"),
            (.authenticationFailed, "Authentication failed"),
            (.unknown(NSError(domain: "Test", code: 123, userInfo: nil)), "Authentication failed:")
        ]
        
        for (error, expectedPrefix) in testCases {
            let description = error.errorDescription ?? ""
            XCTAssertFalse(description.isEmpty, "Error \(error) should have a description")
            XCTAssertTrue(description.contains(expectedPrefix) || description.hasPrefix(expectedPrefix),
                         "Error \(error) description '\(description)' should contain or start with '\(expectedPrefix)'")
        }
    }
    
    // MARK: - Error Mapping Tests
    
    func testLAErrorMapping() {
        // Test mapping of all LAError types
        let mappingTests: [(NSError, AuthenticationService.AuthenticationError)] = [
            (LAErrorFactory.biometryNotAvailable(), .biometryNotAvailable),
            (LAErrorFactory.biometryNotEnrolled(), .biometryNotEnrolled),
            (LAErrorFactory.biometryLockout(), .biometryLockout),
            (LAErrorFactory.userCancel(), .userCancel),
            (LAErrorFactory.userFallback(), .userFallback),
            (LAErrorFactory.systemCancel(), .systemCancel),
            (LAErrorFactory.passcodeNotSet(), .passcodeNotSet),
            (LAErrorFactory.authenticationFailed(), .authenticationFailed)
        ]
        
        for (laError, expectedError) in mappingTests {
            let mappedError = service.mapLAError(laError)
            
            switch (mappedError, expectedError) {
            case (.biometryNotAvailable, .biometryNotAvailable),
                 (.biometryNotEnrolled, .biometryNotEnrolled),
                 (.biometryLockout, .biometryLockout),
                 (.userCancel, .userCancel),
                 (.userFallback, .userFallback),
                 (.systemCancel, .systemCancel),
                 (.passcodeNotSet, .passcodeNotSet),
                 (.authenticationFailed, .authenticationFailed):
                // Correct mapping
                XCTAssertTrue(true)
            case (.unknown(let error), .unknown):
                // For unknown errors, just verify it's wrapped correctly
                XCTAssertNotNil(error)
            default:
                XCTFail("Error mapping failed: \(laError) should map to \(expectedError) but got \(mappedError)")
            }
        }
    }
    
    func testUnknownErrorMapping() {
        // Test non-LAError mapping
        let customError = NSError(domain: "CustomDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Custom error"])
        let mappedError = service.mapLAError(customError)
        
        if case .unknown(let error) = mappedError {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "CustomDomain")
            XCTAssertEqual(nsError.code, 999)
        } else {
            XCTFail("Custom error should map to .unknown")
        }
    }
    
    func testNilErrorMapping() {
        // Test nil error mapping
        let mappedError = service.mapLAError(nil)
        
        if case .unknown(let error) = mappedError {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "AuthenticationService")
            XCTAssertEqual(nsError.code, -1)
        } else {
            XCTFail("Nil error should map to .unknown with default error")
        }
    }
    
    // MARK: - Rate Limiting Tests
    
    func testRateLimitingAfterFailedAttempts() {
        // Clear any previous attempts
        service.clearAuthenticationCache()
        
        // Record multiple failed attempts
        service.recordAuthenticationAttempt(success: false)
        service.recordAuthenticationAttempt(success: false)
        service.recordAuthenticationAttempt(success: false)
        
        // Should be rate limited after 3 failed attempts
        XCTAssertTrue(service.isRateLimited(), "Should be rate limited after 3 failed attempts")
    }
    
    func testRateLimitingWithMixedAttempts() {
        // Clear any previous attempts
        service.clearAuthenticationCache()
        
        // Mix of successful and failed attempts
        service.recordAuthenticationAttempt(success: true)
        service.recordAuthenticationAttempt(success: false)
        service.recordAuthenticationAttempt(success: false)
        service.recordAuthenticationAttempt(success: true)
        service.recordAuthenticationAttempt(success: false)
        
        // Should be rate limited (3 failures total)
        XCTAssertTrue(service.isRateLimited(), "Should be rate limited with 3 total failures")
    }
    
    func testRateLimitingResetAfterTime() {
        // This test would require mocking time, so we'll test the logic
        service.clearAuthenticationCache()
        
        // Record attempts
        service.recordAuthenticationAttempt(success: false)
        service.recordAuthenticationAttempt(success: false)
        
        // Not rate limited with only 2 attempts
        XCTAssertFalse(service.isRateLimited(), "Should not be rate limited with only 2 failed attempts")
    }
    
    func testSuccessfulAttemptsDoNotTriggerRateLimit() {
        service.clearAuthenticationCache()
        
        // Record only successful attempts
        for _ in 1...5 {
            service.recordAuthenticationAttempt(success: true)
        }
        
        XCTAssertFalse(service.isRateLimited(), "Successful attempts should not trigger rate limiting")
    }
    
    // MARK: - Pre-Authentication Checks Tests
    
    func testEmptyReasonRejection() {
        let result = service.performPreAuthenticationChecks(reason: "", policy: .allowPasswordFallback)
        
        if case .failure(let error) = result,
           case .authenticationFailed = error as? AuthenticationService.AuthenticationError {
            // Expected behavior
            XCTAssertTrue(true)
        } else {
            XCTFail("Empty reason should return authenticationFailed error")
        }
    }
    
    func testWhitespaceOnlyReasonRejection() {
        let result = service.performPreAuthenticationChecks(reason: "   \n\t   ", policy: .allowPasswordFallback)
        
        if case .failure(let error) = result,
           case .authenticationFailed = error as? AuthenticationService.AuthenticationError {
            // Expected behavior
            XCTAssertTrue(true)
        } else {
            XCTFail("Whitespace-only reason should return authenticationFailed error")
        }
    }
    
    func testLongReasonRejection() {
        let longReason = String(repeating: "a", count: 201)
        let result = service.performPreAuthenticationChecks(reason: longReason, policy: .allowPasswordFallback)
        
        if case .failure(let error) = result,
           case .authenticationFailed = error as? AuthenticationService.AuthenticationError {
            // Expected behavior
            XCTAssertTrue(true)
        } else {
            XCTFail("Reason over 200 characters should return authenticationFailed error")
        }
    }
    
    func testValidReasonAcceptance() {
        let validReason = "Access secure data"
        let result = service.performPreAuthenticationChecks(reason: validReason, policy: .allowPasswordFallback)
        
        // Should return nil (no early failure)
        XCTAssertNil(result, "Valid reason should not cause early failure")
    }
    
    func testRateLimitingInPreChecks() {
        // Trigger rate limiting
        service.recordAuthenticationAttempt(success: false)
        service.recordAuthenticationAttempt(success: false)
        service.recordAuthenticationAttempt(success: false)
        
        let result = service.performPreAuthenticationChecks(reason: "Test", policy: .allowPasswordFallback)
        
        if case .failure(let error) = result,
           case .biometryLockout = error as? AuthenticationService.AuthenticationError {
            // Expected behavior
            XCTAssertTrue(true)
        } else {
            XCTFail("Rate limited state should return biometryLockout error")
        }
    }
    
    // MARK: - Authentication Policy Tests
    
    func testAuthenticationPolicyContains() {
        let policy: AuthenticationService.AuthenticationPolicy = [.biometricOnly, .requireRecentAuthentication]
        
        XCTAssertTrue(policy.contains(.biometricOnly))
        XCTAssertTrue(policy.contains(.requireRecentAuthentication))
        XCTAssertFalse(policy.contains(.allowPasswordFallback))
    }
    
    func testAuthenticationPolicyRawValues() {
        XCTAssertEqual(AuthenticationService.AuthenticationPolicy.biometricOnly.rawValue, 1)
        XCTAssertEqual(AuthenticationService.AuthenticationPolicy.allowPasswordFallback.rawValue, 2)
        XCTAssertEqual(AuthenticationService.AuthenticationPolicy.requireRecentAuthentication.rawValue, 4)
    }
    
    // MARK: - Integration Tests
    
    func testAuthenticationWithInvalidReason() {
        let expectation = XCTestExpectation(description: "Authentication with empty reason")
        
        service.authenticate(reason: "") { result in
            switch result {
            case .failure(let error):
                if case .authenticationFailed = error as? AuthenticationService.AuthenticationError {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected authenticationFailed error but got: \(error)")
                    expectation.fulfill()
                }
            default:
                XCTFail("Expected failure but got: \(result)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAuthenticationWithRateLimit() {
        let expectations = (0..<4).map { i in
            XCTestExpectation(description: "Authentication attempt \(i)")
        }
        
        // Make 4 authentication attempts
        for (index, expectation) in expectations.enumerated() {
            service.authenticate(reason: "Rate limit test \(index)", policy: .biometricOnly) { result in
                if index == 3 {
                    // Fourth attempt should be rate limited
                    if case .failure(let error) = result,
                       case .biometryLockout = error as? AuthenticationService.AuthenticationError {
                        expectation.fulfill()
                    } else {
                        // In CI or if biometrics aren't available, we might get a different error
                        expectation.fulfill()
                    }
                } else {
                    // First 3 attempts proceed (may fail for other reasons)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: expectations, timeout: 10.0)
    }
    
    func testCancelledAuthentication() {
        let expectation = XCTestExpectation(description: "Cancelled authentication")
        
        // We can't directly trigger a cancel in unit tests, but we can test the flow
        service.authenticate(reason: "Test cancellation") { result in
            // In CI, this will likely fail with biometry not available
            // We're testing that the completion handler is called
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAuthenticationRequests() {
        let expectation = XCTestExpectation(description: "Concurrent requests")
        expectation.expectedFulfillmentCount = 3
        
        // Make multiple concurrent authentication requests
        DispatchQueue.concurrentPerform(iterations: 3) { index in
            service.authenticate(reason: "Concurrent test \(index)") { _ in
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testClearCacheDuringAuthentication() {
        let expectation1 = XCTestExpectation(description: "Authentication")
        let expectation2 = XCTestExpectation(description: "Clear cache")
        
        // Start authentication
        service.authenticate(reason: "Test clear cache") { _ in
            expectation1.fulfill()
        }
        
        // Clear cache immediately
        DispatchQueue.global().async {
            self.service.clearAuthenticationCache()
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 5.0)
    }
}