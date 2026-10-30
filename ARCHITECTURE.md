# Router OS Architecture Design

## Repository Analysis

### Repository Inventory

| Repository | Purpose | Version/Commit | Role in Router OS |
|------------|---------|----------------|-------------------|
| **openwrt** | Primary OS foundation and build system | ca454c0 | Core build system, kernel config, base packages |
| **linux** | Linux kernel source (reference) | c339f4010-dirty | Kernel patches, driver reference, upstream kernel features |
| **luci** | LuCI web interface | 0e27835 | Management UI for system configuration |
| **packages** | OpenWrt community packages | 6307bdf | Additional applications and services |
| **routing** | OpenWrt routing packages | 4b9891b | Advanced routing protocols (BGP, OSPF, etc.) |
| **iproute2** | Network configuration utilities | d1341d0 | Network interface management (ip, tc, ss commands) |
| **dpdk** | Data Plane Development Kit | e3e29ed | Future high-performance packet processing reference |
| **xdp-tutorial** | XDP eBPF tutorials | 4e2bf56 | Future XDP/eBPF integration reference |
| **buildroot** | Alternative build system | 727b904c | Build system reference for alternative approaches |
| **u-boot** | Universal bootloader | 03e45557 | Boot architecture reference for non-x86 platforms |
| **coreboot** | Open-source firmware | 0c9190b7 | Firmware reference for x86 platforms |

### Repository Relationships

```
openwrt (core)
├── uses linux (kernel source for patches/features)
├── feeds to: luci, packages, routing (via feeds.conf)
├── depends on: iproute2 (network utilities)
├── references: dpdk, xdp-tutorial (future performance work)
└── architecture references: buildroot, u-boot, coreboot
```

### OpenWrt Core Structure

```
openwrt/
├── include/          # Build system includes (Makefile fragments)
├── scripts/          # Build scripts and utilities
├── config/           # Kconfig definitions for build configuration
├── target/           # Target system definitions
│   └── linux/        # Architecture-specific targets (x86, armsr, etc.)
├── package/          # Core packages
│   ├── base-files/   # Base filesystem structure
│   ├── kernel/       # Kernel modules
│   ├── network/      # Networking (netifd, firewall, dnsmasq, ppp)
│   ├── system/       # System services (procd, uci, ubus, opkg)
│   └── utils/        # Utilities
├── toolchain/        # Cross-compilation toolchain
└── tools/            # Host tools for building
```

### Key OpenWrt Components to Reuse

**System Services:**
- `procd` - Process manager and init system
- `uci` - Unified Configuration Interface
- `ubus` - System message bus
- `opkg` - Package manager
- `rpcd` - RPC daemon for LuCI

**Networking Stack:**
- `netifd` - Network interface daemon (manages interfaces, bridges, etc.)
- `firewall` / `firewall4` - Firewall management (iptables/nftables)
- `dnsmasq` - DNS and DHCP server
- `odhcpd` - IPv6 DHCP and RA
- `ppp` - PPPoE support
- `iproute2` - Network configuration utilities

**LuCI Structure:**
- `applications/` - App-specific modules
- `collections/` - Pre-configured collections
- `libs/` - Core LuCI libraries
- `modules/` - UI components
- `themes/` - UI themes

---

## Proposed OS Architecture

### Design Principles

1. **Modularity**: Separate custom code from upstream OpenWrt code
2. **Portability**: Support multiple architectures (x86, ARM) without hardware assumptions
3. **Compatibility**: Maintain OpenWrt feed compatibility for package updates
4. **Extensibility**: Provide clean interfaces for future algorithmic optimizations
5. **Reliability**: Leverage upstream-maintained components where possible

### Directory Structure

