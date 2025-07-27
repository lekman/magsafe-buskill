//
//  SecurityEvidenceService.swift
//  MagSafe Guard
//
//  Created on 2025-07-27.
//
//  Manages evidence collection including location tracking and photo capture
//  when theft is detected. Provides secure storage and email backup of evidence.
//

import AppKit
import AVFoundation
import CoreLocation
import CryptoKit
import Foundation
import Security

/// Service responsible for collecting and managing security evidence
///
/// This service captures location data and photos when a theft is detected,
/// stores them securely, and can send them to a backup email address.
/// All evidence is encrypted before storage for security.
public class SecurityEvidenceService: NSObject {

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentLocation: CLLocation?
    private var isCollectingEvidence = false
    private let fileManager = FileManager.default

    /// Delegate for evidence collection events
    public weak var delegate: SecurityEvidenceServiceDelegate?

    // Settings
    private var isEvidenceCollectionEnabled: Bool {
        UserDefaults.standard.bool(forKey: "evidenceCollectionEnabled")
    }

    private var backupEmailAddress: String? {
        UserDefaults.standard.string(forKey: "backupEmailAddress")
    }

    // MARK: - Initialization

    public override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Public Methods

    /// Starts collecting evidence for a security event
    /// - Parameter reason: The reason for evidence collection
    /// - Throws: EvidenceError if collection fails
    public func collectEvidence(reason: String) throws {
        guard isEvidenceCollectionEnabled else {
            throw EvidenceError.featureDisabled
        }

        guard !isCollectingEvidence else {
            Log.info("Evidence collection already in progress", category: .general)
            return
        }

        isCollectingEvidence = true
        Log.info("Evidence collection activated: \(reason)", category: .general)

        // Start location tracking
        startLocationUpdates()

        // Capture photo evidence if permission granted
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            try capturePhotoEvidence()
        } else {
            requestCameraPermission { [weak self] granted in
                if granted {
                    try? self?.capturePhotoEvidence()
                } else {
                    Log.warning("Camera permission denied", category: .general)
                }
            }
        }
    }

    /// Stops evidence collection
    public func stopEvidenceCollection() {
        guard isCollectingEvidence else { return }

        locationManager.stopUpdatingLocation()
        captureSession?.stopRunning()
        captureSession = nil
        photoOutput = nil
        isCollectingEvidence = false

        Log.info("Evidence collection stopped", category: .general)
    }

    // MARK: - Location Management

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Only enable background updates if running in a real app context
        #if !targetEnvironment(simulator) && !DEBUG
        if Bundle.main.bundleIdentifier != nil {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
        #endif
    }

    private func startLocationUpdates() {
        let authStatus = locationManager.authorizationStatus

        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            Log.warning("Location services are disabled", category: .general)
        @unknown default:
            Log.warning("Unknown location authorization status", category: .general)
        }
    }

    // MARK: - Camera Evidence

    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    private func capturePhotoEvidence() throws {
        // Initialize capture session
        let session = AVCaptureSession()
        captureSession = session

        // Configure camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw EvidenceError.cameraUnavailable
        }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            throw EvidenceError.cameraInputError
        }

        guard session.canAddInput(input) else {
            throw EvidenceError.invalidCameraInput
        }

        session.addInput(input)

        // Configure photo output
        let output = AVCapturePhotoOutput()
        photoOutput = output

        guard session.canAddOutput(output) else {
            throw EvidenceError.invalidCameraOutput
        }

        session.addOutput(output)

        // Start capture session on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()

            // Take photo after a short delay to allow camera to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.takePhoto()
            }
        }
    }

    private func takePhoto() {
        guard let photoOutput = photoOutput, captureSession?.isRunning == true else {
            Log.warning("Cannot take photo - camera not ready", category: .general)
            return
        }

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Evidence Storage

    private func storeEvidenceLocally(location: CLLocation?, photoData: Data?) throws {
        guard let location = location else {
            throw EvidenceError.missingLocationData
        }

        // Create evidence object
        let evidence = SecurityEvidence(
            timestamp: Date(),
            location: location,
            photoData: photoData,
            deviceInfo: "\(ProcessInfo.processInfo.operatingSystemVersionString)"
        )

        // Generate unique ID for evidence
        let evidenceId = UUID().uuidString

        // Create evidence directory
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence", isDirectory: true)

        try fileManager.createDirectory(at: evidenceDirectory, withIntermediateDirectories: true)

        // Generate encryption key
        let key = SymmetricKey(size: .bits256)

        // Encrypt evidence data
        let evidenceData = try JSONEncoder().encode(evidence)
        let encryptedData = try encryptData(evidenceData, using: key)

        // Save encrypted evidence
        let fileURL = evidenceDirectory.appendingPathComponent("\(evidenceId).encrypted")
        try encryptedData.write(to: fileURL, options: .atomic)

        // Store encryption key in keychain
        try storeKeyInKeychain(key, for: evidenceId)

        Log.info("Evidence stored locally with ID: \(evidenceId) (encrypted)", category: .general)

        // Send evidence to backup email if configured
        if let photoData = photoData {
            try sendEvidenceToBackupEmail(evidence: evidence, photoData: photoData)
        }

        // Notify delegate
        delegate?.evidenceService(self, didCollectEvidence: evidence)
    }

    // MARK: - Encryption

    private func encryptData(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined ?? Data()
        } catch {
            throw EvidenceError.encryptionFailed
        }
    }

    private func decryptData(_ encryptedData: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw EvidenceError.encryptionFailed
        }
    }

    // MARK: - Keychain Storage

    private func storeKeyInKeychain(_ key: SymmetricKey, for identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.magsafeguard.evidence.\(identifier)",
            kSecAttrService as String: "MagSafeGuard",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EvidenceError.storageError
        }
    }

    private func retrieveKeyFromKeychain(for identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.magsafeguard.evidence.\(identifier)",
            kSecAttrService as String: "MagSafeGuard",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)

        guard status == errSecSuccess,
              let keyData = dataRef as? Data else {
            throw EvidenceError.storageError
        }

        return SymmetricKey(data: keyData)
    }

    // MARK: - Email Sending

    private func sendEvidenceToBackupEmail(evidence: SecurityEvidence, photoData: Data) throws {
        guard let emailAddress = backupEmailAddress, !emailAddress.isEmpty else {
            throw EvidenceError.backupEmailNotConfigured
        }

        // Generate report
        let report = generateSecurityReport(evidence: evidence)

        // Create email content
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        let subject = "Security Alert: Device Activity Detected - \(dateFormatter.string(from: evidence.timestamp))"

        // Create temporary files for attachments
        let tempDirectory = FileManager.default.temporaryDirectory
        let reportURL = tempDirectory.appendingPathComponent("security-report.txt")
        let photoURL = tempDirectory.appendingPathComponent("evidence-photo.jpg")

        do {
            // Write report to temporary file
            try report.write(to: reportURL, atomically: true, encoding: .utf8)

            // Write photo to temporary file
            try photoData.write(to: photoURL)

            // Prepare email using NSSharingService
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Create sharing service for email
                guard let service = NSSharingService(named: .composeEmail) else {
                    Log.error("Email service not available", category: .general)
                    self.delegate?.evidenceService(self, didFailWithError: EvidenceError.emailSendingFailed)
                    return
                }

                // Configure email
                service.recipients = [emailAddress]
                service.subject = subject

                // Items to share (report and photo)
                let itemsToShare: [Any] = [report, reportURL, photoURL]

                // Can we share these items?
                if service.canPerform(withItems: itemsToShare) {
                    service.perform(withItems: itemsToShare)
                    Log.info("Evidence email prepared for: \(emailAddress)", category: .general)
                    self.delegate?.evidenceService(self, didSendEmailTo: emailAddress)
                } else {
                    Log.error("Cannot send email with attachments", category: .general)
                    self.delegate?.evidenceService(self, didFailWithError: EvidenceError.emailSendingFailed)
                }

                // Clean up temporary files after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    try? FileManager.default.removeItem(at: reportURL)
                    try? FileManager.default.removeItem(at: photoURL)
                }
            }
        } catch {
            Log.error("Failed to prepare email attachments", error: error, category: .general)
            throw EvidenceError.emailSendingFailed
        }
    }

    // MARK: - Report Generation

    private func generateSecurityReport(evidence: SecurityEvidence) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full

        var report = "SECURITY EVIDENCE REPORT\n"
        report += "=======================\n\n"
        report += "Timestamp: \(dateFormatter.string(from: evidence.timestamp))\n"
        report += "Device: \(evidence.deviceInfo)\n\n"

        if let location = evidence.location {
            report += "Location Information:\n"
            report += "  Latitude: \(location.coordinate.latitude)\n"
            report += "  Longitude: \(location.coordinate.longitude)\n"
            report += "  Accuracy: \(location.horizontalAccuracy) meters\n"

            if location.horizontalAccuracy > 0 {
                report += "  Google Maps URL: https://maps.google.com/?q=\(location.coordinate.latitude),\(location.coordinate.longitude)\n"
            }

            report += "\n"
        }

        report += "Evidence Collection Triggered by Security System\n"
        report += "Photo evidence is attached to this email.\n\n"
        report += "This is an automated message. Please do not reply.\n"

        return report
    }
}

