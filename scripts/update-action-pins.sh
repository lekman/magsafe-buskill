#!/bin/bash
# Update GitHub Action pins to their latest versions while maintaining security
# This script updates the SHA pins while keeping the same version tags

set -euo pipefail

# Source .env if it exists for GITHUB_TOKEN
if [ -f .env ]; then
    source .env
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get SHA for a given action and version
get_action_sha() {
    local action="$1"
    local version="$2"
    
    # Parse owner/repo from action
    local owner="${action%%/*}"
    local repo="${action#*/}"
    
    # Remove any path from repo (e.g., codeql-action/init -> codeql-action)
    repo="${repo%%/*}"
    
    # Set up curl options with auth if available
    local curl_opts="-s"
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl_opts="$curl_opts -H 'Authorization: token $GITHUB_TOKEN'"
    fi
    
    # Handle version tags vs branch names
    if [[ "$version" =~ ^v[0-9] ]]; then
        # It's a version tag - try multiple formats
        local sha=$(eval "curl $curl_opts 'https://api.github.com/repos/$owner/$repo/git/refs/tags/$version'" | jq -r '.object.sha // empty' 2>/dev/null)
        
        # If not found, try with repo name prefix (e.g., auto-approve-action@v1.0.0)
        if [ -z "$sha" ] || [ "$sha" = "null" ]; then
            sha=$(eval "curl $curl_opts 'https://api.github.com/repos/$owner/$repo/git/refs/tags/$repo@$version'" | jq -r '.object.sha // empty' 2>/dev/null)
        fi
    else
        # It's a branch name
        local sha=$(eval "curl $curl_opts 'https://api.github.com/repos/$owner/$repo/git/refs/heads/$version'" | jq -r '.object.sha // empty' 2>/dev/null)
    fi
    
    if [ -z "$sha" ] || [ "$sha" = "null" ]; then
        echo ""
    else
        echo "$sha"
    fi
}

# Main execution
echo -e "${BLUE}🔄 Updating GitHub Action pins to latest SHAs...${NC}"
if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo -e "${GREEN}✓ Using GitHub authentication${NC}"
else
    echo -e "${YELLOW}⚠ No GITHUB_TOKEN found. API rate limits may apply.${NC}"
    echo -e "${YELLOW}  Set GITHUB_TOKEN in .env file for better performance.${NC}"
fi
echo ""

# Check if we have GitHub API access
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed. Install with: brew install jq${NC}"
    exit 1
fi

# Process each workflow file
updated_count=0
failed_count=0
unchanged_count=0

for file in .github/workflows/*.yml; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}📝 Processing $(basename "$file")...${NC}"
        
        # Create backup
        cp "$file" "$file.bak"
        
        # Find all pinned actions in the file
        pinned_actions=$(grep -E "uses:\s*[^/]+/[^@]+@[0-9a-f]{40}\s*#\s*[^\s]+" "$file" || true)
        
        if [ -z "$pinned_actions" ]; then
            rm "$file.bak"
            echo "   No pinned actions found in this file"
            continue
        fi
        
        # Process each pinned action
        file_updated=false
        while IFS= read -r line; do
            if [ -z "$line" ]; then
                continue
            fi
            
            # Extract action, current SHA, and version comment
            if [[ "$line" =~ uses:[[:space:]]*([^@]+)@([0-9a-f]{40})[[:space:]]*#[[:space:]]*([^[:space:]]+) ]]; then
                action="${BASH_REMATCH[1]}"
                current_sha="${BASH_REMATCH[2]}"
                version="${BASH_REMATCH[3]}"
                
                # Get latest SHA for this version
                echo -n "   Checking $action@$version... "
                new_sha=$(get_action_sha "$action" "$version")
                
                if [ -z "$new_sha" ]; then
                    echo -e "${RED}failed to fetch${NC}"
                    ((failed_count++))
                    continue
                fi
                
                if [ "$current_sha" = "$new_sha" ]; then
                    echo -e "${GREEN}up to date${NC}"
                    ((unchanged_count++))
                    continue
                fi
                
                echo -e "${YELLOW}updating${NC}"
                echo -e "     Current: ${current_sha:0:7}"
                echo -e "     New:     ${new_sha:0:7}"
                
                # Update the SHA in the file
                escaped_action=$(echo "$action" | sed 's/[[\.*^$()+?{|]/\\&/g')
                sed -i '' "s|$escaped_action@$current_sha # $version|$action@$new_sha # $version|g" "$file"
                
                if [ $? -eq 0 ]; then
                    file_updated=true
                    ((updated_count++))
                fi
            fi
        done <<< "$pinned_actions"
        
        # Check if file was actually modified
        if cmp -s "$file" "$file.bak"; then
            rm "$file.bak"
            echo -e "   ${GREEN}✅ No updates needed${NC}"
        else
            rm "$file.bak"
            echo -e "   ${GREEN}✅ Updated successfully${NC}"
        fi
    fi
done

echo ""
echo -e "${GREEN}✅ Update check complete!${NC}"
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo "   • Actions updated: $updated_count"
echo "   • Already up to date: $unchanged_count"
echo "   • Failures: $failed_count"

if [ $updated_count -gt 0 ]; then
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "   1. Review changes: git diff .github/workflows/"
    echo "   2. Test workflows to ensure they still work"
    echo "   3. Commit the updates"
fi

# Exit with error if any actions failed to update
if [ $failed_count -gt 0 ]; then
    exit 1
fi