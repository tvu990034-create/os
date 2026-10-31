#!/bin/sh
# Validate that all files referenced in package Makefiles actually exist

set -eu

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
FAILED=0

fail() {
	echo "FAIL: $1"
	FAILED=1
}

pass() {
	echo "PASS: $1"
}

echo "=== Package file existence validation ==="

# Check router-core files
CORE_FILES="
custom-feed/router-core/files/uci-defaults/98_router-security
custom-feed/router-core/files/uci-defaults/99_router-core
custom-feed/router-core/files/uci-defaults/99_router-logging
custom-feed/router-core/files/init.d/router-core
custom-feed/router-core/files/libexec/router-hw-detect
custom-feed/router-core/files/libexec/router-status
custom-feed/router-core/files/libexec/router-backup
custom-feed/router-core/files/libexec/router-shutdown
custom-feed/router-core/files/libexec/router-config
custom-feed/router-core/files/libexec/router-upgrade
custom-feed/router-core/files/libexec/router-supervisor
custom-feed/router-core/files/libexec/router-setup-wizard
custom-feed/router-core/files/hotplug.d/iface/99_router-core
custom-feed/router-core/files/hotplug.d/net/99_router-core
"

for file in $CORE_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-core: $file"
	else
		fail "router-core missing: $file"
	fi
done

# Check router-net files
NET_FILES="
custom-feed/router-net/files/config/router-net
custom-feed/router-net/files/init.d/router-net
custom-feed/router-net/files/monitor-interfaces.sh
custom-feed/router-net/files/check-network-health.sh
"

for file in $NET_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-net: $file"
	else
		fail "router-net missing: $file"
	fi
done

# Check router-firewall files
FIREWALL_FILES="
custom-feed/router-firewall/files/config/router-firewall
custom-feed/router-firewall/files/libexec/router-firewall-validate
custom-feed/router-firewall/files/libexec/router-firewall-diagnostics
"

for file in $FIREWALL_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-firewall: $file"
	else
		fail "router-firewall missing: $file"
	fi
done

# Check router-routing files
ROUTING_FILES="
custom-feed/router-routing/files/libexec/router-routing-status
custom-feed/router-routing/files/libexec/router-routing-diagnostics
"

for file in $ROUTING_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-routing: $file"
	else
		fail "router-routing missing: $file"
	fi
done

# Check router-monitor files
MONITOR_FILES="
custom-feed/router-monitor/files/libexec/router-monitor-system
custom-feed/router-monitor/files/libexec/router-monitor-network
"

for file in $MONITOR_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-monitor: $file"
	else
		fail "router-monitor missing: $file"
	fi
done

# Check router-device files
DEVICE_FILES="
custom-feed/router-device/files/libexec/router-device-info
custom-feed/router-device/files/libexec/router-device-capabilities
"

for file in $DEVICE_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-device: $file"
	else
		fail "router-device missing: $file"
	fi
done

if [ "$FAILED" -eq 0 ]; then
	echo "=== Package file existence validation PASSED ==="
	exit 0
fi

echo "=== Package file existence validation FAILED ==="
exit 1