```
F:\router-os-source\
├── custom/               # Custom Router OS code (tracked in git)
│   ├── build/            # Custom build configuration
│   │   ├── config/       # Kconfig fragments for custom options
│   │   └── patches/      # Custom patches to OpenWrt
│   ├── configs/          # Pre-built configuration templates
│   │   ├── generic/      # Generic hardware configs
│   │   ├── x86/          # x86-specific configs
│   │   └── armsr/        # ARM-specific configs
│   ├── kernel/           # Custom kernel modules/patches
│   │   ├── patches/      # Kernel patches
│   │   └── modules/      # Custom kernel modules
│   ├── docs/             # Architecture documentation
│   └── feeds.conf.local  # Feed configuration template
├── custom-feed/          # Custom package feed (tracked in git)
│   ├── router-core/      # Core router functionality
│   ├── router-net/       # Networking extensions
│   ├── router-ui/        # LuCI customizations
│   └── router-tests/     # Automated tests
├── openwrt/              # OpenWrt build system (external git repo)
│   ├── custom/           # [COPY] Custom code copied here during build
│   ├── feeds.conf.local  # [COPY] Feed config copied here during build
│   └── package/feeds/    # Feed packages (symlinks created by feeds script)
├── linux/                # Linux kernel reference (external git repo)
├── luci/                 # LuCI feed reference (external git repo)
├── packages/             # OpenWrt packages feed reference (external git repo)
├── routing/              # Routing feed reference (external git repo)
├── iproute2/             # Network utilities reference (external git repo)
├── dpdk/                 # DPDK reference (external git repo)
├── xdp-tutorial/         # XDP reference (external git repo)
├── buildroot/            # Buildroot reference (external git repo)
├── u-boot/               # U-Boot reference (external git repo)
├── coreboot/             # Coreboot reference (external git repo)
└── ARCHITECTURE.md       # This document
```

**Build Workflow:**
1. `custom/` and `custom-feed/` are tracked in this repository
2. Before building, copy `custom/*` to `openwrt/custom/`
3. Copy `custom/feeds.conf.local` to `openwrt/feeds.conf.local`
4. Build work happens inside `openwrt/` directory
5. Custom packages are in separate `custom-feed/` directory (feed structure)
6. Feeds are referenced via `src-link` in `feeds.conf.local`
7. No submodules - use existing repository structure

### Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Router OS                                │
├─────────────────────────────────────────────────────────────┤
│                     User Space                               │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   LuCI UI    │  │ Custom Net   │  │ Monitoring   │      │
│  │  (Management)│  │  Extensions  │  │  & Diagnostics│     │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                 │                 │              │
│  ┌──────▼─────────────────▼─────────────────▼──────┐      │
│  │              UBus (System Bus)                    │      │
│  └──────┬───────────────────────────────────────────┘      │
│         │                                                  │
│  ┌──────▼──────────────────────────────────────────┐     │
│  │              UCI (Configuration)                  │     │
│  └──────┬───────────────────────────────────────────┘     │
│         │                                                  │
│  ┌──────▼──────────────────────────────────────────┐     │
│  │         Netifd (Network Interface Daemon)       │     │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐          │     │
│  │  │  WAN    │  │  LAN    │  │  VLAN   │          │     │
│  │  └─────────┘  └─────────┘  └─────────┘          │     │
│  └──────┬───────────────────────────────────────────┘     │
│         │                                                  │
│  ┌──────▼──────────────────────────────────────────┐     │
│  │    Networking Services (Reuse OpenWrt)          │     │
│  │  ┌────────┐  ┌────────┐  ┌────────┐            │     │
│  │  │firewall│  │dnsmasq │  │ odhcpd │            │     │
│  │  └────────┘  └────────┘  └────────┘            │     │
│  │  ┌────────┐  ┌────────┐  ┌────────┐            │     │
│  │  │  ppp   │  │ routing│  │  VPN   │            │     │
│  │  └────────┘  └────────┘  └────────┘            │     │
│  └──────┬───────────────────────────────────────────┘     │
│         │                                                  │
│  ┌──────▼──────────────────────────────────────────┐     │
│  │              Procd (Init System)                 │     │
│  └───────────────────────────────────────────────────┘     │
├─────────────────────────────────────────────────────────────┤
│                     Kernel Space                             │
├─────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐   │
│  │              Linux Kernel (OpenWrt patches)         │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐         │   │
│  │  │Drivers   │  │  IPv4/6  │  │   Net    │         │   │
│  │  │(Ethernet,│  │  Stack   │  │  Filter  │         │   │
│  │  │ WiFi, etc)│  │          │  │          │         │   │
│  │  └──────────┘  └──────────┘  └──────────┘         │   │
│  │  ┌──────────┐  ┌──────────┐                       │   │
│  │  │  Custom  │  │  Future  │                       │   │
│  │  │ Modules  │  │  XDP/BPF │                       │   │
│  │  └──────────┘  └──────────┘                       │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Analysis

