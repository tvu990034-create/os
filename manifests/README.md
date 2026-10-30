# Source Manifest

This directory contains source management files for the Router OS project.

## sources.lock

The `sources.lock` file records all upstream source repositories and their pinned revisions. This allows reproducible builds across different environments.

## Repository Categories

### Required for Build

These repositories are required for the OpenWrt build system:

- **openwrt**: Core OpenWrt build system (kernel 6.18.55)
- **packages**: OpenWrt package feed
- **luci**: LuCI web interface
- **routing**: OpenWrt routing packages

### Reference Only

These repositories are kept for reference but are not integrated into the build:

- **linux**: Linux kernel reference (OpenWrt manages its own kernel)
- **iproute2**: Networking tools reference (available as OpenWrt package)
- **dpdk**: DPDK reference (future optimization reference)
- **xdp-tutorial**: XDP/eBPF reference (future reference)
- **buildroot**: Alternative build system reference
- **u-boot**: Bootloader reference (not needed for x86)
- **coreboot**: Firmware reference (not needed for current architecture)

## Source Management Scripts

### verify-sources.sh

Verify that all source repositories are at the correct revisions:

```bash
./scripts/verify-sources.sh
```

### fetch-sources.sh

Clone missing repositories and update to pinned revisions:

```bash
./scripts/fetch-sources.sh
```

## Integration Method

OpenWrt manages its own Linux kernel through the build system (see `openwrt/target/linux/generic/kernel-6.18`). The standalone `linux/` repository is kept only as a reference and is NOT used in the build.

Package feeds (packages, luci, routing) are integrated via OpenWrt's feeds system. The `setup.sh` script configures these feeds for local development.
