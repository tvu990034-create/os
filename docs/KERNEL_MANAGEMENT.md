# Linux Kernel Management

## OpenWrt Kernel Integration

OpenWrt manages its own Linux kernel source independently of any standalone kernel repository. This document explains how OpenWrt handles the kernel and why the standalone `linux/` repository is a reference only.

## Kernel Version

**Current OpenWrt Kernel**: 6.18.55

**Definition Location**: `openwrt/target/linux/generic/kernel-6.18`

**Content**:
```
LINUX_VERSION-6.18 = .55
LINUX_KERNEL_HASH-6.18.55 = f410638061a165c12f42ab871d2f3fcd525515359b5faeee80969cff84524df9
```

## Kernel Source Acquisition

OpenWrt obtains the kernel source through its build system:

1. **Download**: The OpenWrt build system downloads the kernel source from official Linux kernel mirrors based on the version specified in `kernel-6.18`.

2. **Patches**: OpenWrt applies patches from:
   - `openwrt/target/linux/generic/` - Generic patches for all architectures
   - `openwrt/target/linux/<arch>/patches-<ver>/` - Architecture-specific patches

3. **Configuration**: Kernel configuration is generated from:
   - `openwrt/target/linux/generic/config-6.18` - Generic configuration
   - `openwrt/target/linux/<arch>/config-<ver>` - Architecture-specific configuration

## Standalone Linux Repository

The `linux/` directory in the Router OS project is a **reference repository only** and is **NOT used** in the OpenWrt build.

### Purpose

- Reference for understanding kernel internals
- Reference for future kernel development work
- Reference for upstream kernel changes
- **NOT** for building the Router OS image

### Why It's Not Integrated

1. **Version Mismatch**: The standalone `linux/` repository tracks the upstream Linux kernel (torvalds/linux), which is at a different version than OpenWrt's kernel (6.18.55).

2. **Patch Conflicts**: OpenWrt applies specific patches to its kernel. Using a different kernel version would cause patch conflicts.

3. **Build System**: OpenWrt's build system expects to download and patch the kernel itself. Integrating a separate kernel source would require modifying OpenWrt's build system.

4. **Maintenance**: Keeping a second kernel tree synchronized with OpenWrt's patches would be complex and error-prone.

## Modifying the Kernel

If you need to modify the kernel for Router OS:

### Option 1: Use OpenWrt's Kernel Patch System (Recommended)

1. Create a patch file in `openwrt/target/linux/generic/patches-6.18/` or `openwrt/target/linux/<arch>/patches-6.18/`
2. Follow OpenWrt patch naming conventions
3. The patch will be applied automatically during the build

### Option 2: Modify Kernel Configuration

1. Edit `openwrt/target/linux/generic/config-6.18` for generic options
2. Edit `openwrt/target/linux/<arch>/config-6.18` for architecture-specific options
3. Rebuild the kernel

### Option 3: Use OpenWrt's Kernel Tree

OpenWrt maintains its own kernel tree at https://github.com/openwrt/linux.git. This tree includes OpenWrt-specific patches and modifications. However, even this is managed by OpenWrt's build system, not by Router OS directly.

## Recommended Workflow

For Router OS development:

1. **Do NOT modify the standalone `linux/` repository** - it's for reference only
2. **Use OpenWrt's patch system** for kernel modifications
3. **Use OpenWrt's config files** for kernel configuration
4. **Let OpenWrt download the kernel** during the build process

## Verification

To verify the kernel version used by OpenWrt:

```bash
cd openwrt
cat target/linux/generic/kernel-6.18
```

To see kernel patches:

```bash
cd openwrt
ls target/linux/generic/patches-6.18/
ls target/linux/x86/patches-6.18/
```

To see kernel configuration:

```bash
cd openwrt
cat target/linux/generic/config-6.18
```

## Summary

- OpenWrt uses kernel 6.18.55
- OpenWrt downloads, patches, and configures the kernel automatically
- The standalone `linux/` repository is for reference only
- Kernel modifications should use OpenWrt's patch system
- Do not integrate a second kernel source into the build
