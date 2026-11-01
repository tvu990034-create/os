# router-net

Optional RouterOS networking extension package.

## Current responsibilities

- Depends on the router-dsa-sdk headers and router-dsa-runtime plugin test runner.
- Provides a lightweight, opt-in interface-state observer managed by procd.
- Keeps monitoring read-only: it never invokes ifup, ifdown, or rewrites UCI settings.

## Enable the observer

The observer is disabled by default. To enable it on a running device:

    uci set router-net.monitor.enabled='1'
    uci set router-net.monitor.interval='10'
    uci commit router-net
    /etc/init.d/router-net enable
    /etc/init.d/router-net restart

The interval is configurable from 1 to 300 seconds with router-net.monitor.interval.

## Algorithm development

Implementations target /usr/include/router-os/dsa.h and can be checked offline with router-dsa-run. The current runner loads a trusted shared object and invokes its callback using synthetic packet metadata. It does not execute algorithms in the live packet-forwarding path. See the router-dsa-sdk and router-dsa-runtime documentation for ABI and runtime limits.
