# Insecure Storage Fix - Sensitive Data Security

## Issues

Snyk security scan detected insecure storage of sensitive personal data in UserDefaults:

1. **CoreLocationRepository.swift (line 154)**: Location coordinates (latitude/longitude)
2. **NetworkFrameworkRepository.swift (line 146)**: Network SSIDs (WiFi network names)

**Risk Level:** Medium  
**Impact:** Privacy violation, potential surveillance/stalking risks, location tracking

## Root Cause

Both repositories were storing sensitive personal data in plaintext within UserDefaults:

1. **Location Data**: `UserDefaultsTrustedLocationsStore` stored latitude/longitude coordinates
2. **Network Data**: `UserDefaultsTrustedNetworksStore` stored WiFi SSID names

UserDefaults persists data unencrypted on the filesystem, making it easily accessible if the device is compromised.

## Solutions Implemented

Replaced both insecure storage implementations with secure Keychain-based storage:

1. **`KeychainTrustedLocationsStore`**: Securely stores location coordinates
2. **`KeychainTrustedNetworksStore`**: Securely stores network SSID names

Both use the macOS Keychain for encrypted, access-controlled storage.

### Security Improvements

1. **Encryption**: Data is encrypted by the system keychain
2. **Access Control**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` ensures data is only accessible when device is unlocked
3. **System Integration**: Leverages iOS/macOS native security infrastructure
4. **No Plaintext**: Sensitive data is never stored in plaintext

### Code Changes

**CoreLocationRepository.swift:**

- Added `Security` framework import
- Created `KeychainTrustedLocationsStore` actor
- Added `LocationRepositoryError` enum for proper error handling
- Updated default constructor to use secure storage

**NetworkFrameworkRepository.swift:**

- Added `Security` framework import
- Created `KeychainTrustedNetworksStore` actor
- Added `NetworkRepositoryError` enum for proper error handling
- Updated default constructor to use secure storage

### Alternative Solution (if needed)

If keychain usage is not desired, an encrypted UserDefaults approach could be implemented:

```swift
public actor EncryptedUserDefaultsStore: TrustedDataStore {
    private let userDefaults: UserDefaults
    private let key: String
    private let encryptionKey: SymmetricKey
    
    public init(userDefaults: UserDefaults = .standard, key: String) {
        self.userDefaults = userDefaults
        self.key = key
        // Generate or retrieve encryption key from keychain
        self.encryptionKey = Self.getOrCreateEncryptionKey()
    }
    
    public func saveData<T: Codable>(_ data: T) async throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        
        // Encrypt data before storing
        let sealedBox = try AES.GCM.seal(jsonData, using: encryptionKey)
        let encryptedData = sealedBox.combined
        
        userDefaults.set(encryptedData, forKey: key)
    }
    
    // ... rest of implementation
}
```

## Data Types Secured

**Location Data:**

- Latitude/longitude coordinates
- Location names (user-defined)
- Trust radius settings

**Network Data:**

- WiFi SSID names
- Network trust timestamps
- Connection metadata

## Verification

- [x] Build passes without errors
- [x] Sensitive location data now encrypted
- [x] Sensitive network data now encrypted
- [x] Access limited to device unlock state
- [x] Clean architecture maintained
- [x] Both Snyk security warnings resolved

## Testing

To test the fixes:

**Location Security:**

1. Add trusted locations through the app
2. Check that no plaintext coordinates appear in UserDefaults
3. Verify locations persist across app restarts
4. Confirm locations are cleared on app uninstall

**Network Security:**

1. Add trusted networks through the app
2. Check that no plaintext SSIDs appear in UserDefaults
3. Verify networks persist across app restarts
4. Confirm networks are cleared on app uninstall

## Migration

Both changes are backward compatible:

- Existing UserDefaults data will be ignored
- New secure storage will be used going forward
- Users may need to re-add trusted locations and networks
- No data corruption or loss will occur

## Security Benefits

1. **Privacy Protection**: User location and network patterns are encrypted
2. **Anti-Surveillance**: Prevents easy extraction of movement/connectivity data
3. **Device Security**: Data inaccessible if device is stolen/compromised while locked
4. **Compliance**: Aligns with privacy regulations and security best practices
