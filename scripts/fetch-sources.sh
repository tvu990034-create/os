#!/bin/bash
# Fetch and manage upstream source repositories
# This script clones missing repositories and updates to pinned revisions
# Usage: ./scripts/fetch-sources.sh [--required-only] [--reference-only] [--all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$PROJECT_ROOT/manifests/sources.lock"

FETCH_REQUIRED=true
FETCH_REFERENCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --required-only)
            FETCH_REQUIRED=true
            FETCH_REFERENCE=false
            shift
            ;;
        --reference-only)
            FETCH_REQUIRED=false
            FETCH_REFERENCE=true
            shift
            ;;
        --all)
            FETCH_REQUIRED=true
            FETCH_REFERENCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--required-only] [--reference-only] [--all]"
            exit 1
            ;;
    esac
done

echo "Router OS Source Management"
echo "==========================="
echo "Project root: $PROJECT_ROOT"
echo "Manifest: $MANIFEST"
echo "Fetch required: $FETCH_REQUIRED"
echo "Fetch reference: $FETCH_REFERENCE"
echo ""

# Validate commit SHA format (40 hex characters)
validate_commit_sha() {
    local commit="$1"
    if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
        echo "  ✗ Invalid commit SHA format: $commit"
        return 1
    fi
    return 0
}

# Function to check for uncommitted changes
check_clean() {
    local repo_dir="$1"
    local repo_name="$2"
    local ignore_patterns="$3"
    
    cd "$repo_dir"
    
    # Check for uncommitted changes (excluding ignored paths)
    if [ -n "$ignore_patterns" ]; then
        status=$(git status --porcelain)
        if [ -n "$status" ]; then
            IFS=',' read -ra PATHS <<< "$ignore_patterns"
            for path in "${PATHS[@]}"; do
                status=$(echo "$status" | grep -v "$path" || true)
            done
        fi
    else
        status=$(git status --porcelain || true)
    fi
    
    if [ -n "$status" ]; then
        echo "  ✗ Repository has uncommitted changes:"
        echo "$status"
        echo "  ERROR: Refusing to update repository with uncommitted changes"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to fetch a single repository
fetch_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_commit="$3"
    local repo_type="$4"
    local repo_required="$5"
    local ignore_patterns="$6"
    
    # Validate commit SHA format
    if ! validate_commit_sha "$repo_commit"; then
        echo "  ERROR: Invalid commit SHA in manifest"
        return 1
    fi
    
    # Skip if not in fetch mode
    if [ "$repo_type" = "required" ] && [ "$FETCH_REQUIRED" = false ]; then
        echo "Skipping: $repo_name (fetching reference only)"
        echo ""
        return 0
    fi
    
    if [ "$repo_type" = "reference" ] && [ "$FETCH_REFERENCE" = false ]; then
        echo "Skipping: $repo_name (fetching required only)"
        echo ""
        return 0
    fi
    
    local repo_dir="$PROJECT_ROOT/$repo_name"
    
    echo "Processing: $repo_name"
    echo "  URL: $repo_url"
    echo "  Commit: $repo_commit"
    echo "  Type: $repo_type"
    
    if [ -d "$repo_dir" ]; then
        if [ -d "$repo_dir/.git" ]; then
            echo "  Repository exists, checking..."
            
            # Check for uncommitted changes
            if ! check_clean "$repo_dir" "$repo_name" "$ignore_patterns"; then
                return 1
            fi
            
            cd "$repo_dir"
            current_commit=$(git rev-parse HEAD)
            current_url=$(git remote get-url origin 2>/dev/null || echo "unknown")
            cd "$PROJECT_ROOT"
            
            # Always validate URL even if commit is correct
            if [ "$current_url" != "$repo_url" ]; then
                echo "  ✗ URL mismatch:"
                echo "    Expected: $repo_url"
                echo "    Current:  $current_url"
                echo "  ERROR: Repository origin URL does not match manifest"
                return 1
            fi
            
            if [ "$current_commit" = "$repo_commit" ]; then
                echo "  ✓ Already at correct revision"
            else
                echo "  Current: $current_commit"
                echo "  Expected: $repo_commit"
                echo "  Updating to correct revision..."
                cd "$repo_dir"
                if ! git fetch origin; then
                    echo "  ERROR: Failed to fetch from origin"
                    cd "$PROJECT_ROOT"
                    return 1
                fi
                
                if ! git checkout "$repo_commit"; then
                    echo "  ERROR: Failed to checkout commit $repo_commit"
                    echo "  ERROR: Commit may not exist in repository"
                    cd "$PROJECT_ROOT"
                    return 1
                fi
                
                echo "  ✓ Updated to correct revision"
                cd "$PROJECT_ROOT"
            fi
        else
            echo "  ✗ Directory exists but is not a git repository"
            if [ "$repo_required" = "true" ]; then
                echo "  ERROR: Required repository is not a git repo"
                return 1
            else
                echo "  Skipping (optional reference)"
            fi
        fi
    else
        echo "  Repository missing, cloning..."
        if ! git clone "$repo_url" "$repo_dir"; then
            echo "  ERROR: Failed to clone repository"
            return 1
        fi
        
        cd "$repo_dir"
        if ! git checkout "$repo_commit"; then
            echo "  ERROR: Failed to checkout commit $repo_commit"
            echo "  ERROR: Commit may not exist in repository"
            cd "$PROJECT_ROOT"
            return 1
        fi
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
    local current_type=""
    local current_required="false"
    local current_ignore=""
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        # Parse sections
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            # Process previous repo if exists
            if [ -n "$current_repo" ]; then
                fetch_repo "$current_repo" "$current_url" "$current_commit" "$current_type" "$current_required" "$current_ignore"
            fi
            
            # Start new repo
            current_repo="${BASH_REMATCH[1]}"
            current_url=""
            current_commit=""
            current_type=""
            current_required="false"
            current_ignore=""
        elif [[ "$line" =~ ^url[[:space:]]*= ]]; then
            current_url="${line#*= }"
        elif [[ "$line" =~ ^commit[[:space:]]*= ]]; then
            current_commit="${line#*= }"
        elif [[ "$line" =~ ^type[[:space:]]*= ]]; then
            current_type="${line#*= }"
        elif [[ "$line" =~ ^required[[:space:]]*= ]]; then
            current_required="${line#*= }"
        elif [[ "$line" =~ ^ignore_changes[[:space:]]*= ]]; then
            current_ignore="${line#*= }"
        fi
    done < "$MANIFEST"
    
    # Process last repo
    if [ -n "$current_repo" ]; then
        fetch_repo "$current_repo" "$current_url" "$current_commit" "$current_type" "$current_required" "$current_ignore"
    fi
}

# Run the main function
parse_and_fetch

echo "==========================="
echo "Source fetch complete"
echo ""
