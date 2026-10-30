# Architecture Technical Corrections

> Current note (2026-10-30): The older notes below include an incorrect reference to feeds.conf.local. OpenWrt's scripts/feeds reads feeds.conf when present, otherwise feeds.conf.default. The current setup therefore writes feeds.conf, includes feeds.conf.default and appends the RouterOS src-link entry. See FOUNDATION_STATUS.md and custom/docs/FEED_VALIDATION.md for the maintained workflow.

## Issues Identified and Corrected

### 1. Directory Structure Correction

**Original Issue:**
- Proposed custom/ as a sibling to openwrt/
- Suggested using OpenWrt as a submodule
- Created separate feeds/ directory structure

**Problem:**
- OpenWrt build system expects to run from openwrt/ directory
- Feed integration expects packages to be external to the build directory
- Submodule approach would complicate local development with existing repos
- Directory structure did not align with OpenWrt's feed mechanism

**Correction:**
- Build work happens inside openwrt/ directory (TOPDIR)
- Custom package feed lives in custom-feed/ at the repository root
- The current setup script keeps custom/ as tracked templates and documentation
- No submodules are used

### 2. Feed Configuration Correction

**Original Issue:**
- Proposed local feed entries using feeds.conf.local

**Correction:**
- The current setup creates openwrt/feeds.conf
- feeds.conf uses src-include defaults feeds.conf.default to retain the pinned upstream package feeds
- A `src-link routeros /absolute/path/to/custom-feed` entry registers the RouterOS custom-feed directory; the feed identifier uses letters only because OpenWrt feed names are parsed as word characters
- Existing user-created feeds.conf files are preserved; setup stops and tells the user how to add the custom feed instead of overwriting them

### 3. Component Dependencies Clarification

- iproute2 utilities are upstream OpenWrt packages, not a direct dependency of the build system.
- The router-tests package uses ip-full at runtime.
- router-net depends on router-dsa-runtime; the latter depends on the header-only router-dsa-sdk.

### 4. Kernel and dataplane scope

- OpenWrt's build system selects and patches its own kernel; the separate linux/ clone is not used as the build kernel.
- No custom kernel patch, XDP/eBPF or DPDK code is required for the current foundation.
- The DSA ABI and offline plugin runner are user-space development tools. They do not intercept live packets.

## Compatibility considerations

- Feed paths are absolute in the generated feeds.conf to avoid ambiguity about the working directory.
- The current build baseline is OpenWrt v25.12.6 x86/64.
- Source validation checks shell syntax, UCI configuration syntax and a host-side DSA plugin lifecycle.
- The pinned SDK workflow checks that custom package definitions integrate with the corresponding OpenWrt toolchain.
