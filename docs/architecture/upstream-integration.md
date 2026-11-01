# Upstream Source Integration

This document describes how RouterOS integrates with upstream OpenWrt source repositories and identifies which components are reused.

## Repository Overview

RouterOS uses the OpenWrt feed system to integrate with upstream repositories. The following upstream sources are available locally:

**Note:** All local repositories are shallow clones. They are available for development but may not have full Git history.

| Repository | Location | Purpose | Integration Status |
|-----------|----------|---------|-------------------|
| OpenWrt | `F:\router-os-source\openwrt\` | Main OpenWrt distribution, build system, target architecture | ✅ Integrated via setup.sh (pinned to v25.12.6) |
| OpenWrt Packages | `F:\router-os-source\packages\` | OpenWrt packages feed | ✅ Configured as local feed (commit: 6307bdf, shallow) |
| OpenWrt Routing | `F:\router-os-source\routing\` | Routing protocols and network routing packages | ✅ Configured as local feed (commit: 4b9891b, shallow) |
| LuCI | `F:\router-os-source\luci\` | OpenWrt web interface framework | ✅ Configured as local feed (commit: 0e27835, shallow) |
| Linux | `F:\router-os-source\linux\` | Linux kernel source | ❌ Not cloned locally (OpenWrt manages kernel) |
| iproute2 | `F:\router-os-source\iproute2\` | Network configuration and tc tool | ⏳ Available in OpenWrt packages |
| Buildroot | `F:\router-os-source\buildroot\` | Alternative build system | ❌ Not used (using OpenWrt build system) |
| DPDK | `F:\router-os-source\dpdk\` | High-performance packet processing | ❌ Not integrated (future performance work) |
| XDP Tutorial | `F:\router-os-source\xdp-tutorial\` | XDP/eBPF learning resources | ❌ Not integrated (future performance work) |
| U-Boot | `F:\router-os-source\u-boot\` | Bootloader | ⏳ Available via OpenWrt target system |
| coreboot | `F:\router-os-source\coreboot\` | Firmware/boot support | ❌ Not integrated (hardware-specific) |

## Local Feed Integration Strategy

### Feed Configuration

RouterOS uses a local feed configuration strategy with configurable source root:

1. **setup.sh automatically configures local feeds**:
   - Uses `ROUTEROS_SOURCE_ROOT` environment variable (default: ROOT_DIR)
   - Allows external source root (e.g., `/mnt/f/router-os-source` for WSL access to Windows F: drive)
   - Checks if local repositories exist at source root (`packages/`, `luci/`, `routing/`)
   - If local feeds exist, creates `openwrt/feeds.conf` with local feeds prioritized
   - Falls back to remote feeds if local repositories are not available
   - This ensures CI can still work without local repositories

2. **Local feeds are prioritized**:
   - `src-git packages $ROUTEROS_SOURCE_ROOT/packages` - Local packages feed
   - `src-git luci $ROUTEROS_SOURCE_ROOT/luci` - Local LuCI feed
   - `src-git routing $ROUTEROS_SOURCE_ROOT/routing` - Local routing feed
   - `src-link routeros $CUSTOM_FEED_DIR` - RouterOS custom feed

3. **Remote feeds remain as fallback**:
   - `src-git telephony https://git.openwrt.org/feed/telephony.git`
   - `src-git video https://github.com/openwrt/video.git`
   - `src-include defaults feeds.conf.default` - Any feeds not defined locally

4. **Manual configuration script**:
   - `scripts/configure-local-feeds.sh` can be run to reconfigure feeds
   - Reports current commits for reproducibility
   - Useful for feed troubleshooting

### Feed Configuration File

The generated `openwrt/feeds.conf` looks like:

