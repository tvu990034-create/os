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
- `set_wan_config`: set WAN to DHCP or static IPv4 on an existing interface
- `set_dhcp_config`: update DHCP pool start, size and lease time

Static WAN configuration requires a physical or virtual interface that already
exists and is not the LAN interface or a LAN bridge member. Supply `device`,
`ipaddr`, `netmask` and `gateway`. DHCP WAN needs only `device` and `proto`.
The API deliberately does not guess which physical NIC is the WAN port.

Write methods validate values before invoking UCI. LAN device topology is
not changed by the API. A failed reload is reported even though UCI may already
have been committed; inspect the active configuration before retrying.

## ACLs

`router-api-read` grants read-only status methods. `router-api-write` grants
only the explicit management methods; neither role grants direct UCI or file
RPC access. Assign the write ACL only to trusted administrator sessions.

## Usage

```sh
ubus -v list router-api
ubus call router-api get_system_info '{}'
ubus call router-api set_wan_config '{"proto":"dhcp","device":"eth1"}'
```

The first command should list the methods after rpcd reloads. Use a maintenance
connection when changing LAN addressing or WAN interface assignments.

The plugin uses OpenWrt's `jshn` JSON helpers and does not evaluate request
values as shell code.
