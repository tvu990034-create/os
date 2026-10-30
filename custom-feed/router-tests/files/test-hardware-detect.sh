#!/bin/sh
# Smoke-test the read-only hardware inventory command.

set -u
DETECT=/usr/libexec/router-core/router-hw-detect
OUTPUT=/tmp/router-os-hardware-test.txt

if [ ! -x "$DETECT" ]; then
	echo "FAIL: $DETECT is missing or not executable"
	exit 1
fi

if ! "$DETECT" > "$OUTPUT" 2>&1; then
	echo "FAIL: hardware inventory returned a non-zero status"
	cat "$OUTPUT"
	exit 1
fi

for section in "Hardware Inventory" "Network Interfaces" "CPU Information" "Memory Information" "Storage Information"; do
	if ! grep -Fq "$section" "$OUTPUT"; then
		echo "FAIL: expected section not found: $section"
		exit 1
	fi
done

echo "PASS: hardware inventory completed and contains expected sections"
