#!/bin/sh
# Exercise generic fallback behavior and preservation of board-generated layouts.

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
mkdir -p "$TMP_DIR/sys-empty/lo"

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
		network.lan_bridge.name)
			[ "$BOARD_CONFIG" != "1" ] || exit 1
			echo "br-lan"
			exit 0
			;;
		network.lan_bridge.ports)
			[ "$EXISTING_LAN" = "1" ] && { echo "eno1"; exit 0; }
			exit 1
			;;
		network.wan.proto)
			[ "$EXISTING_WAN" = "1" ] && { echo "static"; exit 0; }
			exit 1
			;;
		system.@system\[0\].hostname)
			echo "${SYSTEM_HOSTNAME:-OpenWrt}"
			exit 0
			;;
		system.@system\[0\].timezone)
			echo "${SYSTEM_TIMEZONE:-GMT0}"
			exit 0
			;;
		system.@system\[0\].zonename)
			echo "${SYSTEM_ZONENAME:-UTC}"
			exit 0
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
assert_log two 'commit network'
assert_log two "set system.@system[0].hostname=RouterOS"
assert_log two "set system.@system[0].timezone=ICT-7"
if grep -Fq 'wlan0' "$TMP_DIR/two.log"; then
	echo "FAIL: wireless interface was assigned as an ethernet port" >&2
	exit 1
fi

run_case one "$TMP_DIR/sys-one" env
assert_log one 'add_list network.lan_bridge.ports=eno1'
assert_log one 'commit network'
if grep -Fq 'set network.wan.device=' "$TMP_DIR/one.log"; then
	echo "FAIL: a WAN interface was invented on single-NIC hardware" >&2
	exit 1
fi

run_case custom "$TMP_DIR/sys-custom" env EXISTING_WAN=1
assert_log custom 'commit network'
if grep -Fq 'set network.wan.device=' "$TMP_DIR/custom.log"; then
	echo "FAIL: existing WAN configuration was overwritten" >&2
	exit 1
fi

run_case ula "$TMP_DIR/sys-one" env NO_ULA=1
assert_log ula 'set network.globals.ula_prefix=fd00:1122:3344::/48'
assert_log ula 'commit network'

run_case no-nic "$TMP_DIR/sys-empty" env NO_ULA=1
assert_log no-nic 'set network.globals.ula_prefix=fd00:1122:3344::/48'
assert_log no-nic 'commit network'

run_case existing-bridge "$TMP_DIR/sys-one" env NO_ULA=1 EXISTING_LAN=1
assert_log existing-bridge 'commit system'
if grep -Fq 'add_list network.lan_bridge.ports=' "$TMP_DIR/existing-bridge.log"; then
	echo "FAIL: existing bridge members were modified" >&2
	exit 1
fi

# Board-generated layouts lack the RouterOS-only generic bridge marker. They
# must not receive guessed LAN/WAN ports, even on systems with several NICs.
run_case board "$TMP_DIR/sys-two" env BOARD_CONFIG=1 \
	SYSTEM_HOSTNAME=BoardRouter SYSTEM_TIMEZONE=EST5EDT SYSTEM_ZONENAME=America/New_York
if grep -E '^(set|add_list|delete) network\.' "$TMP_DIR/board.log"; then
	echo "FAIL: board-generated network configuration was modified" >&2
	exit 1
fi
if grep -Fq 'commit network' "$TMP_DIR/board.log"; then
	echo "FAIL: board-generated network configuration was committed" >&2
	exit 1
fi
if grep -Fq 'set system.@system[0].hostname=RouterOS' "$TMP_DIR/board.log"; then
	echo "FAIL: board hostname was overwritten" >&2
	exit 1
fi
if grep -Fq 'set system.@system[0].timezone=ICT-7' "$TMP_DIR/board.log"; then
	echo "FAIL: board timezone was overwritten" >&2
	exit 1
fi

echo "First-boot generic defaults and board-network preservation tests passed."
