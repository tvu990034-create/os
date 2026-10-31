# RouterOS Upgrades and Recovery

## Overview

This guide covers firmware upgrades, configuration management, and recovery procedures for RouterOS.

## Firmware Upgrades

### Preparation

1. **Backup Configuration**
```bash
/usr/libexec/router-core/router-backup backup
```

2. **Verify Storage Space**
```bash
/usr/libexec/router-core/router-upgrade check-space
```

3. **Download Firmware**

Download the appropriate firmware image for your platform from the RouterOS releases or build it yourself.

### Upgrade Methods

#### Method 1: LuCI Web Interface

1. Access LuCI at `http://<router-ip>`
2. Navigate to System → Backup / Flash Firmware
3. Upload the firmware image
4. Click "Flash image"
5. Wait for upgrade to complete
6. Router will reboot automatically

#### Method 2: Command Line

1. Upload firmware to router:
```bash
scp openwrt-x86-64-generic-squashfs-sysupgrade.img.gz root@<router-ip>:/tmp/
```

2. SSH to router and verify firmware:
```bash
/usr/libexec/router-core/router-upgrade verify /tmp/openwrt-x86-64-generic-squashfs-sysupgrade.img.gz
```

3. Prepare for upgrade:
```bash
/usr/libexec/router-core/router-upgrade prepare /tmp/openwrt-x86-64-generic-squashfs-sysupgrade.img.gz
```

4. Perform upgrade:
```bash
sysupgrade -v /tmp/openwrt-x86-64-generic-squashfs-sysupgrade.img.gz
```

### Upgrade Process

The upgrade process:
1. Validates firmware format and size
2. Checks available storage
3. Creates configuration backup
4. Stops critical services
5. Writes new firmware
6. Reboots

### Post-Upgrade

1. Verify system boots successfully
2. Check service status:
```bash
/usr/libexec/router-core/router-status
```

3. Verify network configuration
4. Test connectivity
5. Restore configuration if needed

## Configuration Backup

### Manual Backup

```bash
/usr/libexec/router-core/router-backup backup
```

Backups are stored in `/etc/routeros-backups/` with timestamps.

### List Backups

```bash
/usr/libexec/router-core/router-backup list
```

### Backup Contents

Backups include:
- UCI configurations (`/etc/config/`)
- Custom UCI defaults (`/etc/uci-defaults/`)
- SSH authorized keys (`/etc/dropbear/authorized_keys`)

### External Backup

Copy backups to external storage:
```bash
scp root@<router-ip>:/etc/routeros-backups/config-backup-*.tar.gz ./backups/
```

## Configuration Restore

### Restore from Backup

```bash
/usr/libexec/router-core/router-backup restore /etc/routeros-backups/config-backup-<timestamp>.tar.gz
```

### Restore Process

The restore process:
1. Extracts backup archive
2. Restores UCI configurations
3. Restores custom UCI defaults
4. Restores SSH keys
5. Reloads network and firewall services

### Post-Restore

1. Verify configuration:
```bash
uci show network
uci show firewall
```

2. Restart services if needed:
```bash
/etc/init.d/network reload
/etc/init.d/firewall reload
```

## Recovery Procedures

### Firmware Recovery from USB

If the system fails to boot:

1. Prepare USB with RouterOS firmware (see Installation Guide)
2. Boot from USB
3. Reinstall to internal storage if needed

### Recovery Mode

Some devices support a recovery mode:

1. Power off the device
2. Hold recovery button (if available)
3. Power on while holding button
4. Upload firmware via recovery interface
5. Device will restore and reboot

### Serial Console Recovery

For devices with serial console access:

1. Connect serial console
2. Interrupt bootloader if needed
3. Load firmware from TFTP or USB
4. Boot and restore configuration

### Configuration Recovery

If system boots but configuration is corrupted:

1. Access via console or SSH
2. Restore from backup:
```bash
/usr/libexec/router-core/router-backup restore /etc/routeros-backups/config-backup-<timestamp>.tar.gz
```

3. If no backup exists, reconfigure using setup wizard:
```bash
/usr/libexec/router-core/router-setup-wizard
```

## Rollback

### Configuration Rollback

If a configuration change causes issues:

1. Restore previous backup:
```bash
/usr/libexec/router-core/router-backup restore /etc/routeros-backups/config-backup-<previous-timestamp>.tar.gz
```

2. Revert specific UCI changes:
```bash
uci revert network
uci commit network
/etc/init.d/network reload
```

### Firmware Rollback

If firmware upgrade causes issues:

1. Flash previous firmware version
2. Restore configuration backup
3. Verify system operation

## Troubleshooting

### Upgrade Fails

1. Check firmware integrity:
```bash
sha256sum firmware.img.gz
```

2. Check available storage:
```bash
df -h
```

3. Check logs:
```bash
logread
```

4. Try alternative upgrade method

### Configuration Restore Fails

1. Verify backup file exists and is readable
2. Check disk space
3. Verify backup format (tar.gz)
4. Restore manually if needed

### System Won't Boot After Upgrade

1. Attempt recovery mode (if available)
2. Re-flash firmware via USB
3. Check hardware compatibility
4. Contact support with logs

## Safe Practices

### Before Upgrading

1. Always backup configuration
2. Verify firmware compatibility with hardware
3. Ensure sufficient storage space
3. Plan for potential downtime
4. Have recovery media ready

### During Upgrade

1. Do not interrupt the upgrade process
2. Ensure stable power supply
3. Allow sufficient time for completion
4. Monitor progress if possible

### After Upgrading

1. Verify all services start correctly
2. Test network connectivity
3. Check firewall rules
4. Verify configuration persistence
5. Keep old firmware available for rollback

## Version Management

### Check Current Version

```bash
cat /etc/openwrt_release
```

### Track Installed Versions

```bash
opkg list-installed
```

### Keep RouterOS Packages Updated

```bash
opkg update
opkg upgrade
```

## Monitoring After Changes

### System Status

```bash
/usr/libexec/router-core/router-status
```

### Network Health

```bash
/usr/libexec/router-net/check-network-health.sh
```

### Service Supervision

```bash
/usr/libexec/router-core/router-supervisor check
```

## Emergency Procedures

### Safe Reboot

```bash
/usr/libexec/router-core/router-shutdown reboot
```

### Safe Shutdown

```bash
/usr/libexec/router-core/router-shutdown poweroff
```

### Force Reboot (if normal reboot fails)

```bash
reboot -f
```

## Data Loss Prevention

1. **Always backup before major changes**
2. **Keep multiple backup versions**
3. **Store backups off-device when possible**
4. **Document configuration changes**
5. **Test recovery procedures periodically**

## Platform-Specific Notes

### x86_64 Systems

- Use BIOS/UEFI to select boot device
- Can boot from USB for recovery
- Support dual-boot configurations

### Board-Specific Devices

- Recovery procedures vary by device
- Consult device documentation
- Some devices have vendor-specific recovery tools

## Additional Resources

- OpenWrt Upgrade Guide: https://openwrt.org/docs/guide-user/installation/sysupgrade
- Configuration Backup: https://openwrt.org/docs/guide-user/base-system/backup
