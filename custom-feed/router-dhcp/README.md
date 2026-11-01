# RouterOS DHCP Management

## Overview

The `router-dhcp` package provides DHCP configuration and management, integrating with OpenWrt dnsmasq and odhcpd.

## Components

### router-dhcp-validate
Validates DHCP configuration:
- DHCP server status
- DHCP client configuration
- DHCP range validation

### router-dhcp-status
Shows DHCP status:
- DHCP leases
- DHCP configuration
- DHCP pools
- Interface status

## Usage

### Check DHCP server
```sh
/usr/libexec/router-dhcp/router-dhcp-validate server
```

### Show DHCP leases
```sh
/usr/libexec/router-dhcp/router-dhcp-status leases
```

### Show DHCP status
```sh
/usr/libexec/router-dhcp/router-dhcp-status all
```

## Dependencies

- uci: Configuration management
- dnsmasq: DHCP/DNS server
- odhcpd: IPv6 DHCP

## Status

Basic implementation using dnsmasq/odhcpd. Future: LuCI integration.
