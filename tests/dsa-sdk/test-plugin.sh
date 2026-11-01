#!/bin/sh
# Compile a shared-object plugin and exercise the DSA ABI, metadata and runner.

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
echo "DSA legacy CLI compatibility test passed."

make -C "$ROOT_DIR/examples/dsa/protocol-classifier" clean all \
	CC="$CC" ABI_INCLUDE="$INCLUDE_DIR" TARGET="$TMP_DIR/protocol-classifier.so"

OUTPUT="$("$TMP_DIR/router-dsa-run" "$TMP_DIR/protocol-classifier.so" \
	--ingress 3 --length 128 --ip-version 6 --protocol 6 \
	--src-ip 2001:db8::1 --dst-ip 2001:db8::2 \
	--src-port 12345 --dst-port 443 --mark 7 --queue 2 \
	--iterations 1000 --warmup 100)"
printf '%s\n' "$OUTPUT" | grep -Fq 'plugin=protocol-classifier version=1.0.0 stage=classify'
printf '%s\n' "$OUTPUT" | grep -Fq 'source_ip=2001:db8::1 destination_ip=2001:db8::2'
printf '%s\n' "$OUTPUT" | grep -Fq 'source_port=12345 destination_port=443 packet_mark=7 queue_mapping=2'
printf '%s\n' "$OUTPUT" | grep -Fq 'actions=0x00000002 mark=4097'
printf '%s\n' "$OUTPUT" | grep -Fq 'warmup=100 iterations=1000'
echo "DSA IPv6 TCP metadata, classifier and callback benchmark test passed."

OUTPUT="$("$TMP_DIR/router-dsa-run" "$TMP_DIR/protocol-classifier.so" \
	--ingress 4 --length 512 --ip-version 4 --protocol 17 \
	--src-ip 192.0.2.1 --dst-ip 198.51.100.7 \
	--src-port 1234 --dst-port 53 --iterations 10)"
printf '%s\n' "$OUTPUT" | grep -Fq 'source_ip=192.0.2.1 destination_ip=198.51.100.7'
printf '%s\n' "$OUTPUT" | grep -Fq 'source_port=1234 destination_port=53'
printf '%s\n' "$OUTPUT" | grep -Fq 'actions=0x00000002 mark=4098'
echo "DSA IPv4 UDP metadata and classifier test passed."

OUTPUT="$("$TMP_DIR/router-dsa-run" "$TMP_DIR/protocol-classifier.so" \
	--ingress 2 --length 64 --ip-version 4 --protocol 1)"
printf '%s\n' "$OUTPUT" | grep -Fq 'actions=0x00000000 mark=0'
echo "DSA unclassified protocol test passed."

if "$TMP_DIR/router-dsa-run" "$TMP_DIR/sample-plugin.so" --ingress 0 >/dev/null 2>&1; then
	echo "FAIL: runner accepted ingress ifindex zero" >&2
	exit 1
fi
if "$TMP_DIR/router-dsa-run" "$TMP_DIR/sample-plugin.so" --ip-version 5 >/dev/null 2>&1; then
	echo "FAIL: runner accepted invalid IP version" >&2
	exit 1
fi
if "$TMP_DIR/router-dsa-run" "$TMP_DIR/sample-plugin.so" --ip-version 4 --src-ip 2001:db8::1 >/dev/null 2>&1; then
	echo "FAIL: runner accepted an IPv6 address in an IPv4 packet" >&2
	exit 1
fi
if "$TMP_DIR/router-dsa-run" "$TMP_DIR/sample-plugin.so" --src-port 65536 >/dev/null 2>&1; then
	echo "FAIL: runner accepted a source port outside 0..65535" >&2
	exit 1
fi
echo "DSA runner argument validation tests passed."
