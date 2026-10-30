#!/bin/bash
# Router OS Setup Script
# This script prepares the OpenWrt build system for Router OS development

set -e

echo "Router OS Setup Script"
echo "======================"

# Check if openwrt directory exists
if [ ! -d "openwrt" ]; then
    echo "Error: openwrt directory not found."
    echo "Please fetch sources first:"
    echo "  ./scripts/fetch-sources.sh --required-only"
    exit 1
fi

# Check if custom-feed directory exists
if [ ! -d "custom-feed" ]; then
    echo "Error: custom-feed directory not found."
    exit 1
fi

# Check if required feed repositories exist
for feed in packages luci routing; do
    if [ ! -d "$feed" ]; then
        echo "Error: Required feed '$feed' not found."
        echo "Please fetch sources first:"
        echo "  ./scripts/fetch-sources.sh --required-only"
        exit 1
    fi
done

# Copy custom directory to openwrt
echo "Copying custom configuration to openwrt/custom/..."
mkdir -p openwrt/custom
cp -r custom/* openwrt/custom/

# Generate feeds.conf.local using local pinned feeds
echo "Generating feeds.conf.local with local pinned feeds..."
cat > openwrt/feeds.conf.local << 'EOF'
# Router OS Custom Feed Configuration
# This file configures local feeds for Router OS development
# Using locally cloned feeds at pinned revisions for reproducibility

# Custom Router OS feed (local package feed, not a git repo)
src-link custom-feed ../custom-feed

# Use local feeds at pinned revisions (see manifests/sources.lock)
# These are cloned by scripts/fetch-sources.sh
src-git packages ../packages
src-git luci ../luci
src-git routing ../routing

# Remote feeds (optional, for additional packages)
# Uncomment if you need packages not in local feeds
# src-git telephony https://git.openwrt.org/feed/telephony.git
EOF

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  cd openwrt"
echo "  ./scripts/feeds update custom-feed"
echo "  ./scripts/feeds update packages"
echo "  ./scripts/feeds update luci"
echo "  ./scripts/feeds update routing"
echo "  ./scripts/feeds install router-core"
echo "  ./scripts/feeds install router-net"
echo "  ./scripts/feeds install router-tests"
echo "  make menuconfig"
echo "  make"
