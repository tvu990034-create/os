# Adding a Package to RouterOS

This guide explains how to create a new OpenWrt package for RouterOS.

## Package Structure

A RouterOS package follows the standard OpenWrt package structure:

```
custom-feed/<package-name>/
├── Makefile              # Package build definition
├── README.md             # Package documentation
└── files/                # Files to install
    ├── libexec/          # Executable utilities
    ├── etc/              # Configuration files
    ├── etc/init.d/       # Init scripts
    └── etc/uci-defaults/ # First-boot configuration
```

## Step 1: Create Package Directory

```bash
mkdir -p custom-feed/my-package/files/libexec
```

## Step 2: Create Makefile

Create `custom-feed/my-package/Makefile`:

```makefile
#
# RouterOS my-package package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=my-package
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/my-package
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=My Package Title
  DEPENDS:=+uci
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/my-package/description
 Description of what this package does.
endef

define Build/Compile
endef

define Package/my-package/install
	$(INSTALL_DIR) $(1)/usr/libexec/my-package
	$(INSTALL_BIN) ./files/libexec/my-script $(1)/usr/libexec/my-package/my-script
endef

$(eval $(call BuildPackage,my-package))
```

## Step 3: Create Package Files

Create executable scripts in `files/`:

```bash
touch custom-feed/my-package/files/libexec/my-script
chmod +x custom-feed/my-package/files/libexec/my-script
```

Add implementation to the script.

## Step 4: Create README

Create `custom-feed/my-package/README.md`:

```markdown
# My Package

## Overview
Description of the package.

## Components
List of utilities and their purposes.

## Usage
Example commands.

## Dependencies
List of required packages.

## Status
Implementation status and future work.
```

## Step 5: Add to Configuration

Add the package to relevant configuration files:

### For Firmware Images
Edit `config/x86_64.config`:
```
CONFIG_PACKAGE_my-package=y
```

### For SDK Builds
Edit `config/sdk-package-build.config`:
```
CONFIG_PACKAGE_my-package=y
```

## Step 6: Update Validation

Update `validate-packages.sh` to check the new package:

```bash
for package in router-core my-package router-net; do
```

Update `scripts/validate-package-files.sh` to verify files exist:

```bash
# Check my-package files
MY_FILES="
custom-feed/my-package/files/libexec/my-script
"

for file in $MY_FILES; do
	if [ -f "$ROOT_DIR/$file" ]; then
		pass "my-package: $file"
	else
		fail "my-package missing: $file"
	fi
done
```

## Step 7: Test Locally

```bash
# Validate source
./validate-packages.sh

# Build package against SDK
# (requires SDK setup)
make package/feeds/routeros/my-package/compile

# Build full firmware
./scripts/build-platform.sh x86_64
```

## Step 8: Commit and Push

```bash
git add custom-feed/my-package
git add config/x86_64.config
git add validate-packages.sh
git add scripts/validate-package-files.sh
git commit -m "Add my-package package"
git push origin foundation/ready-for-dsa
```

## Package Conventions

### Dependencies

List all required OpenWrt packages in `DEPENDS`:
- `+uci`: Configuration management
- `+procd`: Process manager
- `+firewall4`: Firewall
- `+ip-full`: Full networking tools

### Installation Paths

- Executables: `/usr/libexec/<package>/`
- Configuration: `/etc/config/`
- Init scripts: `/etc/init.d/`
- UCI defaults: `/etc/uci-defaults/`

### Naming

- Package names: lowercase with hyphens: `router-firewall`
- Executables: descriptive: `router-firewall-validate`
- Configuration: match package name

### Shell Scripts

- Use `#!/bin/sh` for POSIX compatibility
- Use `set -eu` for error handling
- Use BusyBox-compatible commands
- Add proper logging with `logger -t`

### UCI Integration

- Use `uci` command for configuration
- Preserve board-generated config
- Avoid hardcoded values

## Example: Simple Utility Package

See `router-firewall`, `router-routing`, `router-monitor`, or `router-device` for complete examples.

## Troubleshooting

### Package Not Found in Feed

Ensure the package is in `custom-feed/` and the feed is registered in `feeds.conf`.

### Build Fails

Check:
- Makefile syntax
- File paths in install section
- Dependencies are correct
- Files exist and have correct permissions

### Files Not Installed

Verify:
- Install directory is created with `$(INSTALL_DIR)`
- Files are installed with `$(INSTALL_BIN)` or `$(INSTALL_CONF)`
- Paths are correct relative to `$(1)`

## Platform-Specific Packages

For platform-specific packages, use conditional defaults:

```makefile
DEFAULT:=y if TARGET_x86
```

This only installs the package on x86 targets.