### Existing Components to Reuse

#### 1. Core Infrastructure (OpenWrt)
- **Build System**: OpenWrt's `make menuconfig` + feeds system
- **Init System**: `procd` (OpenWrt's process manager)
- **Configuration**: `uci` (unified configuration interface)
- **IPC**: `ubus` (system message bus)
- **Package Management**: `opkg` (package manager)

#### 2. Networking Stack (OpenWrt packages)
- **Interface Management**: `netifd` (interface daemon)
- **Firewall**: `firewall4` (nftables-based) + `nftables`
- **DNS/DHCP**: `dnsmasq` (IPv4), `odhcpd` (IPv6)
- **PPPoE**: `ppp` package
- **Routing**: Static routing + routing feed for dynamic protocols
- **Bridging**: Linux bridge support via netifd
- **VLAN**: VLAN support via netifd

#### 3. Management Interface (LuCI)
- **Core Framework**: LuCI MVC framework
- **Network Config**: `luci-app-firewall`, `luci-app-network`
- **System Config**: `luci-app-system`, `luci-app-opkg`
- **Theme**: Bootstrap-based themes

#### 4. System Services (OpenWrt packages)
- **SSH**: `dropbear` (lightweight SSH server)
- **HTTP**: `uhttpd` (lightweight HTTP server for LuCI)
- **Logging**: `logd` + `ubox`
- **Time**: `chrony` or `busybox ntpd`
- **Storage**: `fstools` for filesystem management

### Components Requiring Custom Development

#### 1. Build Integration Layer
- **Purpose**: Integrate custom packages into OpenWrt build
- **Deliverables**:
  - Custom feed configuration (`feeds.conf.local`)
  - Build configuration fragments for target hardware
  - Image generation scripts for router OS branding
  - Reproducible build configuration

#### 2. Router Core Package (`custom/packages/router-core`)
- **Purpose**: Core router OS specific functionality
- **Deliverables**:
  - System initialization scripts
  - Hardware detection and configuration
  - Configuration templates for WAN/LAN setup
  - Interface auto-discovery and configuration
  - Backup/restore functionality
  - Secure update mechanism
  - System monitoring hooks

#### 3. Network Extensions (`custom/packages/router-net`)
- **Purpose**: Networking extensions and future optimization interfaces
- **Deliverables**:
  - Interface management utilities
  - Bonding/LACP configuration helpers
  - VLAN provisioning helpers
  - Bridge management extensions
  - QoS base framework (hooks for future algorithms)
  - Statistics collection framework
  - **Interface for future packet processing optimization**:
    - Abstract packet processing interface
    - Hooks for custom algorithm insertion
    - Performance measurement framework

#### 4. LuCI Customizations (`custom/packages/router-ui`)
- **Purpose**: Custom UI for router OS management
- **Deliverables**:
  - Dashboard with system overview
  - Network topology visualization
  - Hardware status display
  - Performance monitoring UI
  - Backup/restore UI
  - Update management UI
  - Custom branding

#### 5. Configuration Templates (`custom/configs`)
- **Purpose**: Pre-configured profiles for different hardware
- **Deliverables**:
  - Generic x86 configuration (multi-NIC, generic hardware)
  - Generic ARM configuration (armsr target)
  - Virtual machine configuration (KVM/QEMU)
  - Container configuration (Docker/LXC)
  - Default firewall rules

#### 6. Automated Tests (`custom/packages/router-tests`)
- **Purpose**: Validation of router OS functionality
- **Deliverables**:
  - Unit tests for custom components
  - Integration tests for networking
  - Performance benchmarking scripts
  - Configuration validation tests
  - Build system tests

#### 7. Documentation (`custom/docs`)
- **Purpose**: Comprehensive documentation
- **Deliverables**:
  - Architecture documentation
  - Build instructions
  - Configuration guide
  - Hardware compatibility matrix
  - API documentation for custom interfaces
  - Developer guide

---

## Dependencies and Integration Plan

### Build Dependencies

```
OpenWrt Build System
├── Linux Kernel (custom patches)
├── Toolchain (OpenWrt-provided)
├── Custom Feed (router-core, router-net, router-ui)
└── LuCI Feed (custom feed + upstream)
```

### Runtime Dependencies

```
Router OS Runtime
├── OpenWrt Base (procd, uci, ubus, opkg)
├── Networking Stack (netifd, firewall, dnsmasq, ppp)
├── Custom Packages (router-core, router-net)
├── LuCI (uhttpd + custom modules)
└── Linux Kernel (standard + custom modules)
```

### Integration Strategy

#### Phase 1: Build System Integration
1. Create `custom/` directory structure
2. Configure `feeds.conf.local` to point to custom feeds
3. Create build configuration fragments
4. Test reproducible build

#### Phase 2: Core Functionality
1. Implement `router-core` package
2. Create configuration templates
3. Implement hardware detection
4. Test boot and basic operation

#### Phase 3: Networking
1. Implement `router-net` package
2. Extend netifd with custom helpers
3. Implement monitoring framework
4. Test all networking scenarios

#### Phase 4: Management Interface
1. Implement `router-ui` LuCI modules
2. Integrate with custom packages
3. Implement dashboard
4. Test UI functionality

#### Phase 5: Reliability Features
1. Implement backup/restore
2. Implement secure updates
3. Implement monitoring/alerting
4. Test recovery scenarios

#### Phase 6: Performance Foundation
1. Implement performance measurement framework
2. Create benchmarking suite
3. Establish baseline metrics
4. **Prepare interfaces for future algorithm integration**

---

## Implementation Roadmap

### Phase 1: Architecture & Build Setup (Week 1-2)
**Goal**: Establish custom build infrastructure

**Tasks**:
1. [ ] Create `custom/` directory structure
2. [ ] Set up custom feed configuration
3. [ ] Create build configuration fragments for x86 and armsr
4. [ ] Create base `router-core` package skeleton
5. [ ] Configure feeds.conf.local for custom feeds
6. [ ] Test OpenWrt build with custom feed integration
7. [ ] Document build process

**Deliverables**:
- Working custom build system
- Feed integration verified
- Base package structure

**Validation**:
- Successful build of minimal image
- Custom feed recognized by OpenWrt
- Reproducible build verified

---

### Phase 2: Minimal Bootable OS (Week 3-4)
**Goal**: Establish a minimal bootable router OS

**Tasks**:
1. [ ] Implement basic system initialization in router-core
2. [ ] Create generic configuration templates
3. [ ] Implement hardware detection (PCI, USB, NIC enumeration)
4. [ ] Configure base firewall rules
5. [ ] Implement basic logging setup
6. [ ] Test boot on generic x86 hardware
7. [ ] Test boot on ARM (armsr) if available

**Deliverables**:
- Bootable minimal router OS image
- Hardware detection working
- Basic networking functional

**Validation**:
- System boots successfully
- Interfaces detected
- Default configuration loads
- Basic connectivity established

---

### Phase 3: Standard Router Functionality (Week 5-7)
**Goal**: Implement full router networking capabilities

**Tasks**:
1. [ ] Implement WAN/LAN configuration in router-core
2. [ ] Configure DHCPv4 server (dnsmasq)
3. [ ] Configure DHCPv6/RA (odhcpd)
4. [ ] Implement NAT/masquerade
5. [ ] Configure firewall (firewall4 + nftables)
6. [ ] Implement VLAN support
7. [ ] Implement bridging support
8. [ ] Implement PPPoE support
9. [ ] Test all networking scenarios
10. [ ] Validate IPv4 and IPv6 dual-stack

**Deliverables**:
- Full routing functionality
- WAN/LAN separation
- DHCP working
- Firewall operational
- VLAN and bridging functional
- PPPoE working

**Validation**:
- WAN connectivity established
- LAN clients get DHCP
- NAT working
- Firewall rules effective
- VLAN traffic isolated
- Bridge ports communicate
- PPPoE authentication works
- IPv6 functional

---

### Phase 4: Management Interface (Week 8-9)
**Goal**: Integrate and customize LuCI for router OS

**Tasks**:
1. [ ] Integrate LuCI into build
2. [ ] Create custom LuCI theme (router-ui)
3. [ ] Implement dashboard module
4. [ ] Implement network configuration UI
5. [ ] Implement system status UI
6. [ ] Implement backup/restore UI
7. [ ] Test all UI functions
8. [ ] Verify RPC connectivity

**Deliverables**:
- Functional LuCI interface
- Custom branding
- Dashboard with system overview
- Network configuration accessible
- Backup/restore operational

**Validation**:
- LuCI loads and authenticates
- Dashboard displays correct information
- Network changes apply via UI
- Backup/restore works
- All sections functional

---

### Phase 5: Security, Recovery & Updates (Week 10-11)
**Goal**: Implement reliability and security features

**Tasks**:
1. [ ] Implement configuration backup (automated + manual)
2. [ ] Implement configuration restore
3. [ ] Implement secure firmware update mechanism
4. [ ] Implement signature verification
5. [ ] Implement rollback on update failure
6. [ ] Secure default configuration
7. [ ] Implement security hardening
8. [ ] Test all recovery scenarios

**Deliverables**:
- Backup/restore functional
- Secure update mechanism
- Signature verification
- Rollback capability
- Hardened defaults

**Validation**:
- Backup saves correctly
- Restore recovers system
- Updates verify signatures
- Failed updates roll back
- Default configuration is secure

---

### Phase 6: Monitoring & Diagnostics (Week 12)
**Goal**: Implement system monitoring and diagnostics

**Tasks**:
1. [ ] Implement system monitoring (CPU, memory, disk)
2. [ ] Implement network statistics collection
3. [ ] Implement interface status monitoring
4. [ ] Implement log aggregation
5. [ ] Implement diagnostic tools
6. [ ] Create LuCI monitoring UI
7. [ ] Test monitoring accuracy

**Deliverables**:
- System monitoring functional
- Network statistics collected
- Log aggregation working
- Diagnostic tools available
- Monitoring UI operational

**Validation**:
- Metrics collected accurately
- Logs accessible
- Diagnostics helpful
- UI displays correct data

---

### Phase 7: Performance Benchmarking (Week 13-14)
**Goal**: Establish performance baseline and measurement framework

**Tasks**:
1. [ ] Implement performance measurement framework
2. [ ] Create benchmarking suite (router-tests)
3. [ ] Measure throughput (UDP/TCP)
4. [ ] Measure packets-per-second (PPS)
5. [ ] Measure latency (average, P99)
6. [ ] Measure packet loss
7. [ ] Measure CPU and memory usage
8. [ ] Document baseline performance
9. [ ] **Create extension interfaces for future algorithms**
10. [ ] Document integration points for custom algorithms

**Deliverables**:
- Performance measurement framework
- Benchmarking suite
- Baseline performance data
- Documented performance characteristics
- **Clean interfaces for future algorithm integration**
- Performance documentation

**Validation**:
- Benchmarks run reproducibly
- Baseline data accurate
- Interfaces are clean and documented
- Framework supports future algorithm insertion

---

### Phase 8: Hardware Compatibility & Testing (Week 15-16)
**Goal**: Validate on multiple hardware platforms

**Tasks**:
1. [ ] Test on generic x86 hardware
2. [ ] Test on virtual machines (KVM/QEMU)
3. [ ] Test on ARM hardware if available
4. [ ] Document hardware compatibility
5. [ ] Create hardware-specific configuration notes
6. [ ] Fix hardware-specific issues
7. [ ] Finalize documentation

**Deliverables**:
- Hardware compatibility matrix
- Hardware-specific notes
- Issues resolved
- Complete documentation

**Validation**:
- All tested hardware works
- Documentation accurate
- Known limitations documented

---

## Architecture Justification

### Why This Architecture?

1. **OpenWrt Foundation**: Leverages mature, battle-tested Linux distribution for embedded systems
2. **Minimal Customization**: Only modify what's necessary, reducing maintenance burden
3. **Modular Custom Packages**: Clean separation allows easy maintenance and updates
4. **Feed-Based Integration**: Maintains compatibility with OpenWrt ecosystem
5. **Architecture-Agnostic**: No hardcoded hardware assumptions
6. **Extensible Interfaces**: Prepared for future algorithmic optimizations without premature implementation

### Reuse vs. Custom Decision Matrix

| Component | Decision | Rationale |
|-----------|----------|-----------|
| Build System | Reuse OpenWrt | Mature, supports feeds, widely used |
| Init System | Reuse procd | OpenWrt-native, lightweight |
| Config System | Reuse uci | OpenWrt standard, well-integrated |
| Network Daemon | Reuse netifd | Handles complex interface management |
| Firewall | Reuse firewall4 | Modern nftables-based, actively maintained |
| DNS/DHCP | Reuse dnsmasq/odhcpd | Industry standard, well-tested |
| Package Manager | Reuse opkg | OpenWrt-native, feed-compatible |
| Router Core | Custom | Router OS-specific initialization |
| Network Extensions | Custom | Future optimization interfaces |
| UI | Extend LuCI | Custom branding, dashboard |
| Monitoring | Custom | Router-specific metrics |
| Tests | Custom | Router-specific validation |

### Future Algorithm Integration Points

1. **Packet Processing Interface**: Abstract layer in router-net for custom packet handling
2. **QoS Framework**: Base framework with hooks for custom scheduling algorithms
3. **Routing Decision Engine**: Pluggable routing decision interface
4. **Load Balancing**: Interface for custom load distribution algorithms
5. **Traffic Classification**: Framework for custom classification logic

These interfaces will be implemented in Phase 7, providing clean integration points for future mathematical models and algorithms.

---

## Build and Development Workflow

### Development Workflow

```
1. Develop custom package in custom/packages/
2. Add to custom feed
3. Update feeds: ./scripts/feeds update custom
4. Install feeds: ./scripts/feeds install custom-packages
5. Configure: make menuconfig
6. Build: make
7. Test in VM or hardware
8. Iterate
```

### Release Workflow

```
1. Tag version in custom/ git
2. Build reproducible image
3. Verify image signature
4. Document compatibility
5. Release image and source
```

---

## Security Considerations

### Default Security Posture

- Minimal listening services (SSH, HTTP on LAN only)
- Secure default passwords (forced change on first boot)
- Firewall defaults to deny inbound WAN
- Signed firmware updates
- Encrypted configuration backups

### Hardening

- Non-executable stack
- ASLR enabled
- Minimal installed packages
- Regular security updates via OpenWrt feeds
- Audit of custom code

---

## License Considerations

- OpenWrt: GPL-2.0
- Linux: GPL-2.0
- LuCI: Apache-2.0
- Custom code: GPL-2.0 (compatible with OpenWrt)
- Package licenses will be tracked individually

---

## Success Criteria

### Phase Completion Criteria

- **Phase 1**: Custom build system produces images
- **Phase 2**: System boots and detects hardware
- **Phase 3**: All standard router functions work
- **Phase 4**: LuCI fully functional
- **Phase 5**: Secure updates and recovery work
- **Phase 6**: Monitoring provides actionable data
- **Phase 7**: Baseline performance documented, interfaces ready
- **Phase 8**: Multiple hardware platforms validated

### Overall Success Criteria

- Reproducible builds
- Bootable on generic x86 hardware
- Full router functionality operational
- Management interface functional
- Secure update mechanism
- Performance baseline established
- Clean interfaces for future algorithms
- Comprehensive documentation

---

## Next Steps

1. **Review and approve this architecture**
2. **Begin Phase 1: Architecture & Build Setup**
3. **Create custom directory structure**
4. **Set up feed integration**
5. **Test base build**

---

## Questions for Review

1. Do you agree with the component reuse decisions?
2. Should we prioritize any particular hardware platform for initial testing?
3. Are there specific performance targets we should aim for in Phase 7?
4. Should we include any additional networking protocols beyond the standard set?
5. Do you want specific interfaces designed for particular types of algorithms (e.g., routing, QoS, load balancing)?

---

## Appendix: OpenWrt Feed Configuration

### Standard Feeds (from feeds.conf.default)
```
src-git packages https://git.openwrt.org/feed/packages.git
src-git luci https://git.openwrt.org/project/luci.git
src-git routing https://git.openwrt.org/feed/routing.git
src-git telephony https://git.openwrt.org/feed/telephony.git
src-git video https://github.com/openwrt/video.git
```

### Proposed Custom Feeds (feeds.conf.local)
```
src-link custom-feed ../custom-feed
src-git packages ../packages
src-git luci ../luci
src-git routing ../routing
```

This approach uses local feeds for development while maintaining OpenWrt compatibility.
