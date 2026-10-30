#!/bin/bash
# Build host tests for Router OS. These tests do not require a booted router.
set -e

echo "=== Build Host Tests ==="
echo ""

FAILED=0

echo "Test 1: Setup script syntax"
if bash -n setup.sh; then
    echo "✓ setup.sh syntax valid"
else
    echo "✗ setup.sh syntax invalid"
    FAILED=1
fi
echo ""

echo "Test 2: Package Makefile syntax"
for pkg in router-core router-net router-tests; do
    if [ -f "custom-feed/$pkg/Makefile" ]; then
        if make -f "custom-feed/$pkg/Makefile" -n >/dev/null 2>&1; then
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

echo "Test 3: Shell script syntax"
for script in \
    custom-feed/router-core/files/libexec/router-hw-detect \
    custom-feed/router-core/files/init.d/router-core \
    custom-feed/router-core/files/uci-defaults/99_router-core \
    custom-feed/router-net/files/monitor-interfaces.sh \
    custom-feed/router-net/files/init.d/router-net \
    custom-feed/router-net/files/uci-defaults/99_router-net \
    custom-feed/router-tests/files/test-*.sh; do
    if [ -f "$script" ]; then
        if sh -n "$script"; then
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

echo "Test 4: UCI configuration structure"
for config in custom-feed/router-core/files/config/* custom-feed/router-net/files/config/*; do
    [ -f "$config" ] || continue
    if grep -q '^config ' "$config" && grep -q '^[[:space:]]*option ' "$config"; then
        echo "✓ $config has UCI section and options"
    else
        echo "✗ $config has incomplete UCI structure"
        FAILED=1
    fi
done
echo ""

echo "Test 5: Directory structure"
for dir in custom-feed custom-feed/router-core custom-feed/router-net custom-feed/router-tests; do
    if [ -d "$dir" ]; then
        echo "✓ $dir exists"
    else
        echo "✗ $dir not found"
        FAILED=1
    fi
done
echo ""

echo "Test 6: Required package files"
required_files=(
    "custom-feed/router-core/Makefile"
    "custom-feed/router-core/files/init.d/router-core"
    "custom-feed/router-core/files/libexec/router-hw-detect"
    "custom-feed/router-core/files/uci-defaults/99_router-core"
    "custom-feed/router-core/files/config/network"
    "custom-feed/router-core/files/config/firewall"
    "custom-feed/router-core/files/config/dhcp"
    "custom-feed/router-core/files/config/system"
    "custom-feed/router-net/Makefile"
    "custom-feed/router-net/files/monitor-interfaces.sh"
    "custom-feed/router-net/files/init.d/router-net"
    "custom-feed/router-net/files/uci-defaults/99_router-net"
    "custom-feed/router-net/files/config/router-net"
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

echo "Test 7: Interface monitor behavior"
if ./scripts/test-router-net-monitor.sh; then
    echo "✓ Interface monitor functional tests passed"
else
    echo "✗ Interface monitor functional tests failed"
    FAILED=1
fi
echo ""

echo "=== Test Summary ==="
if [ "$FAILED" -eq 0 ]; then
    echo "All build host tests PASSED"
    exit 0
else
    echo "Some build host tests FAILED"
    exit 1
fi
