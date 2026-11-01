#!/bin/bash
# Configure OpenWrt to use local source repositories
# This script creates a feeds.conf that prioritizes local feeds with fallback to remote

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OPENWRT_DIR=${OPENWRT_DIR:-"$ROOT_DIR/openwrt"}
FEEDS_CONF="$OPENWRT_DIR/feeds.conf"

# Allow overriding source root for external repositories
ROUTEROS_SOURCE_ROOT=${ROUTEROS_SOURCE_ROOT:-"$ROOT_DIR"}

# Local feed paths
LOCAL_FEEDS_ROOT="$ROUTEROS_SOURCE_ROOT"
PACKAGES_FEED="$LOCAL_FEEDS_ROOT/packages"
LUCI_FEED="$LOCAL_FEEDS_ROOT/luci"
ROUTING_FEED="$LOCAL_FEEDS_ROOT/routing"
CUSTOM_FEED="$ROOT_DIR/custom-feed"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

# Verify local feeds exist and are Git repositories
verify_git_repo() {
	local repo_path="$1"
	local repo_name="$2"

	if [ ! -d "$repo_path" ]; then
		printf 'WARNING: %s not found at %s\n' "$repo_name" "$repo_path"
		return 1
	fi

	if [ ! -d "$repo_path/.git" ]; then
		printf 'WARNING: %s is not a Git repository: %s\n' "$repo_name" "$repo_path"
		return 1
	fi

	# Verify Git remote
	if ! git -C "$repo_path" remote -v >/dev/null 2>&1; then
		printf 'WARNING: %s has no Git remote: %s\n' "$repo_name" "$repo_path"
		return 1
	fi

	# Get current commit
	local commit=$(git -C "$repo_path" rev-parse HEAD 2>/dev/null || echo "unknown")
	local branch=$(git -C "$repo_path" branch --show-current 2>/dev/null || echo "unknown")
	local remote=$(git -C "$repo_path" remote -v 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")

	# Check if shallow clone
	if [ -f "$repo_path/.git/shallow" ]; then
		local clone_type="shallow"
	else
		local clone_type="full"
	fi

	printf '  %s: %s\n' "$repo_name" "$repo_path"
	printf '    Remote: %s\n' "$remote"
	printf '    Branch: %s\n' "$branch"
	printf '    Commit: %s\n' "${commit:0:8}"
	printf '    Clone type: %s\n' "$clone_type"

	return 0
}

printf 'Verifying local source repositories:\n'
PACKAGES_VERIFIED=false
LUCI_VERIFIED=false
ROUTING_VERIFIED=false

if verify_git_repo "$PACKAGES_FEED" "packages"; then
	PACKAGES_VERIFIED=true
fi

if verify_git_repo "$LUCI_FEED" "luci"; then
	LUCI_VERIFIED=true
fi

if verify_git_repo "$ROUTING_FEED" "routing"; then
	ROUTING_VERIFIED=true
fi

# Only require custom-feed if we're using it directly
[ -d "$CUSTOM_FEED" ] || fail "Custom feed not found: $CUSTOM_FEED"
printf '  custom-feed: %s\n' "$CUSTOM_FEED"

# Get current commits for reproducibility (if verified)
PACKAGES_COMMIT=$(git -C "$PACKAGES_FEED" rev-parse HEAD 2>/dev/null || echo "unknown")
LUCI_COMMIT=$(git -C "$LUCI_FEED" rev-parse HEAD 2>/dev/null || echo "unknown")
ROUTING_COMMIT=$(git -C "$ROUTING_FEED" rev-parse HEAD 2>/dev/null || echo "unknown")

printf '\nConfiguring local feeds for OpenWrt:\n'
printf '  Source root: %s\n' "$LOCAL_FEEDS_ROOT"
if $PACKAGES_VERIFIED; then
	printf '  packages: %s (commit: %s)\n' "$PACKAGES_FEED" "${PACKAGES_COMMIT:0:8}"
fi
if $LUCI_VERIFIED; then
	printf '  luci: %s (commit: %s)\n' "$LUCI_FEED" "${LUCI_COMMIT:0:8}"
fi
if $ROUTING_VERIFIED; then
	printf '  routing: %s (commit: %s)\n' "$ROUTING_FEED" "${ROUTING_COMMIT:0:8}"
fi
printf '  custom-feed: %s\n' "$CUSTOM_FEED"

# Create feeds.conf with local feeds and remote fallback
cat > "$FEEDS_CONF" <<EOF
# RouterOS local feed configuration
# Local feeds are prioritized for development and reproducibility
# Remote feeds are kept as fallback for missing packages

EOF

# Add verified local feeds (use src-link for local working-tree feeds)
if $PACKAGES_VERIFIED; then
	printf 'src-link packages %s\n' "$PACKAGES_FEED" >> "$FEEDS_CONF"
fi
if $LUCI_VERIFIED; then
	printf 'src-link luci %s\n' "$LUCI_FEED" >> "$FEEDS_CONF"
fi
if $ROUTING_VERIFIED; then
	printf 'src-link routing %s\n' "$ROUTING_FEED" >> "$FEEDS_CONF"
fi

# Add RouterOS custom feed
printf 'src-link routeros %s\n' "$CUSTOM_FEED" >> "$FEEDS_CONF"

# Add remote feeds (fallback)
cat >> "$FEEDS_CONF" <<EOF

# Remote feeds (fallback)
src-git telephony https://git.openwrt.org/feed/telephony.git
src-git video https://github.com/openwrt/video.git

# Include OpenWrt defaults for any feeds not defined above
src-include defaults feeds.conf.default
EOF

printf '\nCreated %s\n' "$FEEDS_CONF"
printf 'Local feeds are now prioritized over remote feeds.\n'
printf 'Run: cd "%s" && ./scripts/feeds update -a\n' "$OPENWRT_DIR"