```
# RouterOS local feed configuration
# Local feeds are prioritized for development and reproducibility
# Remote feeds are kept as fallback for missing packages

# Local feeds (prioritized)
src-git packages ../packages
src-git luci ../luci
src-git routing ../routing

# RouterOS custom feed
src-link routeros ../custom-feed

# Remote feeds (fallback)
src-git telephony https://git.openwrt.org/feed/telephony.git
src-git video https://github.com/openwrt/video.git

# Include OpenWrt defaults for any feeds not defined above
src-include defaults feeds.conf.default
```

### Reproducibility

- **OpenWrt is pinned**: v25.12.6 via `OPENWRT_REF` in setup.sh
- **Local feed commits are tracked**: configure-local-feeds.sh reports current commits
- **Future enhancement**: Consider pinning local feed commits in a manifest file

### CI Integration

The current CI workflow uses remote OpenWrt feeds (downloads SDK from official OpenWrt). This is intentional for reproducibility:

- CI builds from official OpenWrt SDKs
- Local feeds are for development convenience
- CI can still reproduce builds without local repositories
- Local feed commits are recorded for documentation

### Using Local Feeds

To use local feeds for development:

```bash
# Initial setup (also configures local feeds)
./setup.sh

# Or reconfigure feeds manually
./scripts/configure-local-feeds.sh

# Update feeds from local sources
cd openwrt
./scripts/feeds update -a

# Install feeds
./scripts/feeds install -a
```

### CI vs Development

**Development:**
- Uses local feeds for faster iteration
- Can test changes to local packages feed
- Can test changes to local LuCI feed
- Can test changes to local routing feed

**CI:**
- Uses official OpenWrt SDKs
- Uses remote feeds for reproducibility
- Ensures builds work without local dependencies
- Validates that RouterOS works with standard OpenWrt ecosystem

## Current RouterOS Package Dependencies

RouterOS packages currently depend on standard OpenWrt components:

### router-core
- `procd`: OpenWrt process manager
- `uci`: OpenWrt configuration system

### router-net
- Depends on standard OpenWrt networking (netifd, etc.)

### router-firewall
- Should integrate with `firewall4` and `nftables`

### router-qos
- Depends on `tc-full`, `kmod-sched-core`, `kmod-sched-cake`, `kmod-sched-htb`
- These are standard OpenWrt kernel modules and tools

### router-vpn
- Depends on `kmod-wireguard`, `wireguard-tools`
- Standard OpenWrt WireGuard packages

### router-dns
- Depends on `dnsmasq`
- Standard OpenWrt DNS forwarder

### router-dhcp
- Depends on `dnsmasq`, `odhcpd`
- Standard OpenWrt DHCP servers

### router-api
- Depends on `rpcd`, `uhttpd-mod-ubus`
- Standard OpenWrt RPC system

## Upstream Packages Available for Integration

### QoS and Traffic Control

**From OpenWrt packages feed:**
- `tcfilter`: Persistent tc ingress filters (UCI-managed)
  - Location: `packages/net/tcfilter/`
  - Integrates with tc-full and kmod-sched-flower
  - Could enhance router-qos with hardware offload support

**From LuCI applications:**
- `luci-app-qos-legacy`: QoS configuration for legacy qos-scripts
  - Location: `luci/applications/luci-app-qos-legacy/`
  - Note: Deprecated, recommends SQM or qosify
- `luci-app-qosify`: Modern QoS UI for qosify daemon
  - Location: `luci/applications/luci-app-qosify/`
  - Uses CAKE/eBPF traffic shaping
  - Could replace custom router-qos UI

**Recommendation:** Consider integrating `luci-app-qosify` for the QoS management interface instead of building custom LuCI modules.

### VPN

**From OpenWrt packages feed:**
- `openvpn`: OpenVPN client/server
  - Location: `packages/net/openvpn/`
  - Could extend router-vpn beyond WireGuard
- `wireguard-tools`: WireGuard userspace tools
  - Already in use by router-vpn

**Recommendation:** Add OpenVPN support to router-vpn package.

### Routing

**From OpenWrt routing feed:**
- `babel-pinger`: Babel routing protocol
- `batmand`: BATMAN routing protocol
- `cjdns`: Encrypted network protocol
- Various routing daemons

