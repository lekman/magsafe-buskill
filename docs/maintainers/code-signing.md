# Code Signing Guide

This comprehensive guide explains how to set up code signing and entitlements for MagSafe Guard, supporting multiple signing scenarios including development, distribution, App Store, and CI/CD environments.

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

## Signing Configurations

MagSafe Guard supports four signing configurations:

### 1. Development (Local Testing)

- **Certificate**: Apple Development
- **Entitlements**: Relaxed for testing
- **Sandbox**: Disabled
- **Command**: `task swift:sign:dev`

### 2. Release (Direct Distribution)

- **Certificate**: Developer ID Application
- **Entitlements**: Production with hardened runtime
- **Sandbox**: Disabled (for system actions)
- **Command**: `task swift:sign:release`
- **Requires**: Notarization for distribution

### 3. App Store

- **Certificate**: Apple Distribution
- **Entitlements**: App Store compliant
- **Sandbox**: Enabled
- **Command**: `task swift:sign:appstore`

### 4. CI/Testing

- **Certificate**: None (ad-hoc signing)
- **Entitlements**: Minimal
- **Sandbox**: Disabled
- **Command**: `task swift:sign:ci`

## Quick Start

```bash
# Interactive signing (prompts for configuration)
task swift:sign

# Or use specific commands:
task swift:sign:dev      # Development
task swift:sign:release  # Developer ID
task swift:sign:appstore # App Store
task swift:sign:ci       # CI/Testing
```

## Verify Signature

```bash
# Use the built-in verification task
task swift:sign:verify
```

This will check:

- Signature validity
- Certificate details
- Entitlements
- Gatekeeper acceptance
- Notarization status

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

## Entitlements

MagSafe Guard uses different entitlements for each configuration:

### Development Entitlements (`Resources/MagSafeGuard.development.entitlements`)

- Sandbox disabled for easier testing
- Debugging enabled (`get-task-allow`)
- All runtime restrictions relaxed

### Release Entitlements (`Resources/MagSafeGuard.developerid.entitlements`)

- Sandbox disabled for system actions
- Hardened runtime enabled
- Production push notifications
- No debugging

### App Store Entitlements (`Resources/MagSafeGuard.entitlements`)

- Sandbox enabled (required)
- All capabilities properly declared
- Hardened runtime enforced

### CI Entitlements (`Resources/MagSafeGuard.ci.entitlements`)

- Minimal entitlements for testing
- Sandbox disabled
- Debugging enabled

## Required Capabilities

MagSafe Guard requires these capabilities:

1. **Menu Bar Operation**
   - `LSUIElement` in Info.plist
2. **CloudKit/iCloud**
   - `com.apple.developer.icloud-container-identifiers`
   - `com.apple.developer.icloud-services`
3. **Security Features**
   - Camera access for evidence collection
   - Location services for trusted locations
   - Apple Events for system automation
4. **Local Authentication**
   - Touch ID support (handled at runtime)
5. **IOKit Access**
   - Power monitoring (no special entitlement needed)
6. **Keychain Access**
   - Automatic with app signature

## CI/CD Integration

### Export Certificate for CI

```bash
# Export your certificate
task swift:sign:export-cert
```

This will:

1. Find your Developer ID certificate
2. Export it as a P12 file
3. Show instructions for GitHub Actions

### GitHub Actions Setup

```yaml
name: Build and Sign

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Import Certificate
        if: github.event_name == 'push'
        env:
          CERTIFICATE_P12: ${{ secrets.SIGNING_CERTIFICATE_P12_DATA }}
          CERTIFICATE_PASSWORD: ${{ secrets.SIGNING_CERTIFICATE_PASSWORD }}
        run: |
          # Create keychain
          KEYCHAIN_PATH=$RUNNER_TEMP/build.keychain
          KEYCHAIN_PASSWORD=$(openssl rand -base64 32)

          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          # Import certificate
          echo "$CERTIFICATE_P12" | base64 --decode > certificate.p12
          security import certificate.p12 -k "$KEYCHAIN_PATH" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          # Make it default
          security default-keychain -s "$KEYCHAIN_PATH"

      - name: Build and Sign
        run: |
          task build
          if [[ "${{ github.event_name }}" == "push" ]]; then
            task swift:sign:release
          else
            task swift:sign:ci
          fi
```

### Local CI Testing

For local CI testing without certificates:

```bash
# Build with ad-hoc signing
task build
task swift:sign:ci
```

## Notarization (Required for Distribution)

After signing with Developer ID:

```bash
# 1. Create a zip for notarization
ditto -c -k --keepParent .build/bundler/MagSafeGuard.app MagSafeGuard.zip

# 2. Submit for notarization
xcrun notarytool submit MagSafeGuard.zip \
  --apple-id "your-apple-id@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password" \
  --wait

# 3. Staple the notarization
xcrun stapler staple .build/bundler/MagSafeGuard.app

# 4. Verify
task swift:sign:verify
```

## Security Best Practices

1. **Never commit** certificates, private keys, or .p12 files
2. **Use different certificates** for development and production
3. **Rotate certificates** before expiration
4. **Always notarize** Developer ID signed apps
5. **Backup** your certificate and private key securely
6. **Use app-specific passwords** for notarization
7. **Test signed apps** on a clean machine

## Troubleshooting

### "No identity found" Error

```bash
# List all certificates
security find-identity -v -p codesigning

# If empty, create certificates in Xcode:
# Xcode → Settings → Accounts → Manage Certificates
```

### Gatekeeper Blocks App

```bash
# Remove quarantine
xattr -cr .build/bundler/MagSafeGuard.app

# Or add to Gatekeeper exceptions
sudo spctl --add .build/bundler/MagSafeGuard.app
```

### Notarization Fails

Common issues:

- Missing hardened runtime
- Invalid entitlements
- Unsigned frameworks
- Network issues

Check the notarization log:

```bash
xcrun notarytool log <submission-id> --apple-id "your-id" --team-id "TEAM"
```

### CI Signing Fails

- Ensure keychain is unlocked
- Check certificate hasn't expired
- Verify keychain search list
- Use `security list-keychains -s` to add keychain
