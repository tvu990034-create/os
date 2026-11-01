# RouterOS Firmware Upgrade

## Overview

The `router-upgrade` package provides firmware upgrade lifecycle management with OpenWrt sysupgrade integration.

## Components

### router-upgrade
Firmware upgrade utility:
- Firmware verification
- Free space check
- Pre-upgrade backup
- Service management
- sysupgrade integration

## Usage

### Verify firmware
```sh
/usr/libexec/router-upgrade/router-upgrade verify firmware.img.gz
```

### Prepare for upgrade
```sh
/usr/libexec/router-upgrade/router-upgrade prepare firmware.img.gz
```

### Perform upgrade
```sh
/usr/libexec/router-upgrade/router-upgrade upgrade firmware.img.gz
```

### Check free space
```sh
/usr/libexec/router-upgrade/router-upgrade check-space
```

## Upgrade Process

1. Verify firmware format and size
2. Check available storage space
3. Create configuration backup (via router-backup)
4. Stop critical services
5. Execute sysupgrade
6. System reboots

## Dependencies

- uci: Configuration management
- sysupgrade: OpenWrt firmware upgrade tool

## Status

Complete implementation using OpenWrt sysupgrade. This replaces the basic upgrade functionality in router-core.
