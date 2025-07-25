# Branch Protection Compliance Adjustments

Your current ruleset needs the following adjustments to fully enforce commit message restrictions:

## Required Changes

### 1. Add Required Status Checks ✅

Your ruleset is missing status checks for our commit message workflows. Add these required checks:

#### In GitHub UI

1. Go to **Settings** → **Rules** → **Rulesets**
2. Edit the "Protected" ruleset
3. Add rule: **Require status checks to pass**
4. Add these specific checks:
   - `Validate Commit Messages` (from commit-message-check.yml)
   - `Enforce Clean Commit History` (from enforce-clean-history.yml)
   - `Block Direct Push to Protected Branches` (from enforce-clean-history.yml)

#### What to add

```json
{
  "type": "required_status_checks",
  "parameters": {
    "required_status_checks": [
      {
        "context": "Validate Commit Messages"
      },
      {
        "context": "Enforce Clean Commit History"
      }
    ],
    "strict_required_status_checks_policy": true
  }
}
```

### 2. Consider Requiring Approvals 🤔

Currently set to 0 required approvals. For better security:

- Change `required_approving_review_count` from `0` to `1`
- This ensures at least one person reviews the code AND commit messages

### 3. Remove or Restrict Bypass Permissions ⚠️

Current setting allows Repository Role ID 5 to bypass ALL rules. This means:

- ❌ Admins can push commits with blocked words directly
- ❌ Admins can bypass signature requirements
- ❌ Admins can force push

**Recommended**: Change bypass mode or remove bypass entirely:

```json
"bypass_actors": []  // No bypasses allowed
```

Or limit bypass scope:

```json
"bypass_actors": [
  {
    "actor_id": 5,
    "actor_type": "RepositoryRole", 
    "bypass_mode": "pull_request"  // Only bypass PR requirement, not other rules
  }
]
```

## Complete Compliant Ruleset

Here's what your ruleset should look like for full compliance:

```json
{
  "id": 6934891,
  "name": "Protected",
  "target": "branch",
  "source_type": "Repository",
  "source": "lekman/magsafe-buskill",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "exclude": [],
      "include": ["~DEFAULT_BRANCH"]
    }
  },
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "required_signatures"
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,  // Changed from 0
        "dismiss_stale_reviews_on_push": true,  // Changed to true
        "require_code_owner_review": true,
        "require_last_push_approval": true,
        "required_review_thread_resolution": true,
        "automatic_copilot_code_review_enabled": true,
        "allowed_merge_methods": ["merge"]
      }
    },
    {
      "type": "required_status_checks",  // NEW RULE
      "parameters": {
        "required_status_checks": [
          {
            "context": "Validate Commit Messages"
          },
          {
            "context": "Enforce Clean Commit History"
          },
          {
            "context": "Security Scan / basic-checks"
          }
        ],
        "strict_required_status_checks_policy": true
      }
    },
    {
      "type": "code_scanning",
      "parameters": {
        "code_scanning_tools": [
          {
            "tool": "CodeQL",
            "security_alerts_threshold": "high_or_higher",
            "alerts_threshold": "errors"
          }
        ]
      }
    }
  ],
  "bypass_actors": []  // Removed bypass to ensure compliance
}
```

## Implementation Steps

### Step 1: Update via GitHub UI

1. Navigate to **Settings** → **Rules** → **Rulesets**
2. Click on "Protected" ruleset
3. Add the "Require status checks" rule
4. Select the three workflows mentioned above
5. Enable "Require branches to be up to date before merging"
6. Save changes

### Step 2: Test the Configuration

1. Create a test branch
2. Add a commit with a blocked word
3. Try to create a PR - it should fail status checks
4. Try to push directly - it should be blocked

### Step 3: Communicate Changes

Inform all contributors about:

- New status check requirements
- No bypass allowed (if you remove it)
- Commit message restrictions

## Why These Changes Matter

### Without Required Status Checks

- ❌ PRs can be merged even with blocked words in commits
- ❌ The workflows run but don't block merge
- ❌ Only local hooks provide protection

### With Required Status Checks

- ✅ PRs cannot merge until all commits are clean
- ✅ Server-side enforcement that cannot be bypassed
- ✅ Clear feedback in PR interface
- ✅ Automated compliance

## Verification

After making changes, verify with:

```bash
# Try to push a commit with blocked word
git commit -m "test: added claude to the code"
git push origin test-branch

# Create PR - should see failing checks

# Try direct push (should fail)
git push origin main
```

## Alternative: Keep Some Bypass

If you need emergency bypass capability:

1. Keep bypass but document when used
2. Create audit trail for bypass usage
3. Regular review of bypass events
4. Consider time-limited bypass windows

## Summary

Your current ruleset is good but needs:

1. ✅ Add required status checks (critical)
2. ✅ Consider requiring at least 1 approval
3. ✅ Remove or restrict bypass permissions
4. ✅ Enable "dismiss stale reviews"

These changes ensure no commits with blocked words can ever enter the main branch, maintaining a clean and professional repository history.
