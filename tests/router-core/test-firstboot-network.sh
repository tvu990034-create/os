#!/bin/sh
# Exercise first-boot NIC assignment with fake sysfs and a fake UCI command.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT_DIR/custom-feed/router-core/files/uci-defaults/99_router-core"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

mkdir -p "$TMP_DIR/bin"
mkdir -p "$TMP_DIR/sys-two/eno1/device" "$TMP_DIR/sys-two/eno2/device"
mkdir -p "$TMP_DIR/sys-two/lo" "$TMP_DIR/sys-two/wlan0/device" "$TMP_DIR/sys-two/wlan0/wireless"
mkdir -p "$TMP_DIR/sys-one/eno1/device" "$TMP_DIR/sys-one/lo"
mkdir -p "$TMP_DIR/sys-custom/eno1/device" "$TMP_DIR/sys-custom/eno2/device"

cat > "$TMP_DIR/bin/uci" <<'UCI'
#!/bin/sh
if [ "$1" = "-q" ]; then
	shift
fi
if [ "$1" = "get" ]; then
	case "$2" in
		network.globals.ula_prefix)
			[ "$NO_ULA" != "1" ] || exit 1
			echo "fd12:3456:789a::/48"
			exit 0
			;;
		network.lan_bridge.name) echo "br-lan"; exit 0 ;;
		network.lan_bridge.ports) exit 1 ;;
		network.wan.proto)
			[ "$EXISTING_WAN" = "1" ] && { echo "static"; exit 0; }
			exit 1
			;;
	esac
fi
printf '%s\n' "$*" >> "$UCI_LOG"
exit 0
UCI
cat > "$TMP_DIR/bin/logger" <<'LOGGER'
#!/bin/sh
exit 0
LOGGER
cat > "$TMP_DIR/bin/cat" <<'CAT'
#!/bin/sh
if [ "$1" = "/proc/sys/kernel/random/uuid" ]; then
	printf '%s\n' "00112233-4455-6677-8899-aabbccddeeff"
else
	exec /bin/cat "$@"
fi
CAT
chmod +x "$TMP_DIR/bin/uci" "$TMP_DIR/bin/logger" "$TMP_DIR/bin/cat"

run_case() {
	name=$1
	sysfs=$2
	shift 2
	if ! UCI_LOG="$TMP_DIR/$name.log" PATH="$TMP_DIR/bin:$PATH" \
		ROUTER_CORE_SYS_CLASS_NET="$sysfs" "$@" sh "$SCRIPT" \
		> "$TMP_DIR/$name.out" 2>&1; then
		echo "FAIL: first-boot script returned non-zero for $name" >&2
		cat "$TMP_DIR/$name.out" >&2
		cat "$TMP_DIR/$name.log" >&2 || true
		exit 1
	fi
}

assert_log() {
	name=$1
	expected=$2
	if ! grep -Fq "$expected" "$TMP_DIR/$name.log"; then
		echo "FAIL: $name did not execute: $expected" >&2
		echo "Recorded UCI commands:" >&2
		cat "$TMP_DIR/$name.log" >&2
		echo "Script output:" >&2
		cat "$TMP_DIR/$name.out" >&2
		exit 1
	fi
}

run_case two "$TMP_DIR/sys-two" env
assert_log two 'add_list network.lan_bridge.ports=eno1'
assert_log two 'set network.wan.device=eno2'
assert_log two 'set network.wan6.proto=dhcpv6'
if grep -Fq 'wlan0' "$TMP_DIR/two.log"; then
	echo "FAIL: wireless interface was assigned as an ethernet port" >&2
	exit 1
fi

run_case one "$TMP_DIR/sys-one" env
assert_log one 'add_list network.lan_bridge.ports=eno1'
if grep -Fq 'set network.wan.device=' "$TMP_DIR/one.log"; then
	echo "FAIL: a WAN interface was invented on single-NIC hardware" >&2
	exit 1
fi

run_case custom "$TMP_DIR/sys-custom" env EXISTING_WAN=1
if grep -Fq 'set network.wan.device=' "$TMP_DIR/custom.log"; then
	echo "FAIL: existing WAN configuration was overwritten" >&2
	exit 1
fi

run_case ula "$TMP_DIR/sys-one" env NO_ULA=1
assert_log ula 'set network.globals.ula_prefix=fd00:1122:3344::/48'

echo "First-boot network assignment and ULA tests passed."
