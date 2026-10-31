# RouterOS Firewall Management

## Overview

The `router-firewall` package provides firewall configuration, validation and diagnostics utilities for RouterOS. It integrates with OpenWrt's firewall4 and nftables.

## Components

### router-firewall-validate
Validates firewall configuration:
- Checks nftables availability
- Validates firewall UCI configuration
- Verifies required zones (LAN, WAN)
- Validates nftables ruleset

### router-firewall-diagnostics
Provides firewall diagnostics:
- Shows firewall status and zones
- Displays active nftables rules
- Shows zone-specific status

## Usage

### Validate firewall configuration
```sh
/usr/libexec/router-firewall/router-firewall-validate validate
```

### Show firewall status
```sh
/usr/libexec/router-firewall/router-firewall-diagnostics status
```

### Show active rules
```sh
/usr/libexec/router-firewall/router-firewall-diagnostics rules
```

### Show zone status
```sh
/usr/libexec/router-firewall/router-firewall-diagnostics zone-status lan
```

## Configuration

Configuration is stored in `/etc/config/router-firewall`:

```
config router-firewall
	option enabled '1'
```

## Dependencies

- uci: Configuration management
- firewall4: OpenWrt firewall service
- kmod-nft-core: nftables kernel module

## Status

This is a basic implementation. Future enhancements:
- Zone management utilities
- Rule management
- Import/export configurations
- Integration with LuCI
