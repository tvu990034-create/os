#!/bin/sh
# Prepare a pinned OpenWrt source tree, sync the RouterOS rootfs overlay and register its feed.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OPENWRT_DIR=\${OPENWRT_DIR:-"$ROOT_DIR/openwrt"}
OPENWRT_REF=\${OPENWRT_REF:-v25.12.6}
CUSTOM_FEED_DIR="$ROOT_DIR/custom-feed"
OVERLAY_DIR="$ROOT_DIR/custom/overlay"
MANIFEST="$OPENWRT_DIR/.routeros-overlay.sha256"
TMP_MANIFEST="$OPENWRT_DIR/.routeros-overlay.sha256.tmp.$$"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

cleanup() {
	rm -f "$TMP_MANIFEST"
}
trap cleanup EXIT HUP INT TERM

command -v git >/dev/null 2>&1 || fail "git is required"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
[ -d "$CUSTOM_FEED_DIR" ] || fail "custom-feed directory is missing"
[ -d "$OVERLAY_DIR" ] || fail "custom/overlay directory is missing"

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
DEFAULTS_LINE="src-include defaults feeds.conf.default"

if [ -f "$FEEDS_CONF" ]; then
	grep -Fqx "$CUSTOM_FEED_LINE" "$FEEDS_CONF" ||
		fail "existing feeds.conf was preserved. Add this exact line to it: $CUSTOM_FEED_LINE"
	grep -Fqx "$DEFAULTS_LINE" "$FEEDS_CONF" ||
		fail "existing feeds.conf must include upstream pinned feeds with: $DEFAULTS_LINE"
else
	{
		printf '%s\n' "$DEFAULTS_LINE"
		printf '%s\n' "$CUSTOM_FEED_LINE"
	} > "$FEEDS_CONF"
fi

# OpenWrt copies TOPDIR/files into the root filesystem after packages are
# installed. Track the managed overlay to avoid overwriting local edits.
mkdir -p "$OPENWRT_DIR/files"
: > "$TMP_MANIFEST"

for name in network firewall dhcp system; do
	relative_path="etc/config/$name"
	source_file="$OVERLAY_DIR/$relative_path"
	target_file="$OPENWRT_DIR/files/$relative_path"

	[ -f "$source_file" ] || fail "rootfs overlay source is missing: $source_file"
	mkdir -p "$(dirname "$target_file")"

	new_hash=$(sha256sum "$source_file" | awk '{ print $1 }')
	old_hash=$(awk -v path="$relative_path" '$2 == path { print $1; exit }' "$MANIFEST" 2>/dev/null || true)
	current_hash=

	if [ -L "$target_file" ]; then
		fail "overlay target is a symbolic link; refusing to replace it: $target_file"
	elif [ -e "$target_file" ]; then
		[ -f "$target_file" ] || fail "overlay target is not a regular file: $target_file"
		current_hash=$(sha256sum "$target_file" | awk '{ print $1 }')
		if [ -n "$old_hash" ]; then
			[ "$current_hash" = "$old_hash" ] || [ "$current_hash" = "$new_hash" ] ||
				fail "overlay target was locally modified; preserve or merge it manually: $target_file"
		else
			[ "$current_hash" = "$new_hash" ] ||
				fail "pre-existing OpenWrt overlay conflicts with RouterOS: $target_file"
		fi
	fi

	if [ "$current_hash" != "$new_hash" ]; then
		temporary_file="$target_file.routeros-tmp.$$"
		cp "$source_file" "$temporary_file"
		chmod 0644 "$temporary_file"
		mv "$temporary_file" "$target_file"
	fi

	printf '%s  %s\n' "$new_hash" "$relative_path" >> "$TMP_MANIFEST"
done

mv "$TMP_MANIFEST" "$MANIFEST"

printf '\nRouterOS build tree is ready.\n'
printf '  OpenWrt ref: %s\n' "$OPENWRT_REF"
printf '  OpenWrt commit: %s\n' "$actual_commit"
printf '  Custom feed: %s\n' "$CUSTOM_FEED_DIR"
printf '  Rootfs overlay: %s/files\n' "$OPENWRT_DIR"
printf '\nNext: cd "%s" && ./scripts/feeds update -a\n' "$OPENWRT_DIR"
