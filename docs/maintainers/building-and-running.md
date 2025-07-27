# Building and Running MagSafe Guard

## Prerequisites

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Hardware**: Any Mac (Intel or Apple Silicon)

### Development Tools

```bash
# Check Xcode version
xcodebuild -version

# Check Swift version
swift --version

# Install Xcode Command Line Tools (if needed)
xcode-select --install
```

## Project Structure

```ini
MagSafeGuard/
├── Sources/
│   └── MagSafeGuard/
│       ├── MagSafeGuardApp.swift      # Main app & menu bar
│       ├── Services/
│       │   └── PowerMonitorService.swift
│       └── Views/
│           └── PowerMonitorDemoView.swift
├── Tests/
│   └── MagSafeGuardTests/
│       ├── MagSafeGuardTests.swift
│       └── PowerMonitorServiceTests.swift
├── Resources/
│   ├── Info.plist
│   └── MagSafeGuard.entitlements
└── Package.swift
```

## Building the Project

### Option 1: Using Xcode (Recommended)

1. **Open the project**:

   ```bash
   open MagSafeGuard.xcodeproj
   ```

2. **Select scheme and destination**:

   - Scheme: `MagSafeGuard`
   - Destination: `My Mac`

3. **Build**:

   - Press `⌘B` (Command+B)
   - Or select `Product → Build`

4. **Run**:
   - Press `⌘R` (Command+R)
   - Or select `Product → Run`

### Option 2: Using Swift Package Manager

```bash
# Build the project
swift build

# Build in release mode
swift build -c release

# Run the app
swift run MagSafeGuard

# Run tests
swift test
```

### Option 3: Using Taskfile

```bash
# Install Task if not already installed
brew install go-task/tap/go-task

# Build and run
task run

# Run tests
task test

# Setup development environment
task init
```

### Option 4: Using xcodebuild

```bash
# Build for debugging
xcodebuild -project MagSafeGuard.xcodeproj \
           -scheme MagSafeGuard \
           -configuration Debug \
           build

# Build for release
xcodebuild -project MagSafeGuard.xcodeproj \
           -scheme MagSafeGuard \
           -configuration Release \
           build

# Build and analyze
xcodebuild -project MagSafeGuard.xcodeproj \
           -scheme MagSafeGuard \
           analyze
```

## Running the Application

### From Xcode

1. Press `⌘R` or click the Run button
2. App launches in menu bar (no dock icon)
3. Look for the lock shield icon in the top-right menu bar

### From Terminal

```bash
# After building with Swift PM
./.build/debug/MagSafeGuard

# Or if built with xcodebuild
./build/Debug/MagSafeGuard.app/Contents/MacOS/MagSafeGuard
```

### From Finder

1. Navigate to build output:
   - Xcode: `~/Library/Developer/Xcode/DerivedData/MagSafeGuard-*/Build/Products/Debug/`
   - Swift PM: `./.build/debug/`
2. Double-click `MagSafeGuard.app`

## First Run Experience

### What to Expect

1. **No Dock Icon**: App runs as menu bar only
2. **Menu Bar Icon**: Lock shield appears in top menu bar
3. **Initial State**: Disarmed (outline icon)
4. **Power Monitoring**: Starts automatically

### Initial Setup

1. Click the menu bar icon
2. Select "Show Demo..." to test power detection
3. Try unplugging/plugging power adapter
4. Test Arm/Disarm functionality

## Development Workflow

### Rapid Development Cycle

1. **Make changes** in Xcode
2. **Stop current run**: `⌘.` (Command+Period)
3. **Build and run**: `⌘R`
4. **Test changes** in menu bar

### Debug Console

View print statements and logs:

- Xcode: Bottom panel console
- Terminal: Direct output
- Console.app: Filter by "MagSafeGuard"

### Common Debug Messages

```text
[PowerMonitorService] Started monitoring (mode: notifications)
[AppDelegate] Power state: Power adapter connected
[PowerMonitorService] Power state changed via notification: Power adapter disconnected
⚠️ SECURITY ALERT: Power disconnected while armed!
```

## Current Implementation Status

### ✅ Completed

- PowerMonitorService class with singleton pattern
- IOKit integration for real-time power monitoring
- Menu bar UI with arm/disarm functionality
- Basic security action (screen lock)
- Power state notifications
- Demo window for testing
- Unit test suite

### 🚧 In Progress

- Efficient polling implementation (subtask 2.3)
- Enhanced callback system (subtask 2.4)
- Comprehensive logging (subtask 2.5)
- Performance testing (subtask 2.6)

### 📋 Future Enhancements

- Additional security actions (logout, custom scripts)
- Auto-arm based on location/network
- Find My Mac integration
- Data protection features
- Accessibility improvements

## Known Issues

- Adapter wattage detection may not work on all Mac models
- Notifications require proper app bundle (see Troubleshooting)
- Menu bar icon may not appear when running directly from Xcode (see Menu Bar Troubleshooting below)

## Menu Bar Troubleshooting

### Icon Not Showing in Xcode

When running from Xcode, the menu bar icon may not appear due to missing bundle configuration. This is because:

1. Swift Package Manager executables don't have Info.plist by default
2. Menu bar apps require `LSUIElement = YES` in Info.plist
3. Xcode needs a proper bundle identifier for menu bar apps

#### Solution 1: Use Task Run Command (Recommended)

