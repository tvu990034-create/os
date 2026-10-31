# RouterOS platform support

## Portability contract

RouterOS is one product and one custom package set built on OpenWrt/Linux. It is
not one firmware binary that can be flashed onto every router. Each device still
needs a matching OpenWrt target, subtarget, device profile, boot flow, storage
layout and supported drivers.

The portable part is the RouterOS user-space code, management experience,
configuration model and future algorithm interfaces. The platform-specific
parts are supplied by OpenWrt and the device integration profile: kernel,
device tree, bootloader/image format, Ethernet and switch drivers, Wi-Fi drivers,
flash layout and hardware-specific network defaults.

A device is not supported merely because its CPU architecture is supported.
Support requires a successful build and boot plus checks for its actual NICs,
switch ports, storage, wireless devices (when present), LAN/WAN mapping and
recovery path.

## Registered development profiles

The source of truth is config/platforms.tsv. The profile registry maps a stable
RouterOS profile name to an OpenWrt target/subtarget and a tracked config.

| RouterOS profile | OpenWrt target | Status | Intended scope |
|---|---|---|---|
| x86_64 | x86/64 | Development | Generic x86-64 PC and virtual-machine image |
| armsr_armv8 | armsr/armv8 | Experimental | Generic ARMv8 EFI image for compatible Arm SystemReady platforms and QEMU |

The ARMv8 profile is based on OpenWrt's generic ARM SystemReady target. It is
not a generic image for every ARM router, Raspberry Pi board or embedded SoC.
Those require their own OpenWrt device target/profile and hardware validation.

Neither status is a production certification. The x86-64 profile is the
current development baseline. ARMv8 is an additional build profile whose
package compilation, boot and network behavior must be verified independently.

## Build commands

Install the host tools once on Ubuntu/WSL2:

    ./scripts/install-build-deps-ubuntu.sh

Build the x86-64 development profile:

    JOBS=1 ./scripts/build-platform.sh x86_64

Build the experimental generic ARMv8 EFI profile:

    JOBS=1 ./scripts/build-platform.sh armsr_armv8

JOBS=1 minimizes memory pressure on small machines. The default is two jobs.
The OpenWrt checkout, downloaded sources and build outputs are kept under the
ignored openwrt/ directory, so an interrupted build can be resumed without
re-cloning the whole RouterOS repository. make download and later builds reuse
already downloaded source archives.

The build command always starts from the tracked profile configuration. If an
OpenWrt .config already exists, the script preserves its first version as
.config.routeros-original before replacing the active profile config. This
prevents accidentally mixing target settings from different builds.

## Adding a router device

1. Confirm that the device is supported by the pinned OpenWrt release and
   identify its exact target, subtarget and device profile.
2. Add a device-specific configuration under config/ and a row in
   config/platforms.tsv.
3. Do not reuse the ARMv8 generic profile for an unrelated board just because
   both use ARM64. A board-specific image needs the correct OpenWrt device
   selector and packages.
4. Check the build in the matching OpenWrt SDK or full build system.
5. Boot the resulting image in QEMU where appropriate, then on the actual
   device. Verify interfaces, switch/DSA ports, Wi-Fi, DHCP, IPv4/IPv6,
   firewall behavior, reboot persistence and recovery before marking it
   supported.

The first-boot network defaults must not assume that all devices expose the
same Ethernet names or port topology. Board-generated OpenWrt network
configuration must be preserved; only generic targets without a board network
profile may use the RouterOS fallback layout. Device-specific board integration
remains a foundation acceptance item before broad embedded-router support.

## Validation

Run:

    python3 scripts/validate-platforms.py
    ./validate-packages.sh

GitHub Actions compiles the custom package feed against the pinned x86-64 and
ARMv8 SDKs. SDK package compilation does not replace full-image builds or boot
and physical-device tests. Current acceptance evidence is tracked in
FOUNDATION_STATUS.md.
