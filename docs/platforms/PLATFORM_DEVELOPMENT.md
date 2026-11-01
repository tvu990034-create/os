# RouterOS Platform Development

## Overview

RouterOS is designed to support multiple hardware platforms through OpenWrt's target and device profile system. This guide explains how to add platform support to RouterOS.

## Platform Types

RouterOS supports several platform types:

### Generic PC
- Desktop computers
- Mini PCs
- Workstations
- Servers
- Intel and AMD x86_64 systems

### Generic VM
- QEMU
- VMware
- VirtualBox
- Hyper-V

### Generic ARM64
- Arm SystemReady/EFI compliant platforms
- Generic ARMv8 servers

### Board-Specific
- Routers with OpenWrt device profiles
- Specific hardware with custom drivers
- Devices requiring board-specific configuration

## Platform Registry

Platforms are registered in `config/platforms.tsv`:

```
# profile       type            OpenWrt target  subtarget  config file                      status
x86_64           generic-pc      x86              64         config/x86_64.config              development
armsr_armv8      generic-arm64   armsr            armv8      config/armsr_armv8.config         experimental
x86_qemu         generic-vm      x86              64         config/x86_64.config              development
```

### Fields

- **profile**: Unique identifier for the platform
- **type**: Platform type (generic-pc, generic-arm64, generic-vm, board-specific)
- **target**: OpenWrt target (e.g., x86, armsr)
- **subtarget**: OpenWrt subtarget (e.g., 64, armv8)
- **config file**: Path to configuration file
- **status**: development, experimental, verified, production-ready

## Adding a New Platform

### Step 1: Identify OpenWrt Target

Check OpenWrt Table of Hardware to identify the correct target and subtarget for your device.

### Step 2: Create Configuration File

Create a configuration file in `config/`:

```bash
cp config/x86_64.config config/my-platform.config
```

Edit the configuration:
```
CONFIG_TARGET_<target>=y
CONFIG_TARGET_<target>_<subtarget>=y
CONFIG_TARGET_DEVICE_<target>_<subtarget>_DEVICE_<device>=y

# Select RouterOS packages
CONFIG_PACKAGE_router-core=y
CONFIG_PACKAGE_router-net=y
# ... other packages
```

### Step 3: Add to Platform Registry

Add entry to `config/platforms.tsv`:

```
my-platform       board-specific  <target>         <subtarget> config/my-platform.config         experimental
```

### Step 4: Validate

Run platform validation:

```bash
python3 scripts/validate-platforms.py
```

### Step 5: Test Build

Build firmware for the new platform:

```bash
./scripts/build-platform.sh my-platform
```

### Step 6: Test on Hardware

Flash firmware to target device and verify:
- System boots
- Network interfaces detected
- Board-generated network configuration correct
- RouterOS services start
- Web interface accessible

### Step 7: Update Status

Once tested, update status in `config/platforms.tsv`:
- `experimental`: Initial testing
- `verified`: Hardware tested and working
- `production-ready`: Fully validated

## Generic x86_64 Platform

### Characteristics

- Generic OpenWrt x86/64 target for standard Intel and AMD 64-bit PCs
- Desktop PCs, office PCs, mini PCs, workstations and many servers
- Legacy BIOS and UEFI boot images
- SATA/AHCI, NVMe, USB mass storage and virtio block support from the x86_64 kernel
- Bundled common Intel, Realtek, Broadcom, Marvell and Atheros PCIe Ethernet drivers
- Bundled common Realtek/ASIX/CDC/RNDIS USB Ethernet drivers
- Virtual NIC support for common virtual-machine environments

This is a broad generic-PC target, not a guarantee for every PC. Unsupported or unusual
Ethernet/Wi-Fi chipsets, RAID/VMD storage modes, vendor-specific platform controllers,
and Secure Boot configurations may require additional drivers or firmware settings.
For the first installation, use a standard AHCI/NVMe storage mode and disable Secure Boot
unless the device has a separately validated signed-boot chain. Wi-Fi support is chipset-
specific and is not guaranteed by the generic wired-Ethernet driver set.

### Configuration

Uses `config/x86_64.config` with generic device profile:
```
CONFIG_TARGET_DEVICE_x86_64_DEVICE_generic=y
```

### Network

For generic x86_64, network configuration is not board-generated. You must:
1. Identify interfaces with `ip link show`
2. Configure LAN/WAN manually
3. Use configuration helper:
```bash
/usr/libexec/router-core/router-config list-interfaces
/usr/libexec/router-core/router-config configure-lan eth0
/usr/libexec/router-core/router-config configure-wan eth1
```

## Generic ARM64 Platform

### Characteristics

- Arm SystemReady/EFI compliance
- ARMv8 CPUs
- Standard ARM server components
- UEFI boot
- Generic device tree

### Configuration

Uses `config/armsr_armv8.config`:
```
CONFIG_TARGET_DEVICE_armsr_armv8_DEVICE_generic=y
```

