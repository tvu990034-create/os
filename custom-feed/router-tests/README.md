# router-tests

Automated test suite for Router OS.

## Purpose

This package provides automated tests for validating Router OS functionality including:
- Configuration syntax validation
- Hardware detection
- Network configuration validation
- System initialization tests

## Tests

### test-config-syntax.sh
Validates UCI configuration files for syntax errors.

**Usage**:
```bash
/usr/libexec/router-tests/test-config-syntax.sh
```

**Validates**:
- /etc/config/network
- /etc/config/firewall
- /etc/config/dhcp
- /etc/config/system

### test-hardware-detect.sh
Validates hardware detection script functionality.

**Usage**:
```bash
/usr/libexec/router-tests/test-hardware-detect.sh
```

**Validates**:
- Hardware detection script exists and is executable
- Detection completes without errors
- Detection log is created
- Expected sections are present in output

### test-network-validation.sh
Validates network configuration and interface availability.

**Usage**:
```bash
/usr/libexec/router-tests/test-network-validation.sh
```

**Validates**:
- Loopback interface exists
- Non-loopback interfaces exist
- Network config file exists
- Loopback configured in UCI
- LAN configured in UCI
- WAN configured in UCI

## Running All Tests

```bash
# Run all tests
/usr/libexec/router-tests/test-config-syntax.sh
/usr/libexec/router-tests/test-hardware-detect.sh
/usr/libexec/router-tests/test-network-validation.sh
```

## Dependencies

- bash
- coreutils
- iproute2
- kmod-nft-core
