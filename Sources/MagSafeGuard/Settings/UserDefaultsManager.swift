//
//  UserDefaultsManager.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Manages persistence of user settings using UserDefaults
//

import Foundation
import Combine

/// Manager for persisting and retrieving user settings
public class UserDefaultsManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = UserDefaultsManager()
    
    // MARK: - Properties
    
    @Published public var settings: Settings
    
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    
    private enum Keys {
        static let settings = "com.magsafeguard.settings"
        static let settingsVersion = "com.magsafeguard.settings.version"
        static let hasLaunchedBefore = "com.magsafeguard.hasLaunchedBefore"
    }
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Load settings or create defaults
        if let loadedSettings = Self.loadSettings(from: userDefaults) {
            self.settings = loadedSettings
        } else {
            self.settings = Settings()
            self.saveSettings()
        }
        
        // Set up auto-save on changes
        setupAutoSave()
        
        // Mark first launch
        if !userDefaults.bool(forKey: Keys.hasLaunchedBefore) {
            userDefaults.set(true, forKey: Keys.hasLaunchedBefore)
            onFirstLaunch()
        }
    }
    
    // MARK: - Public Methods
    
    /// Updates a specific setting value
    public func updateSetting<T>(_ keyPath: WritableKeyPath<Settings, T>, value: T) {
        settings[keyPath: keyPath] = value
        settings = settings.validated()
        saveSettings()
    }
    
    /// Batch update settings
    public func updateSettings(_ updates: (inout Settings) -> Void) {
        updates(&settings)
        settings = settings.validated()
        saveSettings()
    }
    
    /// Resets all settings to defaults
    public func resetToDefaults() {
        settings = Settings()
        saveSettings()
    }
    
    /// Exports settings to data
    public func exportSettings() throws -> Data {
        return try encoder.encode(settings)
    }
    
    /// Imports settings from data
    public func importSettings(from data: Data) throws {
        let imported = try decoder.decode(Settings.self, from: data)
        settings = imported.validated()
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    private func setupAutoSave() {
        // Auto-save when settings change
        $settings
            .dropFirst() // Skip initial value
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    private func saveSettings() {
        do {
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: Keys.settings)
            userDefaults.set(currentSettingsVersion, forKey: Keys.settingsVersion)
        } catch {
            print("[UserDefaultsManager] Failed to save settings: \(error)")
        }
    }
    
    private static func loadSettings(from userDefaults: UserDefaults) -> Settings? {
        guard let data = userDefaults.data(forKey: Keys.settings) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            var settings = try decoder.decode(Settings.self, from: data)
            
            // Apply any necessary migrations
            let savedVersion = userDefaults.integer(forKey: Keys.settingsVersion)
            if savedVersion < currentSettingsVersion {
                settings = migrateSettings(settings, from: savedVersion)
            }
            
            return settings.validated()
        } catch {
            print("[UserDefaultsManager] Failed to load settings: \(error)")
            return nil
        }
    }
    
    private static func migrateSettings(_ settings: Settings, from version: Int) -> Settings {
        // Placeholder for future migrations
        // When settings format changes, implement migration logic here
        return settings
    }
    
    private func onFirstLaunch() {
        // Set sensible defaults for first launch
        updateSettings { settings in
            settings.showStatusNotifications = true
            settings.playCriticalAlertSound = true
            settings.gracePeriodDuration = 10.0
            settings.securityActions = [.lockScreen, .unmountVolumes]
        }
    }
}

// MARK: - Convenience Extensions

extension UserDefaultsManager {
    
    /// Quick access to grace period duration
    public var gracePeriodDuration: TimeInterval {
        get { settings.gracePeriodDuration }
        set { updateSetting(\.gracePeriodDuration, value: newValue) }
    }
    
    /// Quick access to security actions
    public var securityActions: [SecurityActionType] {
        get { settings.securityActions }
        set { updateSetting(\.securityActions, value: newValue) }
    }
    
    /// Quick access to launch at login
    public var launchAtLogin: Bool {
        get { settings.launchAtLogin }
        set { updateSetting(\.launchAtLogin, value: newValue) }
    }
    
    /// Quick access to auto-arm enabled
    public var autoArmEnabled: Bool {
        get { settings.autoArmEnabled }
        set { updateSetting(\.autoArmEnabled, value: newValue) }
    }
}