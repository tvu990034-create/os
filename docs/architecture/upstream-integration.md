# Upstream Source Integration

This document describes how RouterOS integrates with upstream OpenWrt source repositories and identifies which components are reused.

## Repository Overview

RouterOS uses the OpenWrt feed system to integrate with upstream repositories. The following upstream sources are available locally:

| Repository | Location | Purpose | Integration Status |
|-----------|----------|---------|-------------------|
| OpenWrt | `F:\router-os-source\openwrt\` | Main OpenWrt distribution, build system, target architecture | ✅ Integrated via setup.sh (pinned to v25.12.6) |
| OpenWrt Packages | `F:\router-os-source\packages\` | OpenWrt packages feed | ✅ Available via feeds system |
| OpenWrt Routing | `F:\router-os-source\routing\` | Routing protocols and network routing packages | ✅ Available via feeds system |
| LuCI | `F:\router-os-source\luci\` | OpenWrt web interface framework | ✅ Available via feeds system |
| Linux | `F:\router-os-source\linux\` | Linux kernel source | ⏳ Not yet integrated (for kernel customization) |
| iproute2 | `F:\router-os-source\iproute2\` | Network configuration and tc tool | ⏳ Available in OpenWrt packages |
| Buildroot | `F:\router-os-source\buildroot\` | Alternative build system | ❌ Not used (using OpenWrt build system) |
| DPDK | `F:\router-os-source\dpdk\` | High-performance packet processing | ❌ Not integrated (future performance work) |
| XDP Tutorial | `F:\router-os-source\xdp-tutorial\` | XDP/eBPF learning resources | ❌ Not integrated (future performance work) |
| U-Boot | `F:\router-os-source\u-boot\` | Bootloader | ⏳ Available via OpenWrt target system |
| coreboot | `F:\router-os-source\coreboot\` | Firmware/boot support | ❌ Not integrated (hardware-specific) |

## OpenWrt Feed Integration

RouterOS uses OpenWrt's standard feed system. The `feeds.conf.default` in OpenWrt defines:

```
src-git packages https://git.openwrt.org/feed/packages.git
src-git luci https://git.openwrt.org/project/luci.git
src-git routing https://git.openwrt.org/feed/routing.git
src-git telephony https://git.openwrt.org/feed/telephony.git
src-git video https://github.com/openwrt/video.git
```

RouterOS `setup.sh` pins OpenWrt to a specific release (v25.12.6) and registers the custom feed alongside upstream feeds.

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
