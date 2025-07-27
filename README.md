# MagSafe Guard

## A Dead-Man's Cord Theft Protection Switch for Your Mac

MagSafe Guard transforms your Mac's power connection into an intelligent security guard. When armed, it instantly detects if your power cable is disconnected and triggers protective actions to secure your data - perfect for protecting your laptop in coffee shops, airports, or any public space.

![Demo](docs/assets/magsafe-guard.gif)

### Key Features

⚡ **Instant Detection** - Responds in milliseconds when your power cable is disconnected  
🔒 **Secure Authentication** - Touch ID or password required to arm/disarm  
⏱️ **Smart Grace Period** - Prevents false alarms with configurable delay (10 seconds default)  
🎯 **Customizable Actions** - From simple screen lock to full system shutdown  
📍 **Location Aware** - Automatically arms in public spaces, disarms at trusted locations  
🔌 **Universal Compatibility** - Works with any Mac power adapter (MagSafe, USB-C, or third-party)  
📋 **Supply Chain Transparency** - Software Bill of Materials (SBOM) included for security compliance

### How It Works

1. **Arm the protection** when working in public spaces
2. **Continue working normally** with your power adapter connected
3. **If someone grabs your laptop**, the power cable disconnects
4. **Security actions trigger** immediately (or after grace period)
5. **Your data stays protected** even if your laptop is stolen

Perfect for digital nomads, security-conscious professionals, and anyone who works with sensitive data in public spaces.

## Acknowledgments

