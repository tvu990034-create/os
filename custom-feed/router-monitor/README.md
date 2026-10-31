# RouterOS System Monitoring

## Overview

The `router-monitor` package provides system and network monitoring utilities for RouterOS.

## Components

### router-monitor-system
System monitoring:
- CPU usage
- Memory usage
- Disk usage
- Process count
- System uptime

### router-monitor-network
Network monitoring:
- Interface statistics
- Connection count
- Bandwidth monitoring

## Usage

### Show CPU usage
```sh
/usr/libexec/router-monitor/router-monitor-system cpu
```

### Show memory usage
```sh
/usr/libexec/router-monitor/router-monitor-system memory
```

### Show disk usage
```sh
/usr/libexec/router-monitor/router-monitor-system disk
```

### Show all system metrics
```sh
/usr/libexec/router-monitor/router-monitor-system all
```

### Show interface statistics
```sh
/usr/libexec/router-monitor/router-monitor-network interfaces
```

### Show connection count
```sh
/usr/libexec/router-monitor/router-monitor-network connections
```

### Show bandwidth for interface
```sh
/usr/libexec/router-monitor/router-monitor-network bandwidth eth0
```

## Dependencies

- uci: Configuration management
- procd: Process manager

## Status

Basic implementation. Future enhancements:
- Historical data collection
- Threshold alerts
- Integration with LuCI dashboard
