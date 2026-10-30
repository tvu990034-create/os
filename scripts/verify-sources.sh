#!/bin/bash
# Verify that all source repositories are at correct revisions
# This script checks without modifying repositories
# Usage: ./scripts/verify-sources.sh [--required-only] [--reference-only] [--all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="${MANIFEST:-$PROJECT_ROOT/manifests/sources.lock}"

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: Manifest file not found: $MANIFEST"
    exit 1
fi

VERIFY_REQUIRED=true
VERIFY_REFERENCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --required-only)
            VERIFY_REQUIRED=true
            VERIFY_REFERENCE=false
            shift
            ;;
        --reference-only)
            VERIFY_REQUIRED=false
            VERIFY_REFERENCE=true
            shift
            ;;
        --all)
            VERIFY_REQUIRED=true
            VERIFY_REFERENCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--required-only] [--reference-only] [--all]"
            exit 1
            ;;
    esac
done

echo "Router OS Source Verification"
echo "=============================="
echo "Project root: $PROJECT_ROOT"
echo "Manifest: $MANIFEST"
echo "Verify required: $VERIFY_REQUIRED"
echo "Verify reference: $VERIFY_REFERENCE"
echo ""

PASSED=0
FAILED=0
SKIPPED=0

# Validate commit SHA format (40 hex characters)
validate_commit_sha() {
    local commit="$1"
    if [[ ! "$commit" =~ ^[0-9a-fA-F]{40}$ ]]; then
        echo "  ✗ Invalid commit SHA format: $commit" >&2
        return 1
    fi
    return 0
}

# Function to verify a single repository
verify_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_commit="$3"
    local repo_type="$4"
    local repo_required="$5"
    local ignore_patterns="$6"
    
    local result="pass"
    
    # Validate commit SHA format
    if ! validate_commit_sha "$repo_commit"; then
        echo "  ✗ Invalid commit SHA format: $repo_commit"
        result="fail"
    fi
    
    # Skip if not in verify mode
    if [ "$repo_type" = "required" ] && [ "$VERIFY_REQUIRED" = false ]; then
        echo "Skipping: $repo_name (verifying reference only)"
        echo ""
        result="skip"
    elif [ "$repo_type" = "reference" ] && [ "$VERIFY_REFERENCE" = false ]; then
        echo "Skipping: $repo_name (verifying required only)"
        echo ""
        result="skip"
    else
        local repo_dir="$PROJECT_ROOT/$repo_name"
        
        echo "Verifying: $repo_name"
        echo "  Type: $repo_type"
        
        if [ ! -d "$repo_dir" ]; then
            echo "  ✗ Repository directory missing"
            if [ "$repo_required" = "true" ]; then
                echo "  ERROR: Required repository missing"
                result="fail"
            else
                echo "  WARNING: Optional reference repository missing"
                result="fail"
            fi
        elif [ ! -d "$repo_dir/.git" ]; then
            echo "  ✗ Directory exists but is not a git repository"
            if [ "$repo_required" = "true" ]; then
                result="fail"
            else
                result="fail"
            fi
        else
            cd "$repo_dir"
            current_commit=$(git rev-parse HEAD)
            current_url=$(git remote get-url origin 2>/dev/null || echo "unknown")
            
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
            
            cd "$PROJECT_ROOT"
            
            # Check commit
            if [ "$current_commit" = "$repo_commit" ]; then
                echo "  ✓ At correct revision: $repo_commit"
            else
                echo "  ✗ At wrong revision"
                echo "    Expected: $repo_commit"
                echo "    Current:  $current_commit"
                result="fail"
            fi
            
            # Check URL (always validate)
            if [ "$current_url" = "$repo_url" ]; then
                echo "  ✓ URL matches: $repo_url"
            else
                echo "  ✗ URL mismatch"
                echo "    Expected: $repo_url"
                echo "    Current:  $current_url"
                result="fail"
            fi
            
            # Check for uncommitted changes
            if [ -n "$status" ]; then
                echo "  ⚠ Uncommitted changes detected:"
                echo "$status" | head -5
                if [ "$repo_required" = "true" ]; then
                    echo "  (WARNING: required repository has modifications)"
                    # Don't fail for ignored changes
                else
                    echo "  (WARNING: reference repository has modifications)"
                fi
            else
                echo "  ✓ Working tree clean"
            fi
        fi
        echo ""
    fi
    
    # Update counters
    if [ "$result" = "pass" ]; then
        ((PASSED++))
    elif [ "$result" = "fail" ]; then
        ((FAILED++))
    elif [ "$result" = "skip" ]; then
        ((SKIPPED++))
    fi
}

# Parse manifest and verify each repository
parse_and_verify() {
    local current_repo=""
    local current_url=""
    local current_commit=""
    local current_type=""
    local current_required="false"
    local current_ignore=""
    local section_name=""

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            # Save the section name before verify_repo can overwrite BASH_REMATCH.
            section_name="${BASH_REMATCH[1]}"
            if [ -n "$current_repo" ]; then
                verify_repo "$current_repo" "$current_url" "$current_commit" "$current_type" "$current_required" "$current_ignore"
            fi
            
            current_repo="$section_name"
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
    
    if [ -n "$current_repo" ]; then
        verify_repo "$current_repo" "$current_url" "$current_commit" "$current_type" "$current_required" "$current_ignore"
    fi
}

# Run verification
parse_and_verify

echo "=============================="
echo "Verification Summary:"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "  Skipped: $SKIPPED"
echo "=============================="

if [ $FAILED -eq 0 ]; then
    echo "✓ All verified repositories passed"
    exit 0
else
    echo "✗ Some repositories failed verification"
    exit 1
fi
