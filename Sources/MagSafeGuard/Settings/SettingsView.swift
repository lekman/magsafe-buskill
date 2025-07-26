//
//  SettingsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Main settings window UI using SwiftUI
//

import SwiftUI

/// Main settings view with tabbed interface
public struct SettingsView: View {
    @StateObject private var settingsManager = UserDefaultsManager.shared
    @State private var selectedTab = SettingsTab.general

    private enum SettingsTab: String, CaseIterable {
        case general = "General"
        case security = "Security"
        case autoArm = "Auto-Arm"
        case notifications = "Notifications"
        case advanced = "Advanced"

        var symbolName: String {
            switch self {
            case .general:
                return "gear"
            case .security:
                return "lock.shield"
            case .autoArm:
                return "location.fill"
            case .notifications:
                return "bell.badge"
            case .advanced:
                return "wrench.and.screwdriver"
            }
        }
    }

    /// The main view body containing the tabbed settings interface
    public var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label(
                        SettingsTab.general.rawValue,
                        systemImage: SettingsTab.general.symbolName
                    )
                }
                .tag(SettingsTab.general)

            SecuritySettingsView()
                .tabItem {
                    Label(
                        SettingsTab.security.rawValue,
                        systemImage: SettingsTab.security.symbolName
                    )
                }
                .tag(SettingsTab.security)

            AutoArmSettingsView()
                .tabItem {
                    Label(
                        SettingsTab.autoArm.rawValue,
                        systemImage: SettingsTab.autoArm.symbolName
                    )
                }
                .tag(SettingsTab.autoArm)

            NotificationSettingsView()
                .tabItem {
                    Label(
                        SettingsTab.notifications.rawValue,
                        systemImage: SettingsTab.notifications.symbolName
                    )
                }
                .tag(SettingsTab.notifications)

            AdvancedSettingsView()
                .tabItem {
                    Label(
                        SettingsTab.advanced.rawValue,
                        systemImage: SettingsTab.advanced.symbolName
                    )
                }
                .tag(SettingsTab.advanced)
        }
        .frame(width: 600, height: 400)
        .environmentObject(settingsManager)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: UserDefaultsManager

    var body: some View {
        Form {
            Section {
                generalSettingsContent
            }
        }
        .formStyle(.grouped)
    }

    private var generalSettingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            gracePeriodSection

            Divider()

            allowCancellationToggle

            Divider()

            launchAtLoginToggle

            showInDockToggle
        }
        .padding()
    }

    private var gracePeriodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grace Period Duration")
                .font(.headline)

            gracePeriodSlider

            Text("Time before security actions execute after power disconnection")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var gracePeriodSlider: some View {
        HStack {
            Text("5s")
                .font(.caption)
                .foregroundColor(.secondary)

            Slider(
                value: $settingsManager.settings.gracePeriodDuration,
                in: 5...30,
                step: 1
            )

            Text("30s")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(settingsManager.settings.gracePeriodDuration))s")
                .font(.system(.body, design: .monospaced))
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var allowCancellationToggle: some View {
        Toggle(isOn: $settingsManager.settings.allowGracePeriodCancellation) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Allow Grace Period Cancellation")
                Text("Permits canceling security actions during grace period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("with authentication")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var launchAtLoginToggle: some View {
        Toggle(isOn: $settingsManager.settings.launchAtLogin) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Launch at Login")
                Text("Automatically start MagSafe Guard when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: settingsManager.settings.launchAtLogin) { newValue in
            // TODO: Implement launch at login functionality
            print("[Settings] Launch at login: \(newValue)")
        }
    }

    private var showInDockToggle: some View {
        Toggle(isOn: $settingsManager.settings.showInDock) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Show in Dock")
                Text("Display application icon in dock (requires restart)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Security Settings Tab

struct SecuritySettingsView: View {
    @EnvironmentObject var settingsManager: UserDefaultsManager
    @State private var selectedActions = Set<SecurityActionType>()

    var body: some View {
        VStack(spacing: 0) {
            securityActionsHeader

            Divider()

            // Action List
            List {
                enabledActionsSection
                availableActionsSection
            }
            .listStyle(.inset)

            securityActionsFooter
        }
    }

    private var securityActionsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Security Actions")
                .font(.headline)
            Text("Select and order actions to execute when power is disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var enabledActionsSection: some View {
        ForEach(settingsManager.settings.securityActions, id: \.self) { action in
            SecurityActionRow(action: action, isEnabled: true)
        }
        .onMove(perform: moveSecurityActions)
    }

    private var availableActionsSection: some View {
        Section(header: Text("Available Actions")) {
            ForEach(availableActions, id: \.self) { action in
                availableActionRow(for: action)
            }
        }
    }

    @ViewBuilder
    private func availableActionRow(for action: SecurityActionType) -> some View {
        SecurityActionRow(action: action, isEnabled: false)
            .onTapGesture {
                addSecurityAction(action)
            }
    }

    private var securityActionsFooter: some View {
        HStack {
            Text("\(settingsManager.settings.securityActions.count) actions selected")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Reset to Defaults") {
                settingsManager.settings.securityActions = [.lockScreen, .unmountVolumes]
            }
            .buttonStyle(.link)
        }
        .padding()
    }

    private var availableActions: [SecurityActionType] {
        SecurityActionType.allCases.filter { action in
            !settingsManager.settings.securityActions.contains(action)
        }
    }

    private func moveSecurityActions(from source: IndexSet, to destination: Int) {
        settingsManager.settings.securityActions.move(
            fromOffsets: source,
            toOffset: destination
        )
    }

    private func addSecurityAction(_ action: SecurityActionType) {
        withAnimation {
            settingsManager.settings.securityActions.append(action)
        }
    }
}

struct SecurityActionRow: View {
    let action: SecurityActionType
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.symbolName)
                .font(.title3)
                .foregroundColor(isEnabled ? .accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.displayName)
                    .font(.body)
                    .foregroundColor(isEnabled ? .primary : .secondary)

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isEnabled {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "plus.circle")
                    .font(.body)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Auto-Arm Settings Tab

struct AutoArmSettingsView: View {
    @EnvironmentObject var settingsManager: UserDefaultsManager
    @State private var newNetwork = ""
    @State private var showingLocationManager = false
    @State private var showingAutoArmInfo = false

    var body: some View {
        Form {
            autoArmToggleSection
            autoArmTriggersSection
            trustedLocationsSection
            trustedNetworksSection
            autoArmStatusSection
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingLocationManager) {
            if let autoArmManager = getAutoArmManager() {
                TrustedLocationsView(autoArmManager: autoArmManager)
            }
        }
    }

    private var autoArmToggleSection: some View {
        Section {
            Toggle(isOn: $settingsManager.settings.autoArmEnabled) {
                autoArmToggleLabel
            }
            .padding(.vertical, 4)
        }
    }

    private var autoArmTriggersSection: some View {
        Section(header: Text("Auto-Arm Triggers")) {
            Toggle(isOn: $settingsManager.settings.autoArmByLocation) {
                locationBasedToggleLabel
            }
            .disabled(!settingsManager.settings.autoArmEnabled)

            Toggle(isOn: $settingsManager.settings.autoArmOnUntrustedNetwork) {
                untrustedNetworkToggleLabel
            }
            .disabled(!settingsManager.settings.autoArmEnabled)
        }
    }
    
    private var trustedLocationsSection: some View {
        Section(header: Text("Trusted Locations")) {
            Button(action: { showingLocationManager = true }) {
                HStack {
                    Image(systemName: "location.circle")
                        .foregroundColor(.accentColor)
                    Text("Manage Trusted Locations")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .disabled(!settingsManager.settings.autoArmEnabled || !settingsManager.settings.autoArmByLocation)
        }
    }

    private var trustedNetworksSection: some View {
        Section(header: Text("Trusted Networks")) {
            trustedNetworksContent
            addNetworkRow
        }
        .disabled(!settingsManager.settings.autoArmEnabled)
    }

    // MARK: - Computed Properties

    private var autoArmToggleLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Enable Auto-Arm")
            Text("Automatically arm protection based on location or network")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var locationBasedToggleLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Location-Based")
            Text("Arm when leaving trusted locations")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var untrustedNetworkToggleLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Network-Based")
            Text("Arm when not connected to trusted Wi-Fi networks")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var trustedNetworksContent: some View {
        if settingsManager.settings.trustedNetworks.isEmpty {
            Text("No trusted networks configured")
                .foregroundColor(.secondary)
                .italic()
        } else {
            trustedNetworksList
        }
    }

    private var addNetworkRow: some View {
        HStack {
            TextField("Network SSID", text: $newNetwork)
                .textFieldStyle(.roundedBorder)

            Button("Add") {
                addTrustedNetwork()
            }
            .disabled(newNetwork.isEmpty)
        }
    }

    private func addTrustedNetwork() {
        if !newNetwork.isEmpty {
            settingsManager.settings.trustedNetworks.append(newNetwork)
            newNetwork = ""
        }
    }

    private var trustedNetworksList: some View {
        ForEach(settingsManager.settings.trustedNetworks, id: \.self) { network in
            trustedNetworkRow(for: network)
        }
    }

    @ViewBuilder
    private func trustedNetworkRow(for network: String) -> some View {
        HStack {
            Image(systemName: "wifi")
                .foregroundColor(.secondary)
            Text(network)
            Spacer()
            Button(action: {
                removeTrustedNetwork(network)
            }, label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            })
            .buttonStyle(.plain)
        }
    }

    private func removeTrustedNetwork(_ network: String) {
        settingsManager.settings.trustedNetworks.removeAll { $0 == network }
    }
    
    private var autoArmStatusSection: some View {
        Section(header: Text("Auto-Arm Status")) {
            if let autoArmManager = getAutoArmManager() {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: autoArmManager.isAutoArmConditionMet ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundColor(autoArmManager.isAutoArmConditionMet ? .orange : .green)
                        Text(autoArmManager.statusSummary)
                            .font(.body)
                    }
                    
                    if autoArmManager.isTemporarilyDisabled {
                        Button("Cancel Temporary Disable") {
                            autoArmManager.cancelTemporaryDisable()
                        }
                        .buttonStyle(.link)
                    } else if settingsManager.settings.autoArmEnabled {
                        Button("Temporarily Disable (1 hour)") {
                            autoArmManager.temporarilyDisable(for: 3600)
                        }
                        .buttonStyle(.link)
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text("Auto-arm service not available")
                    .foregroundColor(.secondary)
            }
        }
        .disabled(!settingsManager.settings.autoArmEnabled)
    }
    
    private func getAutoArmManager() -> AutoArmManager? {
        // Get the AppController instance from the app delegate
        if let appDelegate = NSApp.delegate as? AppDelegate {
            return appDelegate.core.appController.getAutoArmManager()
        }
        return nil
    }
}

// MARK: - Notification Settings Tab

struct NotificationSettingsView: View {
    @EnvironmentObject var settingsManager: UserDefaultsManager

    var body: some View {
        Form {
            statusNotificationsSection
            alertSettingsSection
            systemSettingsSection
        }
        .formStyle(.grouped)
    }

    private var statusNotificationsSection: some View {
        Section(header: Text("Status Notifications")) {
            Toggle(isOn: $settingsManager.settings.showStatusNotifications) {
                statusNotificationToggleLabel
            }
        }
    }

    private var alertSettingsSection: some View {
        Section(header: Text("Alert Settings")) {
            Toggle(isOn: $settingsManager.settings.playCriticalAlertSound) {
                alertSoundToggleLabel
            }
        }
    }

    private var systemSettingsSection: some View {
        Section {
            systemSettingsContent
                .padding(.vertical, 4)
        }
    }

    private var statusNotificationToggleLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Show Status Changes")
            Text("Display notifications when protection is armed or disarmed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var alertSoundToggleLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Play Alert Sound")
            Text("Play sound for critical security alerts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var systemSettingsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            notificationPermissionsInfo

            Button("Open System Settings") {
                openSystemNotificationSettings()
            }
        }
    }

    private var notificationPermissionsInfo: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text("Notification permissions are managed in System Settings")
                .font(.caption)
        }
    }

    private func openSystemNotificationSettings() {
        let prefsURL = "x-apple.systempreferences:com.apple.preference.notifications"
        if let url = URL(string: prefsURL) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Advanced Settings Tab

struct AdvancedSettingsView: View {
    @EnvironmentObject var settingsManager: UserDefaultsManager
    @State private var showingExportSuccess = false
    @State private var showingImportDialog = false

    var body: some View {
        Form {
            customScriptsSection
            debugSection
            settingsManagementSection
        }
        .formStyle(.grouped)
        .alert("Settings Exported", isPresented: $showingExportSuccess, actions: {
            Button("OK", role: .cancel) {
                // No action needed - SwiftUI automatically dismisses the alert
                // when a button with .cancel role is tapped
            }
        }, message: {
            Text("Your settings have been exported successfully.")
        })
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: { result in
                handleImport(result)
            }
        )
    }

    private func exportSettings() {
        do {
            let data = try settingsManager.exportSettings()
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "MagSafeGuard-Settings.json"
            panel.allowedContentTypes = [.json]

            panel.begin { response in
                handleSavePanelResponse(
                    response: response,
                    data: data,
                    panel: panel
                )
            }
        } catch {
            print("[Settings] Export failed: \(error)")
        }
    }

    // MARK: - Computed Properties

    private var customScriptsSection: some View {
        Section(header: Text("Custom Scripts")) {
            customScriptsContent

            Button("Add Custom Script...") {
                addCustomScript()
            }
        }
    }

    private var debugSection: some View {
        Section(header: Text("Debug")) {
            Toggle(isOn: $settingsManager.settings.debugLoggingEnabled) {
                debugLoggingToggleLabel
            }
        }
    }

    private var settingsManagementSection: some View {
        Section(header: Text("Settings Management")) {
            settingsManagementButtons
        }
    }

    @ViewBuilder
    private var customScriptsContent: some View {
        if settingsManager.settings.customScripts.isEmpty {
            Text("No custom scripts configured")
                .foregroundColor(.secondary)
                .italic()
        } else {
            customScriptsList
        }
    }

    private var debugLoggingToggleLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Enable Debug Logging")
            Text("Log detailed information for troubleshooting")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var settingsManagementButtons: some View {
        HStack {
            Button("Export Settings...") {
                exportSettings()
            }

            Button("Import Settings...") {
                showingImportDialog = true
            }

            Spacer()

            Button("Reset All Settings") {
                settingsManager.resetToDefaults()
            }
            .foregroundColor(.red)
        }
    }

    private func addCustomScript() {
        // TODO: Implement file picker for scripts
        print("[Settings] Add custom script")
    }

    private var customScriptsList: some View {
        ForEach(settingsManager.settings.customScripts, id: \.self) { script in
            customScriptRow(for: script)
        }
    }

    @ViewBuilder
    private func customScriptRow(for script: String) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)
            Text(script)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button(action: {
                removeCustomScript(script)
            }, label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            })
            .buttonStyle(.plain)
        }
    }

    private func removeCustomScript(_ script: String) {
        settingsManager.settings.customScripts.removeAll { $0 == script }
    }

    private func handleSavePanelResponse(
        response: NSApplication.ModalResponse,
        data: Data,
        panel: NSSavePanel
    ) {
        if response == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                showingExportSuccess = true
            } catch {
                print("[Settings] Export failed: \(error)")
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                try settingsManager.importSettings(from: data)
            } catch {
                print("[Settings] Import failed: \(error)")
            }
        case .failure(let error):
            print("[Settings] Import cancelled: \(error)")
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
