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
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @StateObject private var syncService = SyncServiceFactory.create() ?? SyncService()
  @State private var isSyncing = false
  @State private var showingError = false
  @State private var errorMessage = ""

  var body: some View {
    Form {
      enableSection
      statusSection
      syncSection
      limitsSection
      dataSection
    }
    .formStyle(.grouped)
    .alert("Sync Error", isPresented: $showingError) {
      Button("OK", role: .cancel) {
        // Dismisses alert automatically
      }
    } message: {
      Text(errorMessage)
    }
  }

  private var statusSection: some View {
    Section(header: Label("iCloud Status", systemImage: "cloud")) {
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
    Section(header: Label("Sync Actions", systemImage: "arrow.triangle.2.circlepath")) {
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

        Spacer()
      }

      Text("Manually sync all settings and evidence to iCloud")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .disabled(!settingsManager.settings.iCloudSyncEnabled)
    .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
  }

  private var dataSection: some View {
    Section(header: Label("Synced Data", systemImage: "externaldrive.badge.icloud")) {
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
    .disabled(!settingsManager.settings.iCloudSyncEnabled)
    .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
  }

  private var enableSection: some View {
    Section(header: Label("Enable iCloud Sync", systemImage: "icloud.and.arrow.up")) {
      Toggle(
        isOn: Binding(
          get: { settingsManager.settings.iCloudSyncEnabled },
          set: { settingsManager.updateSetting(\.iCloudSyncEnabled, value: $0) }
        )
      ) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Enable iCloud Sync")
          Text("Sync settings and evidence to iCloud")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .onChange(of: settingsManager.settings.iCloudSyncEnabled) { _, newValue in
        if newValue {
          // Enable CloudKit sync
          syncService.enableSync()

          // Trigger initial sync after a short delay
          Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
            try? await syncService.syncAll()
          }
        } else {
          // Disable CloudKit sync
          syncService.disableSync()
        }
      }
    }
  }

  private var limitsSection: some View {
    Section(header: Label("Storage Limits", systemImage: "internaldrive")) {
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
    .disabled(!settingsManager.settings.iCloudSyncEnabled)
    .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
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

  private func performManualSync() {
    isSyncing = true

    Task {
      do {
        try await syncService.syncAll()
      } catch {
        errorMessage = error.localizedDescription
        showingError = true
      }
      isSyncing = false
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
