#!/bin/bash
# Pin GitHub Actions to specific commit SHAs for security
# This script automatically fetches the latest SHA for each action version

set -euo pipefail

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
    
    # Handle version tags vs branch names
    if [[ "$version" =~ ^v[0-9] ]]; then
        # It's a version tag
        local sha=$(curl -s "https://api.github.com/repos/$owner/$repo/git/refs/tags/$version" | jq -r '.object.sha // empty' 2>/dev/null)
    else
        # It's a branch name
        local sha=$(curl -s "https://api.github.com/repos/$owner/$repo/git/refs/heads/$version" | jq -r '.object.sha // empty' 2>/dev/null)
    fi
    
    if [ -z "$sha" ] || [ "$sha" = "null" ]; then
        echo ""
    else
        echo "$sha"
    fi
}

# Function to extract actions from workflow files
extract_actions() {
    local file="$1"
    grep -E "^\s*uses:\s*[^/]+/[^@]+@[^#\s]+" "$file" | \
        sed -E 's/^\s*uses:\s*([^@]+)@([^#\s]+).*/\1@\2/' | \
        grep -v "^\s*uses:\s*\." | \
        sort -u
}

# Main execution
echo -e "${BLUE}🔒 Pinning GitHub Actions to commit SHAs...${NC}"
echo ""

# Check if we have GitHub API access
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed. Install with: brew install jq${NC}"
    exit 1
fi

# Process each workflow file
updated_count=0
failed_count=0

for file in .github/workflows/*.yml; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}📝 Processing $(basename "$file")...${NC}"
        
        # Create backup
        cp "$file" "$file.bak"
        
        # Extract unique actions from the file
        actions=$(extract_actions "$file")
        
        if [ -z "$actions" ]; then
            rm "$file.bak"
            echo "   No actions to pin in this file"
            continue
        fi
        
        # Process each action
        file_updated=false
        while IFS= read -r action_ref; do
            if [ -z "$action_ref" ]; then
                continue
            fi
            
            # Parse action and version
            action="${action_ref%@*}"
            version="${action_ref#*@}"
            
            # Skip if already pinned (40-char hex SHA)
            if [[ "$version" =~ ^[0-9a-f]{40}$ ]]; then
                echo "   ✓ $action is already pinned"
                continue
            fi
            
            # Get SHA for this version
            echo -n "   Fetching SHA for $action@$version... "
            sha=$(get_action_sha "$action" "$version")
            
            if [ -z "$sha" ]; then
                echo -e "${RED}failed${NC}"
                echo -e "   ${RED}⚠️  Could not fetch SHA for $action@$version${NC}"
                ((failed_count++))
                continue
            fi
            
            echo -e "${GREEN}$sha${NC}"
            
            # Replace in file
            # Handle special characters in action names
            escaped_action=$(echo "$action" | sed 's/[[\.*^$()+?{|]/\\&/g')
            escaped_version=$(echo "$version" | sed 's/[[\.*^$()+?{|]/\\&/g')
            
            # Replace the action reference with pinned SHA
            sed -i '' "s|uses: $escaped_action@$escaped_version|uses: $action@$sha # $version|g" "$file"
            
            if [ $? -eq 0 ]; then
                file_updated=true
                ((updated_count++))
            fi
            
        done <<< "$actions"
        
        # Check if file was actually modified
        if cmp -s "$file" "$file.bak"; then
            rm "$file.bak"
            echo -e "   ${GREEN}✅ No changes needed${NC}"
        else
            rm "$file.bak"
            echo -e "   ${GREEN}✅ Updated successfully${NC}"
        fi
    fi
done

echo ""
if [ $failed_count -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Completed with $failed_count failures${NC}"
else
    echo -e "${GREEN}✅ Action pinning complete!${NC}"
fi

echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo "   • Actions updated: $updated_count"
echo "   • Failures: $failed_count"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "   1. Review changes: git diff .github/workflows/"
echo "   2. Test workflows to ensure they still work"
echo "   3. Commit the changes"

# Exit with error if any actions failed to pin
if [ $failed_count -gt 0 ]; then
    exit 1
fi