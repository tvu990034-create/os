# RouterOS Custom UI (DEPRECATED)

## Status

This package is **DEPRECATED** and replaced with upstream LuCI applications.

RouterOS now uses standard OpenWrt LuCI applications instead of custom UI code:
- **luci-app-firewall**: Firewall configuration
- **luci-proto-wireguard**: WireGuard VPN configuration
- **luci-proto-openvpn**: OpenVPN configuration
- **luci-app-qosify**: QoS configuration (via upstream qosify)

## Migration

The custom RouterOS overview dashboard has been removed from firmware builds. Use the standard LuCI status and network pages instead.

## Remaining Package

This package remains in the repository for historical reference but is not included in production firmware builds. It can be safely removed in a future cleanup commit.

## Original Functionality

A small, read-only LuCI overview page for RouterOS that displayed:
- System hostname, model, architecture, target
- Firmware and kernel versions
- Uptime, load average
- Interface protocol/state/address information

This was the initial management dashboard before migrating to upstream LuCI applications.
