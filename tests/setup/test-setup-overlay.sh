#!/bin/sh
# Test safe, idempotent synchronization of RouterOS rootfs overlay files.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/openwrt/.git"
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

run_setup() {
	OPENWRT_DIR="$TMP_DIR/openwrt" PATH="$TMP_DIR/bin:$PATH" "$ROOT_DIR/setup.sh"
}

run_setup

for name in network firewall dhcp system; do
	cmp -s "$ROOT_DIR/custom/overlay/etc/config/$name" "$TMP_DIR/openwrt/files/etc/config/$name"
done

[ -f "$TMP_DIR/openwrt/.routeros-overlay.sha256" ] || {
	echo "FAIL: overlay manifest was not created" >&2
	exit 1
}

# A second invocation is idempotent.
run_setup

# Local modifications must be preserved and must stop a future sync.
printf '\n# local operator change\n' >> "$TMP_DIR/openwrt/files/etc/config/network"
if run_setup >/dev/null 2>&1; then
	echo "FAIL: setup overwrote a locally modified overlay file" >&2
	exit 1
fi
grep -Fq '# local operator change' "$TMP_DIR/openwrt/files/etc/config/network"

echo "Rootfs overlay synchronization tests passed."
