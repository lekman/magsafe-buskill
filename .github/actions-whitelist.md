# GitHub Actions Whitelist Configuration

## Repository Settings → Actions → General

Select: **"Allow lekman, and select non-lekman, actions and reusable workflows"**

Then add these actions to the whitelist:

### Code Quality & Security Scanning

```text
codecov/codecov-action@*
returntocorp/semgrep-action@*
trufflesecurity/trufflehog@*
fossas/fossa-action@*
ossf/scorecard-action@*
snyk/actions/setup@*
```

### Build & Development Tools

```text
swift-actions/setup-swift@*
maxim-lobanov/setup-xcode@*
webiny/action-conventional-commits@*
```

### Release & Deployment

```text
softprops/action-gh-release@*
googleapis/release-please-action@*
```

## Full Whitelist (Copy & Paste)

Copy this entire list and paste it into the GitHub Actions settings:

```text
codecov/codecov-action@*,returntocorp/semgrep-action@*,trufflesecurity/trufflehog@*,fossas/fossa-action@*,ossf/scorecard-action@*,snyk/actions/setup@*,swift-actions/setup-swift@*,maxim-lobanov/setup-xcode@*,webiny/action-conventional-commits@*,softprops/action-gh-release@*,googleapis/release-please-action@*
```

## Security Considerations

### Why Whitelist?

- Prevents use of unknown/malicious actions
- Forces review before adding new dependencies
- Reduces supply chain attack surface

### Best Practices

1. **Pin to specific versions** in workflows (use SHA)
2. **Review actions** before adding to whitelist
3. **Audit regularly** - remove unused actions
4. **Monitor** for security advisories

### Adding New Actions

Before adding a new action:

1. Check the action's source code
2. Verify the publisher
3. Look for security vulnerabilities
4. Consider alternatives from verified publishers

## Verification Script

After setting up the whitelist, run this to verify:

```bash
#!/bin/bash
# Save as scripts/verify-actions-whitelist.sh

echo "Checking if all used actions are in whitelist..."

# Expected actions (from whitelist)
WHITELIST=(
    "actions/cache"
    "actions/checkout"
    "actions/create-github-app-token"
    "actions/dependency-review-action"
    "actions/github-script"
    "actions/upload-artifact"
    "github/codeql-action"
    "codecov/codecov-action"
    "returntocorp/semgrep-action"
    "trufflesecurity/trufflehog"
    "fossas/fossa-action"
    "ossf/scorecard-action"
    "snyk/actions"
    "swift-actions/setup-swift"
    "maxim-lobanov/setup-xcode"
    "webiny/action-conventional-commits"
    "softprops/action-gh-release"
    "googleapis/release-please-action"
    "lekman/auto-approve-action"
)

# Find all used actions
USED_ACTIONS=$(find .github -name "*.yml" -o -name "*.yaml" | \
    xargs grep -h "uses:" | \
    grep -v "\./" | \
    sed 's/.*uses: *//' | \
    sed 's/@.*//' | \
    sed 's|/[^/]*@.*||' | \
    sort -u)

# Check each used action
for action in $USED_ACTIONS; do
    found=false
    for allowed in "${WHITELIST[@]}"; do
        if [[ "$action" == "$allowed"* ]]; then
            found=true
            break
        fi
    done

    if ! $found; then
        echo "❌ Action not in whitelist: $action"
    else
        echo "✅ $action"
    fi
done
```

## Notes

- **GitHub and lekman actions are automatically allowed** when you select "Allow lekman, and select non-lekman, actions"
- The whitelist must be **comma-separated** with no spaces between entries
- The `@*` suffix allows any version of the action
- For `snyk/actions/setup@*`, the `/*` allows subpaths like `/swift` and other language-specific actions
- Always prefer actions from verified publishers (has checkmark on GitHub Marketplace)

## What's Automatically Allowed

When you select "Allow lekman, and select non-lekman, actions", these are automatically allowed:

- All `actions/*` (GitHub's official actions like checkout, upload-artifact, etc.)
- All `github/*` (GitHub's CodeQL and other actions)
- All `lekman/*` (Your own organization's actions)
