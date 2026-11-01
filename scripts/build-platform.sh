#!/bin/sh
# Build one registered RouterOS firmware profile using the pinned OpenWrt tree.
# Keep JOBS low on memory-constrained laptops; downloads/build outputs are reused.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REGISTRY="$ROOT_DIR/config/platforms.tsv"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

usage() {
	cat >&2 <<'EOF'
Usage: scripts/build-platform.sh <profile>

Registered profiles are listed in config/platforms.tsv.
Optional environment variables:
  OPENWRT_DIR  OpenWrt checkout (default: ./openwrt)
  OPENWRT_REF  pinned OpenWrt ref (default: v25.12.6)
  JOBS         parallel build jobs (default: 2; use 1 on low-memory hosts)
EOF
	exit 2
}

[ "$#" -eq 1 ] || usage
PROFILE=$1

[ -f "$REGISTRY" ] || fail "platform registry is missing: $REGISTRY"
row=$(awk -v wanted="$PROFILE" '
	$0 !~ /^[[:space:]]*#/ && NF {
		if ($1 == wanted) {
			print $2, $3, $4, $5, $6
			count++
		}
	}
	END {
		if (count != 1)
			exit 1
	}
' "$REGISTRY") || fail "unknown or duplicate platform profile: $PROFILE"

# Values in the registry are repository-maintained, whitespace-separated fields.
set -- $row
PROFILE_TYPE=$1
TARGET=$2
SUBTARGET=$3
CONFIG_REL=$4
PROFILE_STATUS=$5
CONFIG_FILE="$ROOT_DIR/$CONFIG_REL"

[ -f "$CONFIG_FILE" ] || fail "profile configuration is missing: $CONFIG_FILE"

JOBS=${JOBS:-2}
case "$JOBS" in
	''|*[!0-9]*) fail "JOBS must be a positive integer" ;;
esac
[ "$JOBS" -ge 1 ] || fail "JOBS must be at least 1"

OPENWRT_DIR=${OPENWRT_DIR:-"$ROOT_DIR/openwrt"}
OPENWRT_REF=${OPENWRT_REF:-v25.12.6}

printf 'RouterOS profile: %s\n' "$PROFILE"
printf 'Profile type:     %s\n' "$PROFILE_TYPE"
printf 'OpenWrt target:   %s/%s\n' "$TARGET" "$SUBTARGET"
printf 'Profile status:   %s\n' "$PROFILE_STATUS"
printf 'Build jobs:       %s\n' "$JOBS"
if [ "$PROFILE_STATUS" = "experimental" ]; then
	printf '%s\n' "NOTICE: this profile is experimental; its image is not certified for arbitrary devices."
fi

OPENWRT_DIR="$OPENWRT_DIR" OPENWRT_REF="$OPENWRT_REF" "$ROOT_DIR/setup.sh"

[ -x "$OPENWRT_DIR/scripts/feeds" ] ||
	fail "OpenWrt feeds script is missing or not executable"

cd "$OPENWRT_DIR"
./scripts/feeds update -a
./scripts/feeds install -a

# Preserve a developer's original .config once before selecting a RouterOS
# profile. Re-running a build always starts from its tracked config, not a
# stale config left by a previous target.
if [ -f .config ] && [ ! -f .config.routeros-original ]; then
	cp -p .config .config.routeros-original
fi
cp "$CONFIG_FILE" .config
make defconfig

grep -Fqx "CONFIG_TARGET_$TARGET=y" .config ||
	fail "defconfig did not select target $TARGET"
grep -Fqx "CONFIG_TARGET_${TARGET}_${SUBTARGET}=y" .config ||
	fail "defconfig did not select subtarget $TARGET/$SUBTARGET"

make download -j"$JOBS"
make -j"$JOBS" V=s

OUTPUT_DIR="$OPENWRT_DIR/bin/targets/$TARGET/$SUBTARGET"
[ -d "$OUTPUT_DIR" ] || fail "build completed without expected output directory: $OUTPUT_DIR"

printf '\nBuild completed for %s. Firmware artifacts are in:\n  %s\n' "$PROFILE" "$OUTPUT_DIR"
