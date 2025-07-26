import XCTest
import UserNotifications
@testable import MagSafeGuard

final class NotificationServiceTests: XCTestCase {
    
    var service: NotificationService!
    
    override func setUp() {
        super.setUp()
        service = NotificationService.shared
        // Reset to default state
        NotificationService.disableForTesting = false
    }
    
    override func tearDown() {
        NotificationService.disableForTesting = false
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstance() {
        let instance1 = NotificationService.shared
        let instance2 = NotificationService.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same shared instance")
    }
    
    // MARK: - Permission Tests
    
    func testRequestPermissionsWhenDisabled() {
        NotificationService.disableForTesting = true
        
        // Request permissions - no callback in the public API
        service.requestPermissions()
        
        // Just verify no crash
        XCTAssertTrue(true)
    }
    
    func testNotificationWhenDisabled() {
        NotificationService.disableForTesting = true
        
        // Should not crash when notifications are disabled
        service.showNotification(
            title: "Test",
            message: "Test body"
        )
        
        // No assertion needed - just verifying no crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Multiple Notifications Test
    
    func testMultipleNotifications() {
        NotificationService.disableForTesting = true
        
        // Send multiple notifications
        for i in 0..<5 {
            service.showNotification(
                title: "Test \(i)",
                message: "Message \(i)"
            )
        }
        
        // Verify no crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Permission State Tests
    
    func testPermissionsNotRequestedInitially() {
        // Create a fresh service with mock delivery
        let mockDelivery = MockNotificationDelivery()
        _ = NotificationService(deliveryMethod: mockDelivery)
        
        // Verify permissions weren't requested during init
        XCTAssertFalse(mockDelivery.permissionsRequested)
    }
    
    func testPermissionsRequestedOnFirstNotification() {
        NotificationService.disableForTesting = false
        let mockDelivery = MockNotificationDelivery()
        let freshService = NotificationService(deliveryMethod: mockDelivery)
        
        // Send first notification
        freshService.showNotification(title: "Test", message: "Test")
        
        // Verify permissions were requested
        XCTAssertTrue(mockDelivery.permissionsRequested)
    }
    
    // MARK: - Notification Request Tests
    
    func testCreateNotificationRequest() {
        // Since createNotificationRequest is private, we test it indirectly
        NotificationService.disableForTesting = true
        
        // This should create a request internally
        service.showNotification(
            title: "Test Title",
            message: "Test Body"
        )
        
        // Verify no crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Critical Alert Tests
    
    func testShowCriticalAlert() {
        NotificationService.disableForTesting = true
        
        // Use mock delivery to avoid real alerts
        let mockDelivery = MockNotificationDelivery()
        let testService = NotificationService(deliveryMethod: mockDelivery)
        
        // Test critical alert functionality
        testService.showCriticalAlert(
            title: "Critical Security Alert",
            message: "This is a critical alert"
        )
        
        // Verify the notification was delivered
        XCTAssertEqual(mockDelivery.deliveredNotifications.count, 1)
        XCTAssertEqual(mockDelivery.deliveredNotifications.first?.title, "Critical Security Alert")
        XCTAssertEqual(mockDelivery.deliveredNotifications.first?.message, "This is a critical alert")
    }
    
    func testMultipleCriticalAlerts() {
        NotificationService.disableForTesting = true
        
        // Use mock delivery to avoid real alerts
        let mockDelivery = MockNotificationDelivery()
        let testService = NotificationService(deliveryMethod: mockDelivery)
        
        // Send multiple critical alerts
        for i in 0..<3 {
            testService.showCriticalAlert(
                title: "Critical Alert \(i)",
                message: "Critical message \(i)"
            )
        }
        
        // Verify all notifications were delivered
        XCTAssertEqual(mockDelivery.deliveredNotifications.count, 3)
        for i in 0..<3 {
            XCTAssertEqual(mockDelivery.deliveredNotifications[i].title, "Critical Alert \(i)")
            XCTAssertEqual(mockDelivery.deliveredNotifications[i].message, "Critical message \(i)")
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyTitleAndBody() {
        NotificationService.disableForTesting = true
        
        // Should handle empty strings gracefully
        service.showNotification(
            title: "",
            message: ""
        )
        
        XCTAssertTrue(true)
    }
    
    func testVeryLongContent() {
        NotificationService.disableForTesting = true
        
        let longString = String(repeating: "A", count: 1000)
        
        // Should handle long content gracefully
        service.showNotification(
            title: longString,
            message: longString
        )
        
        XCTAssertTrue(true)
    }
    
    func testSpecialCharactersInContent() {
        NotificationService.disableForTesting = true
        
        // Should handle special characters
        service.showNotification(
            title: "Test 🔒 \n\t Special \"Characters\"",
            message: "Body with <html> & special chars"
        )
        
        XCTAssertTrue(true)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentNotifications() {
        NotificationService.disableForTesting = true
        
        let expectation = expectation(description: "All notifications complete")
        expectation.expectedFulfillmentCount = 10
        
        // Send multiple notifications concurrently
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.service.showNotification(
                    title: "Notification \(i)",
                    message: "Body \(i)"
                )
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testConcurrentPermissionRequests() {
        NotificationService.disableForTesting = true
        
        // Use mock delivery to avoid real UNUserNotificationCenter
        let mockDelivery = MockNotificationDelivery()
        let testService = NotificationService(deliveryMethod: mockDelivery)
        
        let expectation = expectation(description: "All permission requests complete")
        expectation.expectedFulfillmentCount = 5
        
        // Request permissions concurrently
        for _ in 0..<5 {
            DispatchQueue.global().async {
                testService.requestPermissions()
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
        
        // Verify permissions were requested
        XCTAssertTrue(mockDelivery.permissionsRequested)
    }
    
    // MARK: - Integration Tests
    
    func testNotificationServiceWithAppController() {
        NotificationService.disableForTesting = true
        
        // Test that NotificationService works with AppController notifications
        let mockAuthContext = MockAuthenticationContext()
        mockAuthContext.canEvaluatePolicyResult = true
        mockAuthContext.evaluatePolicyShouldSucceed = true
        
        let authService = AuthenticationService(
            contextFactory: MockAuthenticationContextFactory(mockContext: mockAuthContext)
        )
        let securityActions = SecurityActionsService(systemActions: MockSystemActions())
        let appController = AppController(
            authService: authService,
            securityActions: securityActions
        )
        
        // Arm the system - this should trigger a notification
        let armExpectation = expectation(description: "Arm completes")
        appController.arm { result in
            if case .success = result {
                XCTAssertTrue(true, "Arming succeeded")
            } else {
                XCTFail("Arming should succeed")
            }
            armExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
}