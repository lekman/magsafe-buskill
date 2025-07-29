//
//  CloudSyncSettingsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Settings view for configuring iCloud sync features
//

import Combine
import SwiftUI

/// Settings view for iCloud sync configuration
struct CloudSyncSettingsView: View {
    @ObservedObject var settingsManager = UserDefaultsManager.shared
    // TEMPORARILY DISABLED: Comment out SyncService to debug startup crash
    // @StateObject private var syncService = SyncService()
    @State private var isSyncing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Temporary mock values while SyncService is disabled
    private let mockSyncStatus = SyncStatus.idle
    private let mockIsAvailable = false
    private let mockLastSyncDate: Date? = nil

    private var headerIcon: some View {
        Image(systemName: "icloud.fill")
            .font(.title2)
            .foregroundColor(.blue)
    }

    private var headerTitle: some View {
        Text("iCloud Sync Settings")
            .font(.title2)
            .fontWeight(.semibold)
    }

    private var headerContent: some View {
        HStack {
            headerIcon
            headerTitle
            Spacer()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                headerContent
                Text("Configure iCloud backup and synchronization")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Settings
            ScrollView {
                VStack(spacing: 20) {
                    enableSection
                    statusSection
                    syncSection
                    limitsSection
                    dataSection
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
        .alert("Sync Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                // Dismisses alert automatically
            }
        } message: {
            Text(errorMessage)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label("iCloud Status", systemImage: "cloud")
                .font(.headline)
            HStack {
                Label("Status", systemImage: mockSyncStatus.symbolName)
                Spacer()
                Text(mockSyncStatus.displayText)
                    .foregroundColor(statusColor)
                    .font(.caption)
            }

            if let lastSync = mockLastSyncDate {
                HStack {
                    Label("Last Sync", systemImage: "clock.fill")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !mockIsAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("iCloud not available")
                            .font(.subheadline)
                    }

                    Text(unavailabilityReason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label("Sync Actions", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                // Manual sync button
                HStack {
                    Button(action: performManualSync) {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(!mockIsAvailable || isSyncing)

                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.leading, 8)
                    }
                }

                Text("Manually sync all settings and evidence to iCloud")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .disabled(!settingsManager.settings.iCloudSyncEnabled)
        .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label("Synced Data", systemImage: "externaldrive.badge.icloud")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                // Settings sync
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.gray)
                    VStack(alignment: .leading) {
                        Text("Settings")
                            .font(.subheadline)
                        Text("All app preferences and configurations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Evidence sync
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Security Evidence")
                            .font(.subheadline)
                        Text("Photos and location data (encrypted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Storage info
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("End-to-End Encrypted")
                            .font(.subheadline)
                        Text("Your data is encrypted before upload")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .disabled(!settingsManager.settings.iCloudSyncEnabled)
        .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
    }

    private var enableSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label("Enable iCloud Sync", systemImage: "icloud.and.arrow.up")
                .font(.headline)

            // Enable toggle
            Toggle(isOn: Binding(
                get: { settingsManager.settings.iCloudSyncEnabled },
                set: { settingsManager.updateSetting(\.iCloudSyncEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable iCloud Sync")
                        .font(.system(size: 13))
                    Text("Sync settings and evidence to iCloud")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .onChange(of: settingsManager.settings.iCloudSyncEnabled) { newValue in
                if newValue {
                    // Trigger initial sync when enabled
                    Task {
                        // try? await syncService.syncAll()
                        // Temporarily disabled
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var limitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label("Storage Limits", systemImage: "internaldrive")
                .font(.headline)

            // Data size limit
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Maximum Storage")
                    Spacer()
                    Text("\(Int(settingsManager.settings.iCloudDataLimitMB)) MB")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { settingsManager.settings.iCloudDataLimitMB },
                        set: { settingsManager.updateSetting(\.iCloudDataLimitMB, value: $0) }
                    ),
                    in: 10...1000,
                    step: 10
                ) {
                    Text("Maximum storage in MB")
                } minimumValueLabel: {
                    Text("10")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("1000")
                        .font(.caption)
                }

                Text("Evidence exceeding this limit won't be synced")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Data age limit
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Data Retention")
                    Spacer()
                    Text("\(Int(settingsManager.settings.iCloudDataAgeLimitDays)) days")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { settingsManager.settings.iCloudDataAgeLimitDays },
                        set: { settingsManager.updateSetting(\.iCloudDataAgeLimitDays, value: $0) }
                    ),
                    in: 7...365,
                    step: 1
                ) {
                    Text("Data retention in days")
                } minimumValueLabel: {
                    Text("7")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("365")
                        .font(.caption)
                }

                Text("Evidence older than this will be removed from iCloud")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .disabled(!settingsManager.settings.iCloudSyncEnabled)
        .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
    }

    // MARK: - Helper Properties

    private var statusColor: Color {
        switch mockSyncStatus {
        case .idle:
            return .green
        case .syncing:
            return .blue
        case .error:
            return .red
        case .noAccount, .restricted, .temporarilyUnavailable:
            return .orange
        case .unknown:
            return .gray
        }
    }

    private var unavailabilityReason: String {
        switch mockSyncStatus {
        case .noAccount:
            return "Sign in to iCloud in System Preferences to enable sync"
        case .restricted:
            return "iCloud access is restricted by parental controls or device management"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again later"
        default:
            return "Check your iCloud settings and internet connection"
        }
    }

    // MARK: - Actions

    private func performManualSync() {
        isSyncing = true

        Task {
            do {
                // try await syncService.syncAll()
                // Temporarily disabled
                isSyncing = false
            } catch {
                isSyncing = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CloudSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CloudSyncSettingsView()
            .environmentObject(UserDefaultsManager.shared)
    }
}
#endif
