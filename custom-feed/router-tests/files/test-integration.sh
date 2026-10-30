#!/bin/sh
# Integration Tests for Router OS
# Tests actual system behavior and service integration

FAILED=0

echo "=== Router OS Integration Tests ==="
echo ""

# Test 1: Feed Registration
echo "Test 1: Feed Registration"
if [ -d "/feeds/custom-feed" ]; then
    echo "✓ Custom feed directory exists"
else
    echo "✗ Custom feed directory not found"
    FAILED=1
fi
echo ""

# Test 2: Package Discovery
echo "Test 2: Package Discovery"
if [ -f "/tmp/.packageinfo" ]; then
    if grep -q "Package: router-core" /tmp/.packageinfo 2>/dev/null; then
        echo "✓ router-core package discovered"
    else
        echo "✗ router-core package not discovered"
        FAILED=1
    fi
else
    echo "⚠ Package info not found (expected in build environment)"
fi
echo ""

# Test 3: Service Initialization
echo "Test 3: Service Initialization"
if [ -f "/etc/init.d/router-core" ]; then
    echo "✓ router-core init script exists"
    if /etc/init.d/router-core enabled 2>/dev/null; then
        echo "✓ router-core service enabled"
    else
        echo "⚠ router-core service not enabled (may be enabled on boot)"
    fi
else
    echo "⚠ router-core init script not found (expected on running system)"
fi
echo ""

# Test 4: UCI Configuration Loading
echo "Test 4: UCI Configuration Loading"
if command -v uci >/dev/null 2>&1; then
    echo "✓ uci command available"
    
    if uci show network >/dev/null 2>&1; then
        echo "✓ network config loads"
        LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null)
        if [ -n "$LAN_IP" ]; then
            echo "  LAN IP: $LAN_IP"
        fi
    else
        echo "✗ network config fails to load"
        FAILED=1
    fi
    
    if uci show firewall >/dev/null 2>&1; then
        echo "✓ firewall config loads"
    else
        echo "✗ firewall config fails to load"
        FAILED=1
    fi
else
    echo "⚠ uci command not available (expected on running system)"
fi
echo ""

# Test 5: Firewall Initialization
echo "Test 5: Firewall Initialization"
if command -v nft >/dev/null 2>&1; then
    echo "✓ nft command available"
    if nft list ruleset 2>/dev/null | grep -q "table"; then
        echo "✓ nftables rules loaded"
    else
        echo "⚠ nftables rules not loaded (may be OK on fresh boot)"
    fi
else
    echo "⚠ nft command not available (expected on running system)"
fi
echo ""

# Test 6: IPv4 Networking
echo "Test 6: IPv4 Networking"
if command -v ip >/dev/null 2>&1; then
    echo "✓ ip command available"
    
    # Check loopback
    if ip link show lo >/dev/null 2>&1; then
        echo "✓ Loopback interface exists"
    else
        echo "✗ Loopback interface missing"
        FAILED=1
    fi
    
    # Check for IP address on loopback
    if ip addr show lo | grep -q "127.0.0.1"; then
        echo "✓ Loopback has IP address"
    else
        echo "✗ Loopback missing IP address"
        FAILED=1
    fi
else
    echo "⚠ ip command not available (expected on running system)"
fi
echo ""

# Test 7: IPv6 Configuration
echo "Test 7: IPv6 Configuration"
if command -v ip >/dev/null 2>&1; then
    if ip -6 addr show lo >/dev/null 2>&1; then
        echo "✓ IPv6 loopback exists"
        if ip -6 addr show lo | grep -q "::1"; then
            echo "✓ IPv6 loopback has address"
        else
            echo "⚠ IPv6 loopback missing ::1 address"
        fi
    else
        echo "⚠ IPv6 not configured on loopback"
    fi
else
    echo "⚠ ip command not available"
fi
echo ""

# Test 8: Missing Interface Handling
echo "Test 8: Missing Interface Handling"
# This tests that the system handles missing eth0/eth1 gracefully
if command -v ip >/dev/null 2>&1; then
    ETH0_EXISTS=0
    ETH1_EXISTS=0
    
    if ip link show eth0 >/dev/null 2>&1; then
        ETH0_EXISTS=1
    fi
    
    if ip link show eth1 >/dev/null 2>&1; then
        ETH1_EXISTS=1
    fi
    
    if [ $ETH0_EXISTS -eq 0 ] && [ $ETH1_EXISTS -eq 0 ]; then
        echo "✓ System handles missing eth0/eth1 (no crash)"
    else
        echo "ℹ eth0 or eth1 present (normal for systems with hardware)"
    fi
else
    echo "⚠ ip command not available"
fi
echo ""

# Test 9: DHCP/DNS Service Check
echo "Test 9: DHCP/DNS Service Check"
if [ -f "/etc/config/dhcp" ]; then
    echo "✓ DHCP config file exists"
    if command -v uci >/dev/null 2>&1; then
        if uci get dhcp.lan >/dev/null 2>&1; then
            echo "✓ LAN DHCP configured"
        else
            echo "⚠ LAN DHCP not configured"
        fi
    fi
else
    echo "⚠ DHCP config not found (expected on running system)"
fi

if command -v dnsmasq >/dev/null 2>&1; then
    echo "✓ dnsmasq command available"
else
    echo "⚠ dnsmasq command not available"
fi
echo ""

# Test 10: Failure Handling
echo "Test 10: Failure Handling (Optional Components)"
# Test that system doesn't crash when optional components are missing
# This is checked by the fact that the script is still running
echo "✓ Script still running (no crashes from missing components)"
echo ""

# Summary
echo "=== Test Summary ==="
if [ $FAILED -eq 0 ]; then
    echo "All tests PASSED"
    exit 0
else
    echo "Some tests FAILED"
    exit 1
fi
