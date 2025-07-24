//
//  ContentView.swift
//  MagSafe Guard
//
//  Created on 2025-07-24.
//

import SwiftUI

struct ContentView: View {
    @State private var isArmed = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status
            HStack {
                Image(systemName: isArmed ? "lock.shield.fill" : "lock.shield")
                    .font(.system(size: 40))
                    .foregroundColor(isArmed ? .red : .green)
                
                VStack(alignment: .leading) {
                    Text("MagSafe Guard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(isArmed ? "Armed - Protection Active" : "Disarmed - No Protection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Arm/Disarm Button
            Button(action: toggleArmedState) {
                Label(isArmed ? "Disarm" : "Arm", systemImage: isArmed ? "lock.open" : "lock")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(isArmed ? .red : .green)
            
            Divider()
            
            // Quick Actions
            HStack {
                Button("Settings") {
                    // TODO: Open settings
                }
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(width: 300)
    }
    
    private func toggleArmedState() {
        // TODO: Implement authentication
        isArmed.toggle()
    }
}