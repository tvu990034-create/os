# Source Organization

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
└── README.md                           # Main project documentation
```

## Repository Management

### Required Repositories

These are required for the OpenWrt build system:

1. **openwrt/** - Core OpenWrt build system
   - Managed by: Router OS (pinned)
   - Revision: ca454c00b69fc684e1c5ea52f62733c4e644e799
   - Kernel: 6.18.55 (managed by OpenWrt)

2. **packages/** - OpenWrt package feed
   - Managed by: OpenWrt feeds system
   - Revision: 6307bdf3b7997a4de5317e127383b4266fe36108
   - Optional for local development, fetched remotely in CI

3. **luci/** - LuCI web interface
   - Managed by: OpenWrt feeds system
   - Revision: 0e2783557642331eb0afdc92d02c1d624f44fef7
   - Optional for local development, fetched remotely in CI

4. **routing/** - OpenWrt routing packages
   - Managed by: OpenWrt feeds system
   - Revision: 4b9891b9136259f93294a424507ed24c5e8c1cbd
   - Optional for local development, fetched remotely in CI

### Reference Repositories

These are kept for reference but are NOT integrated into the build:

1. **linux/** - Linux kernel reference
   - Purpose: Reference for kernel development
   - Note: OpenWrt manages its own kernel (6.18.55)

2. **iproute2/** - Networking tools reference
   - Purpose: Reference for networking tools
   - Note: Available as OpenWrt package

3. **dpdk/** - DPDK reference
   - Purpose: Future optimization reference
   - Note: Not used in current architecture

4. **xdp-tutorial/** - XDP/eBPF reference
   - Purpose: Future XDP reference
   - Note: Not used in current architecture

5. **buildroot/** - Buildroot reference
   - Purpose: Alternative build system reference
   - Note: OpenWrt uses its own build system

6. **u-boot/** - U-Boot reference
   - Purpose: Bootloader reference
   - Note: Not needed for x86 target

7. **coreboot/** - Coreboot reference
   - Purpose: Firmware reference
   - Note: Not needed for current architecture

## Source Management Workflow

### Initial Setup

```bash
# Clone Router OS repository
git clone https://github.com/tvu990034-create/os.git
cd os

# Fetch all upstream sources
./scripts/fetch-sources.sh

# Verify sources are at correct revisions
./scripts/verify-sources.sh
```

### Updating Sources

```bash
# Update to revisions in sources.lock
./scripts/fetch-sources.sh

# Verify after update
./scripts/verify-sources.sh
```

### Custom Source Management

If you need to pin a different revision:

1. Update the revision in `manifests/sources.lock`
2. Run `./scripts/fetch-sources.sh` to update
3. Commit the change to `manifests/sources.lock`

## Git Repository Structure

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

This keeps the Router OS repository lightweight while allowing reproducible source management through the manifest.

## Build Integration

The `setup.sh` script integrates the custom packages into the OpenWrt build system:

1. Copies custom configuration to openwrt/custom/
2. Generates openwrt/feeds.conf.local
3. Configures custom-feed and OpenWrt feeds

The build system then uses OpenWrt's standard feed mechanism to discover and build packages.

## Reproducibility

The `manifests/sources.lock` file ensures reproducible builds by:

- Pinning exact commit SHAs for all repositories
- Documenting the purpose of each repository
- Documenting the integration method
- Providing scripts to fetch and verify sources

Any developer can reproduce the exact same source tree by running:

```bash
./scripts/fetch-sources.sh
```
