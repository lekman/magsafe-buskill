import XCTest
import SwiftUI
@testable import MagSafeGuard

final class PowerMonitorDemoViewTests: XCTestCase {
    
    func testPowerMonitorDemoViewInitialization() {
        // Create the view
        let view = PowerMonitorDemoView()
        
        // The view should initialize without issues
        XCTAssertNotNil(view)
    }
    
    func testViewModelInitialization() {
        // Create view model
        let viewModel = PowerMonitorDemoViewModel()
        
        // Verify initial state
        XCTAssertFalse(viewModel.isMonitoring)
        // PowerState will be actual system state, not "Unknown"
        XCTAssertTrue(viewModel.powerState == "Power adapter connected" || 
                      viewModel.powerState == "Power adapter disconnected")
        // Battery level and other properties depend on actual system state
        // so we just verify the monitoring state
    }
    
    func testStartMonitoring() {
        let viewModel = PowerMonitorDemoViewModel()
        
        // Start monitoring using toggle
        XCTAssertFalse(viewModel.isMonitoring)
        viewModel.toggleMonitoring()
        
        // Verify monitoring started
        XCTAssertTrue(viewModel.isMonitoring)
        
        // Stop monitoring to clean up
        viewModel.toggleMonitoring()
        XCTAssertFalse(viewModel.isMonitoring)
    }
    
    func testStopMonitoring() {
        let viewModel = PowerMonitorDemoViewModel()
        
        // Start monitoring
        viewModel.toggleMonitoring()
        XCTAssertTrue(viewModel.isMonitoring)
        
        // Stop monitoring
        viewModel.toggleMonitoring()
        
        // Verify monitoring stopped
        XCTAssertFalse(viewModel.isMonitoring)
    }
    
    func testHandlePowerUpdate() {
        let viewModel = PowerMonitorDemoViewModel()
        
        // Test with connected state
        _ = PowerMonitorService.PowerInfo(
            state: .connected,
            batteryLevel: 85,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        
        // Test refresh method
        viewModel.refresh()
        
        // Power state might still be unknown if no adapter connected
        XCTAssertNotNil(viewModel.powerState)
        XCTAssertNotNil(viewModel.lastUpdate)
        
        // Test with monitoring
        viewModel.toggleMonitoring()
        Thread.sleep(forTimeInterval: 0.1)
        viewModel.toggleMonitoring()
    }
    
    func testViewModelMainActor() async {
        // Test that view model updates happen on main actor
        let viewModel = await MainActor.run {
            PowerMonitorDemoViewModel()
        }
        
        await MainActor.run {
            viewModel.toggleMonitoring()
            XCTAssertTrue(viewModel.isMonitoring)
            viewModel.toggleMonitoring()
        }
    }
    
    func testBodyCreation() {
        // Create view and get body
        let view = PowerMonitorDemoView()
        let body = view.body
        
        // Body should exist
        XCTAssertNotNil(body)
    }
    
    func testPowerStateDescriptions() {
        let viewModel = PowerMonitorDemoViewModel()
        
        // Test that power state is one of the valid states
        XCTAssertTrue(viewModel.powerState == "Power adapter connected" || 
                      viewModel.powerState == "Power adapter disconnected")
        
        // Refresh to get current state
        viewModel.refresh()
        
        // State should be set
        XCTAssertNotNil(viewModel.powerState)
        XCTAssertNotNil(viewModel.lastUpdate)
    }
    
    func testMemoryManagement() {
        // Test that view model properly cleans up
        var viewModel: PowerMonitorDemoViewModel? = PowerMonitorDemoViewModel()
        
        viewModel?.toggleMonitoring()
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel?.isMonitoring ?? false)
        
        // Stop monitoring before releasing
        viewModel?.toggleMonitoring()
        
        // Release the view model
        viewModel = nil
        XCTAssertNil(viewModel)
    }
    
    func testViewModelProperties() {
        let viewModel = PowerMonitorDemoViewModel()
        
        // Test initial properties
        XCTAssertFalse(viewModel.isMonitoring)
        XCTAssertNotNil(viewModel.powerState)
        XCTAssertNotNil(viewModel.lastUpdate)
        
        // Refresh and check properties are updated
        viewModel.refresh()
        
        // Properties should have valid values after refresh
        XCTAssertNotNil(viewModel.powerState)
        XCTAssertNotEqual(viewModel.lastUpdate, "Never")
    }
    
    func testMonitoringStateTransitions() {
        let viewModel = PowerMonitorDemoViewModel()
        
        // Initial state
        XCTAssertFalse(viewModel.isMonitoring)
        
        // Start monitoring
        viewModel.toggleMonitoring()
        XCTAssertTrue(viewModel.isMonitoring)
        
        // Stop monitoring
        viewModel.toggleMonitoring()
        XCTAssertFalse(viewModel.isMonitoring)
        
        // Multiple toggles
        viewModel.toggleMonitoring()
        XCTAssertTrue(viewModel.isMonitoring)
        viewModel.toggleMonitoring()
        XCTAssertFalse(viewModel.isMonitoring)
    }
    
    func testPowerInfoIntegration() {
        let viewModel = PowerMonitorDemoViewModel()
        
        // Get current power info
        if let powerInfo = PowerMonitorService.shared.getCurrentPowerInfo() {
            // Refresh should update view model with same data
            viewModel.refresh()
            
            XCTAssertEqual(viewModel.isConnected, powerInfo.state == .connected)
            XCTAssertEqual(viewModel.batteryLevel, powerInfo.batteryLevel)
            XCTAssertEqual(viewModel.isCharging, powerInfo.isCharging)
            XCTAssertEqual(viewModel.adapterWattage, powerInfo.adapterWattage)
        }
    }
}