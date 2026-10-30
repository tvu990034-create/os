# RouterOS

A custom router operating system built on OpenWrt and the Linux kernel. The first hardware target is generic x86-64, including the planned Dell OptiPlex 3050 platform.

## Current baseline

- OpenWrt source is pinned to **v25.12.6** by default.
- RouterOS packages are maintained in `custom-feed/` and remain separate from upstream OpenWrt source.
- The x86-64 build profile includes `router-core`, `router-net`, `router-dsa-sdk` and `router-dsa-runtime`.
- The DSA SDK defines a versioned C plugin ABI. The runtime can load a trusted plugin and execute it against synthetic packet metadata for algorithm development and offline testing.
- **The DSA runtime is not a live packet dataplane.** It does not yet intercept or steer forwarded traffic.

Older PHASE and FINAL reports are historical snapshots. Use FOUNDATION_STATUS.md for the current acceptance checklist and verification status.

## Quick start (Ubuntu / WSL2)

Run the following from a Linux filesystem path (for example, ~/src), not from /mnt/c:

    git clone https://github.com/tvu990034-create/os.git
    cd os
    ./scripts/install-build-deps-ubuntu.sh
    ./setup.sh
    JOBS=2 ./scripts/build-x86_64.sh

setup.sh clones OpenWrt v25.12.6 into the ignored openwrt/ directory when it is absent. It creates OpenWrt's active feeds.conf and syncs the tracked RouterOS configuration into openwrt/files/. The sync is hash-tracked and refuses to overwrite local edits.

## Repository layout

- custom-feed/router-core: first-boot network configuration, hardware inventory and startup diagnostics.
- custom-feed/router-net: optional, read-only interface observer and DSA runtime dependency.
- custom-feed/router-dsa-sdk: versioned C ABI header installed at /usr/include/router-os/dsa.h.
- custom-feed/router-dsa-runtime: router-dsa-run plugin loader/test runner.
- custom-feed/router-tests: optional on-device smoke tests.
- custom-feed/router-ui: read-only LuCI dashboard under Status -> RouterOS.
- custom/configs: generic, x86 and ARM network templates.
- config/x86_64.config: reference build configuration.
- scripts/: build and validation scripts.
- tests/dsa-sdk/: host-side plugin ABI smoke test.

## Network defaults

On first boot, router-core discovers physical wired interfaces. The first detected wired NIC is assigned to LAN; when a second is present, it becomes WAN; additional detected wired NICs join LAN. A single-NIC system receives LAN only and does not get a fictitious WAN interface. The default LAN address is 192.168.1.1/24.

Connect a management computer to the LAN-side port and set a root password on first console login before enabling remote administration. Do not connect an unconfigured WAN uplink to the LAN port.

## Validation

Run source validation on a Linux development host:

    ./validate-packages.sh

For on-device tests, build with router-tests selected and run:

    /usr/libexec/router-tests/test-config-syntax.sh
    /usr/libexec/router-tests/test-hardware-detect.sh
    /usr/libexec/router-tests/test-network-validation.sh

GitHub Actions also validates shell/UCI syntax, exercises the DSA plugin ABI and compiles the custom packages against the pinned OpenWrt x86-64 SDK.

## DSA development boundary

Algorithm authors can now implement a shared object against router-os/dsa.h, choose a classify/route/schedule/observe stage and execute the plugin offline using router-dsa-run. Only trusted shared objects should be loaded. A future dataplane adapter is still required before algorithm outputs can affect live forwarding or performance benchmarks.
