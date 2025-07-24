# Menu Bar Design Guide for MagSafe Guard

## Design Tool Setup

### 1. Figma Setup

1. Create free account at [figma.com](https://figma.com)
2. Download [Apple Design Resources](https://developer.apple.com/design/resources/)
3. Import the macOS UI Kit into your Figma workspace

### 2. Design Specifications

#### Menu Bar Icon Requirements

- **Size**: 16×16pt (design at 2x = 32×32px)
- **Format**: Template image (monochrome)
- **Variants needed**:
  - Armed state (red tinted shield)
  - Disarmed state (green tinted shield)
  - Power connected indicator overlay

#### Menu Structure

```ini
MagSafe Guard
├── Status: [Armed/Disarmed]
├── Power: [Connected/Disconnected]
├── ─────────────────────
├── Arm (requires auth)
├── Disarm (requires auth)
├── ─────────────────────
├── Settings...
├── About
└── Quit
```

#### Design Assets Needed

1. **Menu Bar Icons** (16×16pt)

   - shield.armed.svg
   - shield.disarmed.svg
   - power.connected.overlay.svg

2. **Menu Items**
   - Status indicators
   - Authentication prompts
   - Settings window mockup
   - Grace period countdown UI

## Visual Design Guidelines

### Color Palette

- **Armed**: System Red (#FF3B30)
- **Disarmed**: System Green (#34C759)
- **Warning**: System Orange (#FF9500)
- **Neutral**: System Gray (#8E8E93)

### Typography

- Menu items: SF Pro Text, 13pt
- Status text: SF Pro Text Medium, 13pt
- Keyboard shortcuts: SF Pro Text, 11pt, gray

### Interaction States

1. **Normal**: Default appearance
2. **Hover**: Highlight with selection color
3. **Pressed**: Slightly darker highlight
4. **Disabled**: 50% opacity

## Implementation Notes

### SwiftUI MenuBarExtra Structure

```swift
MenuBarExtra("MagSafe Guard", systemImage: "shield") {
    // Status section
    Text("Status: \(isArmed ? "Armed" : "Disarmed")")
    Text("Power: \(isPowerConnected ? "Connected" : "Disconnected")")

    Divider()

    // Actions
    Button("Arm") {
        authenticateAndArm()
    }
    .disabled(isArmed)

    Button("Disarm") {
        authenticateAndDisarm()
    }
    .disabled(!isArmed)

    Divider()

    // Options
    Button("Settings...") {
        openSettings()
    }

    Button("About") {
        openAbout()
    }

    Divider()

    Button("Quit") {
        NSApplication.shared.terminate(nil)
    }
}
```

## Design References

- **Little Snitch**: Clean security status indication
- **1Password**: Authentication flow
- **CleanMyMac X**: Visual feedback for actions
- **Stats**: Minimalist system monitoring

## Accessibility Considerations

- Support VoiceOver for all menu items
- Provide keyboard navigation
- Include status announcements for screen readers
- Test with Reduce Transparency enabled

## Export Requirements

- @1x: 16×16px PNG
- @2x: 32×32px PNG
- Template images (single color, let system tint)
- Include in Asset Catalog as "Template Image"
