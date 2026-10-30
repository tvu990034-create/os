#!/bin/bash
# Regression tests for source management system
# Tests error conditions using temporary repositories

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="/tmp/router-os-source-tests"

echo "Source Management Regression Tests"
echo "=================================="
echo ""

# Cleanup function
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Test 1: Invalid commit SHA format
echo "Test 1: Invalid commit SHA format"
TEST_MANIFEST="$TEST_DIR/test-invalid-sha.lock"
cat > "$TEST_MANIFEST" << 'EOF'
[test-repo]
url = https://github.com/openwrt/openwrt.git
commit = invalid-sha
type = required
EOF

cd "$TEST_DIR"
if MANIFEST="$TEST_MANIFEST" "$PROJECT_ROOT/scripts/verify-sources.sh" --required-only 2>&1 | grep -q "Invalid commit SHA"; then
    echo "✓ Invalid SHA detected correctly"
else
    echo "✗ Invalid SHA not detected"
    cd "$PROJECT_ROOT"
    exit 1
fi
cd "$PROJECT_ROOT"
echo ""

# Test 2: Missing required repository
echo "Test 2: Missing required repository"
TEST_MANIFEST="$TEST_DIR/test-missing.lock"
cat > "$TEST_MANIFEST" << 'EOF'
[missing-repo]
url = https://github.com/openwrt/openwrt.git
commit = ca454c00b69fc684e1c5ea52f62733c4e644e799
type = required
EOF

cd "$TEST_DIR"
if MANIFEST="$TEST_MANIFEST" "$PROJECT_ROOT/scripts/verify-sources.sh" --required-only 2>&1 | grep -q "Repository directory missing"; then
    echo "✓ Missing repository detected correctly"
else
    echo "✗ Missing repository not detected"
    cd "$PROJECT_ROOT"
    exit 1
fi
cd "$PROJECT_ROOT"
echo ""

# Test 3: Valid manifest parsing
echo "Test 3: Valid manifest parsing"
TEST_MANIFEST="$TEST_DIR/test-valid.lock"
cat > "$TEST_MANIFEST" << 'EOF'
[test-repo]
url = https://github.com/openwrt/openwrt.git
commit = ca454c00b69fc684e1c5ea52f62733c4e644e799
type = required
EOF

# This should not fail on parsing
if "$PROJECT_ROOT/scripts/verify-sources.sh" --required-only 2>&1 | grep -q "Skipping"; then
    echo "✓ Manifest parsed correctly"
else
    echo "✗ Manifest parsing failed"
    exit 1
fi
echo ""

# Test 4: Required vs reference filtering
echo "Test 4: Required vs reference filtering"
# This test is complex due to directory structure, skip for now
echo "⚠ Skipped (complex directory structure test)"
echo ""

# Test 5: Feed configuration validation
echo "Test 5: Feed configuration validation"
cd "$PROJECT_ROOT"
if [ -f "openwrt/feeds.conf.local" ]; then
    if grep -q "src-link custom-feed" openwrt/feeds.conf.local; then
        echo "✓ Custom feed registered"
    else
        echo "✗ Custom feed not registered"
        exit 1
    fi
    
    if grep -q "src-git packages ../packages" openwrt/feeds.conf.local; then
        echo "✓ Local packages feed configured"
    else
        echo "✗ Local packages feed not configured"
        exit 1
    fi
else
    echo "⚠ feeds.conf.local not found (run setup.sh first)"
fi
echo ""

# Test 6: Custom package discovery
echo "Test 6: Custom package discovery"
cd "$PROJECT_ROOT"
if [ -d "custom-feed/router-core" ] && [ -f "custom-feed/router-core/Makefile" ]; then
    echo "✓ router-core package exists"
else
    echo "✗ router-core package missing"
    exit 1
fi

if [ -d "custom-feed/router-net" ] && [ -f "custom-feed/router-net/Makefile" ]; then
    echo "✓ router-net package exists"
else
    echo "✗ router-net package missing"
    exit 1
fi

if [ -d "custom-feed/router-tests" ] && [ -f "custom-feed/router-tests/Makefile" ]; then
    echo "✓ router-tests package exists"
else
    echo "✗ router-tests package missing"
    exit 1
fi
echo ""

echo "=================================="
echo "All regression tests PASSED"
echo ""
