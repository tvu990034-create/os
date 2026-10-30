#!/bin/bash
# Reproducible Build Script for Router OS
set -e

OPENWRT_COMMIT="${OPENWRT_COMMIT:-ca454c0}"
OPENWRT_REPO="${OPENWRT_REPO:-https://github.com/openwrt/openwrt.git}"
JOBS="${JOBS:-$(nproc)}"

echo "Router OS Reproducible Build"
echo "OpenWrt Commit: $OPENWRT_COMMIT"
echo "Jobs: $JOBS"

# Clone or update OpenWrt
if [ ! -d "openwrt" ]; then
    echo "Cloning OpenWrt..."
    git clone $OPENWRT_REPO openwrt
    cd openwrt
    git checkout $OPENWRT_COMMIT
    cd ..
else
    echo "OpenWrt directory exists"
    cd openwrt
    current_commit=$(git rev-parse HEAD)
    if [ "$current_commit" != "$OPENWRT_COMMIT" ]; then
        echo "Updating to $OPENWRT_COMMIT..."
        git fetch origin
        git checkout $OPENWRT_COMMIT
    fi
    cd ..
fi

# Run setup
./setup.sh

# Update feeds
cd openwrt
./scripts/feeds update custom-feed
./scripts/feeds update packages
./scripts/feeds update luci
./scripts/feeds update routing

# Install packages
./scripts/feeds install router-core
./scripts/feeds install router-net
./scripts/feeds install router-tests

# Configure
make defconfig
echo "CONFIG_TARGET_x86=y" >> .config
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_Generic=y" >> .config
echo "CONFIG_PACKAGE_router-core=y" >> .config
echo "CONFIG_PACKAGE_router-net=y" >> .config
echo "CONFIG_PACKAGE_router-tests=y" >> .config
echo "CONFIG_PACKAGE_kmod-e1000=y" >> .config
echo "CONFIG_PACKAGE_kmod-igb=y" >> .config
echo "CONFIG_PACKAGE_kmod-r8169=y" >> .config
make oldconfig

# Build
make toolchain -j$JOBS
make package/router-core/compile -j$JOBS
make package/router-net/compile -j$JOBS
make package/router-tests/compile -j$JOBS
make -j$JOBS

# Check output
echo "=== Build Output ==="
ls -la bin/packages/x86_64/base/router-core_*.ipk
ls -la bin/packages/x86_64/network/router-net_*.ipk
ls -la bin/packages/x86_64/utils/router-tests_*.ipk
ls -la bin/targets/x86_64/*.img.gz
