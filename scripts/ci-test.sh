#!/bin/bash
set -e

echo "🧪 Running CI Tests with Swift Package Manager"
echo "=============================================="

# Clean any previous test artifacts
rm -rf .build

# Build the package
echo "🔨 Building package..."
swift build --configuration debug

# Run tests
echo "🧪 Running tests..."
swift test --configuration debug --parallel

# Generate coverage if available
echo "📊 Generating coverage report..."
swift test --enable-code-coverage || true

# Find and convert coverage data
if [ -d ".build/debug/codecov" ]; then
    echo "✅ Coverage data generated"
    # Convert to LCOV format if needed
    if command -v xcrun &> /dev/null; then
        PROF_DATA=$(find .build -name 'default.profdata' -type f | head -1)
        BINARY=$(find .build -name 'MagSafeGuardCorePackageTests.xctest' -type d | head -1)/Contents/MacOS/MagSafeGuardCorePackageTests
        
        if [[ -f "$PROF_DATA" ]] && [[ -f "$BINARY" ]]; then
            xcrun llvm-cov export \
                -format=lcov \
                -instr-profile="$PROF_DATA" \
                "$BINARY" > coverage.lcov || true
        fi
    fi
else
    echo "⚠️  No coverage data found"
fi

echo "✅ CI tests completed successfully!"