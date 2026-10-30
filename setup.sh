#!/bin/sh
# Prepare a pinned OpenWrt source tree and register the RouterOS local feed.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OPENWRT_DIR=${OPENWRT_DIR:-"$ROOT_DIR/openwrt"}
OPENWRT_REF=${OPENWRT_REF:-v25.12.6}
CUSTOM_FEED_DIR="$ROOT_DIR/custom-feed"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

command -v git >/dev/null 2>&1 || fail "git is required"
[ -d "$CUSTOM_FEED_DIR" ] || fail "custom-feed directory is missing"

if [ ! -d "$OPENWRT_DIR" ]; then
	printf 'Cloning OpenWrt %s into %s\n' "$OPENWRT_REF" "$OPENWRT_DIR"
	git clone --depth 1 --branch "$OPENWRT_REF" https://github.com/openwrt/openwrt.git "$OPENWRT_DIR"
fi

[ -d "$OPENWRT_DIR/.git" ] || fail "$OPENWRT_DIR exists but is not an OpenWrt Git checkout"
actual_commit=$(git -C "$OPENWRT_DIR" rev-parse HEAD)
expected_commit=$(git -C "$OPENWRT_DIR" rev-parse "$OPENWRT_REF^{commit}" 2>/dev/null || true)
[ -n "$expected_commit" ] || fail "OpenWrt ref $OPENWRT_REF is not available locally; fetch it or remove the checkout and rerun setup"
[ "$actual_commit" = "$expected_commit" ] || fail "OpenWrt checkout is not at $OPENWRT_REF (HEAD=$actual_commit). No files were changed; check out the pinned ref and rerun."

FEEDS_CONF="$OPENWRT_DIR/feeds.conf"
CUSTOM_FEED_LINE="src-link routeros $CUSTOM_FEED_DIR"

if [ -f "$FEEDS_CONF" ]; then
	if ! grep -Fqx "$CUSTOM_FEED_LINE" "$FEEDS_CONF"; then
		fail "existing feeds.conf was preserved. Add this exact line to it: $CUSTOM_FEED_LINE"
	fi
else
	{
		printf '%s\n' 'src-include defaults feeds.conf.default'
		printf '%s\n' "$CUSTOM_FEED_LINE"
	} > "$FEEDS_CONF"
fi

printf '\nRouterOS build tree is ready.\n'
printf '  OpenWrt ref: %s\n' "$OPENWRT_REF"
printf '  OpenWrt commit: %s\n' "$actual_commit"
printf '  Custom feed: %s\n' "$CUSTOM_FEED_DIR"
printf '\nNext: cd "%s" && ./scripts/feeds update -a\n' "$OPENWRT_DIR"
