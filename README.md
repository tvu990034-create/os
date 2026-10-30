# Router OS

A custom router operating system based on OpenWrt + Linux.

**Repository**: https://github.com/tvu990034-create/os

## Project Architecture

Router OS is built on OpenWrt with custom packages for system configuration, networking, and testing. The project uses a reproducible source management system with pinned upstream revisions.

## Directory Structure

```
router-os-source/
├── .github/workflows/           # CI/CD
├── manifests/                    # Source management
│   ├── sources.lock            # Pinned upstream source revisions
│   └── README.md               # Source manifest documentation
├── scripts/                      # Source management scripts
│   ├── fetch-sources.sh        # Clone/update repositories
│   └── verify-sources.sh       # Verify source revisions
├── docs/                         # Documentation
│   └── KERNEL_MANAGEMENT.md    # Linux kernel integration details
├── custom-feed/                  # Custom Router OS packages
│   ├── router-core/            # Core system package
│   ├── router-net/             # Networking extensions
│   ├── router-ui/              # UI customizations (skeleton)
│   └── router-tests/           # Test suite
├── custom/                       # Custom build configuration
│   ├── build/                  # Build configuration
│   ├── configs/                # Target-specific configs
│   ├── kernel/                 # Kernel modifications (future)
│   └── docs/                   # Build documentation
├── openwrt/                      # OpenWrt source tree (git repo)
├── packages/                     # OpenWrt packages feed (git repo, optional)
├── luci/                         # LuCI feed (git repo, optional)
├── routing/                      # Routing feed (git repo, optional)
├── linux/                        # Linux kernel reference (git repo, optional)
├── iproute2/                     # iproute2 reference (git repo, optional)
├── dpdk/                         # DPDK reference (git repo, optional)
├── xdp-tutorial/                 # XDP reference (git repo, optional)
├── buildroot/                    # Buildroot reference (git repo, optional)
├── u-boot/                       # U-Boot reference (git repo, optional)
├── coreboot/                     # Coreboot reference (git repo, optional)
├── setup.sh                      # Setup script for OpenWrt integration
├── build-local.sh                # Local build script
├── test-build-host.sh            # Build host tests
├── test-qemu-boot.sh             # QEMU boot test
├── validate-packages.sh          # Package validation
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

## Upstream Repositories

### Required for Build

These repositories are required for the OpenWrt build system:

- **openwrt** - Core OpenWrt build system (kernel 6.18.55)
- **packages** - OpenWrt package feed
- **luci** - LuCI web interface
- **routing** - OpenWrt routing packages

### Reference Only

These repositories are kept for reference but are NOT integrated into the build:

- **linux** - Linux kernel reference (OpenWrt manages its own kernel)
- **iproute2** - Networking tools reference (available as OpenWrt package)
- **dpdk** - DPDK reference (future optimization reference)
- **xdp-tutorial** - XDP/eBPF reference (future reference)
- **buildroot** - Buildroot reference (alternative build system)
- **u-boot** - U-Boot reference (not needed for x86)
- **coreboot** - Coreboot reference (not needed for current architecture)

**Important**: OpenWrt manages its own Linux kernel through the build system (see `openwrt/target/linux/generic/kernel-6.18`). The standalone `linux/` repository is kept only as a reference and is NOT used in the build. See `docs/KERNEL_MANAGEMENT.md` for details.

## Setup

### 1. Clone Router OS Repository

```bash
git clone https://github.com/tvu990034-create/os.git
cd os
```

### 2. Fetch Required Upstream Sources

Use the source management script to fetch required repositories at pinned revisions:

```bash
./scripts/fetch-sources.sh --required-only
```

To also fetch reference repositories:

```bash
./scripts/fetch-sources.sh --all
```

### 3. Verify Sources

Verify that all sources are at the correct revisions:

```bash
./scripts/verify-sources.sh --required-only
```

### 4. Run Setup Script

Integrate custom packages into OpenWrt:

```bash
./setup.sh
```

This script copies custom configuration to `openwrt/custom/` and generates `openwrt/feeds.conf.local` using local pinned feeds.

### 5. Build (Linux/WSL2 Required)

OpenWrt requires a Linux build environment. Install dependencies and build:

```bash
cd openwrt
./scripts/feeds update custom-feed
./scripts/feeds update packages
./scripts/feeds update luci
./scripts/feeds update routing
./scripts/feeds install router-core
./scripts/feeds install router-net
./scripts/feeds install router-tests
make menuconfig
make
```

Or use the local build script:

```bash
./build-local.sh
```

## Custom Components

### custom-feed/

Custom Router OS packages:

- **router-core** - Core system components (init, config, hardware detection)
- **router-net** - Networking extensions (interface monitoring)
- **router-ui** - LuCI customizations (skeleton, future)
- **router-tests** - Test suite (config, hardware, network, integration tests)

### custom/

Custom build configuration and documentation for Router OS:
- This directory is copied to `openwrt/custom/` during setup
- Contains target-specific configuration templates
- Contains kernel modification hooks (future use)

## Source Management

### Fetching Sources

```bash
# Fetch only required sources (for building)
./scripts/fetch-sources.sh --required-only

