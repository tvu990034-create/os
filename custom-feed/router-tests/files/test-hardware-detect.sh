#!/bin/sh
# Test Hardware Detection
# Validates hardware detection script functionality

echo "=== Testing Hardware Detection ==="

if [ ! -x /usr/libexec/router-core/router-hw-detect ]; then
	echo "✗ router-hw-detect not found or not executable"
	exit 1
fi

echo "✓ router-hw-detect exists and is executable"

# Run hardware detection
if /usr/libexec/router-core/router-hw-detect >/tmp/hw-detect-test.log 2>&1; then
	echo "✓ Hardware detection completed without errors"
	
	# Check if log file was created
	if [ -f /tmp/hw-detect-test.log ]; then
		echo "✓ Detection log created"
		
		# Check if it contains expected sections
		if grep -q "Network Interfaces" /tmp/hw-detect-test.log; then
			echo "✓ Network interfaces detected"
		else
			echo "⚠ Network interfaces section missing"
		fi
		
		if grep -q "CPU Information" /tmp/hw-detect-test.log; then
			echo "✓ CPU information detected"
		else
			echo "⚠ CPU information section missing"
		fi
	else
		echo "✗ Detection log not created"
		exit 1
	fi
else
	echo "✗ Hardware detection failed"
	exit 1
fi

echo "=== Hardware Detection Test Complete ==="
exit 0
