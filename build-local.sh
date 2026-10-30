#!/bin/bash
# Reproducible Build Script for Router OS
# This script provides a single entry point for building Router OS

set -e

OPENWRT_COMMIT="${OPENWRT_COMMIT:-ca454c0}"
OPENWRT_REPO="${OPENWRT_REPO:-https://github.com/openwrt/openwrt.git}"
JOBS="${JOBS:-$(nproc)}"

echo "=========================================="
echo "Router OS Reproducible Build"
echo "=========================================="
echo "OpenWrt Commit: $OPENWRT_COMMIT"
echo "Jobs: $JOBS"
echo ""

# Check for required tools
check_dependencies() {
    echo "Checking dependencies..."
    local missing=0
    
    for cmd in git make gcc gawk flex bison wget; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo "  ✗ $cmd not found"
            missing=1
        else
            echo "  ✓ $cmd found"
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo ""
        echo "Error: Missing required dependencies"
        echo "Install with: sudo apt-get install build-essential gawk flex bison wget"
        exit 1
    fi
    echo ""
}

# Clone or update OpenWrt
setup_openwrt() {
    echo "Setting up OpenWrt..."
    
    if [ ! -d "openwrt" ]; then
        echo "  Cloning OpenWrt..."
        git clone $OPENWRT_REPO openwrt
        cd openwrt
        git checkout $OPENWRT_COMMIT
        cd ..
    else
        echo "  OpenWrt directory exists"
        cd openwrt
        current_commit=$(git rev-parse HEAD)
        if [ "$current_commit" != "$OPENWRT_COMMIT" ]; then
            echo "  Updating to $OPENWRT_COMMIT..."
            git fetch origin
            git checkout $OPENWRT_COMMIT
        else
            echo "  Already at correct commit"
        fi
        cd ..
    fi
    echo ""
}

# Run setup script
run_setup() {
    echo "Running setup script..."
    ./setup.sh
    echo ""
}

# Update feeds
update_feeds() {
    echo "Updating feeds..."
    cd openwrt
    ./scripts/feeds update custom-feed
    ./scripts/feeds update packages
    ./scripts/feeds update luci
    ./scripts/feeds update routing
    cd ..
    echo ""
}

# Install packages
install_packages() {
    echo "Installing custom packages..."
    cd openwrt
    ./scripts/feeds install router-core
    ./scripts/feeds install router-net
    ./scripts/feeds install router-tests
    cd ..
    echo ""
}

# Configure build
configure_build() {
    echo "Configuring build..."
    cd openwrt
    
    # Create minimal config for x86_64
    make defconfig
    echo "CONFIG_TARGET_x86=y" >> .config
    echo "CONFIG_TARGET_x86_64=y" >> .config
    echo "CONFIG_TARGET_x86_64_Generic=y" >> .config
    echo "CONFIG_PACKAGE_router-core=y" >> .config
    echo "CONFIG_PACKAGE_router-net=y" >> .config
    echo "CONFIG_PACKAGE_router-tests=y" >> .config
    
    # Essential network drivers
    echo "CONFIG_PACKAGE_kmod-e1000=y" >> .config
    echo "CONFIG_PACKAGE_kmod-igb=y" >> .config
    echo "CONFIG_PACKAGE_kmod-r8169=y" >> .config
    
    # Busybox networking
    echo "CONFIG_BUSYBOX_CONFIG_IP=y" >> .config
    echo "CONFIG_BUSYBOX_CONFIG_IPADDR=y" >> .config
    echo "CONFIG_BUSYBOX_CONFIG_ROUTE=y" >> .config
    
    make oldconfig
    cd ..
    echo ""
}

# Build toolchain
build_toolchain() {
    echo "Building toolchain..."
    cd openwrt
    make toolchain -j$JOBS
    cd ..
    echo ""
}

# Build custom packages
build_packages() {
    echo "Building custom packages..."
    cd openwrt
    make package/router-core/compile -j$JOBS V=s
    make package/router-net/compile -j$JOBS V=s
    make package/router-tests/compile -j$JOBS V=s
    cd ..
    echo ""
}

# Build image
build_image() {
    echo "Building image..."
    cd openwrt
    make -j$JOBS V=s
    cd ..
    echo ""
}

# Check build output
check_output() {
    echo "Checking build output..."
    cd openwrt
    
    echo "Custom packages:"
    ls -la bin/packages/x86_64/base/router-core_*.ipk 2>/dev/null || echo "  router-core not found"
    ls -la bin/packages/x86_64/network/router-net_*.ipk 2>/dev/null || echo "  router-net not found"
    ls -la bin/packages/x86_64/utils/router-tests_*.ipk 2>/dev/null || echo "  router-tests not found"
    
    echo ""
    echo "Images:"
    ls -la bin/targets/x86_64/*.img.gz 2>/dev/null || echo "  No images found"
    
    cd ..
    echo ""
}

# Main execution
main() {
    check_dependencies
    setup_openwrt
    run_setup
    update_feeds
    install_packages
    configure_build
    build_toolchain
    build_packages
    build_image
    check_output
    
    echo "=========================================="
    echo "Build Complete"
    echo "=========================================="
    echo ""
    echo "Image location: openwrt/bin/targets/x86_64/"
    echo "Package location: openwrt/bin/packages/x86_64/"
    echo ""
    echo "To boot in QEMU:"
    echo "  gunzip openwrt/bin/targets/x86_64/openwrt-x86-64-generic-ext4-combined.img.gz"
    echo "  qemu-system-x86_64 -m 512M -drive file=openwrt/bin/targets/x86_64/openwrt-x86-64-generic-ext4-combined.img,format=raw -net nic,model=e1000 -net user -nographic"
}

main "$@"
