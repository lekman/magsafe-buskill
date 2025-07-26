import XCTest
@testable import MagSafeGuard

final class AppDelegateCoreTests: XCTestCase {
    
    var core: AppDelegateCore!
    var mockSystemActions: MockSystemActions!
    var mockSecurityActions: SecurityActionsService!
    var mockAuthContext: MockAuthenticationContext!
    
    override func setUp() {
        super.setUp()
        
        // Disable notifications for testing
        NotificationService.disableForTesting = true
        
        mockSystemActions = MockSystemActions()
        mockSecurityActions = SecurityActionsService(systemActions: mockSystemActions)
        
        // Set up mock authentication
        mockAuthContext = MockAuthenticationContext()
        mockAuthContext.canEvaluatePolicyResult = true
        mockAuthContext.evaluatePolicyShouldSucceed = true
        let authService = AuthenticationService(contextFactory: MockAuthenticationContextFactory(mockContext: mockAuthContext))
        
        core = AppDelegateCore(authService: authService, securityActions: mockSecurityActions)
    }
    
    override func tearDown() {
        core = nil
        // Re-enable notifications after testing
        NotificationService.disableForTesting = false
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertFalse(core.isArmed)
        XCTAssertNotNil(core.powerMonitor)
        XCTAssertNotNil(core.securityActions)
        XCTAssertTrue(core.powerMonitor === PowerMonitorService.shared)
        XCTAssertTrue(core.securityActions === mockSecurityActions)
    }
    
    // MARK: - Menu Tests
    
    func testCreateMenu() {
        let menu = core.createMenu()
        
        // The new menu structure has:
        // Status item, separator, Arm, separator, Power status, separator, Settings, Demo, Event Log, separator, Quit
        XCTAssertGreaterThanOrEqual(menu.items.count, 11)
        
        // Find items by title since positions may vary
        let armItem = menu.items.first { $0.title.contains("Arm") && $0.action != nil }
        let settingsItem = menu.items.first { $0.title == "Settings..." }
        let demoItem = menu.items.first { $0.title == "Run Demo..." }
        let quitItem = menu.items.first { $0.title == "Quit MagSafe Guard" }
        
        XCTAssertNotNil(armItem)
        XCTAssertNotNil(settingsItem)
        XCTAssertNotNil(demoItem)
        XCTAssertNotNil(quitItem)
        
        // Check key equivalents
        XCTAssertEqual(armItem?.keyEquivalent, "a")
        XCTAssertEqual(settingsItem?.keyEquivalent, ",")
        XCTAssertEqual(demoItem?.keyEquivalent, "d")
        XCTAssertEqual(quitItem?.keyEquivalent, "q")
    }
    
