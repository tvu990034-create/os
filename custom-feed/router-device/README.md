# RouterOS Hardware Discovery

## Overview

The `router-device` package provides hardware discovery and platform capability reporting for RouterOS.

## Components

### router-device-info
Reports device information:
- CPU information
- Memory information
- Network interfaces
- Storage information
- System information

### router-device-capabilities
Reports device capabilities:
- VPN support (IPsec, TUN/TAP)
- WiFi support
- Storage capabilities
- PCI devices
- USB devices

## Usage

### Show CPU information
```sh
/usr/libexec/router-device/router-device-info cpu
```

### Show memory information
```sh
/usr/libexec/router-device/router-device-info memory
```

### Show network interfaces
```sh
/usr/libexec/router-device/router-device-info network
```

### Show all device information
```sh
/usr/libexec/router-device/router-device-info all
```

### Check VPN support
```sh
/usr/libexec/router-device/router-device-capabilities vpn
```

### Check WiFi support
```sh
/usr/libexec/router-device/router-device-capabilities wifi
```

### Show all capabilities
```sh
/usr/libexec/router-device/router-device-capabilities all
```

## Dependencies

- uci: Configuration management

## Status

Basic implementation. Future enhancements:
- Integration with LuCI hardware page
- Platform-specific capability profiles
- Hardware validation tests
