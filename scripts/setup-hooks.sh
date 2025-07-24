#!/bin/bash
# Setup script for MagSafe Guard development environment

echo "🔧 Setting up MagSafe Guard development environment..."

# Configure git to use our hooks directory
git config core.hooksPath .githooks

echo "✅ Git hooks configured"

# Check if Semgrep is installed
if command -v semgrep &> /dev/null; then
    echo "✅ Semgrep is installed (version: $(semgrep --version | head -1))"
else
    echo "ℹ️  Semgrep not installed (optional but recommended)"
    echo "   To install: brew install semgrep"
    echo "   Pre-commit will still run basic security checks"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Git hooks will now:"
echo "  • Check for hardcoded secrets in Swift files"
echo "  • Detect private key files"
echo "  • Prevent committing .env files"
echo "  • Run Semgrep scan (if installed)"
echo "  • Validate commit message format (Conventional Commits)"
echo "  • Block certain words in commit messages"
echo ""
echo "To bypass hooks in emergencies: git commit --no-verify"
echo "To skip Semgrep only: SKIP_SEMGREP=1 git commit"