# RouterOS Installation Guide

## Overview

RouterOS is a router operating system built on OpenWrt. This guide covers installation for supported hardware platforms.

## Supported Platforms

### Generic x86_64 PCs
- Desktop computers
- Mini PCs
- Workstations
- Servers
- Intel and AMD systems

### x86_64 Virtual Machines
- QEMU
- VMware
- VirtualBox
- Hyper-V

### Generic ARM64
- Arm SystemReady/EFI compatible platforms
- Note: Not all ARM devices are supported

### Board-Specific Routers
- Devices with OpenWrt device profiles
- See OpenWrt Table of Hardware for compatibility

## Prerequisites

### Hardware Requirements
- CPU: x86_64 or supported ARM64
- RAM: Minimum 512MB, recommended 1GB+
- Storage: Minimum 1GB for installation
- Network: At least one Ethernet interface

### Software Requirements
- Linux host for building firmware
- See `docs/development/DEVELOPMENT_GUIDE.md` for build requirements

## Building Firmware

### 1. Clone Repository

```bash
git clone https://github.com/tvu990034-create/os.git
cd os
```

### 2. Install Build Dependencies

```bash
./scripts/install-build-deps-ubuntu.sh
```

### 3. Build Firmware

For x86_64:
```bash
JOBS=2 ./scripts/build-platform.sh x86_64
```

For ARM64:
```bash
JOBS=2 ./scripts/build-platform.sh armsr_armv8
```

Firmware images will be in `openwrt/bin/targets/<target>/<subtarget>/`.

## Installation Methods

### Method 1: USB Boot (x86_64)

1. Download the combined image:
   - `openwrt-x86-64-generic-ext4-combined.img.gz`

2. Decompress:
```bash
gunzip openwrt-x86-64-generic-ext4-combined.img.gz
```

3. Write to USB drive:
```bash
dd if=openwrt-x86-64-generic-ext4-combined.img of=/dev/sdX bs=1M status=progress
```

Replace `/dev/sdX` with your USB device.

4. Boot from USB on target system

### Method 2: Direct Disk Installation (x86_64)

1. Boot from a live Linux distribution
2. Download RouterOS image
3. Write to target disk:
```bash
dd if=openwrt-x86-64-generic-ext4-combined.img of=/dev/sdX bs=1M status=progress
```

4. Reboot from target disk

### Method 3: Upgrade Existing OpenWrt Installation

1. Access existing OpenWrt installation
2. Upload RouterOS sysupgrade image
3. Use LuCI or command line to upgrade:
```bash
sysupgrade -v /tmp/openwrt-x86-64-generic-squashfs-sysupgrade.img.gz
```

### Method 4: QEMU Virtual Machine

For testing:

```bash
qemu-system-x86_64 \
  -m 512M \
  -drive file=openwrt-x86-64-generic-ext4-combined.img,format=raw \
  -net nic,model=e1000 \
  -net user \
  -nographic
```

## First Boot Configuration

### 1. Access Console

On first boot, RouterOS will start with default configuration.

### 2. Network Configuration

The system will attempt to configure networking based on board metadata. For generic x86_64:

- LAN may be on the first detected Ethernet interface
- Default LAN IP: typically 192.168.1.1 (may vary by board)

### 3. Run Setup Wizard

Access the system console and run:

```bash
/usr/libexec/router-core/router-setup-wizard
```

This will guide you through:
- Setting hostname
- Configuring timezone
- Setting root password
- Enabling SSH access

### 4. Access Web Interface

After configuration, access LuCI at:

```
http://<lan-ip-address>
```

Default credentials require you to set a root password first.

## Configuration

### Network Configuration

See `docs/user-guide/CONFIGURATION.md` for detailed configuration.

### Access Methods

- **Web Interface**: LuCI at http://<lan-ip>
- **SSH**: `ssh root@<lan-ip>` (requires SSH key or password)
- **Console**: Serial console or local terminal

## Troubleshooting

### Boot Fails

1. Check BIOS/UEFI boot settings
2. Verify firmware image integrity
3. Check hardware compatibility
4. Review serial console output

### Network Not Working

1. Check interface detection: `ip link show`
2. Check UCI configuration: `uci show network`
3. Check service status: `/etc/init.d/network status`
4. Run network health check: `/usr/libexec/router-net/check-network-health.sh`

### Cannot Access Web Interface

1. Verify uhttpd is running: `/etc/init.d/uhttpd status`
2. Check firewall rules: `uci show firewall`
3. Verify RPC daemon: `/etc/init.d/rpcd status`
4. Check browser connectivity

### System Unstable

1. Check system logs: `logread`
2. Check service status: `/usr/libexec/router-core/router-status`
3. Check resource usage: `/usr/libexec/router-monitor/router-monitor-system all`
4. Review RouterOS documentation

## Recovery

### Configuration Backup

```bash
/usr/libexec/router-core/router-backup backup
```

### Configuration Restore

```bash
/usr/libexec/router-core/router-backup restore /etc/routeros-backups/config-backup-<timestamp>.tar.gz
```

### Firmware Recovery

If the system fails to boot, use the recovery method for your hardware:
- USB boot
- Recovery partition (if available)
- Re-flash from bootloader

## Upgrades

See `docs/operations/UPGRADES_AND_RECOVERY.md` for upgrade procedures.

## Platform-Specific Notes

### Dell OptiPlex 3050

See `docs/DELL_OPTIPLEX_3050.md` for specific guidance.

### Generic ARM64

- Ensure ARM SystemReady/EFI compliance
- Check device tree configuration
- Verify NIC drivers are available

## Support

For issues or questions:
- Check documentation in `docs/`
- Review GitHub issues
- Consult OpenWrt documentation for platform-specific issues
