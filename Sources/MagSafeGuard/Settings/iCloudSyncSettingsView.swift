//
//  iCloudSyncSettingsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Settings view for configuring iCloud sync features
//

import Combine
import SwiftUI

/// Settings view for iCloud sync configuration
struct iCloudSyncSettingsView: View {
    @EnvironmentObject var settingsManager: UserDefaultsManager
    @StateObject private var syncService = iCloudSyncService()
    @State private var isSyncing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

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
            doneButton
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                headerContent
                Text("Sync your settings and evidence across all your devices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Settings
            Form {
                statusSection
                syncSection
                dataSection
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 450)
        .alert("Sync Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                // Dismisses alert automatically
            }
        } message: {
            Text(errorMessage)
        }
    }

    private var statusSection: some View {
        Section("iCloud Status") {
            HStack {
                Label("Status", systemImage: syncService.syncStatus.symbolName)
                Spacer()
                Text(syncService.syncStatus.displayText)
                    .foregroundColor(statusColor)
                    .font(.caption)
            }

            if let lastSync = syncService.lastSyncDate {
                HStack {
                    Label("Last Sync", systemImage: "clock.fill")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !syncService.isAvailable {
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
    }

    private var syncSection: some View {
        Section("Sync Actions") {
            VStack(alignment: .leading, spacing: 12) {
                // Manual sync button
                HStack {
                    Button(action: performManualSync) {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(!syncService.isAvailable || isSyncing)

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
    }

    private var dataSection: some View {
        Section("Synced Data") {
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
    }

    // MARK: - Helper Properties

    private var statusColor: Color {
        switch syncService.syncStatus {
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
        switch syncService.syncStatus {
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

    private var doneButton: some View {
        Button("Done") {
            dismiss()
        }
    }

    private func performManualSync() {
        isSyncing = true

        Task {
            do {
                try await syncService.syncAll()
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
struct iCloudSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudSyncSettingsView()
            .environmentObject(UserDefaultsManager.shared)
    }
}
#endif
