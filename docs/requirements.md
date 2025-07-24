# MagSafe Guard - Requirements Document

## Project Overview

MagSafe Guard is an open-source macOS menu bar application inspired by the [BusKill Project](https://github.com/BusKill/buskill-app) that monitors power adapter connection status. When armed, the application triggers configurable security actions if the power adapter is unexpectedly disconnected, providing protection against laptop theft in public spaces.

This project adapts BusKill's innovative laptop kill cord concept for Mac users, utilizing the existing power connection instead of requiring a separate USB cable. We gratefully acknowledge the BusKill team's pioneering work in creating the original cross-platform solution.

## Core Concept

Unlike BusKill which uses a physical USB breakaway cable, this application leverages the existing power connection (MagSafe, USB-C, or any power adapter) as the "kill cord". When an attacker attempts to steal a laptop while it's plugged in, the power connector will disconnect, triggering the security response.

## Technical Feasibility (Proven)

We have successfully created proof-of-concept scripts that demonstrate:

- ✅ Power monitoring is technically feasible on macOS
- ✅ IOKit successfully detects power adapter connection/disconnection in real-time
- ✅ Works with ANY power adapter (MagSafe, USB-C, third-party)
- ✅ No kernel extensions or special permissions needed
- ✅ Near-instant detection (< 100ms response time)
- ✅ Can be implemented without kernel extensions

## Key Design Decisions

Based on user requirements, the following decisions have been made:

1. **Action Timing**: Configurable, immediate execution by default
2. **Recovery Mode**: Yes, configurable during grace period
3. **Authentication**: TouchID/password required for arm/disarm
4. **Data Protection**: Force logout if screen locked + grace period expired
5. **Grace Period**: 10 seconds default, fully configurable
6. **Battery Safety**: Configurable, default NO restriction
7. **Licensing**: Fully open source (MIT License)
8. **Distribution**: Direct download first, Mac App Store later

## Core Features

### 1. Menu Bar Interface

- **Status Indicator**: Visual icon showing armed/disarmed state
  - 🔒 Armed (red shield icon)
  - 🔓 Disarmed (green shield icon)
  - ⚡ Power connected indicator
- **Secure Toggle**: Requires TouchID/password authentication to arm/disarm
- **Settings Access**: Right-click menu for configuration

### 2. Power Monitoring

- Real-time power adapter connection status monitoring
- Works with ALL power adapters (MagSafe, USB-C, third-party)
- Differentiate between:
  - Normal disconnection (when disarmed)
  - Security event (when armed)
  - Battery level monitoring

### 3. Security Actions

#### Execution Mode

- **Configurable timing**: Immediate execution by default
- **Sequential or parallel**: User configurable
- **Priority-based**: Execute most critical actions first

#### Available Actions

1. **Screen Lock** (Default)

   - Immediately lock the screen requiring password/TouchID
   - If already locked and grace period expires: Force logout
   - Prevents USB attack vectors while logged in

2. **Sleep Mode**

   - Put computer to sleep
   - Requires authentication to wake

3. **Shutdown**

   - Clean system shutdown
   - Configurable countdown

4. **Alarm**

   - Play loud alarm sound
   - Flash screen
   - Draw attention to theft attempt

5. **Location Tracking**

   - Enable Find My Mac
   - Send GPS coordinates to backup email
   - Take photo with FaceTime camera

6. **Data Protection**

   - Force logout if screen locked
   - Lock FileVault encrypted volumes
   - Unmount external drives
   - Clear clipboard and recent documents

7. **Network Security**

   - Disconnect VPN
   - Clear SSH keys from memory
   - Logout from sensitive applications

8. **Custom Script**
   - Execute user-defined shell script
   - Enables any scriptable action

### 4. Smart Features

#### Auto-Arm Conditions

- Automatically arm when:
  - Connected to power in public networks (coffee shops, airports)
  - Screen is locked while charging
  - Specific time schedules

#### False Positive Prevention

- **Grace Period**: 10-second default delay before triggering (configurable)
- **Recovery Window**: Cancel trigger during grace period with authentication
- **Battery Threshold**: Configurable, default NO restriction
- **Safe Locations**: GPS-based whitelist (home, office)
- **Trusted Networks**: Wi-Fi SSID whitelist

## Authentication Requirements

### Security Model

- TouchID/password required for ALL arm/disarm operations
- No keyboard shortcuts for state changes
- No AppleScript support for state changes
- Authentication cannot be disabled

### Authentication Flow

1. **Arming**: Requires authentication, warns if no power connected
2. **Disarming**: Requires authentication, warns if action in progress
3. **Grace Period Cancel**: Requires authentication to cancel pending action
4. **Timeout**: 30-second auth prompt timeout (configurable)
5. **Failed Attempts**: Max 3 attempts, then 1-minute cooldown

## Configuration

The application uses JSON configuration with the following structure:

```yaml
# Default configuration example
security:
  require_auth_to_toggle: true # Cannot be disabled
  grace_period: 10000 # milliseconds (10 seconds default)
  recovery_allowed: true # Allow cancellation during grace
  action_timing: "immediate" # immediate/delayed
  action_mode: "sequential" # sequential/parallel

battery:
  low_battery_protection: false # Default: no restriction
  minimum_battery_level: 10 # If enabled, min % to allow shutdown

actions:
  screen_lock:
    enabled: true
    priority: 1
    force_logout_if_locked: true
    logout_delay: 30 # seconds after grace period

  # Additional actions configured similarly...

smart_features:
  auto_arm:
    public_networks: true
    on_screen_lock: true
    schedule:
      - days: ["mon", "tue", "wed", "thu", "fri"]
        start: "09:00"
        end: "18:00"

  safe_locations:
    - name: "Home"
      latitude: 37.7749
      longitude: -122.4194
      radius: 100 # meters

  trusted_networks:
    - "MyHomeWiFi"
    - "MyOfficeWiFi"

notifications:
  show_armed: true
  show_disarmed: true
  show_trigger: true
  show_grace_countdown: true
```

## Technical Architecture

### Components

1. **Menu Bar Application**

   - SwiftUI for modern macOS interface
   - NSStatusItem for menu bar presence
   - LaunchAgent for startup

2. **Power Monitor Service**

   - IOKit framework for power state monitoring
   - Supports all power adapter types
   - Real-time event handling

3. **Security Action Engine**

   - Modular action system
   - Configurable execution (immediate/delayed, sequential/parallel)
   - Failure recovery with logging

4. **Authentication Manager**

   - LocalAuthentication framework
   - TouchID/password for arm/disarm
   - Secure credential handling

5. **Configuration Manager**
   - JSON configuration files
   - Secure storage in Keychain for sensitive data
   - Hot-reload support

### System Requirements

- macOS 11.0 (Big Sur) or later
- Any Mac with power adapter support
- Administrator privileges for some actions

## Development Roadmap

### Phase 1: MVP (Week 1)

- [x] Proof of concept power monitoring
- [ ] Basic menu bar app with authentication
- [ ] Screen lock action with force logout
- [ ] Grace period implementation
- [ ] Configuration file support

### Phase 2: Core Features (Week 2)

- [ ] All security actions
- [ ] Configuration UI
- [ ] Auto-arm features
- [ ] Notification system

### Phase 3: Advanced Features (Week 3)

- [ ] Location awareness
- [ ] Custom scripts
- [ ] Network actions
- [ ] Alarm system with visual alerts

### Phase 4: Release Preparation (Week 4)

- [ ] Code signing and notarization
- [ ] Documentation
- [ ] GitHub repository setup
- [ ] Direct download distribution
- [ ] Security audit

## Use Cases

1. **Coffee Shop Protection**

   - Auto-arms when connecting to public Wi-Fi
   - 10-second grace period for accidental disconnects
   - Force logout if already locked

2. **Office Security**

   - Arms automatically when screen locks
   - Custom script notifies IT security
   - Trusted network prevents false positives

3. **Travel Safety**

   - Enhanced protection in airports/hotels
   - Alarm draws attention to theft
   - Location tracking activated

4. **High-Security Environments**
   - Immediate action, no grace period
   - Custom script for data destruction
   - Network isolation

## Security Considerations

- **Open Source**: Full source code transparency
- Code signing with Developer ID
- Notarization for Gatekeeper
- Secure storage of sensitive settings
- Authentication required for state changes
- No telemetry by default
- Local processing only

## Distribution Plan

1. **Phase 1**: Direct download with Developer ID signing
2. **Phase 2**: Homebrew cask for easy installation
3. **Phase 3**: Mac App Store (if sandboxing permits)

## Related Projects

- [BusKill](https://github.com/BusKill/buskill-app) - Original USB kill cord
- [Lockdown](https://objective-see.com/products/lockdown.html) - macOS security tool
- [Do Not Disturb](https://github.com/sindresorhus/do-not-disturb) - Menu bar app example

## Resources

- [IOKit Power Management](https://developer.apple.com/documentation/iokit/power_management)
- [LocalAuthentication Framework](https://developer.apple.com/documentation/localauthentication)
- [macOS Security Guide](https://developer.apple.com/documentation/security)
- [Swift Menu Bar Apps](https://developer.apple.com/documentation/appkit/nsstatusitem)
