# MagSafe BusKill

## A Dead-Man's Cord Theft Protection Switch for Your Mac

MagSafe BusKill transforms your Mac's power connection into an intelligent security guard. When armed, it instantly detects if your power cable is disconnected and triggers protective actions to secure your data - perfect for protecting your laptop in coffee shops, airports, or any public space.

### Key Features

⚡ **Instant Detection** - Responds in milliseconds when your power cable is disconnected  
🔒 **Secure Authentication** - Touch ID or password required to arm/disarm  
⏱️ **Smart Grace Period** - Prevents false alarms with configurable delay (10 seconds default)  
🎯 **Customizable Actions** - From simple screen lock to full system shutdown  
📍 **Location Aware** - Automatically arms in public spaces, disarms at trusted locations  
🔌 **Universal Compatibility** - Works with any Mac power adapter (MagSafe, USB-C, or third-party)

### How It Works

1. **Arm the protection** when working in public spaces
2. **Continue working normally** with your power adapter connected
3. **If someone grabs your laptop**, the power cable disconnects
4. **Security actions trigger** immediately (or after grace period)
5. **Your data stays protected** even if your laptop is stolen

Perfect for digital nomads, security-conscious professionals, and anyone who works with sensitive data in public spaces.

## Acknowledgments

MagSafe BusKill is inspired by the excellent work of the [BusKill Project](https://github.com/BusKill/buskill-app) - an open-source laptop kill cord that uses a USB magnetic breakaway to trigger security actions. We deeply appreciate their pioneering work in this space and their commitment to open-source security tools.

While BusKill requires a physical USB cable attachment, MagSafe BusKill adapts the concept to use your existing power connection, making it seamless for Mac users. We encourage you to check out the original BusKill project, especially if you need cross-platform support or prefer a dedicated hardware solution.

Special thanks to:

- The [BusKill team](https://github.com/BusKill) for creating the original concept and implementation
- [Michael Altfield](https://github.com/maltfield) and all BusKill contributors
- The open-source security community for continuous innovation

## Intended Usage

MagSafe BusKill is fully open source software, licensed under the [MIT License](LICENSE). We believe in transparency and community-driven development for security tools.

For information about contributing to the project, please see our [Contributors Guide](CONTRIBUTORS.md).

## Quick Start

### Installation Options

#### 1. Mac App Store (Recommended)

_Coming Soon_ - Get automatic updates and easy installation directly from the Mac App Store.

#### 2. Direct Download

Download the latest release from our [GitHub Releases](https://github.com/lekman/magsafe-buskill/releases) page.

**Note:** Direct downloads require manual updates. For automatic updates, please wait for the Mac App Store release.

### Getting Help

Need help or found an issue? We're here to assist:

- **Feature Request**: Have an idea? [Submit a feature request](https://github.com/lekman/magsafe-buskill/issues/new?template=feature_request.md)
- **Bug Report**: Found a problem? [Report an issue](https://github.com/lekman/magsafe-buskill/issues/new?template=bug_report.md)
- **Security Issue**: Found a vulnerability? [Report securely](https://github.com/lekman/magsafe-buskill/security/advisories/new)
- **General Question**: [Ask the community](https://github.com/lekman/magsafe-buskill/issues/new?template=question.md)

### Documentation

- [Requirements & Specifications](requirements.md)
- [Configuration Guide](docs/config-examples.yaml)
- [Authentication Flow](docs/auth-flow-design.md)
- [Developer Documentation](docs/) - _More sections coming soon_

## System Requirements

- macOS 11.0 (Big Sur) or later
- Any Mac with power adapter support
- Administrator privileges for some security actions

## Privacy & Security

- **No tracking**: We don't collect any user data
- **Local only**: All processing happens on your Mac
- **Open source**: Review our code anytime
- **Secure**: Requires authentication for all security operations

---

Made with ❤️ for the Mac community. Stay safe out there!
