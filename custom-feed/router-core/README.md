# router-core

Core components for Router OS.

## Purpose

This package provides core system functionality for Router OS including:
- Default network configuration (IPv4/IPv6)
- Default firewall configuration
- Default DHCP/DNS configuration
- System configuration (hostname, timezone, logging)
- Hardware detection utility
- Interface hotplug scripts
- UCI defaults for initial setup

## Files

### Configuration Files
- `files/config/network` - Default network configuration (LAN: 192.168.1.1/24, WAN: DHCP)
- `files/config/firewall` - Default firewall rules (LAN<->WAN forwarding, ICMP allow)
- `files/config/dhcp` - DHCP server configuration for LAN
- `files/config/system` - System configuration (hostname, timezone, NTP)

### Scripts
- `files/libexec/router-hw-detect` - Hardware detection utility
- `files/hotplug.d/iface/99_router-core` - Interface hotplug handler
- `files/hotplug.d/net/99_router-core` - Network device hotplug handler
- `files/uci-defaults/99_router-core` - UCI defaults for initial boot

## Default Configuration

### Network
- **LAN**: 192.168.1.1/24, DHCP enabled (100-250)
- **WAN**: DHCP (IPv4), DHCPv6 (IPv6)
- **Bridge**: br-lan with eth1 (default, modify for your hardware)

### Firewall
- **LAN**: Accept all
- **WAN**: Reject input/forward, accept output, masquerade enabled
- **Forwarding**: LAN to WAN allowed
- **ICMP**: Ping allowed from WAN

### DHCP
- **LAN**: DHCP server, DNS relay, RA server
- **WAN**: DHCP client (disabled)

### System
- **Hostname**: RouterOS
- **Timezone**: UTC
- **NTP**: Enabled (openwrt.pool.ntp.org)
- **Logging**: Enabled (64KB circular buffer)

## Hardware Detection

Run hardware detection:
```bash
/usr/libexec/router-core/router-hw-detect
```

This will display:
- Network interfaces
- PCI devices (if lspci available)
- CPU information
- Memory information

## Customization

### Modify Network Configuration

Edit `/etc/config/network` to match your hardware:
```bash
# Change WAN device (e.g., from eth0 to enp1s0)
uci set network.wan.device='enp1s0'
uci commit network
/etc/init.d/network restart
```

### Modify LAN IP
```bash
uci set network.lan.ipaddr='192.168.0.1'
uci commit network
/etc/init.d/network restart
```

### Add LAN Bridge Ports
```bash
uci add_list device.br-lan.ports='eth2'
uci add_list device.br-lan.ports='eth3'
uci commit network
/etc/init.d/network restart
```

## Current Status

Phase 2: Implemented basic system initialization and default configuration.

## Dependencies

- procd (init system)
- uci (configuration system)
- ubus (system bus)
- netifd (network interface daemon)
- firewall4 (firewall management)
- dnsmasq (DNS/DHCP server)
- odhcpd (IPv6 DHCP/RA)

## Future Implementation

See ARCHITECTURE.md for future phases.
