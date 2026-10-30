# Build environment

RouterOS currently targets OpenWrt x86/64 generic first.

## Pinned upstream

The default build pins OpenWrt v25.12.6. This keeps the base system and package feeds aligned with a known stable release.

## Supported developer setup

Use Ubuntu 24.04, native Linux, or Ubuntu under WSL2. Keep the checkout and build directory on the Linux filesystem (for example, under ~/src), not on a Windows-mounted /mnt/c path.

Install host dependencies:

    ./scripts/install-build-deps-ubuntu.sh

Prepare the upstream checkout and custom feed:

    ./setup.sh

## Build

    JOBS=2 ./scripts/build-x86_64.sh

Set JOBS=1 or JOBS=2 on machines with limited memory. Build output is written under openwrt/bin/targets/x86/64/.

## Validation boundary

Repository validation and the SDK package-build workflow validate the custom source and package integration. A complete firmware image still needs to be booted and exercised on QEMU or supported hardware before calling the OS runtime validated.