// MARK: - CLLocationManagerDelegate

extension SecurityEvidenceService: CLLocationManagerDelegate {
    /// Called when the location manager receives updated location data.
    /// - Parameters:
    ///   - manager: The location manager providing the update
    ///   - locations: Array of CLLocation objects containing the location data
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        Log.debug("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)", category: .general)
    }

    /// Called when the location manager fails to retrieve location data.
    /// - Parameters:
    ///   - manager: The location manager that failed
    ///   - error: The error that occurred
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.error("Location manager error", error: error, category: .general)
    }

    /// Called when the app's authorization to use location services changes.
    /// - Parameter manager: The location manager reporting the authorization change
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if isCollectingEvidence {
                locationManager.startUpdatingLocation()
            }
        default:
            break
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension SecurityEvidenceService: AVCapturePhotoCaptureDelegate {
    /// Called when photo capture is complete.
    /// - Parameters:
    ///   - output: The photo output that captured the photo
    ///   - photo: The captured photo object
    ///   - error: An error if photo capture failed, nil otherwise
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            Log.error("Error capturing photo", error: error, category: .general)
            return
        }

        guard let photoData = photo.fileDataRepresentation() else {
            Log.error("Could not get photo data", category: .general)
            return
        }

        do {
            try storeEvidenceLocally(location: currentLocation, photoData: photoData)
        } catch {
            Log.error("Failed to store evidence", error: error, category: .general)
        }

        // Stop the capture session after taking the photo
        captureSession?.stopRunning()
    }
}

