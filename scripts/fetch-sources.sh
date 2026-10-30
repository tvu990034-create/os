#!/bin/bash
# Fetch and manage upstream source repositories
# This script clones missing repositories and updates to pinned revisions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$PROJECT_ROOT/manifests/sources.lock"

echo "Router OS Source Management"
echo "==========================="
echo "Project root: $PROJECT_ROOT"
echo "Manifest: $MANIFEST"
echo ""

# Function to parse manifest and fetch repository
fetch_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_commit="$3"
    local repo_required="$4"
    
    local repo_dir="$PROJECT_ROOT/$repo_name"
    
    echo "Processing: $repo_name"
    echo "  URL: $repo_url"
    echo "  Commit: $repo_commit"
    echo "  Required: $repo_required"
    
    if [ -d "$repo_dir" ]; then
        if [ -d "$repo_dir/.git" ]; then
            echo "  Repository exists, checking revision..."
            cd "$repo_dir"
            current_commit=$(git rev-parse HEAD)
            if [ "$current_commit" = "$repo_commit" ]; then
                echo "  ✓ Already at correct revision"
            else
                echo "  Current: $current_commit"
                echo "  Updating to: $repo_commit"
                git fetch origin
                git checkout "$repo_commit"
                echo "  ✓ Updated to correct revision"
            fi
            cd "$PROJECT_ROOT"
        else
            echo "  ⚠ Directory exists but is not a git repository"
            if [ "$repo_required" = "true" ]; then
                echo "  ERROR: Required repository is not a git repo"
                exit 1
            else
                echo "  Skipping (optional reference)"
            fi
        fi
    else
        echo "  Repository missing, cloning..."
        git clone "$repo_url" "$repo_dir"
        cd "$repo_dir"
        git checkout "$repo_commit"
        echo "  ✓ Cloned and checked out to correct revision"
        cd "$PROJECT_ROOT"
    fi
    echo ""
}

# Parse manifest and process each repository
parse_and_fetch() {
    local current_repo=""
    local current_url=""
    local current_commit=""
    local current_required="false"
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        # Parse sections
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            # Process previous repo if exists
            if [ -n "$current_repo" ]; then
                fetch_repo "$current_repo" "$current_url" "$current_commit" "$current_required"
            fi
            
            # Start new repo
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
    
    # Process last repo
    if [ -n "$current_repo" ]; then
        fetch_repo "$current_repo" "$current_url" "$current_commit" "$current_required"
    fi
}

# Run the main function
parse_and_fetch

echo "==========================="
echo "Source fetch complete"
echo ""
