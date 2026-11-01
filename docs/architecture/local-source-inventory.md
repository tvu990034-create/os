# Local Source Repository Inventory

This document provides a verified inventory of all local source repositories available at `F:\router-os-source\`.

## Repository Overview

| Repository | Availability | Current Commit | Branch | Remote | Clone Type |
|-----------|-------------|----------------|--------|--------|------------|
| openwrt | ✅ Available | ca454c0 | main | https://github.com/openwrt/openwrt.git | Full |
| luci | ✅ Available | 0e27835 | master | https://github.com/openwrt/luci.git | Full |
| packages | ✅ Available | 6307bdf | master | https://github.com/openwrt/packages.git | Full |
| routing | ✅ Available | 4b9891b | master | https://github.com/openwrt/routing.git | Full |
| buildroot | ✅ Available | 727b904c | master | https://github.com/buildroot/buildroot.git | Full |
| iproute2 | ✅ Available | d1341d0 | main | https://github.com/iproute2/iproute2.git | Full |
| dpdk | ✅ Available | e3e29ed | main | https://github.com/DPDK/dpdk.git | Full |
| xdp-tutorial | ✅ Available | 4e2bf56 | main | https://github.com/xdp-project/xdp-tutorial.git | Full |
| u-boot | ✅ Available | 03e45557 | main | https://github.com/u-boot/u-boot.git | Full |
| coreboot | ✅ Available | 0c9190b7 | main | https://github.com/coreboot/coreboot.git | Full |
| linux | ❌ Not Found | N/A | N/A | N/A | N/A |

## Detailed Repository Information

### 1. OpenWrt

**Location:** `F:\router-os-source\openwrt\`

**Remote:** https://github.com/openwrt/openwrt.git

**Current Branch:** main

**Current Commit:** ca454c00b69fc684e1c5ea52f62733c4e644e799

**Commit Message:** netfilter: fix file clash during install of kmod-iptables

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `package/` - OpenWrt package system
- `target/` - Target device configurations
- `toolchain/` - Toolchain build infrastructure
- `scripts/` - Build scripts
- `config/` - Configuration system
- `include/` - Build includes
- `rules.mk` - Makefile rules
- `feeds.conf.default` - Default feed configuration
- `feeds.conf.local` - **RouterOS custom feed configuration**

**Current RouterOS Integration:**
- ✅ **ACTIVELY USED** - Pinned to v25.12.6 via setup.sh
- feeds.conf.local references local packages, luci, and routing feeds
- Used as the base build system for RouterOS firmware

**Relevant Components:**
- Build system for RouterOS firmware
- Target configurations for x86_64 and ARMv8
- Package management infrastructure
- Kernel and toolchain selection

**Build System:** OpenWrt Makefile-based build system

---

### 2. LuCI

**Location:** `F:\router-os-source\luci\`

**Remote:** https://github.com/openwrt/luci.git

**Current Branch:** master

**Current Commit:** 0e27835

**Commit Message:** luci-base: add FileUploadList widget and form option

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `applications/` - LuCI web applications
- `modules/` - LuCI core modules
- `libs/` - LuCI libraries
- `protocols/` - Network protocol handlers
- `themes/` - UI themes
- `build/` - Build infrastructure
- `luci.mk` - LuCI build rules

**Current RouterOS Integration:**
- ✅ **ACTIVELY USED** - Referenced in openwrt/feeds.conf.local
- Provides web interface applications (luci-app-firewall, luci-proto-wireguard, etc.)
- Used for RouterOS management interface

**Relevant Components:**
- `applications/luci-app-firewall` - Firewall configuration UI
- `applications/luci-app-qosify` - QoS configuration UI
- `protocols/luci-proto-wireguard` - WireGuard protocol handler
- `protocols/luci-proto-openvpn` - OpenVPN protocol handler
- `modules/luci-base` - Core LuCI functionality

**Build System:** LuCI-specific build system (luci.mk)

---

### 3. OpenWrt Packages

**Location:** `F:\router-os-source\packages\`

**Remote:** https://github.com/openwrt/packages.git

**Current Branch:** master

**Current Commit:** 6307bdf

**Commit Message:** wg-installer: indent the package metadata with two spaces

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `admin/` - Administration tools
- `devel/` - Development tools
- `ipv6/` - IPv6 tools
- `kernel/` - Kernel modules
- `libs/` - Libraries
- `mail/` - Mail servers
- `multimedia/` - Multimedia tools
- `net/` - Network tools and services
- `sound/` - Audio tools
- `utils/` - Utilities

**Current RouterOS Integration:**
- ✅ **ACTIVELY USED** - Referenced in openwrt/feeds.conf.local
- Source of upstream packages used in RouterOS (tcfilter, openvpn-openssl, wireguard-tools)

**Relevant Components:**
- `net/tcfilter` - Persistent tc ingress filters (used by router-qos)
- `net/openvpn` - OpenVPN client/server (used by router-vpn)
- `net/wireguard-tools` - WireGuard userspace tools (used by router-vpn)
- Various network monitoring and diagnostic tools

**Build System:** OpenWrt package Makefile system

---

### 4. OpenWrt Routing

**Location:** `F:\router-os-source\routing\`

**Remote:** https://github.com/openwrt/routing.git

**Current Branch:** master

**Current Commit:** 4b9891b

**Commit Message:** opennds: remove package, moved to openwrt/packages

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `ahcpd/` - Ad-Hoc Configuration Protocol Daemon
- `babel-pinger/` - Babel routing protocol
- `batmand/` - BATMAN routing protocol
- `cjdns/` - Encrypted network protocol
- `luci-app-cjdns/` - LuCI interface for cjdns
- `naywatch/` - Neighbor discovery
- `ndppd/` - IPv6 neighbor proxy
- `ohybridproxy/` - DHCPv6 proxy
- `pimbd/` - PIM multicast routing
- `prince/` - RIP routing
- `vis/` - Visualization

**Current RouterOS Integration:**
- ✅ **ACTIVELY USED** - Referenced in openwrt/feeds.conf.local
- Available for routing protocol integration (not yet used by RouterOS)

**Relevant Components:**
- Various routing protocol implementations
- Could be used for advanced routing features (BGP, OSPF, etc.)

**Build System:** OpenWrt package Makefile system

**Current Usage:** Available but not actively integrated into RouterOS

---

### 5. Buildroot

**Location:** `F:\router-os-source\buildroot\`

**Remote:** https://github.com/buildroot/buildroot.git

**Current Branch:** master

**Current Commit:** 727b904c

**Commit Message:** package/grpc: security bump version to 1.84.1

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `arch/` - Architecture-specific code
- `board/` - Board-specific configurations
- `boot/` - Bootloader configurations
- `configs/` - Sample configurations
- `docs/` - Documentation
- `fs/` - Filesystem configurations
- `linux/` - Linux kernel configurations
- `package/` - Package system
- `support/` - Build infrastructure
- `system/` - System configurations
- `toolchain/` - Toolchain infrastructure
- `utils/` - Utilities

**Current RouterOS Integration:**
- ❌ **NOT USED** - RouterOS uses OpenWrt build system instead
- Available for research on alternative build infrastructure

**Relevant Components:**
- Alternative build system research
- Package management patterns

**Build System:** Buildroot Makefile-based system

**Current Usage:** Not integrated (OpenWrt build system used instead)

---

### 6. iproute2

**Location:** `F:\router-os-source\iproute2\`

**Remote:** https://github.com/iproute2/iproute2.git

**Current Branch:** main

**Current Commit:** d1341d0

**Commit Message:** uapi: update headers to 7.4 pre rc1

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `ip/` - IP configuration commands
- `tc/` - Traffic control commands
- `bridge/` - Bridge management
- `devlink/` - Device link management
- `netem/` - Network emulation
- `include/` - Header files
- `lib/` - Libraries
- `man/` - Manual pages
- `examples/` - Example usage

**Current RouterOS Integration:**
- ⏳ **INDIRECTLY USED** - tc-full package in OpenWrt includes iproute2
- Used by router-qos for traffic control
- Used by routing packages for advanced network configuration

**Relevant Components:**
- `tc/` - Traffic control (used by router-qos)
- `ip/` - IP routing and configuration
- `bridge/` - Bridge management
- Network emulation and traffic shaping

**Build System:** Autotools-based (configure script)

**Current Usage:** Indirectly via OpenWrt tc-full package

---

### 7. DPDK

**Location:** `F:\router-os-source\dpdk\`

**Remote:** https://github.com/DPDK/dpdk.git

**Current Branch:** main

**Current Commit:** e3e29ed

**Commit Message:** event/dlb2: fix race condition during dynamic linking

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `app/` - DPDK applications
- `buildtools/` - Build tools
- `config/` - Configuration
- `devtools/` - Development tools
- `doc/` - Documentation
- `drivers/` - Hardware drivers
- `dts/` - Device tree source
- `examples/` - Example applications
- `kernel/` - Kernel modules
- `lib/` - Libraries
- `usertools/` - User-space tools

**Current RouterOS Integration:**
- ❌ **NOT USED** - Available for future performance optimization work
- Could be used for high-performance packet processing

**Relevant Components:**
- High-performance packet processing framework
- Hardware drivers for NICs
- Poll-mode drivers for zero-copy networking

**Build System:** Meson-based build system

**Current Usage:** Not integrated (future performance work)

---

### 8. XDP Tutorial

**Location:** `F:\router-os-source\xdp-tutorial\`

**Remote:** https://github.com/xdp-project/xdp-tutorial.git

**Current Branch:** main

**Current Commit:** 4e2bf56

**Commit Message:** tracing01-xdp-simple/README.org: add reference to xdp-tools for xdp-loader command

**Clone Type:** Full (not shallow) - Has git submodules

**Top-Level Structure:**
- `basic01-xdp-pass/` - Basic XDP pass example
- `basic02-prog-by-name/` - Program by name
- `basic03-map-counter/` - Map counter
- `basic04-pinning-maps/` - Pinning maps
- `advanced01-xdp-tc-interact/` - XDP-TC interaction
- `advanced03-AF_XDP/` - AF_XDP
- `packet01-parsing/` - Packet parsing
- `packet02-rewriting/` - Packet rewriting
- `packet03-redirecting/` - Packet redirecting
- `tracing01-xdp-simple/` - Tracing examples
- `common/` - Common utilities
- `testenv/` - Test environment

**Current RouterOS Integration:**
- ❌ **NOT USED** - Available for XDP/eBPF learning and research
- Could be used for future performance optimization

**Relevant Components:**
- XDP programming examples
- eBPF map usage patterns
- Performance optimization techniques

**Build System:** Custom Makefile-based

**Current Usage:** Not integrated (future performance work)

---

### 9. U-Boot

**Location:** `F:\router-os-source\u-boot\`

**Remote:** https://github.com/u-boot/u-boot.git

**Current Branch:** main

**Current Commit:** 03e45557

**Commit Message:** Merge patch series "boot: image-fdt: fix reservation errors above ram_top"

**Clone Type:** Full (not shallow)

**Top-Level Structure:**
- `arch/` - Architecture-specific code
- `board/` - Board-specific code
- `boot/` - Boot functionality
- `cmd/` - Command implementations
- `common/` - Common code
- `configs/` - Board configurations
- `disk/` - Disk support
- `doc/` - Documentation
- `drivers/` - Hardware drivers
- `dts/` - Device tree source
- `env/` - Environment handling
- `fs/` - Filesystem support
- `include/` - Header files
- `lib/` - Libraries
- `net/` - Network support
- `scripts/` - Build scripts
- `test/` - Tests
- `tools/` - Tools

**Current RouterOS Integration:**
- ⏳ **INDIRECTLY USED** - Available via OpenWrt target system
- Used by OpenWrt for devices requiring U-Boot bootloader

**Relevant Components:**
- Bootloader implementation
- Device boot support
- Hardware initialization

**Build System:** U-Boot Makefile-based system

**Current Usage:** Indirectly via OpenWrt target bootloaders

---

### 10. coreboot

**Location:** `F:\router-os-source\coreboot\`

**Remote:** https://github.com/coreboot/coreboot.git

**Current Branch:** main

**Current Commit:** 0c9190b7

**Commit Message:** soc/mediatek/mt8189: Reserve the whole TZRAM for BL31

**Clone Type:** Full (not shallow) - Has git submodules

**Top-Level Structure:**
- `3rdparty/` - Third-party code
- `Documentation/` - Documentation
- `configs/` - Board configurations
- `payloads/` - Payload configurations
- `src/` - Source code
- `tests/` - Tests
- `util/` - Utilities

**Current RouterOS Integration:**
- ❌ **NOT USED** - Available for firmware/boot research
- Could be used for custom firmware on supported hardware

**Relevant Components:**
- Firmware implementation
- Hardware initialization
- Payload management

**Build System:** coreboot Makefile-based system

**Current Usage:** Not integrated (firmware-specific work)

---

### 11. Linux Kernel

**Location:** NOT FOUND in F:\router-os-source\

**Status:** ❌ **MISSING**

**Expected Location:** `F:\router-os-source\linux\`

**Current RouterOS Integration:**
- ⏳ **INDIRECTLY USED** - OpenWrt includes Linux kernel
- Kernel selection managed by OpenWrt target system
- Could be cloned for custom kernel development

**Relevance:**
- Kernel customization
- Driver development
- Performance optimization

---

## Current Integration Summary

### Actively Used (4 repositories)
1. **openwrt** - Main build system and firmware base
2. **luci** - Web interface applications
3. **packages** - Upstream packages (tcfilter, openvpn, wireguard-tools)
4. **routing** - Available for routing protocols (not yet integrated)

### Indirectly Used (3 repositories)
1. **iproute2** - Via OpenWrt tc-full package
2. **u-boot** - Via OpenWrt target bootloaders
3. **linux** - Via OpenWrt kernel selection (repository not cloned locally)

### Available for Future Work (3 repositories)
1. **dpdk** - High-performance packet processing
2. **xdp-tutorial** - XDP/eBPF learning
3. **coreboot** - Firmware customization

### Not Used (1 repository)
1. **buildroot** - Alternative build system (RouterOS uses OpenWrt)

### Missing (1 repository)
1. **linux** - Linux kernel source (not cloned)

## RouterOS Feed Configuration

The RouterOS project configures local feeds in `openwrt/feeds.conf.local`:

```
src-link custom-feed ../custom-feed
src-git packages ../packages
src-git luci ../luci
src-git routing ../routing
```

This configuration:
- Uses local RouterOS custom feed
- Uses local packages feed (verified available)
- Uses local luci feed (verified available)
- Uses local routing feed (verified available)

## Notes

1. **No shallow clones detected** - All repositories are full clones
2. **All Git repositories are on latest main/master branches**
3. **Linux kernel is not cloned locally** - OpenWrt manages kernel selection internally
4. **Local feeds are configured** - The openwrt/feeds.conf.local references local repositories
5. **Version pinning** - OpenWrt is pinned to v25.12.6 via setup.sh, but feeds are on latest commits
6. **Build system integration** - The local feeds are currently configured but may not be used in CI builds (CI likely uses remote feeds)

## Integration Gaps

1. **Local feed usage in CI**: The current CI workflow uses remote OpenWrt feeds, not the local repositories
2. **Version synchronization**: Local feeds are on latest commits, not pinned to specific versions
3. **Linux kernel**: Not cloned locally, managed entirely by OpenWrt
4. **Performance repositories**: DPDK and XDP are available but not integrated

## Recommendations

1. **Investigate CI feed configuration** - Determine why CI uses remote feeds instead of local ones
2. **Consider version pinning** - Pin local feed commits for reproducibility
3. **Linux kernel** - Clone Linux kernel repository if custom kernel development is needed
4. **Feed verification** - Verify that local feeds are actually used by the build process
