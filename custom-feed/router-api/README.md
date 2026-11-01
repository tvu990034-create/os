# RouterOS Management API

## Overview

The package installs an executable rpcd plugin at `/usr/libexec/rpcd/router-api`.
rpcd discovers the plugin through its `list` operation and sends method input as
JSON on stdin through `call <method>`.

## Read methods

- `get_system_info`: RouterOS system status report
- `get_network_status`: network health report (`degraded` if checks fail)
- `get_monitoring`: system monitoring report
- `get_device_info`: hardware inventory report
- `list_backups`: available configuration backups

## Write methods

- `backup_config`: create a configuration backup
- `set_lan_config`: set the existing LAN interface IPv4 address and netmask
- `set_wan_config`: set WAN to DHCP or static IPv4
- `set_dhcp_config`: update DHCP pool start, size and lease time

Write methods validate values before invoking UCI. The API does not change LAN
device topology. A failed reload is reported even though UCI may already have
been committed; inspect the active configuration before retrying.

## ACLs

`router-api-read` and `router-api-write` grant separate ubus method access.
Assign the write ACL only to trusted administrator sessions. No method is
granted to the unauthenticated ACL.

## Usage

```sh
ubus -v list router-api
ubus call router-api get_system_info '{}'
ubus call router-api set_lan_config '{"ipaddr":"192.168.10.1","netmask":"255.255.255.0"}'
```

The plugin uses OpenWrt's `jshn` JSON helpers and does not evaluate request
values as shell code.
