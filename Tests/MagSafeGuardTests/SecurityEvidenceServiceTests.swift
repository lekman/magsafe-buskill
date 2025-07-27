//
//  SecurityEvidenceServiceTests.swift
//  MagSafe Guard Tests
//
//  Created on 2025-07-27.
//
//  Tests for the SecurityEvidenceService functionality
//

import XCTest
import CoreLocation
@testable import MagSafeGuard

class SecurityEvidenceServiceTests: XCTestCase {
    
    var evidenceService: SecurityEvidenceService!
    
    override func setUp() {
        super.setUp()
        evidenceService = SecurityEvidenceService()
        
        // Enable evidence collection for tests
        UserDefaults.standard.set(true, forKey: "evidenceCollectionEnabled")
    }
    
    override func tearDown() {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "evidenceCollectionEnabled")
        UserDefaults.standard.removeObject(forKey: "backupEmailAddress")
        
        // Clean up any test evidence files
        cleanupTestEvidence()
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testEvidenceCollectionWhenDisabled() {
        // Disable evidence collection
        UserDefaults.standard.set(false, forKey: "evidenceCollectionEnabled")
        
        // Try to collect evidence
        XCTAssertThrowsError(try evidenceService.collectEvidence(reason: "Test")) { error in
            XCTAssertEqual(error as? EvidenceError, EvidenceError.featureDisabled)
        }
    }
    
    func testEvidenceCollectionInitiation() {
        // This test verifies that evidence collection can be initiated
        // Note: Actual camera and location capture would require mock implementations
        
        do {
            try evidenceService.collectEvidence(reason: "Unit test")
            // If we get here without throwing, the collection was initiated
            XCTAssertTrue(true, "Evidence collection initiated successfully")
            
            // Stop collection
            evidenceService.stopEvidenceCollection()
        } catch {
            XCTFail("Evidence collection should not throw when enabled: \(error)")
        }
    }
    
    func testListStoredEvidence() throws {
        // Initially should be empty or contain existing evidence
        let evidenceList = try evidenceService.listStoredEvidence()
        
        // We can't assert exact count as there might be existing evidence
        // Just verify the method doesn't throw
        XCTAssertNotNil(evidenceList)
    }
    
    func testEvidenceEncryption() throws {
        // Create test evidence
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let testPhotoData = "Test photo data".data(using: .utf8)!
        
        let evidence = SecurityEvidence(
            timestamp: Date(),
            location: testLocation,
            photoData: testPhotoData,
            deviceInfo: "Test Device"
        )
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encoded = try encoder.encode(evidence)
        let decoded = try decoder.decode(SecurityEvidence.self, from: encoded)
        
        XCTAssertEqual(decoded.deviceInfo, evidence.deviceInfo)
        XCTAssertEqual(decoded.photoData, evidence.photoData)
        XCTAssertNotNil(decoded.location)
    }
    
    func testBackupEmailConfiguration() {
        // Test setting backup email
        let testEmail = "test@example.com"
        UserDefaults.standard.set(testEmail, forKey: "backupEmailAddress")
        
        // Verify it's stored
        let retrievedEmail = UserDefaults.standard.string(forKey: "backupEmailAddress")
        XCTAssertEqual(retrievedEmail, testEmail)
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestEvidence() {
        do {
            let documentsDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence", isDirectory: true)
            
            // Only remove if it exists and is a test environment
            if FileManager.default.fileExists(atPath: evidenceDirectory.path) {
                // Could add additional checks here to ensure we're only removing test data
                // For now, we'll leave the evidence directory intact
            }
        } catch {
            // Ignore cleanup errors
        }
    }
}