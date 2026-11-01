# RouterOS VPN Integration

## Overview

The `router-vpn` package provides VPN configuration and management, primarily WireGuard integration. It can work with OpenVPN and other VPN protocols available from upstream OpenWrt packages.

## Components

### router-vpn-validate
Validates VPN configuration:
- WireGuard support check
- Key format validation
- Endpoint format validation

### router-vpn-status
Shows VPN status:
- WireGuard interfaces
- Interface status
- Peer information

## Upstream Integration

This package integrates with the following upstream OpenWrt components:

- **wireguard-tools**: WireGuard userspace tools
  - Available from OpenWrt packages feed
  - WireGuard kernel module (kmod-wireguard)

- **openvpn-openssl**: OpenVPN with OpenSSL support
  - Available from OpenWrt packages feed
  - Full OpenVPN client/server support
  - Included in firmware for optional use

## Usage

### Check WireGuard support
```sh
/usr/libexec/router-vpn/router-vpn-validate wg-support
```

### Show VPN interfaces
```sh
/usr/libexec/router-vpn/router-vpn-status interfaces
```

### Show VPN status
```sh
/usr/libexec/router-vpn/router-vpn-status all
```

## Dependencies

- uci: Configuration management
- kmod-wireguard: WireGuard kernel module
- wireguard-tools: WireGuard userspace tools

Note: OpenVPN is available in firmware but not a hard dependency of this package.

## Security

VPN configuration should be handled carefully:
- Store private keys securely
- Limit VPN interface exposure
- Configure firewall appropriately
- Use peer authentication

## Future Enhancements

- LuCI integration (use upstream luci-app-openvpn)
- OpenVPN support helpers
- VPN wizard
- Connection status monitoring
- Automatic reconnection