# Fetch only reference sources (for future development)
./scripts/fetch-sources.sh --reference-only

# Fetch all sources
./scripts/fetch-sources.sh --all
```

### Verifying Sources

```bash
# Verify only required sources
./scripts/verify-sources.sh --required-only

# Verify only reference sources
./scripts/verify-sources.sh --reference-only

# Verify all sources
./scripts/verify-sources.sh --all
```

### Updating Sources

To update to different source revisions:

1. Edit `manifests/sources.lock` with new commit SHAs
2. Run `./scripts/fetch-sources.sh` to update
3. Run `./scripts/verify-sources.sh` to verify
4. Commit the change to `manifests/sources.lock`

### Git Repository

The Router OS Git repository tracks:
- Custom packages (custom-feed/)
- Custom configuration (custom/)
- Build scripts (scripts/)
- CI/CD configuration (.github/)
- Documentation (README.md, docs/, manifests/)
- Source manifest (manifests/sources.lock)

The following are NOT tracked in Git (see .gitignore):
- openwrt/ (managed separately)
- packages/ (managed separately)
- luci/ (managed separately)
- routing/ (managed separately)
- All reference repositories (linux, iproute2, dpdk, etc.)

This keeps the Router OS repository lightweight while allowing reproducible source management.

## Feed Integration

The `setup.sh` script generates `openwrt/feeds.conf.local` which uses local pinned feeds:

```
src-link custom-feed ../custom-feed
src-git packages ../packages
src-git luci ../luci
src-git routing ../routing
```

This ensures reproducible builds by using locally cloned feeds at the exact revisions specified in `manifests/sources.lock`.

## Testing

### Build Host Tests

Run tests that don't require a booted system:

```bash
./test-build-host.sh
```

### QEMU Boot Test

Boot the built image in QEMU (requires Linux):

```bash
./test-qemu-boot.sh
```

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall architecture design
- [ARCHITECTURE_CORRECTIONS.md](ARCHITECTURE_CORRECTIONS.md) - Technical corrections
- [SOURCE_ORGANIZATION.md](SOURCE_ORGANIZATION.md) - Source organization details
- [docs/KERNEL_MANAGEMENT.md](docs/KERNEL_MANAGEMENT.md) - Linux kernel integration
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) - Detailed build instructions
- [OPENWRT_REVISION.md](OPENWRT_REVISION.md) - OpenWrt revision pinning
- [manifests/README.md](manifests/README.md) - Source manifest documentation

## Status

**Phase 1**: ✅ Complete - Architecture & Build Setup
**Phase 2**: ✅ Complete - System Foundation
**Phase 3**: ✅ Complete - Build Pipeline and Verification
**Source Management**: ✅ Complete - Reproducible source system

## Scope

This project does NOT currently include:
- DSA algorithms (future)
- AI/ML features (future)
- DPDK/XDP optimization (future)
- Custom kernel modifications (future)
- Advanced dashboard (future)

The current focus is on building a solid foundation with OpenWrt integration, reproducible builds, and automated testing.

## License

GPL-2.0 (compatible with OpenWrt)
