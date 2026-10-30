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

# Copy custom directory to openwrt
echo "Copying custom configuration to openwrt/custom/..."
cp -r custom/* openwrt/custom/

# Generate feeds.conf.local
echo "Generating feeds.conf.local..."
cat > openwrt/feeds.conf.local << 'EOF'
# Router OS Custom Feed Configuration
# This file configures local feeds for Router OS development

# Custom Router OS feed (local package feed, not a git repo)
src-link custom-feed ../custom-feed

# Local OpenWrt package feeds (using sibling git repositories)
# These are local clones of the official OpenWrt feeds
src-git packages ../packages
src-git luci ../luci
src-git routing ../routing

# Note: These local feeds use relative paths from the openwrt/ directory
# The standard feeds.conf.default uses remote git repositories
# This local configuration is for development with existing cloned repositories
# src-link is used for custom-feed since it's not a git repository
# src-git is used for packages/luci/routing since they are git repositories
EOF

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  cd openwrt"
echo "  ./scripts/feeds update custom-feed"
echo "  ./scripts/feeds install router-core"
echo "  make menuconfig"
echo "  make"
