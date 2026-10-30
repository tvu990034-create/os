#!/bin/sh
# Functional tests for the Router OS interface monitor using a fake sysfs tree.
set -eu

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MONITOR="$PROJECT_ROOT/custom-feed/router-net/files/monitor-interfaces.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/router-net-monitor.XXXXXX")"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT HUP INT TERM

SYS_CLASS_NET="$TMP_DIR/sys/class/net"
STATE_DIR="$TMP_DIR/state"
mkdir -p "$SYS_CLASS_NET/lo" "$SYS_CLASS_NET/eth0" "$SYS_CLASS_NET/eth1"
printf '%s\n' "unknown" > "$SYS_CLASS_NET/lo/operstate"
printf '%s\n' "up" > "$SYS_CLASS_NET/eth0/operstate"
printf '%s\n' "down" > "$SYS_CLASS_NET/eth1/operstate"

SYS_CLASS_NET="$SYS_CLASS_NET" STATE_DIR="$STATE_DIR" "$MONITOR" --once

[ "$(cat "$STATE_DIR/eth0")" = "up" ]
[ "$(cat "$STATE_DIR/eth1")" = "down" ]
[ ! -e "$STATE_DIR/lo" ]

printf '%s\n' "lowerlayerdown" > "$SYS_CLASS_NET/eth0/operstate"
SYS_CLASS_NET="$SYS_CLASS_NET" STATE_DIR="$STATE_DIR" "$MONITOR" --once
[ "$(cat "$STATE_DIR/eth0")" = "lowerlayerdown" ]

echo "Router OS interface monitor tests passed"
