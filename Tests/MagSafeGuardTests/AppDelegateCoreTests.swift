import XCTest
@testable import MagSafeGuard

final class AppDelegateCoreTests: XCTestCase {
    
    var core: AppDelegateCore!
    var mockSystemActions: MockSystemActions!
    var mockSecurityActions: SecurityActionsService!
    
    override func setUp() {
        super.setUp()
        mockSystemActions = MockSystemActions()
        mockSecurityActions = SecurityActionsService(systemActions: mockSystemActions)
        core = AppDelegateCore(securityActions: mockSecurityActions)
    }
    
    override func tearDown() {
        core = nil
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
        
        XCTAssertEqual(menu.items.count, 6) // Arm, separator, Settings, Demo, separator, Quit
        
        // Check menu items
        XCTAssertEqual(menu.items[0].title, "Arm Protection")
        XCTAssertTrue(menu.items[1].isSeparatorItem)
        XCTAssertEqual(menu.items[2].title, "Settings...")
        XCTAssertEqual(menu.items[3].title, "Run Demo...")
        XCTAssertTrue(menu.items[4].isSeparatorItem)
        XCTAssertEqual(menu.items[5].title, "Quit")
        
        // Check key equivalents
        XCTAssertEqual(menu.items[2].keyEquivalent, ",")
        XCTAssertEqual(menu.items[3].keyEquivalent, "d")
        XCTAssertEqual(menu.items[5].keyEquivalent, "q")
    }
    
    func testMenuItemStates() {
        let menu = core.createMenu()
        
        // Initial state - not armed
        XCTAssertEqual(menu.items[0].state, .off)
        
        // Update armed state
        core.isArmed = true
        core.updateMenuItems(in: menu)
        
        XCTAssertEqual(menu.items[0].state, .on)
        
        // Toggle back
        core.isArmed = false
        core.updateMenuItems(in: menu)
        
        XCTAssertEqual(menu.items[0].state, .off)
    }
    
    func testMenuActions() {
        let menu = core.createMenu()
        
        // Check actions are set
        XCTAssertNotNil(menu.items[0].action) // Arm
        XCTAssertNotNil(menu.items[2].action) // Settings
        XCTAssertNotNil(menu.items[3].action) // Demo
        XCTAssertNotNil(menu.items[5].action) // Quit
        
        // Check action selectors
        XCTAssertEqual(menu.items[0].action?.description, "toggleArmed")
        XCTAssertEqual(menu.items[2].action?.description, "showSettings")
        XCTAssertEqual(menu.items[3].action?.description, "showDemo")
    }
    
    // MARK: - Status Icon Tests
    
    func testStatusIconName() {
        // Not armed
        core.isArmed = false
        XCTAssertEqual(core.statusIconName(), "lock")
        
        // Armed
        core.isArmed = true
        XCTAssertEqual(core.statusIconName(), "lock.fill")
    }
    
    // MARK: - Power Monitoring Tests
    
    func testHandlePowerStateChangeWhileArmed() {
        core.isArmed = true
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
        core.isArmed = false
        
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
        core.isArmed = true
        
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
    
    func testShouldAuthenticate() {
        core.isArmed = false
        XCTAssertFalse(core.shouldAuthenticate())
        
        core.isArmed = true
        XCTAssertTrue(core.shouldAuthenticate())
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
        XCTAssertEqual(core.statusIconName(), "lock.fill")
        
        // Simulate power disconnect
        let powerInfo = PowerMonitorService.PowerInfo(
            state: .disconnected,
            batteryLevel: 50,
            isCharging: false,
            adapterWattage: nil,
            timestamp: Date()
        )
        
        let shouldTriggerSecurity = core.handlePowerStateChange(powerInfo)
        XCTAssertTrue(shouldTriggerSecurity)
        XCTAssertTrue(core.shouldAuthenticate())
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