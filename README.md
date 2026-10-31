# RouterOS

A portable, multi-platform router operating system built on OpenWrt and the
Linux kernel. RouterOS is designed to share one custom user-space and package
set across multiple hardware families while using the correct OpenWrt target,
device profile, drivers and firmware image for each supported device.

This is not one universal firmware image for every router. CPU architecture
alone is not enough: bootloader, device tree, Ethernet/switch drivers, Wi-Fi,
flash layout and board network configuration must also match. See
docs/PLATFORM_SUPPORT.md before treating a device as supported.

## Current baseline

- OpenWrt source is pinned to v25.12.6 by default.
- RouterOS packages are maintained in custom-feed/, separate from upstream
  OpenWrt source.
- The x86_64 profile is the current generic PC/VM development baseline.
- The armsr_armv8 profile is experimental and produces a generic ARMv8 EFI
  image for compatible Arm SystemReady platforms and QEMU. It is not a profile
  for every ARM router or single-board computer.
- The DSA SDK defines a versioned C plugin ABI. The runtime can load a trusted
  plugin and execute it against synthetic packet metadata. The example under
  examples/dsa/ is for ABI testing only; the runtime is not a live packet
  dataplane.

Use FOUNDATION_STATUS.md for the current acceptance checklist and verification
status. Older PHASE and FINAL reports are historical snapshots.

## Quick start (Ubuntu / WSL2)

Work from a Linux filesystem path (for example, ~/src), not from /mnt/c, to
avoid cross-filesystem build overhead:

    git clone https://github.com/tvu990034-create/os.git
    cd os
    ./scripts/install-build-deps-ubuntu.sh
    ./validate-packages.sh
    ./setup.sh
    JOBS=1 ./scripts/build-platform.sh x86_64

Use JOBS=1 on a memory-constrained laptop. Increase it only when the host has
enough RAM and cooling capacity. The default is two parallel jobs.

To build the experimental ARMv8 generic EFI profile instead:

    JOBS=1 ./scripts/build-platform.sh armsr_armv8

The first build fetches the pinned OpenWrt source, feeds and package source
archives. Keep the ignored openwrt/ directory between attempts: interrupted
downloads and builds can be resumed. The build script preserves the first
pre-existing OpenWrt .config as .config.routeros-original and applies the
tracked profile config on every run to avoid accidental target mixing.

## Repository layout

- custom-feed/router-core: first-boot defaults, hardware inventory and
  startup diagnostics.
- custom-feed/router-net: optional read-only interface observer and DSA
  runtime dependency.
- custom-feed/router-dsa-sdk: versioned C ABI header for user-written
  algorithm plugins.
- custom-feed/router-dsa-runtime: trusted plugin loader and offline test
  runner; it does not process forwarded packets.
- custom-feed/router-tests: optional on-device smoke tests.
- custom-feed/router-ui: read-only LuCI system/network dashboard.
- custom/overlay: common root filesystem configuration overlay.
- config/platforms.tsv: registered OpenWrt targets and tracked profiles.
- config/: full firmware and SDK package-build configurations.
- scripts/build-platform.sh: common build entry point for registered profiles.
- tests/: host-side regression tests.

## Default network behavior

On the generic profile, router-core discovers physical wired interfaces on
first boot. The first detected wired NIC is assigned to LAN; when a second is
present, it becomes WAN; additional detected wired NICs join LAN. A
single-NIC system receives LAN only. Board-specific router layouts must retain
their OpenWrt-generated network configuration and must be validated per device.

Connect a management computer to the configured LAN-side port. Set a root
password on the local console before enabling remote administration. Do not
assume a board's physical port order without checking its device profile.

## Validation

Run source and profile validation on a Linux development host:

    ./validate-packages.sh
    python3 scripts/validate-platforms.py

For on-device tests, build with router-tests selected and run:

    /usr/libexec/router-tests/test-config-syntax.sh
    /usr/libexec/router-tests/test-hardware-detect.sh
    /usr/libexec/router-tests/test-network-validation.sh

GitHub Actions validates shell/UCI/UI metadata, exercises the offline DSA
plugin ABI and compiles custom packages against the pinned x86-64 and ARMv8
SDKs. Full firmware builds, QEMU boot tests and physical hardware tests are
separate acceptance gates; a successful package build alone does not certify a
router.

## DSA development boundary

You can write algorithm modules against router-os/dsa.h and test them
offline with router-dsa-run. Only trusted shared objects should be loaded.
The current runtime passes synthetic metadata to plugins; a separate dataplane
adapter and live forwarding tests are still required before plugin decisions
can affect traffic or be described as router performance improvements.
