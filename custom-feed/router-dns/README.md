# RouterOS DNS Management

## Overview

The `router-dns` package provides DNS configuration and diagnostics, integrating with OpenWrt dnsmasq.

## Components

### router-dns-validate
Validates DNS configuration:
- dnsmasq status
- DNS server IP validation
- Domain name validation

### router-dns-status
Shows DNS status:
- DNS servers
- DNS cache
- Local domains
- DNS resolution tests

## Usage

### Check dnsmasq
```sh
/usr/libexec/router-dns/router-dns-validate dnsmasq
```

### Show DNS servers
```sh
/usr/libexec/router-dns/router-dns-status servers
```

### Test DNS resolution
```sh
/usr/libexec/router-dns/router-dns-status test www.google.com
```

## Dependencies

- uci: Configuration management
- dnsmasq: DNS forwarder

## Status

Basic implementation using dnsmasq. Future: LuCI integration.
