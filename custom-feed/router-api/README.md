# RouterOS Management API

## Overview

The `router-api` package provides a structured management API for LuCI integration using OpenWrt's RPC system.

## Components

### ACL Definitions
`router-api-acl.json` defines RPC access permissions:
- `router-api-read`: Read access to system/network information
- `router-api-write`: Write access to UCI configuration
- `unauthenticated`: Public read access

### RPC Methods
The `router-api` script provides RPC methods:
- `get_system_info`: System status
- `get_network_status`: Network health
- `get_monitoring`: System monitoring
- `get_device_info`: Hardware information
- `backup_config`: Configuration backup
- `list_backups`: List available backups

## Usage

### Access via ubus
```sh
ubus call router-api get_system_info
ubus call router-api get_network_status
```

### ACL Enforcement
Methods enforce permissions defined in ACL files.

## Dependencies

- uci: Configuration management
- rpcd: RPC daemon
- uhttpd-mod-ubus: HTTP to ubus bridge

## Status

Basic RPC implementation. Future: More methods for configuration updates.
