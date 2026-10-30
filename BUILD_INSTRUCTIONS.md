# RouterOS Build Instructions

## Target and upstream version

The reference target is OpenWrt x86/64 generic, pinned to OpenWrt v25.12.6. The same package feed is structured to remain architecture-neutral, but x86/64 is the first build target.

## Host environment

Use Ubuntu 24.04, native Linux, or Ubuntu under WSL2. Keep the source tree inside the Linux filesystem (for example, ~/src/os). OpenWrt requires a case-sensitive filesystem and a full Linux build toolchain.

Install the required host packages:

    ./scripts/install-build-deps-ubuntu.sh

## Prepare source and feeds

    ./setup.sh

The setup script clones the pinned OpenWrt tag when openwrt/ is absent. If an existing OpenWrt checkout is at a different revision, setup stops without resetting it. Check out v25.12.6 manually and rerun setup.sh. It also syncs the four tracked RouterOS defaults from custom/overlay/etc/config/ into openwrt/files/etc/config/ using a SHA-256 manifest; changes in the local OpenWrt overlay are preserved and cause setup to stop rather than overwrite them.

The script creates openwrt/feeds.conf with:

    src-include defaults feeds.conf.default
    src-link routeros /absolute/path/to/os/custom-feed

This is intentional: OpenWrt's feeds utility reads feeds.conf (or feeds.conf.default when feeds.conf is absent); feeds.conf.local is not the active feeds configuration.

## Build x86-64 firmware

    JOBS=2 ./scripts/build-x86_64.sh

The build script updates the pinned release feeds, installs available packages, applies config/x86_64.config when no local .config exists, runs make defconfig, downloads sources and builds the image. The reference profile includes the standard LuCI web interface and the RouterOS read-only Status -> RouterOS dashboard.

You can change JOBS to suit available memory. If a .config already exists, the script preserves it; edit it with make menuconfig rather than deleting it blindly.

Expected output directory:

    openwrt/bin/targets/x86/64/

The release's standard generic x86-64 image is an ext4 or squashfs combined image. Use the exact filename produced by the selected configuration.

## Include the on-device test package

router-tests is optional. From openwrt/ after feeds have been installed:

    ./scripts/feeds install router-tests
    make menuconfig

Select Utilities -> router-tests, save the configuration, then run make -j2.

## Boot in QEMU

Install qemu-system-x86 and use the ext4 combined image produced by the build. For example:

    gunzip -k openwrt/bin/targets/x86/64/openwrt-25.12.6-x86-64-generic-ext4-combined.img.gz
    qemu-system-x86_64 -m 1024 -smp 2 -nographic \
      -drive file=openwrt/bin/targets/x86/64/openwrt-25.12.6-x86-64-generic-ext4-combined.img,format=raw \
      -netdev user,id=net0 -device e1000,netdev=net0

Use the serial console for first boot. Set a root password before enabling remote administration. A one-NIC QEMU instance is configured as LAN only by design.

## Package SDK validation

The GitHub Actions SDK job uses `config/sdk-package-build.config`, a deliberately minimal x86-64 selection that compiles each RouterOS feed package and its declared dependencies. It is separate from `config/x86_64.config`, which selects the full firmware image and LuCI management stack.

## DSA plugin development

The router-dsa-sdk package installs /usr/include/router-os/dsa.h. A plugin exports router_dsa_get_algorithm_v1() and implements the lifecycle callbacks in the ABI descriptor.

The router-dsa-runtime package supplies:

    router-dsa-run /path/to/plugin.so [ingress-ifindex] [packet-length] [ip-version] [ip-protocol]

The runner invokes the plugin once with synthetic metadata and prints its decision. It is intended for deterministic algorithm development and smoke testing. It is not a live packet capture, forwarding, routing or scheduling dataplane.

Host-side ABI smoke test:

    ./tests/dsa-sdk/test-plugin.sh

## On-device smoke tests

When router-tests is installed:

    /usr/libexec/router-tests/test-config-syntax.sh
    /usr/libexec/router-tests/test-hardware-detect.sh
    /usr/libexec/router-tests/test-network-validation.sh

## Validation boundaries

A successful package SDK build proves that custom package definitions compile against the pinned OpenWrt toolchain. It does not prove that the full image boots, that physical NIC assignments match every chassis, or that throughput/latency targets are met. Those require image boot and hardware testing.
