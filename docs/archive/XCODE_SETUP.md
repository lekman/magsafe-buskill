# Xcode Project Setup for MagSafe Guard

## Issue: "No such module 'MagSafeGuardDomain'"

The Xcode project needs to be configured to use the local Swift Package Manager libraries.

## Solution

### Option 1: Add Local Package Dependency (Recommended)

1. Open `MagSafeGuard.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "MagSafeGuard" target
4. Go to the "General" tab
5. Under "Frameworks, Libraries, and Embedded Content", click the "+" button
6. Instead of selecting a framework, click "Add Package Dependency..."
7. Click "Add Local..."
8. Navigate to your project root directory and select it
9. Click "Add Package"
10. In the package products selection, check:
    - `MagSafeGuardDomain`
    - `MagSafeGuardCore`
11. Click "Add Package"

### Option 2: Remove Module Imports (Quick Fix)

If you need to run immediately without setting up the package dependency:

1. Remove the `import MagSafeGuardDomain` statements from:
   - `/MagSafeGuard/Models/SettingsModel.swift`
   - Any other files that import it

2. Copy the `SecurityActionType` enum definition directly into `SettingsModel.swift` temporarily

### Option 3: Use Swift Package Manager Command Line

Build and run using Swift Package Manager instead of Xcode:

```bash
# Build the app
swift build

# Or use the Taskfile
task build
```

## Long-term Solution

The project should be restructured to either:

1. Use Swift Package Manager exclusively (recommended for clean architecture)
2. Configure the Xcode project to properly reference the SPM packages
3. Create an Xcode workspace that includes both the project and the package

## Current Architecture

The project follows Clean Architecture with:

- **Domain Layer** (`MagSafeGuardDomain`): Business logic, protocols, use cases
- **Core Layer** (`MagSafeGuardCore`): Shared utilities, models
- **App Layer**: UI, controllers, system integration

The Xcode project needs to reference these SPM libraries to access the domain types.