// MARK: - Evidence Retrieval

extension SecurityEvidenceService {
    /// Retrieves all stored evidence entries
    /// - Returns: Array of evidence IDs
    public func listStoredEvidence() throws -> [String] {
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence", isDirectory: true)

        guard fileManager.fileExists(atPath: evidenceDirectory.path) else {
            return []
        }

        let files = try fileManager.contentsOfDirectory(at: evidenceDirectory, includingPropertiesForKeys: nil)
        return files
            .filter { $0.pathExtension == "encrypted" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    /// Retrieves and decrypts evidence by ID
    /// - Parameter evidenceId: The evidence ID to retrieve
    /// - Returns: Decrypted evidence object
    public func retrieveEvidence(by evidenceId: String) throws -> SecurityEvidence {
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence", isDirectory: true)
        let fileURL = evidenceDirectory.appendingPathComponent("\(evidenceId).encrypted")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw EvidenceError.storageError
        }

        // Read encrypted data
        let encryptedData = try Data(contentsOf: fileURL)

        // Retrieve key from keychain
        let key = try retrieveKeyFromKeychain(for: evidenceId)

        // Decrypt data
        let decryptedData = try decryptData(encryptedData, using: key)

        // Decode evidence
        return try JSONDecoder().decode(SecurityEvidence.self, from: decryptedData)
    }
}

// MARK: - SecurityEvidenceServiceDelegate

/// Delegate protocol for evidence collection events
public protocol SecurityEvidenceServiceDelegate: AnyObject {
    /// Called when evidence has been collected
    func evidenceService(_ service: SecurityEvidenceService, didCollectEvidence evidence: SecurityEvidence)

