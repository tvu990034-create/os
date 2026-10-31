# Dell OptiPlex 3050 Hardware Compatibility Checklist

## System Specifications

**Model**: Dell OptiPlex 3050
**Form Factor**: Micro (Micro Tower)
**Processor Options**:
- Intel Core i3-7100T (3.40 GHz, 2 cores, 4 threads)
- Intel Core i5-7500T (3.30 GHz, 4 cores, 8 threads)
- Intel Core i7-7700T (3.40 GHz, 4 cores, 8 threads)
- Intel Pentium G4620T (3.70 GHz, 2 cores, 4 threads)

**Chipset**: Intel B250
**Memory**: Up to 32GB DDR4-2400 UDIMM (2x16GB)
**Storage**: 1x 3.5" HDD, 1x 2.5" SSD
**Network**: Intel I219-V Gigabit Ethernet

## Hardware Validation Steps

### 1. Boot Mode Compatibility
- [ ] Verify BIOS supports UEFI boot
- [ ] Verify BIOS supports Legacy BIOS boot
- [ ] Check boot order settings
- [ ] Test boot from USB (OpenWrt image)
- [ ] Test boot from SSD (installed OpenWrt)

### 2. Network Controller
- [ ] Identify NIC: Intel I219-V (PCIe)
- [ ] Verify Linux driver support (e1000e)
- [ ] Check device naming (e.g., enp2s0, eth0)
- [ ] Test driver detection during boot
- [ ] Verify link status
- [ ] Test actual network throughput

### 3. Storage
- [ ] Test SSD compatibility (SATA)
- [ ] Test HDD compatibility (SATA)
- [ ] Verify OpenWrt storage driver support
- [ ] Check filesystem compatibility (ext4, squashfs)
- [ ] Test overlay filesystem on target storage

### 4. USB
- [ ] Test USB 2.0 ports (4x rear)
- [ ] Test USB 3.0 ports (2x front)
- [ ] Verify USB storage boot capability
- [ ] Test USB networking (if using USB Ethernet)

### 5. PCIe Expansion
- [ ] Identify available PCIe slot (x16 for GPU, x1 for other)
- [ ] Test PCIe network card compatibility (if adding NIC)
- [ ] Check PCIe slot length and power requirements

### 6. Power and Thermal
- [ ] Verify power supply (65W or 90W)
- [ ] Check thermal monitoring support
- [ ] Monitor CPU temperature under load
- [ ] Verify fan operation

### 7. BIOS Configuration
Required BIOS settings for OpenWrt:
- [ ] Boot mode: UEFI or Legacy
- [ ] Secure Boot: Disabled
- [ ] Fast Boot: Disabled (for reliable boot)
- [ ] USB Boot: Enabled
- [ ] Network Boot: Can be disabled
- [ ] VT-x/VT-d: Enabled (if needed for virtualization testing)

## OpenWrt Target Profile

**Target**: x86
**Subtarget**: 64
**Device**: generic

The OptiPlex 3050 uses standard x86-64 components and should work with the generic x86/64 profile.

## Known Issues and Workarounds

1. **NIC Device Naming**: The Intel I219-V may appear as `enp2s0` or similar. OpenWrt may rename it to `eth0` depending on udev rules. This must be verified during first boot.

2. **BIOS Boot Speed**: Dell BIOS fast boot may interfere with serial console or PXE. Disable fast boot for development.

3. **Wake-on-LAN**: May interfere with power state testing. Disable in BIOS for initial testing.

## Testing Procedure

1. Create OpenWrt x86-64 image using `scripts/build-platform.sh x86_64`
2. Write image to USB using `dd` or Rufus
3. Boot OptiPlex 3050 from USB
4. Verify boot completes (no kernel panic)
5. Verify network interface detected
6. Verify SSH access (configure network first)
7. Test LAN connectivity
8. Test WAN connectivity (if second NIC available)
9. Test DHCP server
10. Test DNS resolution
11. Test routing and NAT
12. Test LuCI access
13. Test router-status output
14. Test network health check
15. Reboot and verify persistence

## Performance Baseline

Target performance measurements:
- **Throughput**: >500 Mbps (single core, gigabit NIC)
- **PPS**: To be measured
- **Latency**: To be measured
- **Jitter**: To be measured
- **Packet Loss**: <0.1% under load

## Success Criteria

The OptiPlex 3050 is supported when:
- [ ] Complete firmware builds successfully
- [ ] Firmware boots without errors
- [ ] Network interface is detected and functional
- [ ] LAN configuration works
- [ ] DHCP server works
- [ ] DNS resolution works
- [ ] WAN configuration works (if applicable)
- [ ] Routing and NAT work
- [ ] Firewall works
- [ ] LuCI is accessible
- [ ] Configuration persists across reboots
- [ ] No critical kernel errors in logs

## Notes

- This is a micro form factor - ensure adequate cooling for long-duration testing
- The 65W power supply may limit PCIe expansion cards
- For production use, consider SSD for better performance and reliability