    func testMenuItemStates() {
        // Initial menu - not armed
        var menu = core.createMenu()
        let initialArmItem = menu.items.first { $0.title.contains("Arm Protection") && $0.action != nil }
        XCTAssertNotNil(initialArmItem)
        
        // Arm the system through AppController
        let armExpectation = expectation(description: "Arm completion")
        core.appController.arm { _ in
            armExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Recreate menu to get updated state
        menu = core.createMenu()
        let armedItem = menu.items.first { $0.title.contains("Disarm Protection") && $0.action != nil }
        XCTAssertNotNil(armedItem)
        
        // Disarm the system
        let disarmExpectation = expectation(description: "Disarm completion")
        core.appController.disarm { _ in
            disarmExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Recreate menu again
        menu = core.createMenu()
        let disarmedItem = menu.items.first { $0.title.contains("Arm Protection") && $0.action != nil }
        XCTAssertNotNil(disarmedItem)
    }
    
    func testMenuActions() {
        let menu = core.createMenu()
        
        // Find items by title
        let armItem = menu.items.first { $0.title.contains("Arm") && $0.action != nil }
        let settingsItem = menu.items.first { $0.title == "Settings..." }
        let demoItem = menu.items.first { $0.title == "Run Demo..." }
        let quitItem = menu.items.first { $0.title == "Quit MagSafe Guard" }
        
        // Check actions are set
        XCTAssertNotNil(armItem?.action)
        XCTAssertNotNil(settingsItem?.action)
        XCTAssertNotNil(demoItem?.action)
        XCTAssertNotNil(quitItem?.action)
        
        // Check action selectors
        XCTAssertEqual(armItem?.action?.description, "toggleArmed")
        XCTAssertEqual(settingsItem?.action?.description, "showSettings")
        XCTAssertEqual(demoItem?.action?.description, "showDemo")
    }
    
    // MARK: - Status Icon Tests
    
    func testStatusIconName() {
        // Not armed
        XCTAssertEqual(core.statusIconName(), "shield")
        
        // Arm the system
        let armExpectation = expectation(description: "Arm completion")
        core.appController.arm { _ in
            armExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(core.statusIconName(), "shield.fill")
    }
    
    // MARK: - Power Monitoring Tests
    
    func testHandlePowerStateChangeWhileArmed() {
        // Arm the system first
        let armExpectation = expectation(description: "Arm completion")
        core.appController.arm { _ in
            armExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        mockSystemActions.reset() // Ensure clean state
        
        // Configure to execute immediately without delay
        var config = mockSecurityActions.configuration
        config.actionDelay = 0
        mockSecurityActions.updateConfiguration(config)
        
        // Test disconnected state
        let disconnectedInfo = PowerMonitorService.PowerInfo(
            state: .disconnected,
            batteryLevel: 50,
            isCharging: false,
            adapterWattage: nil,
            timestamp: Date()
        )
        
        XCTAssertTrue(core.handlePowerStateChange(disconnectedInfo))
        
        // Wait for async execution
        let expectation = self.expectation(description: "Security actions executed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Verify that the screen lock was called
            XCTAssertTrue(self.mockSystemActions.lockScreenCalled, "Screen lock should have been called")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testHandlePowerStateChangeWhileDisarmed() {
        // Ensure system is disarmed (default state)
        XCTAssertFalse(core.isArmed)
        
        // Test disconnected state
        let disconnectedInfo = PowerMonitorService.PowerInfo(
            state: .disconnected,
            batteryLevel: 50,
            isCharging: false,
            adapterWattage: nil,
            timestamp: Date()
        )
        
        XCTAssertFalse(core.handlePowerStateChange(disconnectedInfo))
    }
    
    func testHandlePowerStateChangeConnected() {
        // Arm the system
        let armExpectation = expectation(description: "Arm completion")
        core.appController.arm { _ in
            armExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Test connected state
        let connectedInfo = PowerMonitorService.PowerInfo(
            state: .connected,
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        
        XCTAssertFalse(core.handlePowerStateChange(connectedInfo))
    }
    
    // MARK: - Security Tests
    
    func testIsArmedProperty() {
        // Not armed
        XCTAssertFalse(core.isArmed)
        
        // Arm the system
        let armExpectation = expectation(description: "Arm completion")
        core.appController.arm { _ in
            armExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(core.isArmed)
    }
    
    func testCreateNotificationContent() {
        let (title, text, identifier) = core.createNotificationContent(
            title: "Test Title",
            message: "Test Message"
        )
        
        XCTAssertEqual(title, "Test Title")
        XCTAssertEqual(text, "Test Message")
        XCTAssertTrue(identifier.starts(with: "MagSafeGuard-"))
        XCTAssertTrue(identifier.count > 13) // Prefix + UUID
    }
    
    // MARK: - State Management Tests
    
    func testToggleArmedState() {
        XCTAssertFalse(core.isArmed)
        
        core.toggleArmedState()
        XCTAssertTrue(core.isArmed)
        
        core.toggleArmedState()
        XCTAssertFalse(core.isArmed)
    }
    
    func testShouldRequestNotificationPermissions() {
        // In test environment, Bundle.main.bundleIdentifier might be nil
        let shouldRequest = core.shouldRequestNotificationPermissions()
        
        if Bundle.main.bundleIdentifier != nil {
            XCTAssertTrue(shouldRequest)
        } else {
            XCTAssertFalse(shouldRequest)
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() {
        // Start disarmed
        XCTAssertFalse(core.isArmed)
        
        // Create menu
        let menu = core.createMenu()
        XCTAssertEqual(menu.items[0].state, .off)
        
        // Arm the system
        core.toggleArmedState()
        XCTAssertTrue(core.isArmed)
        
        // Update menu
        core.updateMenuItems(in: menu)
        XCTAssertEqual(menu.items[0].state, .on)
        
        // Check icon
        XCTAssertEqual(core.statusIconName(), "shield.fill")
        
        // Simulate power disconnect
        let powerInfo = PowerMonitorService.PowerInfo(
            state: .disconnected,
            batteryLevel: 50,
            isCharging: false,
            adapterWattage: nil,
            timestamp: Date()
        )
        
        let shouldTriggerSecurity = core.handlePowerStateChange(powerInfo)
        // Now handlePowerStateChange always returns false because AppController handles it internally
        XCTAssertFalse(shouldTriggerSecurity)
        XCTAssertTrue(core.isArmed)
    }
    
    func testMenuUpdateWithoutArmItem() {
        // Create empty menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Other Item", action: nil, keyEquivalent: ""))
        
        // Should not crash
        core.updateMenuItems(in: menu)
        
        // Menu should remain unchanged
        XCTAssertEqual(menu.items.count, 1)
        XCTAssertEqual(menu.items[0].title, "Other Item")
    }
}