# Router OS

A custom router operating system based on OpenWrt + Linux.

**Repository**: https://github.com/tvu990034-create/os

## Project Architecture

Router OS is built on OpenWrt with custom packages for system configuration, networking, and testing. The project uses a reproducible source management system with pinned upstream revisions.

## Directory Structure

```
router-os-source/
├── .github/
│   └── workflows/
│       └── build-and-test.yml          # GitHub Actions CI/CD pipeline
├── manifests/
│   ├── sources.lock                    # Pinned upstream source revisions
│   └── README.md                       # Source manifest documentation
├── scripts/
│   ├── fetch-sources.sh                # Clone/update upstream sources
│   └── verify-sources.sh               # Verify source revisions
├── custom-feed/                        # Custom Router OS packages
│   ├── router-core/                    # Core system package
│   ├── router-net/                     # Networking extensions
│   ├── router-ui/                      # UI customizations (skeleton)
│   └── router-tests/                   # Test suite
├── custom/                             # Custom build configuration
│   ├── build/                          # Build configuration
│   ├── configs/                        # Target-specific configs
│   ├── kernel/                         # Kernel modifications (future)
│   └── docs/                           # Build documentation
├── openwrt/                            # OpenWrt source tree (git repo)
├── packages/                          # OpenWrt packages feed (git repo, optional)
├── luci/                               # LuCI feed (git repo, optional)
├── routing/                            # Routing feed (git repo, optional)
├── linux/                              # Linux kernel reference (git repo, optional)
├── iproute2/                           # iproute2 reference (git repo, optional)
├── dpdk/                               # DPDK reference (git repo, optional)
├── xdp-tutorial/                       # XDP reference (git repo, optional)
├── buildroot/                          # Buildroot reference (git repo, optional)
├── u-boot/                             # U-Boot reference (git repo, optional)
├── coreboot/                           # Coreboot reference (git repo, optional)
├── setup.sh                            # Setup script for OpenWrt integration
├── build-local.sh                      # Local build script
├── test-build-host.sh                  # Build host tests
├── test-qemu-boot.sh                   # QEMU boot test
├── validate-packages.sh                # Package validation
├── .gitignore                          # Git ignore rules
└── README.md                           # This file
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
- **buildroot** - Alternative build system reference
- **u-boot** - Bootloader reference (not needed for x86)
- **coreboot** - Firmware reference (not needed for current architecture)

**Important**: OpenWrt manages its own Linux kernel through the build system (see `openwrt/target/linux/generic/kernel-6.18`). The standalone `linux/` repository is kept only as a reference and is NOT used in the build.

## Setup

### 1. Clone Router OS Repository

```bash
git clone https://github.com/tvu990034-create/os.git
cd os
```

### 2. Fetch Upstream Sources

Use the source management script to fetch all upstream repositories at pinned revisions:

```bash
./scripts/fetch-sources.sh
```

This will clone/update all repositories to the revisions specified in `manifests/sources.lock`.

### 3. Verify Sources

Verify that all sources are at the correct revisions:

```bash
./scripts/verify-sources.sh
```

### 4. Run Setup Script

Integrate custom packages into OpenWrt:

```bash
./setup.sh
```

This script copies custom configuration to `openwrt/custom/` and generates `openwrt/feeds.conf.local`.

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
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) - Detailed build instructions
- [OPENWRT_REVISION.md](OPENWRT_REVISION.md) - OpenWrt revision pinning

## Status

**Phase 1**: ✅ Complete - Architecture & Build Setup
**Phase 2**: ✅ Complete - System Foundation
**Phase 3**: ✅ Complete - Build Pipeline and Verification

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
