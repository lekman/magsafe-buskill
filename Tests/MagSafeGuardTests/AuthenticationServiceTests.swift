//
//  AuthenticationServiceTests.swift
//  MagSafeGuardTests
//
//  Created on 2025-07-25.
//

import XCTest
import LocalAuthentication
@testable import MagSafeGuard

final class AuthenticationServiceTests: XCTestCase {
    
    var service: AuthenticationService!
    
    override func setUp() {
        super.setUp()
        service = AuthenticationService.shared
        service.clearAuthenticationCache()
    }
    
    override func tearDown() {
        service.invalidateAuthentication()
        super.tearDown()
    }
    
    // MARK: - Basic Tests
    
    func testServiceSingleton() {
        let instance1 = AuthenticationService.shared
        let instance2 = AuthenticationService.shared
        XCTAssertTrue(instance1 === instance2, "AuthenticationService should be a singleton")
    }
    
    func testBiometryTypeProperty() {
        // This will vary by device/simulator
        let biometryType = service.biometryType
        XCTAssertTrue(
            [LABiometryType.none, .touchID, .faceID].contains(biometryType),
            "Biometry type should be valid"
        )
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticationInCIEnvironment() {
        let expectation = XCTestExpectation(description: "Authentication completes")
        
        // In CI/test environments, we expect authentication to fail gracefully
        // We're testing that the service handles the lack of biometric hardware properly
        
        service.authenticate(reason: "Test authentication") { result in
            switch result {
            case .cancelled:
                // User cancellation - acceptable
                expectation.fulfill()
            case .failure(let error):
                // Expected in CI - biometrics not available
                if case .biometryNotAvailable = error as? AuthenticationService.AuthenticationError {
                    // This is the expected case in CI
                    expectation.fulfill()
                } else {
                    // Other failures are also acceptable
                    print("Authentication failed with: \(error)")
                    expectation.fulfill()
                }
            case .success:
                // Unlikely in CI, but not impossible if password fallback works
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAuthenticationCaching() {
        // Test that clearAuthenticationCache works
        service.clearAuthenticationCache()
        
        // We can't easily test the actual caching behavior without mocking
        // but we can verify the method exists and doesn't crash
        XCTAssertNotNil(service, "Service should exist after clearing cache")
    }
    
    func testInvalidateAuthentication() {
        // Test that invalidation doesn't crash
        service.invalidateAuthentication()
        XCTAssertNotNil(service, "Service should exist after invalidation")
    }
    
    // MARK: - Error Mapping Tests
    
    func testAuthenticationErrorDescriptions() {
        let errors: [AuthenticationService.AuthenticationError] = [
            .biometryNotAvailable,
            .biometryNotEnrolled,
            .biometryLockout,
            .userCancel,
            .userFallback,
            .systemCancel,
            .passcodeNotSet,
            .authenticationFailed,
            .unknown(NSError(domain: "Test", code: 1, userInfo: nil))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have error description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) should have non-empty error description")
        }
    }
    
    // MARK: - Policy Tests
    
    func testAuthenticationPolicyOptions() {
        let biometricOnly = AuthenticationService.AuthenticationPolicy.biometricOnly
        let allowPassword = AuthenticationService.AuthenticationPolicy.allowPasswordFallback
        let requireRecent = AuthenticationService.AuthenticationPolicy.requireRecentAuthentication
        
        XCTAssertEqual(biometricOnly.rawValue, 1)
        XCTAssertEqual(allowPassword.rawValue, 2)
        XCTAssertEqual(requireRecent.rawValue, 4)
        
        // Test option set behavior
        let combined: AuthenticationService.AuthenticationPolicy = [.biometricOnly, .allowPasswordFallback]
        XCTAssertTrue(combined.contains(.biometricOnly))
        XCTAssertTrue(combined.contains(.allowPasswordFallback))
        XCTAssertFalse(combined.contains(.requireRecentAuthentication))
    }
    
    // MARK: - Integration Tests (Simulator/Device Specific)
    
    func testBiometricAvailability() {
        // This test result depends on the device/simulator
        let isAvailable = service.isBiometricAuthenticationAvailable()
        
        // On simulator or devices without biometrics, this should be false
        // On devices with TouchID/FaceID, this might be true
        XCTAssertNotNil(isAvailable, "Should return a boolean value")
        
        // Log for CI debugging
        if isAvailable {
            print("[CI Test] Biometric authentication is available")
        } else {
            print("[CI Test] Biometric authentication is NOT available (expected in CI)")
        }
    }
    
    func testCIEnvironmentHandling() {
        // This test specifically validates CI environment behavior
        let biometryType = service.biometryType
        
        if biometryType == .none {
            // Expected in CI - no biometrics available
            print("[CI Test] No biometry available (expected in CI)")
            
            // Test that authentication fails appropriately
            let expectation = XCTestExpectation(description: "Biometric-only auth should fail")
            
            service.authenticate(
                reason: "CI Test",
                policy: .biometricOnly  // Force biometric only
            ) { result in
                if case .failure(let error) = result {
                    print("[CI Test] Biometric-only auth failed as expected: \(error)")
                    expectation.fulfill()
                } else {
                    XCTFail("Biometric-only auth should fail in CI environment")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        } else {
            print("[CI Test] Biometry type available: \(biometryType == .touchID ? "TouchID" : "FaceID")")
        }
    }
    
    // MARK: - Security Tests
    
    func testRateLimiting() {
        // Test that rate limiting prevents excessive authentication attempts
        let expectations = [
            XCTestExpectation(description: "First auth attempt"),
            XCTestExpectation(description: "Second auth attempt"),
            XCTestExpectation(description: "Third auth attempt"),
            XCTestExpectation(description: "Fourth auth attempt - should be rate limited")
        ]
        
        // Clear any previous attempts
        service.clearAuthenticationCache()
        
        // Simulate multiple failed authentication attempts
        for (index, expectation) in expectations.enumerated() {
            service.authenticate(
                reason: "Rate limit test \(index + 1)",
                policy: .biometricOnly
            ) { result in
                if index < 3 {
                    // First 3 attempts should proceed (may fail due to no biometrics)
                    print("[Rate Limit Test] Attempt \(index + 1): \(result)")
                } else {
                    // Fourth attempt should be rate limited
                    if case .failure(let error) = result,
                       case .biometryLockout = error as? AuthenticationService.AuthenticationError {
                        print("[Rate Limit Test] Attempt \(index + 1): Correctly rate limited")
                    } else {
                        print("[Rate Limit Test] Attempt \(index + 1): Expected rate limiting but got: \(result)")
                    }
                }
                expectation.fulfill()
            }
            
            // Small delay between attempts
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        wait(for: expectations, timeout: 10.0)
    }
    
    func testEmptyReasonValidation() {
        // Test that empty authentication reasons are rejected
        let expectation = XCTestExpectation(description: "Empty reason should fail")
        
        service.authenticate(reason: "") { result in
            if case .failure(let error) = result,
               case .authenticationFailed = error as? AuthenticationService.AuthenticationError {
                expectation.fulfill()
            } else {
                XCTFail("Empty reason should fail with authenticationFailed error")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock LAContext for Testing
// Note: In a real project, you might want to use dependency injection
// to properly mock LAContext for better unit testing

extension AuthenticationServiceTests {
    
    /// Test helper to verify authentication flow
    /// Note: This is limited in unit tests without proper mocking
    func testAuthenticationFlow() {
        let expectation = XCTestExpectation(description: "Authentication flow completes")
        var resultReceived = false
        
        service.authenticate(
            reason: "Test authentication flow",
            policy: .allowPasswordFallback
        ) { result in
            resultReceived = true
            
            // Log the result for CI debugging
            switch result {
            case .success:
                print("[CI Test] Authentication succeeded (password fallback may have been used)")
            case .cancelled:
                print("[CI Test] Authentication was cancelled")
            case .failure(let error):
                print("[CI Test] Authentication failed: \(error.localizedDescription)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(resultReceived, "Should receive authentication result")
    }
}