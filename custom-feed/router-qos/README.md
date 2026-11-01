# RouterOS QoS and Traffic Management

## Overview

The `router-qos` package provides QoS (Quality of Service) configuration and traffic management for RouterOS. It integrates with Linux tc (traffic control) and Cake/HTB schedulers.

## Components

### router-qos-validate
Validates QoS configuration:
- tc command availability
- Scheduler support (Cake, HTB)
- Interface validity
- Bandwidth format validation

### router-qos-apply
Applies QoS policies:
- Simple QoS with Cake scheduler
- HTB fallback
- QoS removal
- Interface-level policies

### router-qos-status
Shows QoS status:
- Active qdiscs
- Traffic classes
- Traffic filters
- Statistics

## Usage

### Validate tc support
```sh
/usr/libexec/router-qos/router-qos-validate tc-support
```

### Validate interface
```sh
/usr/libexec/router-qos/router-qos-validate interface eth0
```

### Apply simple QoS
```sh
/usr/libexec/router-qos/router-qos-apply simple eth0 100mbit
```

### Remove QoS
```sh
/usr/libexec/router-qos/router-qos-apply remove eth0
```

### Show QoS status
```sh
/usr/libexec/router-qos/router-qos-status all
```

## Dependencies

- uci: Configuration management
- kmod-sched-core: Traffic control core
- kmod-sched-cake: Cake scheduler
- kmod-sched-htb: HTB scheduler
- tc: Traffic control utility

## Limitations

- Basic implementation with simple bandwidth limiting
- No advanced traffic classification yet
- No priority queues yet
- Cake scheduler may not be available on all platforms

## Future Enhancements

- Advanced traffic classification
- Priority queues
- Per-application policies
- Integration with LuCI
- Performance benchmarks
