#!/bin/bash
# QEMU Boot Test Script for Router OS
# This script boots the Router OS image in QEMU and validates startup

set -e

IMAGE_PATH="${1:-openwrt/bin/targets/x86_64/openwrt-x86-64-generic-ext4-combined.img}"
MEMORY="${MEMORY:-512M}"
QEMU_TIMEOUT="${QEMU_TIMEOUT:-120}"

echo "=========================================="
echo "Router OS QEMU Boot Test"
echo "=========================================="
echo "Image: $IMAGE_PATH"
echo "Memory: $MEMORY"
echo "Timeout: ${QEMU_TIMEOUT}s"
echo ""

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    if [ -f "${IMAGE_PATH}.gz" ]; then
        echo "Image is compressed, extracting..."
        gunzip -k "${IMAGE_PATH}.gz"
        IMAGE_PATH="${IMAGE_PATH}"
    else
        echo "Error: Image not found at $IMAGE_PATH"
        echo "Please build the image first using build-local.sh"
        exit 1
    fi
fi

# Check if QEMU is available
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "Error: qemu-system-x86_64 not found"
    echo "Install with: sudo apt-get install qemu-system-x86"
    exit 1
fi

# Function to kill QEMU on exit
cleanup() {
    echo "Cleaning up..."
    if [ -n "$QEMU_PID" ]; then
        kill $QEMU_PID 2>/dev/null || true
        wait $QEMU_PID 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Boot QEMU in background with serial output
echo "Starting QEMU..."
qemu-system-x86_64 \
    -m $MEMORY \
    -drive file="$IMAGE_PATH",format=raw \
    -net nic,model=e1000 \
    -net user,hostfwd=tcp::2222-:22 \
    -nographic \
    -serial file:/tmp/qemu-serial.log \
    &
QEMU_PID=$!

echo "QEMU PID: $QEMU_PID"
echo "Serial output: /tmp/qemu-serial.log"
echo ""

# Wait for boot with timeout
echo "Waiting for boot (timeout: ${QEMU_TIMEOUT}s)..."
BOOTED=false
ELAPSED=0

while [ $ELAPSED -lt $QEMU_TIMEOUT ]; do
    if [ -f /tmp/qemu-serial.log ]; then
        # Check for successful boot indicators
        if grep -q "init done" /tmp/qemu-serial.log 2>/dev/null; then
            echo "✓ System boot completed"
            BOOTED=true
            break
        fi
        
        if grep -q "BusyBox" /tmp/qemu-serial.log 2>/dev/null; then
            echo "✓ Kernel started, BusyBox loaded"
        fi
        
        if grep -q "procd" /tmp/qemu-serial.log 2>/dev/null; then
            echo "✓ procd started"
        fi
    fi
    
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

# Check boot status
if [ "$BOOTED" = true ]; then
    echo ""
    echo "=== Boot Validation ==="
    
    # Check for router-core service
    if grep -q "router-core" /tmp/qemu-serial.log 2>/dev/null; then
        echo "✓ router-core mentioned in logs"
    else
        echo "⚠ router-core not mentioned in logs"
    fi
    
    # Check for hardware detection
    if grep -q "Hardware Detection" /tmp/qemu-serial.log 2>/dev/null; then
        echo "✓ Hardware detection ran"
    else
        echo "⚠ Hardware detection not found in logs"
    fi
    
    # Check for network interfaces
    if grep -q "eth0" /tmp/qemu-serial.log 2>/dev/null; then
        echo "✓ Network interface detected"
    else
        echo "⚠ Network interface not found in logs"
    fi
    
    # Check for errors
    if grep -i "error\|fail\|panic" /tmp/qemu-serial.log 2>/dev/null; then
        echo "⚠ Errors found in logs:"
        grep -i "error\|fail\|panic" /tmp/qemu-serial.log | head -10
    else
        echo "✓ No obvious errors in logs"
    fi
    
    echo ""
    echo "=== Serial Log (last 50 lines) ==="
    tail -50 /tmp/qemu-serial.log
    
    echo ""
    echo "=========================================="
    echo "Boot Test: PASSED"
    echo "=========================================="
    exit 0
else
    echo ""
    echo "=== Boot Timeout ==="
    echo "System did not boot within ${QEMU_TIMEOUT}s"
    echo ""
    echo "=== Serial Log (last 50 lines) ==="
    tail -50 /tmp/qemu-serial.log
    echo ""
    echo "=========================================="
    echo "Boot Test: FAILED"
    echo "=========================================="
    exit 1
fi
