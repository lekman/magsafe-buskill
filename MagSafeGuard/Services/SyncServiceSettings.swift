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
        Log.info("Syncing settings to iCloud", category: .sync)

        let settings = UserDefaultsManager.shared.settings
        let record = try await fetchOrCreateSettingsRecord()

        // Update record with current settings
        record["gracePeriodDuration"] = settings.gracePeriodDuration
        record["cancelGracePeriodOnReconnect"] = settings.cancelGracePeriodOnReconnect ? 1 : 0
        record["lockScreen"] = settings.lockScreen ? 1 : 0
        record["shutDown"] = settings.shutDown ? 1 : 0
        record["unmountDisks"] = settings.unmountDisks ? 1 : 0
        record["quitApps"] = settings.quitApps ? 1 : 0
        record["takeScreenshot"] = settings.takeScreenshot ? 1 : 0
        record["showNotification"] = settings.showNotification ? 1 : 0
        record["customCommand"] = settings.customCommand
        record["customCommandEnabled"] = settings.customCommandEnabled ? 1 : 0
        record["actionDelay"] = settings.actionDelay
        record["soundEnabled"] = settings.soundEnabled ? 1 : 0
        record["soundVolume"] = settings.soundVolume
        record["soundDuration"] = settings.soundDuration
        record["soundFrequency"] = settings.soundFrequency
        record["autoArmEnabled"] = settings.autoArmEnabled ? 1 : 0
        record["autoArmByLocation"] = settings.autoArmByLocation ? 1 : 0
        record["autoArmByNetwork"] = settings.autoArmByNetwork ? 1 : 0
        record["autoArmByBluetooth"] = settings.autoArmByBluetooth ? 1 : 0
        record["autoArmByCalendar"] = settings.autoArmByCalendar ? 1 : 0
        record["autoArmDelay"] = settings.autoArmDelay
        record["logSecurityEvents"] = settings.logSecurityEvents ? 1 : 0
        record["collectScreenshotEvidence"] = settings.collectScreenshotEvidence ? 1 : 0
        record["collectWebcamEvidence"] = settings.collectWebcamEvidence ? 1 : 0
        record["collectLocationEvidence"] = settings.collectLocationEvidence ? 1 : 0
        record["collectSystemInfoEvidence"] = settings.collectSystemInfoEvidence ? 1 : 0
        record["cloudSyncEnabled"] = settings.cloudSyncEnabled ? 1 : 0
        record["lastModified"] = Date()

        // Save to CloudKit
        try await database.save(record)
        Log.info("Settings synced successfully", category: .sync)
    }

    /// Download settings from iCloud
    func downloadSettings() async throws {
        Log.info("Downloading settings from iCloud", category: .sync)

        do {
            let record = try await database.record(for: settingsRecordID)
            applySettingsFromRecord(record)
            Log.info("Settings downloaded successfully", category: .sync)
        } catch let error as CKError where error.code == .unknownItem {
            // No settings in cloud yet, use local settings
            Log.info("No cloud settings found, using local settings", category: .sync)
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
        
        // Apply string settings
        if let value = record["customCommand"] as? String {
            manager.updateSetting(\.customCommand, value: value)
        }
    }
    
    private func applyNumericSettings(from record: CKRecord, to manager: UserDefaultsManager) {
        let numericMappings: [(key: String, keyPath: WritableKeyPath<Settings, Double>)] = [
            ("gracePeriodDuration", \.gracePeriodDuration),
            ("actionDelay", \.actionDelay),
            ("soundVolume", \.soundVolume),
            ("soundDuration", \.soundDuration),
            ("soundFrequency", \.soundFrequency),
            ("autoArmDelay", \.autoArmDelay)
        ]
        
        for mapping in numericMappings {
            if let value = record[mapping.key] as? Double {
                manager.updateSetting(mapping.keyPath, value: value)
            }
        }
    }
    
    private func applyBooleanSettings(from record: CKRecord, to manager: UserDefaultsManager) {
        let booleanMappings: [(key: String, keyPath: WritableKeyPath<Settings, Bool>)] = [
            ("cancelGracePeriodOnReconnect", \.cancelGracePeriodOnReconnect),
            ("lockScreen", \.lockScreen),
            ("shutDown", \.shutDown),
            ("unmountDisks", \.unmountDisks),
            ("quitApps", \.quitApps),
            ("takeScreenshot", \.takeScreenshot),
            ("showNotification", \.showNotification),
            ("customCommandEnabled", \.customCommandEnabled),
            ("soundEnabled", \.soundEnabled),
            ("autoArmEnabled", \.autoArmEnabled),
            ("autoArmByLocation", \.autoArmByLocation),
            ("autoArmByNetwork", \.autoArmByNetwork),
            ("autoArmByBluetooth", \.autoArmByBluetooth),
            ("autoArmByCalendar", \.autoArmByCalendar),
            ("logSecurityEvents", \.logSecurityEvents),
            ("collectScreenshotEvidence", \.collectScreenshotEvidence),
            ("collectWebcamEvidence", \.collectWebcamEvidence),
            ("collectLocationEvidence", \.collectLocationEvidence),
            ("collectSystemInfoEvidence", \.collectSystemInfoEvidence),
            ("cloudSyncEnabled", \.cloudSyncEnabled)
        ]
        
        for mapping in booleanMappings {
            if let value = record[mapping.key] as? Int {
                manager.updateSetting(mapping.keyPath, value: value == 1)
            }
        }
    }
}
