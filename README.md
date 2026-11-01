# RouterOS

A portable, multi-platform router operating system built on OpenWrt and the Linux kernel. RouterOS provides a complete, configurable, secure router for compatible hardware platforms.

## Current Status

**Priority: Complete the router operating system**

The current objective is to build a complete, functional router operating system that can boot, configure, and route traffic. DSA algorithm development is deferred until the router OS is fully validated.

## What is Implemented

- ✅ Modular package architecture (router-core, router-net, router-tests)
- ✅ New subsystem packages (router-firewall, router-routing, router-monitor, router-device)
- ✅ Additional subsystem packages (router-qos, router-vpn, router-dns, router-dhcp, router-api, router-backup, router-upgrade)
- ✅ Upstream integration (tcfilter, wireguard-tools, openvpn-openssl, luci-app-qosify, luci-proto-wireguard, luci-proto-openvpn)
- ✅ Source management and platform architecture
- ✅ Build scripts and configuration for multiple platforms
- ✅ First-boot configuration and security defaults
- ✅ Network health monitoring
- ✅ System status and diagnostics
- ✅ Configuration backup/restore
- ✅ Service supervision
- ✅ Hardware discovery and capability reporting
- ✅ Firewall validation and diagnostics
- ✅ Routing status and diagnostics
- ✅ System and network monitoring
- ✅ QoS configuration and management
- ✅ VPN configuration helpers
- ✅ DNS and DHCP management
- ✅ Management API integration
- ✅ Comprehensive documentation
- ✅ CI for source validation and SDK compilation

## What is NOT Complete

- ⚠️ Full firmware builds require validation
- ⚠️ QEMU boot testing needs runtime validation
- ⚠️ Networking functionality needs QEMU network tests
- ⚠️ Physical hardware testing (Dell OptiPlex 3050) not yet performed
- ⚠️ LuCI uses upstream applications (no custom UI needed)
- ⚠️ DSA algorithm framework is future work (deferred)

## Supported Platforms

- **Generic x86_64 PCs**: Desktop, mini PC, workstation, server (development status)
- **x86_64 Virtual Machines**: QEMU, VMware, VirtualBox (development status)
- **Generic ARM64**: Arm SystemReady/EFI platforms (experimental status)
- **Board-specific routers**: Using OpenWrt device profiles (requires testing)

See `docs/platforms/PLATFORM_DEVELOPMENT.md` for platform details.

## Quick Start (Ubuntu / WSL2)

    git clone https://github.com/tvu990034-create/os.git
    cd os
    ./scripts/install-build-deps-ubuntu.sh
    ./validate-packages.sh
    ./setup.sh
    JOBS=2 ./scripts/build-platform.sh x86_64

Use JOBS=1 on memory-constrained systems.

## Documentation

- **Architecture**: `docs/architecture/REPOSITORY_ARCHITECTURE.md`, `docs/architecture/SYSTEM_OVERVIEW.md`, `docs/architecture/upstream-integration.md`
- **Development**: `docs/development/DEVELOPMENT_GUIDE.md`, `docs/development/ADDING_A_PACKAGE.md`
- **Platforms**: `docs/platforms/PLATFORM_DEVELOPMENT.md`
- **User Guide**: `docs/user-guide/INSTALLATION.md`, `docs/user-guide/CONFIGURATION.md`
- **Operations**: `docs/operations/UPGRADES_AND_RECOVERY.md`
- **Hardware**: `docs/DELL_OPTIPLEX_3050.md`

## Repository Structure

```
custom-feed/
├── router-core/         # Core system services
├── router-net/          # Network monitoring
├── router-tests/        # On-device tests
├── router-firewall/     # Firewall management
├── router-routing/      # Routing utilities
├── router-monitor/      # System monitoring
├── router-device/       # Hardware discovery
├── router-qos/          # QoS management (with upstream tcfilter/qosify)
├── router-vpn/          # VPN helpers (with upstream WireGuard/OpenVPN)
├── router-dns/          # DNS management
├── router-dhcp/         # DHCP management
├── router-api/          # Management API
├── router-backup/       # Configuration backup
├── router-upgrade/      # Firmware upgrade
├── router-dsa-sdk/      # DSA SDK (future work)
└── router-dsa-runtime/  # DSA runtime (future work)

config/
├── platforms.tsv        # Platform registry
├── x86_64.config        # x86_64 firmware config
├── armsr_armv8.config   # ARMv8 firmware config
└── sdk-*.config         # SDK build configs

docs/
├── architecture/        # System architecture
├── development/         # Development guides
├── platforms/           # Platform documentation
├── user-guide/          # User documentation
├── operations/          # Operations documentation
└── reports/             # Historical reports
```

## Validation

Run source validation:

    ./validate-packages.sh

Run platform validation:

    python3 scripts/validate-platforms.py

## CI/CD

- `validate.yml`: Source validation on push/PR
- `openwrt-sdk-build.yml`: SDK package compilation
- `build-and-boot.yml`: Full firmware build and QEMU boot test (path-filtered)

## Development

See `docs/development/DEVELOPMENT_GUIDE.md` for complete development workflow.

## DSA Development

DSA (Data Structure Acceleration) development is deferred until the router OS foundation is complete. DSA packages are isolated in the repository but are not required for router OS builds.

## Contribution

RouterOS is under active development. The router OS foundation is being completed before resuming DSA algorithm work.