### Limitations

- Not all ARM devices are supported
- Requires Arm SystemReady/EFI compliance
- May need device-specific drivers

## Board-Specific Platforms

### Characteristics

- Dedicated router hardware
- Specific CPU and chipset
- Board-specific network topology
- Custom switch configuration
- Device-specific drivers

### Configuration

Uses OpenWrt device profiles:
```
CONFIG_TARGET_DEVICE_<target>_<subtarget>_DEVICE_<device>=y
```

### Network Configuration

OpenWrt generates network configuration from board metadata. RouterOS:
- Preserves board-generated configuration
- Does not override board network topology
- Only adds board-independent service defaults

### Example: Adding a Router

1. Identify OpenWrt device profile from Table of Hardware
2. Create configuration file selecting that device
3. Add to platform registry with type `board-specific`
4. Build and test on actual hardware
5. Document any device-specific requirements

## Platform-Specific Packages

For platforms that require special handling, create platform-specific packages:

### Structure

```
custom-feed/router-platform-<name>/
├── Makefile
├── README.md
└── files/
    ├── libexec/
    └── etc/
```

### Conditional Installation

Use platform conditionals in Makefile:
```makefile
DEFAULT:=y if TARGET_<target>
```

### Device Detection

Use platform detection in scripts:
```bash
if [ "$(uname -m)" = "aarch64" ]; then
    # ARM64-specific code
fi
```

## Hardware Testing Checklist

### Boot Testing
- [ ] System boots successfully
- [ ] Boot messages show no errors
- [ ] Init system completes
- [ ] Services start correctly

### Network Testing
- [ ] Network interfaces detected
- [ ] Board-generated config correct
- [ ] LAN connectivity works
- [ ] WAN connectivity works (if applicable)
- [ ] DHCP server works
- [ ] DNS resolution works

### Service Testing
- [ ] Firewall starts
- [ ] Web interface accessible
- [ ] SSH accessible
- [ ] All RouterOS services start

### Configuration Testing
- [ ] Configuration persists across reboot
- [ ] Backup/restore works
- [ ] UCI configuration valid
- [ ] First-boot setup works

### Hardware-Specific Testing
- [ ] Switch ports correct (if applicable)
- [ ] WiFi works (if applicable)
- [ ] LED indicators work (if applicable)
- [ ] Recovery mode works (if applicable)

## Platform Validation

### Source-Level Validation

```bash
python3 scripts/validate-platforms.py
```

Checks:
- Profile naming
- Target/subtarget validity
- Configuration file existence
- Required packages selected

### Build-Level Validation

```bash
./scripts/build-platform.sh <profile>
```

Checks:
- Firmware builds successfully
- Image is generated
- No build errors

### Runtime-Level Validation

Test on actual hardware:
- Boot test
- Network test
- Service test
- Configuration test

## Platform Profiles in CI

### SDK Build

Add to `.github/workflows/openwrt-sdk-build.yml`:

```yaml
- profile: my-platform
  sdk_url: <sdk-url>
  sdk_sha256: <sdk-sha256>
  config_file: config/my-platform.config
```

### Firmware Build

Add to `.github/workflows/build-and-boot.yml` if QEMU test is applicable.

## Documentation

For each platform, document:

- Hardware specifications
- CPU, chipset, storage
- Network interfaces
- Special requirements
- Known issues
- Workarounds
- Testing status

Example: `docs/DELL_OPTIPLEX_3050.md`

## Common Issues

### Build Fails

1. Verify target/subtarget exists in OpenWrt
2. Check device profile is correct
3. Verify dependencies are available
4. Check OpenWrt version compatibility

### Network Not Working

1. Check board-generated config
2. Verify interface names
3. Check drivers are loaded
4. Review device-specific documentation

### Services Don't Start

1. Check service logs
2. Verify dependencies
3. Check resource availability
4. Review hardware compatibility

## Platform Support Policy

### Supported Platforms

Platforms marked as `production-ready` have:
- Successful firmware builds
- Hardware testing completed
- All features working
- Comprehensive documentation

### Experimental Platforms

Platforms marked as `experimental` have:
- Firmware builds successfully
- Limited hardware testing
- Some features may not work
- Documentation may be incomplete

### Unsupported Platforms

Platforms not in the registry are:
- Not tested
- Not guaranteed to work
- May require custom development

## Multi-Platform Considerations

### Configuration Isolation

Each platform should have:
- Separate configuration file
- Platform-specific settings
- Independent validation

### Package Selection

Select packages appropriate for each platform:
- WiFi only for platforms with WiFi
- Specific drivers when needed
- Optional features for capable hardware

### Testing Strategy

Test each platform independently:
- Don't assume x86_64 behavior applies to ARM
- Test on actual hardware
- Document platform-specific issues

## Resources

- OpenWrt Table of Hardware: https://openwrt.org/toh/start
- OpenWrt Targets: https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem
- OpenWrt Device Profiles: target/linux/<target>/base-files/
