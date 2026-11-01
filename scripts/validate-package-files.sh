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
custom-feed/router-core/files/libexec/router-shutdown
custom-feed/router-core/files/libexec/router-config
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

# Check router-qos files
QOS_FILES="
custom-feed/router-qos/files/libexec/router-qos-validate
custom-feed/router-qos/files/libexec/router-qos-apply
custom-feed/router-qos/files/libexec/router-qos-status
"

for file in $QOS_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-qos: $file"
	else
		fail "router-qos missing: $file"
	fi
done

# Check router-vpn files
VPN_FILES="
custom-feed/router-vpn/files/libexec/router-vpn-validate
custom-feed/router-vpn/files/libexec/router-vpn-status
"

for file in $VPN_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-vpn: $file"
	else
		fail "router-vpn missing: $file"
	fi
done

# Check router-dns files
DNS_FILES="
custom-feed/router-dns/files/libexec/router-dns-validate
custom-feed/router-dns/files/libexec/router-dns-status
"

for file in $DNS_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-dns: $file"
	else
		fail "router-dns missing: $file"
	fi
done

# Check router-dhcp files
DHCP_FILES="
custom-feed/router-dhcp/files/libexec/router-dhcp-validate
custom-feed/router-dhcp/files/libexec/router-dhcp-status
"

for file in $DHCP_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-dhcp: $file"
	else
		fail "router-dhcp missing: $file"
	fi
done

# Check router-api files
API_FILES="
custom-feed/router-api/files/acl.d/router-api-acl.json
custom-feed/router-api/files/router-api
"

for file in $API_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-api: $file"
	else
		fail "router-api missing: $file"
	fi
done

# Check router-backup files
BACKUP_FILES="
custom-feed/router-backup/files/libexec/router-backup
custom-feed/router-backup/files/cron.d/router-backup-cron
"

for file in $BACKUP_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-backup: $file"
	else
		fail "router-backup missing: $file"
	fi
done

# Check router-upgrade files
UPGRADE_FILES="
custom-feed/router-upgrade/files/libexec/router-upgrade
"

for file in $UPGRADE_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "router-upgrade: $file"
	else
		fail "router-upgrade missing: $file"
	fi
done

if [ "$FAILED" -eq 0 ]; then
	echo "=== Package file existence validation PASSED ==="
	exit 0
fi

echo "=== Package file existence validation FAILED ==="
exit 1
