#!/bin/sh
# Validate the base network configuration without assuming a specific NIC count.

set -u
FAILED=0

if ! ip link show lo >/dev/null 2>&1; then
	echo "FAIL: loopback interface is unavailable"
	FAILED=1
else
	echo "PASS: loopback interface exists"
fi

if ! uci -q get network.lan >/dev/null 2>&1; then
	echo "FAIL: LAN interface section is missing"
	FAILED=1
else
	LAN_PROTO="$(uci -q get network.lan.proto 2>/dev/null || true)"
	LAN_DEVICE="$(uci -q get network.lan.device 2>/dev/null || true)"
	if [ "$LAN_PROTO" != "static" ] || [ "$LAN_DEVICE" != "br-lan" ]; then
		echo "FAIL: LAN must use static addressing on br-lan"
		FAILED=1
	else
		echo "PASS: LAN configuration is present"
	fi
fi

if ! uci -q get network.lan_bridge >/dev/null 2>&1; then
	echo "FAIL: LAN bridge device section is missing"
	FAILED=1
else
	BRIDGE_TYPE="$(uci -q get network.lan_bridge.type 2>/dev/null || true)"
	if [ "$BRIDGE_TYPE" != "bridge" ]; then
		echo "FAIL: br-lan is not configured as a bridge"
		FAILED=1
	else
		echo "PASS: LAN bridge configuration is present"
	fi
fi

# WAN is intentionally optional on a single-NIC device.
if uci -q get network.wan >/dev/null 2>&1; then
	WAN_PROTO="$(uci -q get network.wan.proto 2>/dev/null || true)"
	WAN_DEVICE="$(uci -q get network.wan.device 2>/dev/null || true)"
	if [ "$WAN_PROTO" != "dhcp" ] || [ -z "$WAN_DEVICE" ] || [ "$WAN_DEVICE" = "br-lan" ]; then
		echo "FAIL: WAN configuration is invalid"
		FAILED=1
	else
		echo "PASS: WAN configuration is present"
	fi
else
	echo "INFO: WAN is not configured (expected when only one wired NIC is detected)"
fi

[ "$FAILED" -eq 0 ] || exit 1
echo "Network configuration smoke tests passed."
