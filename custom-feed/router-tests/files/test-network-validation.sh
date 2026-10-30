#!/bin/sh
# Test Network Validation
# Validates network configuration and interface availability

echo "=== Testing Network Configuration ==="

TEST_FAILED=0

# Check if loopback exists
if ip link show lo >/dev/null 2>&1; then
	echo "✓ Loopback interface exists"
else
	echo "✗ Loopback interface missing"
	TEST_FAILED=1
fi

# Check for at least one non-loopback interface
NON_LOOPBACK=$(ip link show 2>/dev/null | grep -v "lo:" | grep -v "^$" | head -1)
if [ -n "$NON_LOOPBACK" ]; then
	echo "✓ At least one non-loopback interface found"
else
	echo "⚠ No non-loopback interfaces found (may be expected in VM)"
fi

# Check if UCI network config exists
if [ -f /etc/config/network ]; then
	echo "✓ Network config file exists"
	
	# Check if loopback is configured
	if uci get network.loopback >/dev/null 2>&1; then
		echo "✓ Loopback configured in UCI"
	else
		echo "✗ Loopback not configured in UCI"
		TEST_FAILED=1
	fi
	
	# Check if LAN is configured
	if uci get network.lan >/dev/null 2>&1; then
		echo "✓ LAN configured in UCI"
	else
		echo "✗ LAN not configured in UCI"
		TEST_FAILED=1
	fi
	
	# Check if WAN is configured
	if uci get network.wan >/dev/null 2>&1; then
		echo "✓ WAN configured in UCI"
		WAN_DEVICE=$(uci get network.wan.device)
		if [ -n "$WAN_DEVICE" ]; then
			echo "  WAN device: $WAN_DEVICE"
		fi
	else
		echo "⚠ WAN not configured in UCI (may be optional)"
	fi
else
	echo "⚠ Network config file not found (expected on running system)"
fi

if [ $TEST_FAILED -eq 0 ]; then
	echo "=== Network Validation Complete ==="
	exit 0
else
	echo "=== Network Validation Failed ==="
	exit 1
fi