**Current router-routing:** Only provides status/diagnostics
**Recommendation:** Integrate routing protocols from upstream routing feed for actual routing functionality.

### Network Tools

**From OpenWrt packages feed:**
- `tcp-in-udp`: TCP over UDP tunneling
- `tcpproxy`: TCP proxy
- `tcpreplay`: TCP traffic replay
- `ratched`: TLS reverse proxy
- Various network monitoring tools

**Recommendation:** Integrate relevant network diagnostic tools into router-monitor package.

## Integration Strategy

### Phase 1: Enhance Existing Packages with Upstream Components

1. **router-qos Enhancement**
   - Integrate `tcfilter` for hardware offload support
   - Evaluate `luci-app-qosify` for UI
   - Add dependency on qosify if it provides better CAKE/eBPF integration

2. **router-vpn Enhancement**
   - Add OpenVPN support from upstream `openvpn` package
   - Keep WireGuard as primary VPN
   - Add UI integration from upstream LuCI VPN apps

3. **router-routing Enhancement**
   - Integrate BGP or OSPF from routing feed if needed
   - Add static routing configuration helpers
   - Add routing table management

4. **router-monitor Enhancement**
   - Integrate upstream network monitoring tools
   - Add traffic analysis tools

### Phase 2: Replace Custom LuCI with Upstream

Where upstream LuCI applications exist and provide equivalent functionality, prefer them:

- Use `luci-app-qosify` instead of custom QoS UI
- Use `luci-app-firewall` for firewall configuration
- Use `luci-app-openvpn` or similar for VPN configuration
- Build custom RouterOS-specific UI only where upstream is insufficient

### Phase 3: Performance Optimization (Future)

Use DPDK and XDP repositories when:
- Performance benchmarks justify it
- Target hardware supports required features
- Linux networking stack is insufficient

## Build Integration

### Adding Upstream Packages to RouterOS

To include an upstream package in RouterOS firmware:

1. Ensure the package is available in the appropriate feed
2. Add the package to the firmware config (`config/x86_64.config`):
   ```
   CONFIG_PACKAGE_<package-name>=y
   ```
3. Add dependencies to RouterOS package Makefiles if needed
4. Test in SDK build before full firmware build

### Example: Adding tcfilter to router-qos

Edit `custom-feed/router-qos/Makefile`:
```makefile
DEPENDS:=+uci +kmod-sched-core +kmod-sched-cake +kmod-sched-htb +tc-full +tcfilter
```

Edit `config/x86_64.config`:
```
CONFIG_PACKAGE_tcfilter=y
```

## Repository Usage Policy

### What to Inspect and Reuse
- OpenWrt package source code for integration patterns
- LuCI application structure for UI design
- Upstream routing protocols for routing functionality
- Linux kernel headers for kernel-space development

### What NOT to Do
- Do not copy entire upstream repositories into RouterOS
- Do not modify upstream repositories directly
- Do not commit upstream source into RouterOS Git
- Do not duplicate functionality that exists upstream

### Correct Integration Method
- Use OpenWrt feed system to access upstream packages
- Reference upstream packages in dependencies
- Build custom RouterOS packages that use upstream components
- Keep upstream source separate from RouterOS project

## Current Integration Gaps

1. **router-qos**: Only basic tc integration, could use upstream qosify or tcfilter
2. **router-vpn**: Only WireGuard, missing OpenVPN and other VPN types
3. **router-routing**: Only diagnostics, no actual routing protocol integration
4. **router-ui**: Custom dashboard only, not using upstream LuCI apps
5. **Performance**: No DPDK or XDP integration (future work)

## Next Steps

1. Audit each RouterOS package against upstream alternatives
2. Replace custom implementations with upstream packages where appropriate
3. Add upstream packages to firmware configs
4. Test SDK compilation with added upstream dependencies
5. Update documentation to reflect upstream usage
6. Only build custom RouterOS code where genuinely new functionality is needed
