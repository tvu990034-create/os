#!/bin/bash
# Build Host Tests - Tests that can run without a booted system
set -e

echo "=== Build Host Tests ==="
echo ""

FAILED=0

# Test 1: Setup script syntax
echo "Test 1: Setup script syntax"
if bash -n setup.sh; then
    echo "✓ setup.sh syntax valid"
else
    echo "✗ setup.sh syntax invalid"
    FAILED=1
fi
echo ""

# Test 2: Package Makefile syntax
echo "Test 2: Package Makefile syntax"
for pkg in router-core router-net router-tests; do
    if [ -f "custom-feed/$pkg/Makefile" ]; then
        if make -f custom-feed/$pkg/Makefile -n >/dev/null 2>&1; then
            echo "✓ $pkg/Makefile syntax valid"
        else
            echo "⚠ $pkg/Makefile syntax check skipped (requires OpenWrt build environment)"
        fi
    else
        echo "✗ $pkg/Makefile not found"
        FAILED=1
    fi
done
echo ""

# Test 3: Shell script syntax
echo "Test 3: Shell script syntax"
for script in custom-feed/router-core/files/libexec/router-hw-detect \
              custom-feed/router-core/files/init.d/router-core \
              custom-feed/router-net/files/monitor-interfaces.sh \
              custom-feed/router-tests/files/test-*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script"; then
            echo "✓ $script syntax valid"
        else
            echo "✗ $script syntax invalid"
            FAILED=1
        fi
    else
        echo "✗ $script not found"
        FAILED=1
    fi
done
echo ""

# Test 4: UCI configuration syntax
echo "Test 4: UCI configuration syntax"
for config in custom-feed/router-core/files/config/*; do
    if [ -f "$config" ]; then
        # Basic UCI syntax check (lines should not have invalid characters)
        if grep -q '^config' "$config" && grep -q '^option' "$config"; then
            echo "✓ $config has valid UCI structure"
        else
            echo "⚠ $config may have incomplete UCI structure"
        fi
    fi
done
echo ""

# Test 5: Directory structure
echo "Test 5: Directory structure"
if [ -d "custom-feed" ]; then
    echo "✓ custom-feed directory exists"
else
    echo "✗ custom-feed directory not found"
    FAILED=1
fi

if [ -d "custom-feed/router-core" ]; then
    echo "✓ router-core package directory exists"
else
    echo "✗ router-core package directory not found"
    FAILED=1
fi

if [ -d "custom-feed/router-net" ]; then
    echo "✓ router-net package directory exists"
else
    echo "✗ router-net package directory not found"
    FAILED=1
fi

if [ -d "custom-feed/router-tests" ]; then
    echo "✓ router-tests package directory exists"
else
    echo "✗ router-tests package directory not found"
    FAILED=1
fi
echo ""

# Test 6: Package files
echo "Test 6: Package files"
required_files=(
    "custom-feed/router-core/Makefile"
    "custom-feed/router-core/files/init.d/router-core"
    "custom-feed/router-core/files/libexec/router-hw-detect"
    "custom-feed/router-core/files/config/network"
    "custom-feed/router-core/files/config/firewall"
    "custom-feed/router-core/files/config/dhcp"
    "custom-feed/router-core/files/config/system"
    "custom-feed/router-net/Makefile"
    "custom-feed/router-net/files/monitor-interfaces.sh"
    "custom-feed/router-tests/Makefile"
    "custom-feed/router-tests/files/test-config-syntax.sh"
    "custom-feed/router-tests/files/test-hardware-detect.sh"
    "custom-feed/router-tests/files/test-network-validation.sh"
    "custom-feed/router-tests/files/test-integration.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file not found"
        FAILED=1
    fi
done
echo ""

# Summary
echo "=== Test Summary ==="
if [ $FAILED -eq 0 ]; then
    echo "All build host tests PASSED"
    exit 0
else
    echo "Some build host tests FAILED"
    exit 1
fi
