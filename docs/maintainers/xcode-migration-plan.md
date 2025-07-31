# Xcode Migration Plan for MagSafe Guard

## Overview

This document outlines the migration from Swift Package Manager (SPM) to a proper Xcode project structure to resolve CloudKit and app launch issues.

## Current Issues with SPM Approach

1. **CloudKit Configuration**: Difficult to properly configure CloudKit containers without Xcode
2. **Code Signing**: Manual signing configuration is error-prone
3. **Entitlements**: Manual entitlement management causes issues
4. **Launch Issues**: App crashes with "Launchd job spawn failed"
5. **Bundle Resources**: Manual resource bundling is problematic

## Migration Strategy

### Option 1: Copy Xcode Project Here (Recommended)
```
magsafe-buskill/
├── MagSafe Guard.xcodeproj
├── MagSafe Guard/
│   ├── Sources/
│   ├── Resources/
│   └── MagSafe_Guard.entitlements
├── MagSafe GuardTests/
└── MagSafe GuardUITests/
```

### Option 2: Use Existing Xcode Project Location
- Keep project at `/Users/tobiaslekman/Repo/MagSafe Guard`
- Move source files there
- Update git remotes

## Migration Steps

### Phase 1: Project Setup
1. Copy Xcode project to current repository
2. Configure CloudKit container in Xcode
3. Set up proper code signing
4. Configure entitlements

### Phase 2: Source Migration
1. Move all Swift files from `Sources/MagSafeGuard/` to Xcode project
2. Update import statements if needed
3. Add resources (Assets, Info.plist)
4. Configure build settings

### Phase 3: CloudKit Configuration
1. Enable CloudKit capability in Xcode
2. Create CloudKit container (if needed)
3. Configure development/production environments
4. Set up push notifications

### Phase 4: Testing & Cleanup
1. Test app launch and CloudKit functionality
2. Remove old SPM files
3. Update documentation
4. Update CI/CD if needed

## Benefits of Xcode Project

1. **Visual Configuration**: Easy setup of capabilities, entitlements, and signing
2. **CloudKit Integration**: Proper CloudKit container setup with visual tools
3. **Debugging**: Better debugging support and crash logs
4. **Resources**: Proper resource management with asset catalogs
5. **Testing**: Integrated UI and unit testing

## File Mapping

| Current SPM Location | Xcode Project Location |
|---------------------|------------------------|
| Sources/MagSafeGuard/MagSafeGuardApp.swift | MagSafe Guard/MagSafe_GuardApp.swift |
| Sources/MagSafeGuard/AppController.swift | MagSafe Guard/Controllers/AppController.swift |
| Sources/MagSafeGuard/Services/* | MagSafe Guard/Services/* |
| Sources/MagSafeGuard/Settings/* | MagSafe Guard/Views/Settings/* |
| Resources/Assets.xcassets | MagSafe Guard/Assets.xcassets |
| Resources/*.entitlements | MagSafe Guard/MagSafe_Guard.entitlements |

## Next Steps

1. Decide on project location (Option 1 or 2)
2. Begin migration with project setup
3. Move source files systematically
4. Test each component after migration
5. Clean up old structure