# RouterOS platform support

## Portability contract

RouterOS is one product and one custom package set built on OpenWrt/Linux. It is
not one firmware binary that can be flashed onto every router. Each device needs
a matching OpenWrt target, subtarget, device profile, boot flow, storage layout,
kernel drivers and board integration.

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
current generic PC/VM development baseline. ARMv8 is an additional experimental
build profile; its package compilation, boot and network behavior must be
verified independently.

## Board-aware first boot

RouterOS deliberately does not ship a static network or system file through
the shared rootfs overlay. OpenWrt's first-boot config generation uses the
selected board's board.json and board.d scripts to produce the initial
/etc/config/network and /etc/config/system. Replacing those files in a shared
overlay can suppress that process and destroy important port/VLAN/switch
topology for an embedded router.

The shared overlay therefore contains only service defaults that do not define
physical port topology (currently DHCP and firewall). RouterOS first-boot
defaults preserve the generated interfaces and switch topology. They brand
only untouched OpenWrt hostname/timezone defaults. Any explicitly selected
RouterOS generic network template remains a separate opt-in compatibility
path; it is not installed by the normal build.

Files under custom/configs/*/network.conf are reference templates only. They
are not deployed by setup.sh or build-platform.sh.

## Build commands

Install the host tools once on Ubuntu/WSL2:

    ./scripts/install-build-deps-ubuntu.sh

Build the x86-64 development profile:

    JOBS=1 ./scripts/build-platform.sh x86_64

Build the experimental generic ARMv8 EFI profile:

    JOBS=1 ./scripts/build-platform.sh armsr_armv8

JOBS=1 minimizes memory pressure on small machines. The default is two jobs.
The OpenWrt checkout, downloaded sources and build outputs are kept under the
ignored openwrt/ directory, so an interrupted download/build can be resumed.
make download and subsequent builds reuse already downloaded source archives.

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

Board-generated configurations take precedence over RouterOS generic
templates. Any new target must pass a check proving that LAN/WAN interface
names, switch VLANs and board port topology are preserved.

## Validation

Run:

    python3 scripts/validate-platforms.py
    ./validate-packages.sh

GitHub Actions compiles the custom package feed against the pinned x86-64 and
ARMv8 SDKs. SDK package compilation does not replace full-image builds, QEMU
boots or physical-device tests. Current acceptance evidence is tracked in
FOUNDATION_STATUS.md.
