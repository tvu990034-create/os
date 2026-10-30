#!/bin/sh
# Validate all RouterOS UCI configuration files using the target's UCI parser.

set -u
FAILED=0

for package in network firewall dhcp system router-net; do
	config_file="/etc/config/$package"
	if [ ! -f "$config_file" ]; then
		echo "FAIL: missing $config_file"
		FAILED=1
		continue
	fi
	if uci -q show "$package" >/dev/null 2>&1; then
		echo "PASS: $package parses"
	else
		echo "FAIL: $package does not parse"
		FAILED=1
	fi
done

[ "$FAILED" -eq 0 ] || exit 1
echo "All RouterOS UCI configuration files parse successfully."