MagSafe Guard is inspired by the excellent work of the [BusKill Project](https://github.com/BusKill/buskill-app) - an open-source laptop kill cord that uses a USB magnetic breakaway to trigger security actions. We deeply appreciate their pioneering work in this space and their commitment to open-source security tools.

While BusKill requires a physical USB cable attachment, MagSafe Guard adapts the concept to use your existing power connection, making it seamless for Mac users. We encourage you to check out the original BusKill project, especially if you need cross-platform support or prefer a dedicated hardware solution.

Special thanks to:

- The [BusKill team](https://github.com/BusKill) for creating the original concept and implementation
- [Michael Altfield](https://github.com/maltfield) and all BusKill contributors
- The open-source security community for continuous innovation

## Intended Usage

MagSafe Guard is fully open source software, licensed under the [MIT License](LICENSE). We believe in transparency and community-driven development for security tools.

For information about contributing to the project, please see our [Contributors Guide](docs/CONTRIBUTORS.md).

## Installation

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

📚 **[View Full Documentation](docs/README.md)** - Comprehensive guides and API references

**Quick Links:**

- [Changelog](docs/CHANGELOG.md)
- [QA Dashboard](docs/QA.md)
- [All Documentation](docs/)

## Development

> **Note:** MagSafe Guard is a Swift Package project. You can use either Xcode or command-line tools for development. The menu bar app requires special handling - use `task run` for the best experience.

### Quick Start

1. **Install Task** (if not already installed):

   ```bash
   brew install go-task/tap/go-task
   ```

2. **Initialize Development Environment**:

   ```bash
   task setup
   ```

   This sets up git hooks and verifies your development tools.

3. **Build and Run**:

   ```bash
   # Run the menu bar app
   task run
   ```

   Look for the lock shield icon in your menu bar.

   **For Debugging:**

   Since MagSafe Guard is a menu bar app, it requires special handling in Xcode:

   1. **Run the app in debug mode first:**

      ```bash
      task run:debug
      ```

   2. **Attach debugger from Xcode:**

      - Open the project in Xcode: `open Package.swift`
      - Once the app is running, go to **Debug → Attach to Process**
      - Select **MagSafeGuard** from the list
      - Now you can set breakpoints and debug normally

      This shows detailed logs in the terminal for troubleshooting.

### Testing

**For Development Testing:**

```bash
# Run all tests
task test

# Run tests with coverage
task test:coverage
```

**For CI/CD Automation:**

The following tasks are used to run testing and quality assurance prior to opening a pull request:

```ini
task qa            # Run standard QA checks
task qa:quick      # Quick checks (for git hooks)
task qa:fix        # Auto-fix all fixable issues
task qa:full       # Full QA with SonarCloud
```

Tests are required to pass in our CI/CD approval flow. For more information, see the [CI/CD Workflows Documentation](docs/devops/ci-cd-workflows.md).

## System Requirements

- macOS 11.0 (Big Sur) or later
- Any Mac with power adapter support
- Administrator privileges for some security actions

## Security & Quality

View our [Quality Assurance Dashboard](docs/QA.md) for security status, code coverage, and quality metrics.

## Privacy & Security

- **No tracking**: We don't collect any user data
- **Local only**: All processing happens on your Mac
- **Open source**: Review our code anytime
- **Secure**: Requires authentication for all security operations

## Project Task Status

For details on the project progress, planned initiatives and current status, expand the section below.

<details>
<summary>Expand task status report</summary>

<!-- TASKMASTER_EXPORT_START -->
> 🎯 **Taskmaster Export** - 2025-07-27 12:33:57 UTC
> 📋 Export: without subtasks • Status filter: none
> 🔗 Powered by [Task Master](https://task-master.dev?utm_source=github-readme&utm_medium=readme-export&utm_campaign=magsafe-buskill&utm_content=task-export-link)

| Project Dashboard |  |
| :-                |:-|
| Task Progress     | ███████████░░░░░░░░░ 56% |
| Done | 9 |
| In Progress | 1 |
| Pending | 6 |
| Deferred | 0 |
| Cancelled | 0 |
|-|-|
| Subtask Progress | ███████████░░░░░░░░░ 55% |
| Completed | 56 |
| In Progress | 1 |
| Pending | 45 |


| ID | Title | Status | Priority | Dependencies | Complexity |
| :- | :-    | :-     | :-       | :-           | :-         |
| 1 | Setup Project Repository and Structure | ✓&nbsp;done | high | None | ● 4 |
| 2 | Implement Power Monitoring Service | ✓&nbsp;done | high | 1 | ● 7 |
| 3 | Implement Authentication Service | ✓&nbsp;done | high | 1 | ● 6 |
| 4 | Implement Security Actions Service | ✓&nbsp;done | high | 1 | ● 7 |
| 5 | Create Menu Bar UI Component | ✓&nbsp;done | high | 1 | ● 6 |
| 6 | Implement Core Application Logic | ✓&nbsp;done | high | 2, 3, 4, 5 | ● 8 |
| 7 | Implement Settings UI and Persistence | ✓&nbsp;done | medium | 1, 6 | ● 6 |
| 8 | Implement Auto-Arm Feature | ✓&nbsp;done | medium | 6, 7 | ● 7 |
| 9 | Implement Location Tracking and Evidence Collection | ►&nbsp;in-progress | low | 6 | ● 5 |
| 10 | Implement Custom Script Execution | ○&nbsp;pending | low | 6, 7 | ● 6 |
| 11 | Implement Network Actions | ○&nbsp;pending | low | 6, 7 | ● 6 |
| 12 | Implement Data Protection Features | ○&nbsp;pending | low | 6, 7 | ● 7 |
| 13 | Implement Accessibility Features | ✓&nbsp;done | medium | 5, 7 | ● 6 |
| 14 | Implement Documentation and Help System | ○&nbsp;pending | medium | 1, 5, 6, 7 | ● 5 |
| 15 | Implement Code Signing and Distribution | ○&nbsp;pending | high | 1, 2, 3, 4, 5, 6, 7, 16 | ● 8 |
| 16 | Implement ViewInspector for SwiftUI Testing | ○&nbsp;pending | medium | 6, 13 | N/A |

> 📋 **End of Taskmaster Export** - Tasks are synced from your project using the `sync-readme` command.
<!-- TASKMASTER_EXPORT_END -->


</details>
