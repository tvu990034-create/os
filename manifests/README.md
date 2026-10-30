# Source Manifest

This directory contains source management files for the Router OS project.

## sources.lock

The `sources.lock` file records all upstream source repositories and their pinned revisions. This allows reproducible builds across different environments.

## Repository Classification

### Required Sources

These repositories are required for the OpenWrt build system:

- **openwrt** - Core OpenWrt build system (kernel 6.18.55)
- **packages** - OpenWrt package feed
- **luci** - LuCI web interface
- **routing** - OpenWrt routing packages

### Reference Sources

These repositories are kept for reference but are not integrated into the build:

- **linux** - Linux kernel reference (OpenWrt manages its own kernel)
- **iproute2** - Networking tools reference (available as OpenWrt package)
- **dpdk** - DPDK reference (future optimization reference)
- **xdp-tutorial** - XDP/eBPF reference (future reference)
- **buildroot** - Buildroot reference (alternative build system)
- **u-boot** - U-Boot reference (not needed for x86)
- **coreboot** - Coreboot reference (not needed for current architecture)

## Source Management Scripts

### verify-sources.sh

Verify that all source repositories are at the correct revisions:

```bash
# Verify only required sources
./scripts/verify-sources.sh --required-only

# Verify only reference sources
./scripts/verify-sources.sh --reference-only

# Verify all sources
./scripts/verify-sources.sh --all
```

### fetch-sources.sh

Clone missing repositories and update to pinned revisions:

```bash
# Fetch only required sources
./scripts/fetch-sources.sh --required-only

# Fetch only reference sources
./scripts/fetch-sources.sh --reference-only

# Fetch all sources
./scripts/fetch-sources.sh --all
```

## Integration Method

### OpenWrt Kernel

OpenWrt manages its own Linux kernel through the build system (see `openwrt/target/linux/generic/kernel-6.18`). The standalone `linux/` repository is kept only as a reference and is NOT used in the build.

See `docs/KERNEL_MANAGEMENT.md` for details.

### Package Feeds

Package feeds (packages, luci, routing) are integrated via OpenWrt's feeds system. The `setup.sh` script configures these feeds to use local cloned repositories at pinned revisions for reproducibility.

### Custom Feed

The custom-feed is integrated via src-link in feeds.conf.local. This points to the local custom-feed/ directory which contains Router OS-specific packages.

## Reproducibility

The source manifest ensures reproducible builds by:

- Pinning exact commit SHAs for all repositories
- Documenting the purpose of each repository
- Documenting the integration method
- Providing scripts to fetch and verify sources
- Separating required and reference sources

Any developer can reproduce the exact same source tree by running:

```bash
./scripts/fetch-sources.sh --required-only
```

For full source including references:

```bash
./scripts/fetch-sources.sh --all
```

## Feed Configuration

The `setup.sh` script generates `openwrt/feeds.conf.local` which uses local pinned feeds:

```
src-link custom-feed ../custom-feed
src-git packages ../packages
src-git luci ../luci
src-git routing ../routing
```

This ensures reproducible builds by using locally cloned feeds at the exact revisions specified in sources.lock.
