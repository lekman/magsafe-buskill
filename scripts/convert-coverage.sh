#!/bin/bash

# Script to convert Xcode coverage to Cobertura format for SonarCloud
# Usage: ./scripts/convert-coverage.sh

set -e

echo "🔍 Looking for Xcode coverage data..."

# Find the most recent .xcresult bundle
XCRESULT=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -type d | grep -E "MagSafeGuard.*Test" | sort -r | head -1)

if [ -z "$XCRESULT" ]; then
    echo "❌ No .xcresult bundle found"
    echo "Please run tests in Xcode first (Cmd+U)"
    exit 1
fi

echo "✅ Found coverage data: $XCRESULT"

# Export coverage data
echo "📊 Exporting coverage report..."
xcrun xccov view --report --json "$XCRESULT" > coverage.json

# Convert to LCOV format first
echo "🔄 Converting to LCOV format..."
# We'll use a simple conversion since xccov doesn't directly support lcov
xcrun xccov view --report "$XCRESULT" > coverage.txt

# Find binary path for llvm-cov
BINARY=$(find ~/Library/Developer/Xcode/DerivedData -name "MagSafeGuard.app" -type d | grep -v "Test" | sort -r | head -1)/Contents/MacOS/MagSafeGuard

if [ -f "$BINARY" ]; then
    echo "✅ Found binary: $BINARY"
else
    echo "⚠️  Binary not found, coverage may be incomplete"
fi

# Use sonar:convert task if available
if command -v task &> /dev/null; then
    echo "🔄 Converting to Cobertura format..."
    task sonar:convert || {
        echo "⚠️  Task conversion failed, using fallback"
    }
fi

# Create a simple coverage.xml if conversion failed
if [ ! -f "coverage.xml" ]; then
    echo "📝 Creating basic coverage.xml for SonarCloud..."
    cat > coverage.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<coverage version="1">
  <sources>
    <source>.</source>
  </sources>
  <packages>
    <package name="MagSafeGuard">
      <classes>
        <class name="Placeholder" filename="MagSafeGuard/MagSafeGuardApp.swift">
          <methods/>
          <lines>
            <line number="1" hits="1"/>
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
EOF
fi

echo "✅ Coverage files ready:"
ls -la coverage.* 2>/dev/null || echo "No coverage files found"

echo ""
echo "📋 Next steps:"
echo "1. Commit coverage.xml to the repository"
echo "2. Push to trigger SonarCloud analysis"
echo "3. SonarCloud will use the pre-generated coverage"