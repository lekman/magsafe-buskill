#!/bin/bash
#
# sign-app.sh - Code signing script for MagSafe Guard
# 
# This script handles code signing for different build configurations:
# - development: Local development with Apple Development certificate
# - release: Direct distribution with Developer ID certificate
# - appstore: App Store distribution with Apple Distribution certificate
# - ci: CI/testing with ad-hoc signing (no certificate required)
#
# Usage: ./scripts/sign-app.sh [configuration] [app-path]
#   configuration: development|release|appstore|ci (default: development)
#   app-path: Path to .app bundle (default: .build/bundler/MagSafeGuard.app)

set -euo pipefail

# Configuration
CONFIGURATION="${1:-development}"
APP_PATH="${2:-.build/bundler/MagSafeGuard.app}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Validate configuration
case "$CONFIGURATION" in
    development|release|appstore|ci)
        ;;
    *)
        log_error "Invalid configuration: $CONFIGURATION"
        echo "Valid options: development, release, appstore, ci"
        exit 1
        ;;
esac

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    log_error "App bundle not found at: $APP_PATH"
    echo "Build the app first with: task build"
    exit 1
fi

log_info "Signing MagSafe Guard"
echo "Configuration: $CONFIGURATION"
echo "App path: $APP_PATH"
echo ""

# Determine signing parameters based on configuration
case "$CONFIGURATION" in
    development)
        IDENTITY="Apple Development"
        ENTITLEMENTS="$PROJECT_ROOT/Resources/MagSafeGuard.development.entitlements"
        RUNTIME_FLAGS=""
        ;;
    release)
        IDENTITY="Developer ID Application"
        ENTITLEMENTS="$PROJECT_ROOT/Resources/MagSafeGuard.developerid.entitlements"
        RUNTIME_FLAGS="--options=runtime --timestamp"
        ;;
    appstore)
        IDENTITY="Apple Distribution"
        ENTITLEMENTS="$PROJECT_ROOT/Resources/MagSafeGuard.entitlements"
        RUNTIME_FLAGS="--options=runtime --timestamp"
        ;;
    ci)
        IDENTITY="-" # Ad-hoc signing
        ENTITLEMENTS="$PROJECT_ROOT/Resources/MagSafeGuard.ci.entitlements"
        RUNTIME_FLAGS=""
        ;;
esac

# Check entitlements file
if [ ! -f "$ENTITLEMENTS" ]; then
    log_error "Entitlements file not found: $ENTITLEMENTS"
    exit 1
fi

# For non-CI builds, check for signing identity
if [ "$CONFIGURATION" != "ci" ]; then
    log_info "Checking for signing identity..."
    
    # Find exact identity
    FOUND_IDENTITY=$(security find-identity -v -p codesigning | grep "$IDENTITY" | head -1 | awk '{print $2}')
    
    if [ -z "$FOUND_IDENTITY" ]; then
        log_error "No valid '$IDENTITY' certificate found"
        echo ""
        echo "Available identities:"
        security find-identity -v -p codesigning || echo "No identities found"
        echo ""
        
        if [ "$CONFIGURATION" = "development" ]; then
            echo "To create a development certificate:"
            echo "1. Open Xcode → Settings → Accounts"
            echo "2. Select your Apple ID"
            echo "3. Click 'Manage Certificates'"
            echo "4. Click '+' → 'Apple Development'"
        elif [ "$CONFIGURATION" = "release" ]; then
            echo "To create a Developer ID certificate:"
            echo "1. Visit https://developer.apple.com/account"
            echo "2. Go to Certificates, Identifiers & Profiles"
            echo "3. Create a 'Developer ID Application' certificate"
            echo "4. Download and install it"
        fi
        exit 1
    fi
    
    log_success "Found signing identity: $FOUND_IDENTITY"
    IDENTITY="$FOUND_IDENTITY"
fi

# Remove extended attributes
log_info "Removing extended attributes..."
xattr -cr "$APP_PATH" 2>/dev/null || true

# Sign the app
log_info "Signing app bundle..."

if [ "$CONFIGURATION" = "ci" ]; then
    # Ad-hoc signing for CI
    if codesign --force --deep --sign "-" "$APP_PATH"; then
        log_success "Ad-hoc signing successful"
    else
        log_error "Ad-hoc signing failed"
        exit 1
    fi
else
    # Certificate-based signing
    SIGN_CMD="codesign --force --deep --sign \"$IDENTITY\" --entitlements \"$ENTITLEMENTS\" $RUNTIME_FLAGS \"$APP_PATH\""
    
    if eval "$SIGN_CMD"; then
        log_success "Code signing successful"
    else
        log_error "Code signing failed"
        exit 1
    fi
fi

# Verify signature
log_info "Verifying signature..."

if codesign --verify --deep --verbose=2 "$APP_PATH" 2>&1; then
    log_success "Signature verification passed"
else
    log_error "Signature verification failed"
    exit 1
fi

# Display signature info
log_info "Signature details:"
codesign -dvvv "$APP_PATH" 2>&1 | grep -E "Authority|TeamIdentifier|Signature" | head -10

# Additional checks for release builds
if [ "$CONFIGURATION" = "release" ] || [ "$CONFIGURATION" = "appstore" ]; then
    log_info "Checking notarization readiness..."
    
    # Check if app is ready for notarization
    if spctl -a -t exec -vvv "$APP_PATH" 2>&1 | grep -q "accepted"; then
        log_success "App is ready for notarization"
    else
        log_warning "App may need notarization for distribution"
        echo ""
        echo "To notarize:"
        echo "1. Create a zip: ditto -c -k --keepParent \"$APP_PATH\" \"MagSafeGuard.zip\""
        echo "2. Submit: xcrun notarytool submit \"MagSafeGuard.zip\" --wait"
        echo "3. Staple: xcrun stapler staple \"$APP_PATH\""
    fi
fi

echo ""
log_success "Code signing complete!"
echo ""
echo "Signed app: $APP_PATH"

# Show next steps based on configuration
case "$CONFIGURATION" in
    development)
        echo ""
        echo "To run the app:"
        echo "  open \"$APP_PATH\""
        ;;
    release)
        echo ""
        echo "Next steps for distribution:"
        echo "1. Notarize the app (see above)"
        echo "2. Create DMG or installer"
        echo "3. Distribute to users"
        ;;
    appstore)
        echo ""
        echo "Next steps for App Store:"
        echo "1. Archive in Xcode"
        echo "2. Upload to App Store Connect"
        echo "3. Submit for review"
        ;;
    ci)
        echo ""
        echo "CI build ready for testing"
        ;;
esac