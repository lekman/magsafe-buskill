//
//  PowerMonitorDemoView.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import SwiftUI

/// Demo view for testing PowerMonitorService
struct PowerMonitorDemoView: View {
    @StateObject private var viewModel = PowerMonitorDemoViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Power Monitor Demo")
                .font(.largeTitle)
                .padding()
            
            // Power State
            HStack {
                Image(systemName: viewModel.isConnected ? "bolt.fill" : "bolt.slash")
                    .foregroundColor(viewModel.isConnected ? .green : .red)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading) {
                    Text("Power State: \(viewModel.powerState)")
                        .font(.headline)
                    Text("Last Update: \(viewModel.lastUpdate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Battery Info
            if let batteryLevel = viewModel.batteryLevel {
                VStack {
                    Text("Battery Level: \(batteryLevel)%")
                        .font(.headline)
                    
                    ProgressView(value: Double(batteryLevel), total: 100)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                    
                    if viewModel.isCharging {
                        Label("Charging", systemImage: "battery.100.bolt")
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
            
            // Adapter Info
            if let wattage = viewModel.adapterWattage {
                Text("Adapter: \(wattage)W")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Control Buttons
            HStack {
                Button(viewModel.isMonitoring ? "Stop Monitoring" : "Start Monitoring") {
                    viewModel.toggleMonitoring()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Refresh") {
                    viewModel.refresh()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            // Instructions
            Text("Unplug and replug your power adapter to test detection")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .frame(width: 400, height: 500)
        .padding()
    }
}

class PowerMonitorDemoViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var powerState = "Unknown"
    @Published var batteryLevel: Int?
    @Published var isCharging = false
    @Published var adapterWattage: Int?
    @Published var lastUpdate = "Never"
    @Published var isMonitoring = false
    
    private let powerMonitor = PowerMonitorService.shared
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
    
    init() {
        refresh()
    }
    
    func toggleMonitoring() {
        if isMonitoring {
            powerMonitor.stopMonitoring()
            isMonitoring = false
        } else {
            powerMonitor.startMonitoring { [weak self] powerInfo in
                self?.updateUI(with: powerInfo)
            }
            isMonitoring = true
        }
    }
    
    func refresh() {
        if let powerInfo = powerMonitor.getCurrentPowerInfo() {
            updateUI(with: powerInfo)
        }
    }
    
    private func updateUI(with powerInfo: PowerMonitorService.PowerInfo) {
        isConnected = powerInfo.state == .connected
        powerState = powerInfo.state.description
        batteryLevel = powerInfo.batteryLevel
        isCharging = powerInfo.isCharging
        adapterWattage = powerInfo.adapterWattage
        lastUpdate = dateFormatter.string(from: powerInfo.timestamp)
    }
}