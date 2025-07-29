#!/bin/bash
#
# test-run-commands.sh - Test script to verify enhanced run commands
#
# This script tests the various run commands to ensure they work correctly
# for different user types and scenarios.
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}MagSafe Guard Run Commands Test${NC}"
echo "=================================="
echo ""

# Detect environment
IS_ADMIN=false
if groups | grep -q admin; then
    IS_ADMIN=true
fi

HAS_SUDO=false
if sudo -n true 2>/dev/null; then
    HAS_SUDO=true
fi

HAS_DEV_CERT=false
if security find-identity -v -p codesigning | grep -q "Apple Development"; then
    HAS_DEV_CERT=true
fi

echo "Environment:"
echo "  • User type: $([ "$IS_ADMIN" = true ] && echo "Admin" || echo "Standard")"
echo "  • Sudo access: $([ "$HAS_SUDO" = true ] && echo "Available" || echo "Not available")"
echo "  • Dev certificate: $([ "$HAS_DEV_CERT" = true ] && echo "Found" || echo "Not found")"
echo ""

# Test function
test_command() {
    local cmd=$1
    local desc=$2
    
    echo -e "${YELLOW}Testing: $desc${NC}"
    echo "Command: $cmd"
    
    # Kill any existing instances first
    killall MagSafeGuard 2>/dev/null || true
    sleep 1
    
    # Run the command
    if $cmd; then
        echo -e "${GREEN}✅ Success${NC}"
        
        # Check if app is running
        sleep 2
        if pgrep -x "MagSafeGuard" > /dev/null; then
            echo -e "${GREEN}✅ App is running${NC}"
            # Kill it for next test
            killall MagSafeGuard 2>/dev/null || true
            sleep 1
        else
            echo -e "${RED}❌ App not running after launch${NC}"
        fi
    else
        echo -e "${RED}❌ Command failed${NC}"
    fi
    
    echo ""
}

# Show help first
echo -e "${BLUE}Running help command...${NC}"
task run:help
echo ""
echo "Press Enter to continue with tests..."
read -r

# Test based on user type
if [ "$IS_ADMIN" = false ]; then
    echo -e "${BLUE}Running tests for STANDARD user${NC}"
    echo ""
    
    # Most likely to work for standard users
    test_command "task run:direct" "Direct execution mode"
    test_command "task run:unsigned" "Unsigned app bundle"
    test_command "task run" "Smart detection mode"
    
else
    echo -e "${BLUE}Running tests for ADMIN user${NC}"
    echo ""
    
    # Test in order of likelihood to work
    test_command "task run" "Smart detection mode"
    test_command "task run:unsigned" "Unsigned app bundle"
    test_command "task run:direct" "Direct execution mode"
    
    if [ "$HAS_DEV_CERT" = true ]; then
        test_command "task run:sign" "Signed app bundle"
    fi
fi

# Always test debug mode
test_command "task run:debug" "Debug mode"

echo -e "${BLUE}Test Summary${NC}"
echo "============="
echo ""
echo "All tests completed. Check output above for any issues."
echo ""
echo "Recommendations:"

if [ "$IS_ADMIN" = false ]; then
    echo "  • As a standard user, 'task run:direct' is most reliable"
    echo "  • For app bundle features, ask admin to run:"
    echo "    su - ADMIN_USER -c 'xattr -cr $(pwd)/.build/bundler/MagSafeGuard.app'"
else
    echo "  • As an admin user, 'task run' should work well"
    echo "  • If you have signing issues, use 'task run:unsigned'"
fi

echo ""
echo "For rapid development, try: task run:watch (requires fswatch)"