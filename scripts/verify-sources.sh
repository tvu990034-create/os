#!/bin/bash
# Verify that all source repositories are at correct revisions
# This script checks without modifying repositories

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$PROJECT_ROOT/manifests/sources.lock"

echo "Router OS Source Verification"
echo "=============================="
echo "Project root: $PROJECT_ROOT"
echo "Manifest: $MANIFEST"
echo ""

FAILED=0

# Function to verify a single repository
verify_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_commit="$3"
    local repo_required="$4"
    
    local repo_dir="$PROJECT_ROOT/$repo_name"
    
    echo "Verifying: $repo_name"
    
    if [ ! -d "$repo_dir" ]; then
        if [ "$repo_required" = "true" ]; then
            echo "  ✗ Repository directory missing (REQUIRED)"
            FAILED=1
        else
            echo "  ⚠ Repository directory missing (optional reference)"
        fi
        echo ""
        return
    fi
    
    if [ ! -d "$repo_dir/.git" ]; then
        echo "  ✗ Directory exists but is not a git repository"
        if [ "$repo_required" = "true" ]; then
            FAILED=1
        fi
        echo ""
        return
    fi
    
    cd "$repo_dir"
    current_commit=$(git rev-parse HEAD)
    current_url=$(git remote get-url origin 2>/dev/null || echo "unknown")
    cd "$PROJECT_ROOT"
    
    if [ "$current_commit" = "$repo_commit" ]; then
        echo "  ✓ At correct revision: $repo_commit"
    else
        echo "  ✗ At wrong revision"
        echo "    Expected: $repo_commit"
        echo "    Current:  $current_commit"
        FAILED=1
    fi
    
    if [ "$current_url" = "$repo_url" ]; then
        echo "  ✓ URL matches: $repo_url"
    else
        echo "  ⚠ URL differs"
        echo "    Expected: $repo_url"
        echo "    Current:  $current_url"
    fi
    
    echo ""
}

# Parse manifest and verify each repository
parse_and_verify() {
    local current_repo=""
    local current_url=""
    local current_commit=""
    local current_required="false"
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            if [ -n "$current_repo" ]; then
                verify_repo "$current_repo" "$current_url" "$current_commit" "$current_required"
            fi
            
            current_repo="${BASH_REMATCH[1]}"
            current_url=""
            current_commit=""
            current_required="false"
        elif [[ "$line" =~ ^url[[:space:]]*= ]]; then
            current_url="${line#*= }"
        elif [[ "$line" =~ ^commit[[:space:]]*= ]]; then
            current_commit="${line#*= }"
        elif [[ "$line" =~ ^required[[:space:]]*= ]]; then
            current_required="${line#*= }"
        fi
    done < "$MANIFEST"
    
    if [ -n "$current_repo" ]; then
        verify_repo "$current_repo" "$current_url" "$current_commit" "$current_required"
    fi
}

# Run verification
parse_and_verify

echo "=============================="
if [ $FAILED -eq 0 ]; then
    echo "✓ All required repositories verified"
    exit 0
else
    echo "✗ Some repositories failed verification"
    exit 1
fi
