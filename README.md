# Router OS

A custom router operating system based on OpenWrt + Linux.

**Repository**: https://github.com/tvu990034-create/os

## Project Structure

```
router-os-source/
├── linux/              # Linux kernel reference (external git repo)
├── openwrt/            # OpenWrt build system (external git repo)
├── luci/               # LuCI web interface (external git repo)
├── packages/           # OpenWrt packages (external git repo)
├── routing/            # OpenWrt routing packages (external git repo)
├── iproute2/           # Network utilities (external git repo)
├── dpdk/               # DPDK reference (external git repo)
├── xdp-tutorial/       # XDP reference (external git repo)
├── buildroot/          # Buildroot reference (external git repo)
├── u-boot/             # U-Boot reference (external git repo)
├── coreboot/           # Coreboot reference (external git repo)
├── custom/             # Custom Router OS code (tracked in this repo)
│   ├── build/          # Build configuration
│   ├── configs/        # Configuration templates
│   ├── kernel/         # Kernel modifications
│   ├── docs/           # Documentation
│   └── feeds.conf.local # Feed configuration
├── custom-feed/        # Custom Router OS packages (tracked in this repo)
└── *.md                # Documentation (tracked in this repo)
```

## Custom Components

### custom/
Custom build configuration and documentation for Router OS.
- This directory should be copied to `openwrt/custom/` before building
- Feed configuration is generated during setup (see below)

### custom-feed/
Custom Router OS packages:
- `router-core` - Core system components
- `router-net` - Networking extensions
- `router-ui` - LuCI customizations
- `router-tests` - Test suite

## Setup

1. Clone external repositories:
```bash
git clone https://github.com/openwrt/openwrt.git openwrt
git clone https://github.com/torvalds/linux.git
git clone https://github.com/openwrt/luci.git
git clone https://github.com/openwrt/packages.git
git clone https://github.com/openwrt/routing.git
git clone https://github.com/iproute2/iproute2.git
git clone https://github.com/DPDK/dpdk.git
git clone https://github.com/xdp-project/xdp-tutorial.git
git clone https://github.com/buildroot/buildroot.git
git clone https://github.com/u-boot/u-boot.git
git clone https://github.com/coreboot/coreboot.git
```

2. Run setup script:
```bash
./setup.sh
```

This script copies custom configuration to openwrt/ and generates feeds.conf.local.

3. Set up build environment (Linux/WSL2 required):
```bash
cd openwrt
./scripts/feeds update custom-feed
./scripts/feeds install router-core
make menuconfig
make
```

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall architecture design
- [ARCHITECTURE_CORRECTIONS.md](ARCHITECTURE_CORRECTIONS.md) - Technical corrections
- [PHASE1_COMPLETION_REPORT.md](PHASE1_COMPLETION_REPORT.md) - Phase 1 report
- [PHASE1_FILE_MANIFEST.md](PHASE1_FILE_MANIFEST.md) - File inventory
- [PHASE1_SUMMARY.md](PHASE1_SUMMARY.md) - Phase 1 summary

## Status

**Phase 1**: ✅ Complete - Architecture & Build Setup
**Phase 2**: ⏳ Pending - Requires build environment setup

## License

GPL-2.0 (compatible with OpenWrt)
