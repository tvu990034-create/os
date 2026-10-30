#!/bin/sh
# Test Configuration Syntax
# Validates UCI configuration files for syntax errors

TEST_FAILED=0

echo "=== Testing Configuration Syntax ==="

# Test network config
if [ -f /etc/config/network ]; then
	if uci show network >/dev/null 2>&1; then
		echo "✓ network config syntax valid"
	else
		echo "✗ network config syntax INVALID"
		TEST_FAILED=1
	fi
else
	echo "⚠ network config not found (expected on running system)"
fi

# Test firewall config
if [ -f /etc/config/firewall ]; then
	if uci show firewall >/dev/null 2>&1; then
		echo "✓ firewall config syntax valid"
	else
		echo "✗ firewall config syntax INVALID"
		TEST_FAILED=1
	fi
else
	echo "⚠ firewall config not found (expected on running system)"
fi

# Test dhcp config
if [ -f /etc/config/dhcp ]; then
	if uci show dhcp >/dev/null 2>&1; then
		echo "✓ dhcp config syntax valid"
	else
		echo "✗ dhcp config syntax INVALID"
		TEST_FAILED=1
	fi
else
	echo "⚠ dhcp config not found (expected on running system)"
fi

# Test system config
if [ -f /etc/config/system ]; then
	if uci show system >/dev/null 2>&1; then
		echo "✓ system config syntax valid"
	else
		echo "✗ system config syntax INVALID"
		TEST_FAILED=1
	fi
else
	echo "⚠ system config not found (expected on running system)"
fi

if [ $TEST_FAILED -eq 0 ]; then
	echo "=== All tested configs valid ==="
	exit 0
else
	echo "=== Some configs invalid ==="
	exit 1
fi
