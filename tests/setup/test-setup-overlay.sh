#!/bin/sh
# Test safe overlay synchronization and migration to board-generated network/system config.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/openwrt/.git" "$TMP_DIR/openwrt/files/etc/config"
cat > "$TMP_DIR/bin/git" <<'GIT'
#!/bin/sh
if [ "$1" = "-C" ]; then
	shift 2
fi
case "$1" in
	rev-parse)
		printf '%s\n' "0123456789abcdef0123456789abcdef01234567"
		;;
	*)
		echo "unexpected fake git command: $*" >&2
		exit 1
		;;
esac
GIT
chmod +x "$TMP_DIR/bin/git"

# Simulate the old revision's files and ownership manifest. Setup may remove
# these only when their bytes still match the old manifest.
printf '%s\n' '# legacy static network config' > "$TMP_DIR/openwrt/files/etc/config/network"
printf '%s\n' '# legacy static system config' > "$TMP_DIR/openwrt/files/etc/config/system"
NETWORK_HASH=$(sha256sum "$TMP_DIR/openwrt/files/etc/config/network" | awk '{ print $1 }')
SYSTEM_HASH=$(sha256sum "$TMP_DIR/openwrt/files/etc/config/system" | awk '{ print $1 }')
printf '%s  %s\n%s  %s\n' \
	"$NETWORK_HASH" etc/config/network "$SYSTEM_HASH" etc/config/system \
	> "$TMP_DIR/openwrt/.routeros-overlay.sha256"

run_setup() {
	OPENWRT_DIR="$TMP_DIR/openwrt" PATH="$TMP_DIR/bin:$PATH" "$ROOT_DIR/setup.sh"
}

run_setup

for name in firewall dhcp; do
	cmp -s "$ROOT_DIR/custom/overlay/etc/config/$name" "$TMP_DIR/openwrt/files/etc/config/$name"
done

[ ! -e "$TMP_DIR/openwrt/files/etc/config/network" ] || {
	echo "FAIL: legacy managed network overlay was not removed" >&2
	exit 1
}
[ ! -e "$TMP_DIR/openwrt/files/etc/config/system" ] || {
	echo "FAIL: legacy managed system overlay was not removed" >&2
	exit 1
}

if grep -q 'etc/config/network\|etc/config/system' "$TMP_DIR/openwrt/.routeros-overlay.sha256"; then
	echo "FAIL: retired overlay paths remain in the ownership manifest" >&2
	exit 1
fi

[ -f "$TMP_DIR/openwrt/.routeros-overlay.sha256" ] || {
	echo "FAIL: overlay manifest was not created" >&2
	exit 1
}

# A second invocation is idempotent.
run_setup

# Local modifications to a managed service overlay must be preserved and stop
# a future sync.
printf '\n# local operator change\n' >> "$TMP_DIR/openwrt/files/etc/config/firewall"
if run_setup >/dev/null 2>&1; then
	echo "FAIL: setup overwrote a locally modified firewall overlay" >&2
	exit 1
fi
grep -Fq '# local operator change' "$TMP_DIR/openwrt/files/etc/config/firewall"

# An unmanaged or locally modified retired network overlay is never deleted.
rm -f "$TMP_DIR/openwrt/files/etc/config/firewall"
run_setup
printf '%s\n' '# operator-owned network overlay' > "$TMP_DIR/openwrt/files/etc/config/network"
if run_setup >/dev/null 2>&1; then
	echo "FAIL: setup silently accepted an unmanaged network overlay" >&2
	exit 1
fi
grep -Fq 'operator-owned' "$TMP_DIR/openwrt/files/etc/config/network"

echo "Board-aware overlay synchronization and migration tests passed."
