#!/bin/bash
# Router OS Setup Script
# This script prepares the OpenWrt build system for Router OS development

set -e

echo "Router OS Setup Script"
echo "======================"

# Check if openwrt directory exists
if [ ! -d "openwrt" ]; then
    echo "Error: openwrt directory not found."
    echo "Please clone OpenWrt first:"
    echo "  git clone https://github.com/openwrt/openwrt.git"
    exit 1
fi

# Check if custom-feed directory exists
if [ ! -d "custom-feed" ]; then
    echo "Error: custom-feed directory not found."
    exit 1
fi

# Copy custom directory to openwrt
echo "Copying custom configuration to openwrt/custom/..."
mkdir -p openwrt/custom
cp -r custom/* openwrt/custom/

# Generate feeds.conf.local
echo "Generating feeds.conf.local..."
cat > openwrt/feeds.conf.local << 'EOF'
# Router OS Custom Feed Configuration
# This file configures local feeds for Router OS development

# Custom Router OS feed (local package feed, not a git repo)
src-link custom-feed ../custom-feed

# Use remote feeds for build reproducibility
# This ensures consistent builds across different environments
src-git packages https://git.openwrt.org/feed/packages.git
src-git luci https://git.openwrt.org/project/luci.git
src-git routing https://git.openwrt.org/feed/routing.git
src-git telephony https://git.openwrt.org/feed/telephony.git

# Note: For local development with cloned repos, uncomment below:
# src-git packages ../packages
# src-git luci ../luci
# src-git routing ../routing
EOF

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  cd openwrt"
echo "  ./scripts/feeds update custom-feed"
echo "  ./scripts/feeds install router-core"
echo "  ./scripts/feeds install router-net"
echo "  ./scripts/feeds install router-tests"
echo "  make menuconfig"
echo "  make"
