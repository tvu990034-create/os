#!/bin/sh
# Build a RouterOS x86_64 generic image with a pinned OpenWrt release.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OPENWRT_DIR=${OPENWRT_DIR:-"$ROOT_DIR/openwrt"}
JOBS=${JOBS:-2}
CONFIG_FILE="$ROOT_DIR/config/x86_64.config"

if [ ! -d "$OPENWRT_DIR" ]; then
	"$ROOT_DIR/setup.sh"
fi

[ -x "$OPENWRT_DIR/scripts/feeds" ] || {
	echo "OpenWrt build tree is missing scripts/feeds; run setup.sh first." >&2
	exit 1
}

cd "$OPENWRT_DIR"
./scripts/feeds update -a
./scripts/feeds install -a

if [ ! -f .config ]; then
	cp "$CONFIG_FILE" .config
fi

make defconfig
make download
make -j"$JOBS" V=s

printf '\nBuild finished. Look for the x86/64 image in:\n'
printf '  %s/bin/targets/x86/64/\n' "$OPENWRT_DIR"
