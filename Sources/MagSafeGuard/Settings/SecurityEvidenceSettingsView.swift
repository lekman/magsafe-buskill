//
//  SecurityEvidenceSettingsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-27.
//
//  Settings view for configuring evidence collection features
//

import AVFoundation
import CoreLocation
import SwiftUI

/// Settings view for evidence collection configuration
struct SecurityEvidenceSettingsView: View {
    @EnvironmentObject var settingsManager: UserDefaultsManager
    @State private var showingPermissionsAlert = false
    @State private var permissionType: PermissionType = .camera
    @State private var testInProgress = false
    @State private var testResult: String = ""
    @Environment(\.dismiss) private var dismiss

    private enum PermissionType {
        case camera
        case location

        var title: String {
            switch self {
            case .camera:
                return "Camera Permission Required"
            case .location:
                return "Location Permission Required"
            }
        }

        var message: String {
            switch self {
            case .camera:
                return "MagSafe Guard needs camera access to capture photos as evidence when theft is detected. This helps identify the thief."
            case .location:
                return "MagSafe Guard needs location access to track your device when theft is detected. This helps recover your device."
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Evidence Collection Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                }
                Text("Configure how evidence is collected and stored when theft is detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Settings
            Form {
                permissionsSection
                emailSection
                storageSection
                testSection
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 450)
        .alert(permissionType.title, isPresented: $showingPermissionsAlert) {
            Button("Open System Preferences") {
                openSystemPreferences()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionType.message)
        }
    }

    private var permissionsSection: some View {
        Section("Permissions") {
            // Camera Permission
            HStack {
                Label("Camera Access", systemImage: "camera.fill")
                Spacer()
                Text(cameraPermissionStatus)
                    .foregroundColor(cameraPermissionColor)
                    .font(.caption)
                if !hasCameraPermission {
                    Button("Request") {
                        requestCameraPermission()
                    }
                    .buttonStyle(.link)
                }
            }

            // Location Permission
            HStack {
                Label("Location Access", systemImage: "location.fill")
                Spacer()
                Text(locationPermissionStatus)
                    .foregroundColor(locationPermissionColor)
                    .font(.caption)
                if !hasLocationPermission {
                    Button("Request") {
                        requestLocationPermission()
                    }
                    .buttonStyle(.link)
                }
            }
        }
    }

    private var emailSection: some View {
        Section("Backup Email") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Email Address", text: Binding(
                    get: { settingsManager.settings.backupEmailAddress },
                    set: { settingsManager.updateSetting(\.backupEmailAddress, value: $0) }
                ))
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)

                Text("Evidence will be sent to this email when collected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var storageSection: some View {
        Section("Local Storage") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Evidence is encrypted before storage")
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text("Stored in: ~/Documents/Evidence/")
                        .font(.subheadline)
                }

                Button("View Evidence Folder") {
                    openEvidenceFolder()
                }
                .buttonStyle(.link)
            }
        }
    }

    private var testSection: some View {
        Section("Test") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Test evidence collection to ensure everything works correctly")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button("Test Evidence Collection") {
                        testEvidenceCollection()
                    }
                    .disabled(testInProgress || !settingsManager.settings.evidenceCollectionEnabled)

                    if testInProgress {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.leading, 8)
                    }
                }

                if !testResult.isEmpty {
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testResult.contains("Success") ? .green : .red)
                        .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Permission Status

    private var hasCameraPermission: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    private var cameraPermissionStatus: String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Granted"
        @unknown default:
            return "Unknown"
        }
    }

    private var cameraPermissionColor: Color {
        hasCameraPermission ? .green : .orange
    }

    private var hasLocationPermission: Bool {
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways
    }

    private var locationPermissionStatus: String {
        let locationManager = CLLocationManager()
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        @unknown default:
            return "Unknown"
        }
    }

    private var locationPermissionColor: Color {
        hasLocationPermission ? .green : .orange
    }

    // MARK: - Actions

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                DispatchQueue.main.async {
                    permissionType = .camera
                    showingPermissionsAlert = true
                }
            }
        }
    }

    private func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()

        // Check permission after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !hasLocationPermission {
                permissionType = .location
                showingPermissionsAlert = true
            }
        }
    }

    private func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openEvidenceFolder() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let evidenceURL = documentsURL.appendingPathComponent("Evidence", isDirectory: true)

        // Create folder if it doesn't exist
        try? FileManager.default.createDirectory(at: evidenceURL, withIntermediateDirectories: true)

        // Open in Finder
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: evidenceURL.path)
    }

    func testEvidenceCollection() {
        testInProgress = true
        testResult = ""

        // Create evidence service
        let evidenceService = SecurityEvidenceService()

        // Simulate evidence collection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            do {
                try evidenceService.collectEvidence(reason: "Manual test from settings")
                testResult = "✓ Success! Check evidence folder and email."
            } catch {
                testResult = "✗ Failed: \(error.localizedDescription)"
            }
            testInProgress = false

            // Clear result after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                testResult = ""
            }
        }
    }
}
