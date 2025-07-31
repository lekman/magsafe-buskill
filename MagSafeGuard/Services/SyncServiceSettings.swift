//
//  SyncServiceSettings.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//

import CloudKit
import Foundation

/// Handles settings synchronization with CloudKit
final class SyncServiceSettings {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "Settings"
    private let settingsRecordID = CKRecord.ID(recordName: "UserSettings")

    init(container: CKContainer) {
        self.container = container
        self.database = container.privateCloudDatabase
    }

    /// Sync settings to iCloud
    func syncSettings() async throws {
        Log.info("Syncing settings to iCloud", category: .general)

        let settings = UserDefaultsManager.shared.settings
        let record = try await fetchOrCreateSettingsRecord()

        // Update record with current settings
        record["gracePeriodDuration"] = settings.gracePeriodDuration
        record["allowGracePeriodCancellation"] = settings.allowGracePeriodCancellation ? 1 : 0

        // Encode security actions as a comma-separated string
        let actionsString = settings.securityActions.map { $0.rawValue }.joined(separator: ",")
        record["securityActions"] = actionsString

        // Auto-arm settings
        record["autoArmEnabled"] = settings.autoArmEnabled ? 1 : 0
        record["autoArmByLocation"] = settings.autoArmByLocation ? 1 : 0
        record["autoArmOnUntrustedNetwork"] = settings.autoArmOnUntrustedNetwork ? 1 : 0

        // Encode trusted networks as JSON
        if let trustedNetworksData = try? JSONEncoder().encode(settings.trustedNetworks) {
            record["trustedNetworks"] = String(data: trustedNetworksData, encoding: .utf8)
        }

        // Notification settings
        record["showStatusNotifications"] = settings.showStatusNotifications ? 1 : 0
        record["playCriticalAlertSound"] = settings.playCriticalAlertSound ? 1 : 0

        // General settings
        record["launchAtLogin"] = settings.launchAtLogin ? 1 : 0
        record["showInDock"] = settings.showInDock ? 1 : 0

        // Advanced settings
        if let customScriptsData = try? JSONEncoder().encode(settings.customScripts) {
            record["customScripts"] = String(data: customScriptsData, encoding: .utf8)
        }
        record["debugLoggingEnabled"] = settings.debugLoggingEnabled ? 1 : 0

        // Cloud sync settings
        record["iCloudSyncEnabled"] = settings.iCloudSyncEnabled ? 1 : 0
        record["iCloudDataLimitMB"] = settings.iCloudDataLimitMB
        record["iCloudDataAgeLimitDays"] = settings.iCloudDataAgeLimitDays

        record["lastModified"] = Date()

        // Save to CloudKit
        try await database.save(record)
        Log.info("Settings synced successfully", category: .general)
    }

    /// Download settings from iCloud
    func downloadSettings() async throws {
        Log.info("Downloading settings from iCloud", category: .general)

        do {
            let record = try await database.record(for: settingsRecordID)
            applySettingsFromRecord(record)
            Log.info("Settings downloaded successfully", category: .general)
        } catch let error as CKError where error.code == .unknownItem {
            // No settings in cloud yet, use local settings
            Log.info("No cloud settings found, using local settings", category: .general)
        }
    }

    // MARK: - Private Methods

    private func fetchOrCreateSettingsRecord() async throws -> CKRecord {
        do {
            return try await database.record(for: settingsRecordID)
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, create it
            return CKRecord(recordType: recordType, recordID: settingsRecordID)
        }
    }

    private func applySettingsFromRecord(_ record: CKRecord) {
        let manager = UserDefaultsManager.shared

        // Apply numeric settings
        applyNumericSettings(from: record, to: manager)

        // Apply boolean settings
        applyBooleanSettings(from: record, to: manager)

        // Apply complex settings
        applyComplexSettings(from: record, to: manager)
    }

    private func applyNumericSettings(from record: CKRecord, to manager: UserDefaultsManager) {
        let numericMappings: [(key: String, keyPath: WritableKeyPath<Settings, TimeInterval>)] = [
            ("gracePeriodDuration", \.gracePeriodDuration)
        ]

        for mapping in numericMappings {
            if let value = record[mapping.key] as? TimeInterval {
                manager.updateSetting(mapping.keyPath, value: value)
            }
        }

        // Apply Double settings
        let doubleMappings: [(key: String, keyPath: WritableKeyPath<Settings, Double>)] = [
            ("iCloudDataLimitMB", \.iCloudDataLimitMB),
            ("iCloudDataAgeLimitDays", \.iCloudDataAgeLimitDays)
        ]

        for mapping in doubleMappings {
            if let value = record[mapping.key] as? Double {
                manager.updateSetting(mapping.keyPath, value: value)
            }
        }
    }

    private func applyBooleanSettings(from record: CKRecord, to manager: UserDefaultsManager) {
        let booleanMappings: [(key: String, keyPath: WritableKeyPath<Settings, Bool>)] = [
            ("allowGracePeriodCancellation", \.allowGracePeriodCancellation),
            ("autoArmEnabled", \.autoArmEnabled),
            ("autoArmByLocation", \.autoArmByLocation),
            ("autoArmOnUntrustedNetwork", \.autoArmOnUntrustedNetwork),
            ("showStatusNotifications", \.showStatusNotifications),
            ("playCriticalAlertSound", \.playCriticalAlertSound),
            ("launchAtLogin", \.launchAtLogin),
            ("showInDock", \.showInDock),
            ("debugLoggingEnabled", \.debugLoggingEnabled),
            ("iCloudSyncEnabled", \.iCloudSyncEnabled)
        ]

        for mapping in booleanMappings {
            if let value = record[mapping.key] as? Int {
                manager.updateSetting(mapping.keyPath, value: value == 1)
            }
        }
    }

    private func applyComplexSettings(from record: CKRecord, to manager: UserDefaultsManager) {
        // Decode security actions
        if let actionsString = record["securityActions"] as? String {
            let actionStrings = actionsString.split(separator: ",").map { String($0) }
            let actions = actionStrings.compactMap { SecurityActionType(rawValue: $0) }
            if !actions.isEmpty {
                manager.updateSetting(\.securityActions, value: actions)
            }
        }

        // Decode trusted networks
        if let trustedNetworksString = record["trustedNetworks"] as? String,
           let data = trustedNetworksString.data(using: .utf8),
           let networks = try? JSONDecoder().decode([String].self, from: data) {
            manager.updateSetting(\.trustedNetworks, value: networks)
        }

        // Decode custom scripts
        if let customScriptsString = record["customScripts"] as? String,
           let data = customScriptsString.data(using: .utf8),
           let scripts = try? JSONDecoder().decode([String].self, from: data) {
            manager.updateSetting(\.customScripts, value: scripts)
        }
    }
}