```bash
# Build and run as a proper menu bar app
task run

# Or run in debug mode
task run:debug
```

This task:

- Builds the app in release mode
- Creates a minimal app bundle with proper Info.plist
- Sets LSUIElement to hide the dock icon
- Launches the app with proper bundle configuration

#### Solution 2: Xcode Scheme Settings

1. Product → Scheme → Edit Scheme
2. Run → Options → Launch: "Wait for executable to be launched"
3. Build and Run
4. Manually launch from: `.build/debug/MagSafeGuard`

#### Solution 3: Create Xcode Project

For full Xcode integration:

1. File → New → Project → macOS → App
2. Copy source files to new project
3. Add LSUIElement = YES to Info.plist
4. Set "Application is agent" in project settings

### Text Instead of Icon

If you see "MG" text instead of the shield icon:

- SF Symbols may not be available in development mode
- The app falls back to text when icons fail to load
- This is normal when running without a proper bundle

## Testing

### Unit Tests

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test
swift test --filter PowerMonitorServiceTests
```

### Manual Testing

#### Testing Power Detection

1. Run the app (it appears as a menu bar icon)
2. Click the menu bar icon (shield with lock)
3. Select "Show Demo..." to open the demo window
4. In the demo window:
   - Click "Start Monitoring" to begin real-time updates
   - Unplug and replug your power adapter to see status changes
   - View battery level and charging status

## Build Artifacts

### Software Bill of Materials (SBOM)

Generate an SBOM for security compliance and dependency tracking:

```bash
# Generate SBOM in SPDX format
task swift:sbom

# Generate SBOM for the project
task swift:sbom
```

This creates:

- `sbom.spdx` - SPDX 2.3 format SBOM
- `sbom-deps.json` - Swift dependencies in JSON

See the [SBOM Guide](../security/sbom-guide.md) for details.

#### Testing Security Features

1. From the menu bar:
   - Select "Arm" to enable security mode (icon turns red)
   - Unplug your power adapter
   - The app should lock your screen
   - Select "Disarm" to disable security mode

#### Testing Checklist

- [ ] App launches without crash
- [ ] Menu bar icon appears
- [ ] Menu opens on click
- [ ] Demo window opens
- [ ] Power detection works (unplug/replug adapter)
- [ ] Armed mode changes icon to filled shield
- [ ] Disarmed mode changes icon to outline
- [ ] Screen locks when power disconnected while armed
- [ ] Notifications appear (if supported)
- [ ] Battery level displays correctly
- [ ] No memory leaks or high CPU usage

### Performance Testing

1. Open Activity Monitor
2. Find "MagSafeGuard" process
3. Monitor:
   - CPU: Should be < 1%
   - Memory: Should be < 50MB
   - Energy Impact: Should be "Low"

## Troubleshooting

### Build Failures

**"Command Line Tools not found"**:

```bash
xcode-select --install
sudo xcode-select -s /Applications/Xcode.app
```

**"Swift version mismatch"**:

- Update Xcode to latest version
- Check Package.swift for version requirement

**"Module not found"**:

- Clean build folder: `⌘⇧K`
- Delete derived data
- Restart Xcode

### Runtime Issues

**App doesn't appear in menu bar**:

- Check Console.app for crash logs
- Verify `NSStatusItem` creation
- Check for early exits

**Power detection not working**:

- Test with demo window first
- Check IOKit permissions
- Try both power adapters (if available)

**High CPU usage**:

- Check if polling mode is active
- Look for infinite loops
- Profile with Instruments

### Permission Issues

**"Operation not permitted"**:

- Grant accessibility permissions if requested
- Check System Settings → Privacy & Security
- May need to restart app

## Distribution

### Creating a Release Build

1. **In Xcode**:

   - Select "Any Mac" as destination
   - Product → Archive
   - Distribute App → Direct Distribution

2. **Via Command Line**:

   ```bash
   xcodebuild -project MagSafeGuard.xcodeproj \
              -scheme MagSafeGuard \
              -configuration Release \
              -derivedDataPath build \
              archive -archivePath build/MagSafeGuard.xcarchive
   ```

### Code Signing (Future)

```bash
# Check signing identity
security find-identity -p codesigning

# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" \
         MagSafeGuard.app
```

### Creating DMG (Future)

```bash
# Create DMG for distribution
hdiutil create -volname "MagSafe Guard" \
               -srcfolder build/Release/MagSafeGuard.app \
               -ov -format UDZO \
               MagSafeGuard.dmg
```

## Environment Setup

### Recommended Xcode Settings

1. **Preferences → Text Editing**:

   - Line numbers: On
   - Code folding: On
   - Page guide at column: 120

2. **Preferences → Behaviors**:
   - Starts → Show console
   - Generates output → Show console

### Git Configuration

```bash
# Set up git hooks
task setup-hooks

# Configure git
git config core.hooksPath .git/hooks
```

## Continuous Integration

### GitHub Actions (Future)

```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: swift build
      - name: Test
        run: swift test
```

## Quick Commands Reference

```bash
# Build
⌘B          # Xcode: Build
swift build # Terminal: Build

# Run
⌘R          # Xcode: Run
swift run   # Terminal: Run

# Test
⌘U          # Xcode: Test
swift test  # Terminal: Test

# Clean
⌘⇧K         # Xcode: Clean
rm -rf .build # Terminal: Clean

# Stop
⌘.          # Xcode: Stop
Ctrl+C      # Terminal: Stop
```
