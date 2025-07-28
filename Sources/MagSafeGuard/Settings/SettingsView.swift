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
                .environmentObject(settingsManager)
                .tabItem {
                    Label(
                        SettingsTab.security.rawValue,
                        systemImage: SettingsTab.security.symbolName
                    )
                }
                .tag(SettingsTab.security)

            AutoArmSettingsView()
                .environmentObject(settingsManager)
                .tabItem {
                    Label(
                        SettingsTab.autoArm.rawValue,
                        systemImage: SettingsTab.autoArm.symbolName
                    )
                }
                .tag(SettingsTab.autoArm)

            NotificationSettingsView()
                .environmentObject(settingsManager)
                .tabItem {
                    Label(
                        SettingsTab.notifications.rawValue,
                        systemImage: SettingsTab.notifications.symbolName
                    )
                }
                .tag(SettingsTab.notifications)

            AdvancedSettingsView()
                .environmentObject(settingsManager)
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
            HStack {
                Text("Grace Period Duration")
                    .font(.headline)
                Spacer()
                Toggle("Immediate Action", isOn: Binding(
                    get: { settingsManager.settings.gracePeriodDuration == 0 },
                    set: { immediate in
                        if immediate {
                            settingsManager.updateSetting(\.gracePeriodDuration, value: 0)
                        } else {
                            settingsManager.updateSetting(\.gracePeriodDuration, value: 5)
                        }
                    }
                ))
                .toggleStyle(.checkbox)
            }

            gracePeriodSlider
                .disabled(settingsManager.settings.gracePeriodDuration == 0)
                .opacity(settingsManager.settings.gracePeriodDuration == 0 ? 0.5 : 1.0)

            Text(settingsManager.settings.gracePeriodDuration == 0
                ? "Security actions will execute immediately upon power disconnection"
                : "Time before security actions execute after power disconnection")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var gracePeriodSlider: some View {
        HStack {
            Text("0s")
                .font(.caption)
                .foregroundColor(.secondary)

            Slider(
                value: Binding(
                    get: { settingsManager.settings.gracePeriodDuration },
                    set: { settingsManager.updateSetting(\.gracePeriodDuration, value: $0) }
                ),
                in: 0...30,
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
        Toggle(isOn: Binding(
            get: { settingsManager.settings.allowGracePeriodCancellation },
            set: { settingsManager.updateSetting(\.allowGracePeriodCancellation, value: $0) }
        )) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Allow Grace Period Cancellation")
                Text("Permits canceling security actions during grace period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("by reconnecting MagSafe or authenticating to disarm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var launchAtLoginToggle: some View {
        Toggle(isOn: Binding(
            get: { settingsManager.settings.launchAtLogin },
            set: { settingsManager.updateSetting(\.launchAtLogin, value: $0) }
        )) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Launch at Login")
                Text("Automatically start MagSafe Guard when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var showInDockToggle: some View {
        Toggle(isOn: Binding(
            get: { settingsManager.settings.showInDock },
            set: { settingsManager.updateSetting(\.showInDock, value: $0) }
        )) {
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
    @State private var showingEvidenceSettings = false

    var body: some View {
        VStack(spacing: 0) {
            securityActionsHeader

            Divider()

            // Action List
            List {
                evidenceCollectionSection
                enabledActionsSection
                availableActionsSection
            }
            .listStyle(.inset)

            securityActionsFooter
        }
        .sheet(isPresented: $showingEvidenceSettings) {
            SecurityEvidenceSettingsView()
                .environmentObject(settingsManager)
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

    private var evidenceCollectionSection: some View {
        Section(header: Text("Evidence Collection")) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.orange)
                        Text("Evidence Collection")
                            .font(.headline)
                    }
                    Text("Capture location and photos when theft is detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: evidenceCollectionBinding)
                    .toggleStyle(.switch)
            }
            .padding(.vertical, 4)

            if settingsManager.settings.evidenceCollectionEnabled {
                Button("Configure Evidence Collection...") {
                    showingEvidenceSettings = true
                }
                .buttonStyle(.link)
            }
        }
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
                settingsManager.updateSetting(\.securityActions, value: [.lockScreen, .unmountVolumes])
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

    // MARK: - Bindings

    private var evidenceCollectionBinding: Binding<Bool> {
        Binding(
            get: { settingsManager.settings.evidenceCollectionEnabled },
            set: { settingsManager.updateSetting(\.evidenceCollectionEnabled, value: $0) }
        )
    }

    private func moveSecurityActions(from source: IndexSet, to destination: Int) {
        var actions = settingsManager.settings.securityActions
        actions.move(
            fromOffsets: source,
            toOffset: destination
        )
        settingsManager.updateSetting(\.securityActions, value: actions)
    }

    private func addSecurityAction(_ action: SecurityActionType) {
        withAnimation {
            var actions = settingsManager.settings.securityActions
            actions.append(action)
            settingsManager.updateSetting(\.securityActions, value: actions)
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
            Toggle(isOn: Binding(
                get: { settingsManager.settings.autoArmEnabled },
                set: { settingsManager.updateSetting(\.autoArmEnabled, value: $0) }
            )) {
                autoArmToggleLabel
            }
            .padding(.vertical, 4)
        }
    }

    private var autoArmTriggersSection: some View {
        Section(header: Text("Auto-Arm Triggers")) {
            Toggle(isOn: Binding(
                get: { settingsManager.settings.autoArmByLocation },
                set: { settingsManager.updateSetting(\.autoArmByLocation, value: $0) }
            )) {
                locationBasedToggleLabel
            }
            .disabled(!settingsManager.settings.autoArmEnabled)

            Toggle(isOn: Binding(
                get: { settingsManager.settings.autoArmOnUntrustedNetwork },
                set: { settingsManager.updateSetting(\.autoArmOnUntrustedNetwork, value: $0) }
            )) {
                untrustedNetworkToggleLabel
            }
            .disabled(!settingsManager.settings.autoArmEnabled)
        }
    }

    private var trustedLocationsSection: some View {
        Section(header: Text("Trusted Locations")) {
            Button {
                showingLocationManager = true
            } label: {
                trustedLocationsButtonLabel
            }
            .disabled(!settingsManager.settings.autoArmEnabled || !settingsManager.settings.autoArmByLocation)
        }
    }

    private var trustedLocationsButtonLabel: some View {
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
            var networks = settingsManager.settings.trustedNetworks
            networks.append(newNetwork)
            settingsManager.updateSetting(\.trustedNetworks, value: networks)
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
        var networks = settingsManager.settings.trustedNetworks
        networks.removeAll { $0 == network }
        settingsManager.updateSetting(\.trustedNetworks, value: networks)
    }

    private var autoArmStatusSection: some View {
        Section(header: Text("Auto-Arm Status")) {
            autoArmStatusContent
        }
        .disabled(!settingsManager.settings.autoArmEnabled)
    }

    @ViewBuilder
    private var autoArmStatusContent: some View {
        if let autoArmManager = getAutoArmManager() {
            VStack(alignment: .leading, spacing: 8) {
                autoArmStatusRow(autoArmManager)
                autoArmActionButton(autoArmManager)
            }
            .padding(.vertical, 4)
        } else {
            Text("Auto-arm service not available")
                .foregroundColor(.secondary)
        }
    }

    private func autoArmStatusRow(_ autoArmManager: AutoArmManager) -> some View {
        HStack {
            Image(systemName: autoArmManager.isAutoArmConditionMet ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(autoArmManager.isAutoArmConditionMet ? .orange : .green)
            Text(autoArmManager.statusSummary)
                .font(.body)
        }
    }

    @ViewBuilder
    private func autoArmActionButton(_ autoArmManager: AutoArmManager) -> some View {
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
            Toggle(isOn: Binding(
                get: { settingsManager.settings.showStatusNotifications },
                set: { settingsManager.updateSetting(\.showStatusNotifications, value: $0) }
            )) {
                statusNotificationToggleLabel
            }
        }
    }

    private var alertSettingsSection: some View {
        Section(header: Text("Alert Settings")) {
            Toggle(isOn: Binding(
                get: { settingsManager.settings.playCriticalAlertSound },
                set: { settingsManager.updateSetting(\.playCriticalAlertSound, value: $0) }
            )) {
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
            Log.error("Export failed", error: error, category: .settings)
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
            Toggle(isOn: Binding(
                get: { settingsManager.settings.debugLoggingEnabled },
                set: { settingsManager.updateSetting(\.debugLoggingEnabled, value: $0) }
            )) {
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
        Log.info("Add custom script", category: .settings)
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
        var scripts = settingsManager.settings.customScripts
        scripts.removeAll { $0 == script }
        settingsManager.updateSetting(\.customScripts, value: scripts)
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
                Log.error("Export failed", error: error, category: .settings)
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
                Log.error("Import failed", error: error, category: .settings)
            }
        case .failure(let error):
            Log.info("Import cancelled: \(error)", category: .settings)
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
