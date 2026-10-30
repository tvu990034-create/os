# router-ui

A small, read-only LuCI overview page for RouterOS.

## Page

After installing the package, the RouterOS page is available under **Status -> RouterOS**. It displays system hostname, model, architecture, target, firmware and kernel versions, uptime, load average and interface protocol/state/address information.

## Security

The page only reads the ubus methods system.board, system.info and network.interface.dump. Its dedicated rpcd ACL grants read-only access to those methods. It does not edit UCI configuration or expose command execution.

## Scope

This is the initial management dashboard. Network configuration, backup/restore, firmware management and algorithm controls are separate future UI features.
