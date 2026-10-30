#!/bin/sh
# Compile a shared-object plugin and exercise both the ABI and runner.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
CC=${CC:-cc}
command -v "$CC" >/dev/null 2>&1 || {
	echo "C compiler not found: $CC" >&2
	exit 1
}

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

INCLUDE_DIR="$ROOT_DIR/custom-feed/router-dsa-sdk/files/include"
PLUGIN_SOURCE="$ROOT_DIR/tests/dsa-sdk/sample-plugin.c"
HOST_SOURCE="$ROOT_DIR/tests/dsa-sdk/host-smoke.c"
RUNNER_SOURCE="$ROOT_DIR/custom-feed/router-dsa-runtime/src/router-dsa-run.c"

"$CC" -std=c11 -Wall -Wextra -Werror -fPIC -shared \
	-I "$INCLUDE_DIR" -o "$TMP_DIR/sample-plugin.so" "$PLUGIN_SOURCE"

"$CC" -std=c11 -Wall -Wextra -Werror \
	-I "$INCLUDE_DIR" -o "$TMP_DIR/host-smoke" "$HOST_SOURCE" -ldl

"$CC" -std=c11 -Wall -Wextra -Werror \
	-I "$INCLUDE_DIR" -o "$TMP_DIR/router-dsa-run" "$RUNNER_SOURCE" -ldl

"$TMP_DIR/host-smoke" "$TMP_DIR/sample-plugin.so"
OUTPUT="$("$TMP_DIR/router-dsa-run" "$TMP_DIR/sample-plugin.so" 3 128 6 58)"
printf '%s\n' "$OUTPUT" | grep -Fq 'plugin=abi-smoke version=1.0.0 stage=observe'
printf '%s\n' "$OUTPUT" | grep -Fq 'ingress_ifindex=3 packet_length=128 ip_version=6 ip_protocol=58'
printf '%s\n' "$OUTPUT" | grep -Fq 'actions=0x00000000'
echo "DSA runner metadata and decision test passed."

if "$TMP_DIR/router-dsa-run" "$TMP_DIR/sample-plugin.so" 0 64 4 17 >/dev/null 2>&1; then
	echo "FAIL: runner accepted ingress ifindex zero" >&2
	exit 1
fi
if "$TMP_DIR/router-dsa-run" "$TMP_DIR/sample-plugin.so" 2 64 5 17 >/dev/null 2>&1; then
	echo "FAIL: runner accepted invalid IP version" >&2
	exit 1
fi
echo "DSA runner argument validation tests passed."
