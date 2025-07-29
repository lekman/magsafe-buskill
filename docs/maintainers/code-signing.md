# Code Signing Guide

This guide explains how to set up code signing for MagSafe Guard using Apple's Developer ID certificate.

## Prerequisites

- Apple Developer account ($99/year)
- macOS with Keychain Access

## Creating Developer Certificates

1. Open **Xcode**
2. Go to **Xcode → Settings** (or Preferences on older versions)
3. Click **Accounts** tab
4. Click **"+"** to add Apple Account (if not already added)
5. Sign in with your Apple ID
6. Select your account in the list
7. Click **"Manage Certificates..."**
8. Delete any invalid certificates (shown with red X)
9. Click **"+"** and select all certificate types you need:
   - **Apple Development** (for testing)
   - **Apple Distribution** (for App Store)
   - **Developer ID Application** (for direct distribution)
   - **Developer ID Installer** (for installer packages)
   - **Mac App Distribution** (for Mac App Store)

Xcode will automatically:

- Create the private keys
- Generate CSRs
- Request certificates from Apple
- Install them with proper trust chains
- Handle all keychain permissions

## Sign Your App

```bash
# Build the app first
task build

# Sign the app
task swift:sign
```

The sign task will:

- Find your Developer ID certificate automatically
- Apply proper entitlements for MagSafe Guard
- Sign the app bundle

## Verify Signature

```bash
# Verify the signature
codesign --verify --deep --verbose=2 /tmp/MagSafeGuard.app

# Check Gatekeeper acceptance
spctl --assess --type execute --verbose /tmp/MagSafeGuard.app
```

## Troubleshooting

### Certificate Not Found

If signing fails with "No valid signing identity found":

```bash
# List all certificates
security find-identity -v -p codesigning
```

You should see your certificates listed. If not:

1. Open **Xcode → Settings → Accounts**
2. Click **"Manage Certificates..."**
3. Check if certificates show as valid (no red X)
4. If missing or invalid, click **"+"** to create new ones

### Certificate Shows as Invalid in Xcode

If certificates show with a red X in Xcode:

1. Click the invalid certificate
2. Click **"-"** to delete it
3. Click **"+"** to create a new one
4. Select the appropriate type (Developer ID Application for distribution)

### Signing Works but App Won't Run

If the app signs successfully but won't run when distributed:

```bash
# Check if app is quarantined
xattr -l /path/to/MagSafeGuard.app

# Remove quarantine if present
xattr -d com.apple.quarantine /path/to/MagSafeGuard.app

# For distribution, notarize the app
xcrun notarytool submit /path/to/MagSafeGuard.app --wait
```

### Check Certificate Expiration

```bash
# View certificate details
security find-certificate -c "Developer ID Application" -p | \
  openssl x509 -text | grep "Not After"
```

Developer ID certificates are valid for 5 years. Renew through Xcode before expiration.

## Important Notes

- **Developer ID certificates are valid for 5 years**
- **Keep your private key secure** - it cannot be recovered if lost
- **Never share or commit** certificates or private keys
- **One certificate** can sign multiple apps
- **Backup your certificate**: Export as .p12 from Keychain Access

## Exporting Certificate (Backup)

1. Open Keychain Access
2. Find "Developer ID Application: Your Name"
3. Right-click → Export
4. Save as .p12 file
5. Set a strong password
6. Store securely (not in Git!)

To restore on another machine:

1. Double-click the .p12 file
2. Enter the password
3. Certificate and private key will be imported

## Required Entitlements

MagSafe Guard requires these entitlements (automatically handled by `task swift:sign`):

```xml
<!-- Disable sandbox for system actions -->
<key>com.apple.security.app-sandbox</key>
<false/>

<!-- Notifications -->
<key>com.apple.developer.aps-environment</key>
<string>development</string>

<!-- iCloud/CloudKit -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.lekman.magsafeguard</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

## CI/CD Considerations

For GitHub Actions or other CI systems:

1. Export certificate as .p12 file from Keychain Access
2. Convert to base64: `base64 -i cert.p12 -o cert.txt`
3. Store in GitHub secrets
4. Import during build:

```yaml
- name: Import certificate
  run: |
    echo "${{ secrets.CERT_BASE64 }}" | base64 --decode > cert.p12
    security create-keychain -p actions build.keychain
    security default-keychain -s build.keychain
    security import cert.p12 -k build.keychain -P "${{ secrets.CERT_PASSWORD }}" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions build.keychain
```

## Security Best Practices

1. **Never commit** certificates, private keys, or .p12 files
2. **Use different certificates** for development and production
3. **Rotate certificates** before expiration
4. **Notarize** for distribution: `xcrun notarytool submit`
5. **Backup** your certificate and private key securely
