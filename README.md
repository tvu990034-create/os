# RouterOS

A portable, multi-platform router operating system built on OpenWrt and the
Linux kernel. RouterOS shares one custom user-space and package set across
hardware families while using the correct OpenWrt target, device profile,
drivers and firmware image for each supported device.

This is not one universal firmware image for every router. CPU architecture
alone is not enough: bootloader, device tree, Ethernet/switch drivers, Wi-Fi,
flash layout and board network configuration must also match. See
docs/PLATFORM_SUPPORT.md before treating a device as supported.

## Current status

**Priority: Complete the router operating system**

The current objective is to build a complete, functional router operating system that can boot, configure, and route traffic. DSA algorithm development is deferred until the router OS is fully validated.

## Current baseline

- OpenWrt source is pinned to v25.12.6 by default.
- RouterOS packages are maintained in custom-feed/, separate from upstream
  OpenWrt source.
- x86_64 is the current generic PC/VM development profile.
- armsr_armv8 is experimental and produces a generic ARMv8 EFI image for
  compatible Arm SystemReady platforms and QEMU. It is not a profile for every
  ARM router or single-board computer.
- Shared rootfs overlays do not replace board-generated network or system
  configuration.

## What is complete

- ✅ Source management and platform architecture
- ✅ RouterOS packages (router-core, router-net, router-ui, router-tests)
- ✅ Build scripts and configuration
- ✅ First-boot network configuration logic
- ✅ Service overlays (DHCP, firewall)
- ✅ LuCI management interface
- ✅ CI for package compilation

## What is NOT complete

- ⚠️ Full firmware image has not been built
- ⚠️ Firmware has not been booted in QEMU
- ⚠️ Networking has not been tested
- ⚠️ Physical hardware has not been tested
- ⚠️ DSA algorithm framework is future work

## Quick start (Ubuntu / WSL2)

Work from a Linux filesystem path (for example, ~/src), not from /mnt/c:

    git clone https://github.com/tvu990034-create/os.git
    cd os
    ./scripts/install-build-deps-ubuntu.sh
    ./validate-packages.sh
    ./setup.sh
    JOBS=1 ./scripts/build-platform.sh x86_64

Use JOBS=1 on a memory-constrained laptop. Increase it only when the host has
enough RAM and cooling capacity. The default is two parallel jobs.

To build the experimental ARMv8 generic EFI profile:

    JOBS=1 ./scripts/build-platform.sh armsr_armv8

The first build fetches pinned OpenWrt sources, feeds and package archives.
Keep the ignored openwrt/ directory between attempts: interrupted downloads
and builds can be resumed. The build script preserves the original OpenWrt
.config once and reapplies the selected tracked profile on each run.

## Repository layout

- custom-feed/router-core: first-boot defaults, hardware inventory and
  startup diagnostics.
- custom-feed/router-net: optional read-only interface observer.
- custom-feed/router-dsa-sdk: versioned C ABI header for user-written plugins.
- custom-feed/router-dsa-runtime: trusted plugin loader and offline test runner.
- custom-feed/router-tests: optional on-device smoke tests.
- custom-feed/router-ui: read-only LuCI system/network dashboard.
- custom/overlay: shared DHCP and firewall service defaults only.
- config/platforms.tsv: registered OpenWrt targets and tracked profiles.
- config/: firmware and SDK package-build configurations.
- scripts/build-platform.sh: common build entry point for registered profiles.
- tests/: host-side regression tests.

## First-boot behavior

OpenWrt generates network and system configuration from each selected board's
metadata and board.d scripts. RouterOS preserves that generated configuration,
including board-specific Ethernet names, switch ports and VLAN topology.

For the generic x86-64 and ARMv8 profiles, the actual generated defaults still
need boot testing. Do not assume the first physical port is LAN or that the
second is WAN without checking the target's generated UCI configuration.

Connect through the documented management interface for the selected board.
Set a root password on the local console before enabling remote administration.

## Validation

Run source and platform validation on a Linux development host:

    ./validate-packages.sh
    python3 scripts/validate-platforms.py

For on-device tests, build with router-tests selected and run:

    /usr/libexec/router-tests/test-config-syntax.sh
    /usr/libexec/router-tests/test-hardware-detect.sh
    /usr/libexec/router-tests/test-network-validation.sh

GitHub Actions validates shell/UCI/UI metadata and compiles the custom packages
against the pinned x86-64 and ARMv8 SDKs. Full firmware builds, QEMU boots and
physical hardware tests are required before the router OS can be considered
complete.
