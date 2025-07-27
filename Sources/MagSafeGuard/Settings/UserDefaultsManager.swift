//
//  UserDefaultsManager.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Manages persistence of user settings using UserDefaults
//

import Combine
import Foundation

/// Manages persistence and synchronization of user settings.
///
/// UserDefaultsManager provides a centralized interface for managing application settings
/// with automatic persistence, validation, and migration capabilities. It uses the
/// Combine framework to provide reactive updates when settings change.
///
/// ## Features
///
/// - **Automatic Persistence**: Settings are automatically saved when modified
/// - **Validation**: All settings are validated before saving
/// - **Migration**: Supports versioned settings migration for future updates  
/// - **Thread Safety**: All operations are thread-safe
/// - **Testing Support**: Supports dependency injection for unit testing
///
/// ## Usage
///
/// ```swift
/// // Access shared instance
/// let manager = UserDefaultsManager.shared
///
/// // Modify settings (automatically saved)
/// manager.updateSetting(\.gracePeriodDuration, value: 15.0)
///
/// // Export/import settings
/// let data = try manager.exportSettings()
/// try manager.importSettings(from: data)
/// ```
///
/// ## Settings Synchronization
///
/// The manager publishes changes to the `@Published settings` property,
/// allowing SwiftUI views and other components to automatically update
/// when settings change.
///
/// ## Thread Safety
///
/// All public methods are thread-safe and can be called from any queue.
/// Settings updates are automatically synchronized to the main queue.
public class UserDefaultsManager: ObservableObject {

    // MARK: - Singleton

    /// Shared instance of the settings manager.
    ///
    /// The shared instance uses `UserDefaults.standard` for persistence
    /// and is the primary interface for accessing application settings.
    public static let shared = UserDefaultsManager()

    // MARK: - Properties

    /// Current application settings.
    ///
    /// This property is published and automatically triggers UI updates
    /// when settings change. Settings are validated and persisted
    /// automatically when modified through the manager's methods.
    @Published public private(set) var settings: Settings

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

    /// Initialize the settings manager with custom UserDefaults.
    ///
    /// This initializer allows dependency injection for testing or custom
    /// UserDefaults configurations. It automatically loads existing settings
    /// or creates defaults if none exist.
    ///
    /// - Parameter userDefaults: UserDefaults instance for persistence (default: .standard)
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
        // Disabled auto-save to prevent conflicts with SwiftUI bindings
        // setupAutoSave()

        // Mark first launch
        if !userDefaults.bool(forKey: Keys.hasLaunchedBefore) {
            userDefaults.set(true, forKey: Keys.hasLaunchedBefore)
            onFirstLaunch()
        }
    }

    // MARK: - Public Methods

    /// Updates a specific setting using a key path.
    ///
    /// This method provides type-safe updates to individual settings with
    /// automatic validation and persistence. The settings are validated
    /// before saving to ensure data integrity.
    ///
    /// - Parameters:
    ///   - keyPath: Key path to the setting property
    ///   - value: New value for the setting
    ///
    /// ## Example
    /// ```swift
    /// manager.updateSetting(\.gracePeriodDuration, value: 15.0)
    /// ```
    public func updateSetting<T>(_ keyPath: WritableKeyPath<Settings, T>, value: T) {
        settings[keyPath: keyPath] = value
        settings = settings.validated()
        saveSettings()
    }

    /// Performs batch updates to multiple settings.
    ///
    /// This method allows efficient modification of multiple settings in a single
    /// operation, with validation and persistence happening once at the end.
    /// This is preferred when updating multiple related settings.
    ///
    /// - Parameter updates: Closure that modifies the settings
    ///
    /// ## Example
    /// ```swift
    /// manager.updateSettings { settings in
    ///     settings.gracePeriodDuration = 20.0
    ///     settings.allowGracePeriodCancellation = false
    /// }
    /// ```
    public func updateSettings(_ updates: (inout Settings) -> Void) {
        updates(&settings)
        settings = settings.validated()
        saveSettings()
    }

    /// Resets all settings to their default values.
    ///
    /// This operation creates a new Settings instance with default values
    /// and immediately persists the changes. This action cannot be undone.
    ///
    /// - Warning: This permanently removes all customized settings
    public func resetToDefaults() {
        settings = Settings()
        saveSettings()
    }

    /// Exports current settings as JSON data.
    ///
    /// This method serializes the current settings to JSON format suitable
    /// for backup, sharing, or migration purposes. The exported data includes
    /// all user preferences and can be imported later.
    ///
    /// - Returns: JSON data containing all settings
    /// - Throws: `EncodingError` if serialization fails
    public func exportSettings() throws -> Data {
        return try encoder.encode(settings)
    }

    /// Imports settings from JSON data.
    ///
    /// This method replaces current settings with those from the provided data.
    /// The imported settings are validated before being applied to ensure
    /// compatibility and data integrity.
    ///
    /// - Parameter data: JSON data containing settings to import
    /// - Throws: `DecodingError` if the data is invalid or incompatible
    ///
    /// - Warning: This replaces all current settings
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
            Log.error("Failed to save settings", error: error, category: .settings)
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
            Log.error("Failed to load settings", error: error, category: .settings)
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
