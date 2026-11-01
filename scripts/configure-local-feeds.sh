#!/bin/sh
# Configure OpenWrt to use local source repositories
# This script creates a feeds.conf that prioritizes local feeds with fallback to remote

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OPENWRT_DIR=${OPENWRT_DIR:-"$ROOT_DIR/openwrt"}
FEEDS_CONF="$OPENWRT_DIR/feeds.conf"

# Local feed paths
LOCAL_FEEDS_ROOT="$ROOT_DIR"
PACKAGES_FEED="$LOCAL_FEEDS_ROOT/packages"
LUCI_FEED="$LOCAL_FEEDS_ROOT/luci"
ROUTING_FEED="$LOCAL_FEEDS_ROOT/routing"
CUSTOM_FEED="$LOCAL_FEEDS_ROOT/custom-feed"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

# Verify local feeds exist
[ -d "$PACKAGES_FEED" ] || fail "Local packages feed not found: $PACKAGES_FEED"
[ -d "$LUCI_FEED" ] || fail "Local luci feed not found: $LUCI_FEED"
[ -d "$ROUTING_FEED" ] || fail "Local routing feed not found: $ROUTING_FEED"
[ -d "$CUSTOM_FEED" ] || fail "Custom feed not found: $CUSTOM_FEED"

# Get current commits for reproducibility
PACKAGES_COMMIT=$(git -C "$PACKAGES_FEED" rev-parse HEAD 2>/dev/null || echo "unknown")
LUCI_COMMIT=$(git -C "$LUCI_FEED" rev-parse HEAD 2>/dev/null || echo "unknown")
ROUTING_COMMIT=$(git -C "$ROUTING_FEED" rev-parse HEAD 2>/dev/null || echo "unknown")

printf 'Configuring local feeds for OpenWrt:\n'
printf '  packages: %s (commit: %s)\n' "$PACKAGES_FEED" "${PACKAGES_COMMIT:0:8}"
printf '  luci: %s (commit: %s)\n' "$LUCI_FEED" "${LUCI_COMMIT:0:8}"
printf '  routing: %s (commit: %s)\n' "$ROUTING_FEED" "${ROUTING_COMMIT:0:8}"
printf '  custom-feed: %s\n' "$CUSTOM_FEED"

# Create feeds.conf with local feeds and remote fallback
cat > "$FEEDS_CONF" <<EOF
# RouterOS local feed configuration
# Local feeds are prioritized for development and reproducibility
# Remote feeds are kept as fallback for missing packages

# Local feeds (prioritized)
src-git packages $PACKAGES_FEED
src-git luci $LUCI_FEED
src-git routing $ROUTING_FEED

# RouterOS custom feed
src-link routeros $CUSTOM_FEED

# Remote feeds (fallback)
src-git telephony https://git.openwrt.org/feed/telephony.git
src-git video https://github.com/openwrt/video.git

# Include OpenWrt defaults for any feeds not defined above
src-include defaults feeds.conf.default
EOF

printf '\nCreated %s\n' "$FEEDS_CONF"
printf 'Local feeds are now prioritized over remote feeds.\n'
printf 'Run: cd "%s" && ./scripts/feeds update -a\n' "$OPENWRT_DIR"
