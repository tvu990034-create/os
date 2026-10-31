# RouterOS Routing Management

## Overview

The `router-routing` package provides routing configuration and diagnostics utilities for RouterOS.

## Components

### router-routing-status
Shows routing information:
- Routing table
- Default route
- Interface-specific routes

### router-routing-diagnostics
Provides routing diagnostics:
- Connectivity tests
- Route lookup
- DNS resolution tests

## Usage

### Show routing table
```sh
/usr/libexec/router-routing/router-routing-status table
```

### Show default route
```sh
/usr/libexec/router-routing/router-routing-status default
```

### Show interface routes
```sh
/usr/libexec/router-routing/router-routing-status interfaces
```

### Test connectivity
```sh
/usr/libexec/router-routing/router-routing-diagnostics ping 8.8.8.8
```

### Show route to host
```sh
/usr/libexec/router-routing/router-routing-diagnostics route-to 8.8.8.8
```

### Test DNS resolution
```sh
/usr/libexec/router-routing/router-routing-diagnostics dns www.google.com
```

## Dependencies

- uci: Configuration management
- ip-full: Full iproute2 utilities

## Status

Basic implementation. Future enhancements:
- Static route management
- Route policy configuration
- Integration with LuCI
