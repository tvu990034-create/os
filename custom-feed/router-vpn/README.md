# RouterOS VPN Integration

## Overview

The `router-vpn` package provides VPN configuration and management, primarily WireGuard integration.

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

## Limitations

- Basic WireGuard integration only
- Configuration through standard UCI/wg tools
- No LuCI integration yet
- No OpenVPN support yet

## Security

VPN configuration should be handled carefully:
- Store private keys securely
- Limit VPN interface exposure
- Configure firewall appropriately
- Use peer authentication

## Future Enhancements

- LuCI integration
- OpenVPN support
- VPN wizard
- Connection status monitoring
- Automatic reconnection
