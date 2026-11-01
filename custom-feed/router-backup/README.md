# RouterOS Configuration Backup

## Overview

The `router-backup` package provides persistent configuration backup and restore for RouterOS.

## Components

### router-backup
Backup and restore utility:
- Creates timestamped backups
- Stores in `/etc/routeros-backups/` (persistent)
- Automatic cleanup of old backups
- Backup verification
- Configuration restore with service reload

### Automated Backups
Cron job creates daily backups at 3 AM.

## Usage

### Create backup
```sh
/usr/libexec/router-backup/router-backup backup
```

### List backups
```sh
/usr/libexec/router-backup/router-backup list
```

### Restore backup
```sh
/usr/libexec/router-backup/router-backup restore /etc/routeros-backups/config-backup-<timestamp>.tar.gz
```

### Verify backup
```sh
/usr/libexec/router-backup/router-backup verify /etc/routeros-backups/config-backup-<timestamp>.tar.gz
```

## Backup Location

Backups are stored in `/etc/routeros-backups/` which persists across reboots (unlike /tmp).

Maximum backups: 10 (configurable)

## Backup Contents

- UCI configurations (`/etc/config/`)
- Custom UCI defaults (`/etc/uci-defaults/`)
- SSH authorized keys (`/etc/dropbear/authorized_keys`)

## Status

Complete implementation with automated backups. This replaces the basic backup functionality in router-core.