    /// Called when evidence has been sent via email
    func evidenceService(_ service: SecurityEvidenceService, didSendEmailTo address: String)

    /// Called when an error occurs
    func evidenceService(_ service: SecurityEvidenceService, didFailWithError error: Error)
}

// MARK: - Evidence Model

/// Represents collected security evidence
public struct SecurityEvidence: Codable {
    /// The timestamp when the evidence was collected
    public let timestamp: Date
    /// The location where the evidence was collected
    public let location: CLLocation?
    /// The photo data captured as evidence
    public let photoData: Data?
    /// Information about the device that collected the evidence
    public let deviceInfo: String

    enum CodingKeys: String, CodingKey {
        case timestamp, deviceInfo
        case locationLatitude, locationLongitude, locationAccuracy
        case photoData
    }

    /// Initialize a new SecurityEvidence instance.
    /// - Parameters:
    ///   - timestamp: When the evidence was collected
    ///   - location: Where the evidence was collected
    ///   - photoData: Photo data captured as evidence
    ///   - deviceInfo: Information about the device
    public init(timestamp: Date, location: CLLocation?, photoData: Data?, deviceInfo: String) {
        self.timestamp = timestamp
        self.location = location
        self.photoData = photoData
        self.deviceInfo = deviceInfo
    }

    /// Initialize SecurityEvidence from decoded data.
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: DecodingError if decoding fails
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        deviceInfo = try container.decode(String.self, forKey: .deviceInfo)
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)

        // Decode location if available
        if let latitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude),
           let longitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude),
           let accuracy = try container.decodeIfPresent(Double.self, forKey: .locationAccuracy) {
            location = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                altitude: 0,
                horizontalAccuracy: accuracy,
                verticalAccuracy: 0,
                timestamp: Date()
            )
        } else {
            location = nil
        }
    }

    /// Encode the SecurityEvidence instance.
    /// - Parameter encoder: The encoder to write data to
    /// - Throws: EncodingError if encoding fails
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(deviceInfo, forKey: .deviceInfo)
        try container.encodeIfPresent(photoData, forKey: .photoData)

        // Encode location if available
        if let location = location {
            try container.encode(location.coordinate.latitude, forKey: .locationLatitude)
            try container.encode(location.coordinate.longitude, forKey: .locationLongitude)
            try container.encode(location.horizontalAccuracy, forKey: .locationAccuracy)
        }
    }
}

// MARK: - Error Types

/// Errors that can occur during evidence collection
public enum EvidenceError: LocalizedError {
    /// Evidence collection feature is disabled in settings
    case featureDisabled
    /// Camera is not available on this device
    case cameraUnavailable
    /// Failed to configure camera input
    case cameraInputError
    /// Camera input is not compatible with capture session
    case invalidCameraInput
    /// Camera output is not compatible with capture session
    case invalidCameraOutput
    /// Location data is required but not available
    case missingLocationData
    /// Backup email address is not configured in settings
    case backupEmailNotConfigured
    /// Failed to send evidence via email
    case emailSendingFailed
    /// Failed to encrypt evidence data
    case encryptionFailed
    /// Failed to store or retrieve evidence from storage
    case storageError

    /// Localized description of the error for user display.
    public var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "Evidence collection is disabled in settings"
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .cameraInputError:
            return "Failed to configure camera input"
        case .invalidCameraInput:
            return "Camera input is not compatible"
        case .invalidCameraOutput:
            return "Camera output is not compatible"
        case .missingLocationData:
            return "Location data is not available"
        case .backupEmailNotConfigured:
            return "Backup email address is not configured"
        case .emailSendingFailed:
            return "Failed to send evidence email"
        case .encryptionFailed:
            return "Failed to encrypt evidence data"
        case .storageError:
            return "Failed to store evidence locally"
        }
    }
}
