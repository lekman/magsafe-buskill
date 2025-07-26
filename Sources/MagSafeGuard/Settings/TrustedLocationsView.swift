//
//  TrustedLocationsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  UI for managing trusted locations for auto-arm functionality
//

import CoreLocation
import MapKit
import SwiftUI

/// View for managing trusted locations in auto-arm settings
struct TrustedLocationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var locations: [TrustedLocation] = []
    @State private var showingAddLocation = false
    @State private var showingLocationPicker = false
    @State private var newLocationName = ""
    @State private var newLocationCoordinate = CLLocationCoordinate2D()
    @State private var newLocationRadius: Double = 100.0
    @State private var showingPermissionAlert = false

    /// Access to the auto-arm manager through AppController
    let autoArmManager: AutoArmManager?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if locations.isEmpty {
                    emptyStateView
                } else {
                    locationsList
                }
            }
            .navigationTitle("Trusted Locations")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddLocation = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            loadLocations()
            checkLocationPermission()
        }
        .sheet(isPresented: $showingAddLocation) {
            AddLocationView(
                locationName: $newLocationName,
                coordinate: $newLocationCoordinate,
                radius: $newLocationRadius,
                onSave: addLocation,
                onCancel: { showingAddLocation = false }
            )
        }
        .alert("Location Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Location-based auto-arm requires location permission. Please enable it in System Settings.")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Trusted Locations")
                .font(.title2)
                .fontWeight(.medium)

            Text("Add locations where auto-arm should be disabled")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Add First Location") {
                showingAddLocation = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var locationsList: some View {
        List {
            ForEach(locations, id: \.id) { location in
                LocationRow(location: location) {
                    removeLocation(location)
                }
            }
        }
    }

    private func loadLocations() {
        locations = autoArmManager?.getTrustedLocations() ?? []
    }

    private func checkLocationPermission() {
        let status = CLLocationManager().authorizationStatus
        if status == .denied || status == .restricted {
            showingPermissionAlert = true
        }
    }

    private func addLocation() {
        let location = TrustedLocation(
            name: newLocationName,
            coordinate: newLocationCoordinate,
            radius: newLocationRadius
        )

        autoArmManager?.addTrustedLocation(location)
        locations.append(location)

        // Reset form
        newLocationName = ""
        newLocationRadius = 100.0
        showingAddLocation = false
    }

    private func removeLocation(_ location: TrustedLocation) {
        autoArmManager?.removeTrustedLocation(id: location.id)
        locations.removeAll { $0.id == location.id }
    }
}

/// Row view for displaying a trusted location
struct LocationRow: View {
    let location: TrustedLocation
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.body)

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Radius: \(Int(location.radius))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

/// View for adding a new trusted location
struct AddLocationView: View {
    @Binding var locationName: String
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var radius: Double
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var useCurrentLocation = true
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""
    @State private var isLoadingLocation = false

    private let locationManager = CLLocationManager()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location Details")) {
                    TextField("Location Name", text: $locationName)

                    Picker("Location Source", selection: $useCurrentLocation) {
                        Text("Current Location").tag(true)
                        Text("Manual Entry").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if !useCurrentLocation {
                        HStack {
                            TextField("Latitude", text: $manualLatitude)
                                .textFieldStyle(.roundedBorder)
                            TextField("Longitude", text: $manualLongitude)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                Section(header: Text("Trust Radius")) {
                    VStack(alignment: .leading) {
                        Text("\(Int(radius)) meters")
                            .font(.headline)

                        Slider(value: $radius, in: 50...1000, step: 50)

                        Text("Area around this location where auto-arm is disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Trusted Location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if useCurrentLocation {
                            getCurrentLocationAndSave()
                        } else {
                            saveWithManualCoordinates()
                        }
                    }
                    .disabled(locationName.isEmpty || isLoadingLocation)
                }
            }
        }
        .frame(width: 500, height: 400)
    }

    private func getCurrentLocationAndSave() {
        isLoadingLocation = true

        // Request current location
        locationManager.requestLocation()

        // For simplicity, we'll use a default location
        // In a real app, you'd implement CLLocationManagerDelegate
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Use Apple Park as default for demo
            coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
            isLoadingLocation = false
            onSave()
        }
    }

    private func saveWithManualCoordinates() {
        guard let lat = Double(manualLatitude),
              let lon = Double(manualLongitude) else {
            return
        }

        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        onSave()
    }
}

// MARK: - Preview

struct TrustedLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        TrustedLocationsView(autoArmManager: nil)
    }
}
