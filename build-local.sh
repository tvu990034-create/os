#!/usr/bin/env bash
# Build Router OS reproducibly from the pinned source manifest.
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc)}"

cd "$PROJECT_ROOT"

echo "Router OS build"
echo "Project root: $PROJECT_ROOT"
echo "Build jobs: $JOBS"

# Fetch and verify every required repository from manifests/sources.lock.
./scripts/fetch-sources.sh --required-only
./scripts/verify-sources.sh --required-only

# Prepare OpenWrt and register the local custom feed.
./setup.sh

cd "$PROJECT_ROOT/openwrt"

# Update the exact feeds pinned by the project manifest.
for feed in custom-feed packages luci routing; do
    echo "Updating feed: $feed"
    ./scripts/feeds update "$feed"
done

# Register Router OS packages in the OpenWrt build tree.
for package in router-core router-net router-tests; do
    echo "Installing feed package: $package"
    ./scripts/feeds install "$package"
done

# Select a generic x86-64 target suitable for QEMU and x86 mini PCs.
make defconfig

set_config() {
    local key="$1"
    local value="$2"
    local line="${key}=${value}"

    if grep -q "^$key=" .config; then
        sed -i "s|^$key=.*|$line|" .config
    elif grep -q "^# $key is not set$" .config; then
        sed -i "s|^# $key is not set$|$line|" .config
    else
        printf '%s\n' "$line" >> .config
    fi
}

set_config CONFIG_TARGET_x86 y
set_config CONFIG_TARGET_x86_64 y
set_config CONFIG_TARGET_x86_64_Generic y
set_config CONFIG_PACKAGE_router-core y
set_config CONFIG_PACKAGE_router-net y
set_config CONFIG_PACKAGE_router-tests y
set_config CONFIG_PACKAGE_kmod-e1000 y
set_config CONFIG_PACKAGE_kmod-igb y
set_config CONFIG_PACKAGE_kmod-r8169 y

make defconfig

# Build host tools/toolchain, then the actual custom feed packages.
make toolchain/install -j"$JOBS" V=s
for package in router-core router-net router-tests; do
    make "package/feeds/custom-feed/$package/compile" -j"$JOBS" V=s
done

# Build the complete firmware image.
make -j"$JOBS" V=s

# Confirm the custom packages and generic x86/64 firmware image exist.
PACKAGE_DIR="bin/packages/x86_64"
for package in router-core router-net router-tests; do
    package_file="$(find "$PACKAGE_DIR" -type f -name "${package}_*.ipk" -print -quit)"
    if [ -z "$package_file" ]; then
        echo "ERROR: $package package was not produced."
        find "$PACKAGE_DIR" -maxdepth 4 -type f -name '*.ipk' -print || true
        exit 1
    fi
    echo "Built package: $package_file"
done

IMAGE_DIR="bin/targets/x86/64"
image_file="$(find "$IMAGE_DIR" -maxdepth 1 -type f -name '*.img.gz' -print -quit)"
if [ -z "$image_file" ]; then
    echo "ERROR: No compressed x86/64 disk image was produced."
    find bin/targets -maxdepth 4 -type f -print 2>/dev/null || true
    exit 1
fi

echo "Built firmware image: $image_file"
echo "Router OS build completed successfully."
