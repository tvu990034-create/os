# RouterOS QoS and Traffic Management

## Overview

The `router-qos` package provides QoS (Quality of Service) configuration and traffic management for RouterOS. It integrates with Linux tc (traffic control), Cake/HTB schedulers, and upstream OpenWrt components.

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

## Upstream Integration

This package integrates with the following upstream OpenWrt components:

- **tcfilter**: Persistent tc ingress filters (UCI-managed)
  - Provides hardware offload support for tc-flower
  - Enables advanced filter management
  - Available from OpenWrt packages feed

- **luci-app-qosify**: Modern QoS web interface
  - CAKE/eBPF traffic shaping daemon
  - Replaces custom QoS UI with upstream solution
  - Available from OpenWrt LuCI feed

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
- tc-full: Traffic control utility
- tcfilter: Persistent tc filters (upstream)

## Limitations

- Basic implementation with simple bandwidth limiting
- No advanced traffic classification yet
- No priority queues yet
- Cake scheduler may not be available on all platforms

## Future Enhancements

- Advanced traffic classification
- Priority queues
- Per-application policies
- Full integration with qosify for eBPF-based shaping
- Hardware offload support via tcfilter
