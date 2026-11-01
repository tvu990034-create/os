# RouterOS Development Guide

## Prerequisites

- Linux development environment (Ubuntu 24.04 recommended)
- Git
- OpenWrt build dependencies (see `scripts/install-build-deps-ubuntu.sh`)
- Python 3 (for validation scripts)
- Node.js (for LuCI JavaScript validation)

## Repository Structure

See `docs/architecture/REPOSITORY_ARCHITECTURE.md` for the complete repository structure.

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/tvu990034-create/os.git
cd os
```

2. Install build dependencies:
```bash
./scripts/install-build-deps-ubuntu.sh
```

3. Validate the source:
```bash
./validate-packages.sh
```

4. Setup OpenWrt build tree:
```bash
./setup.sh
```

**For Windows/WSL users with external source repositories:**

If you have downloaded upstream source repositories on Windows (e.g., `F:\router-os-source\`), you can configure RouterOS to use them from WSL:

```bash
# In WSL, set the source root to the Windows drive mount point
export ROUTEROS_SOURCE_ROOT=/mnt/f/router-os-source
./setup.sh
```

This will configure local feeds to use the Windows repositories while keeping the RouterOS code in the WSL filesystem.

5. Build firmware for a platform:
```bash
JOBS=2 ./scripts/build-platform.sh x86_64
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/my-feature
```

### 2. Make Changes

- Edit files in appropriate directories
- Follow existing code style and conventions
- Add tests for new functionality
- Update documentation as needed

### 3. Validate Locally

```bash
./validate-packages.sh
```

### 4. Test Changes

- Run host-side tests
- Build SDK packages if relevant
- Build firmware if relevant
- Test in QEMU if applicable

### 5. Commit Changes

```bash
git add -A
git commit -m "Descriptive commit message"
```

### 6. Push and Create PR

```bash
git push origin feature/my-feature
```

Create a pull request to `foundation/ready-for-dsa`.

## Package Development

See `docs/development/ADDING_A_PACKAGE.md` for detailed instructions on creating new packages.

## Validation

### Source Validation

Run the complete source validation:

```bash
./validate-packages.sh
```

This checks:
- Package Makefile structure
- Shell syntax
- Platform profiles
- UCI configuration
- LuCI UI metadata
- Package file existence

### Platform Validation

Validate platform registry:

```bash
python3 scripts/validate-platforms.py
```

### UCI Configuration Validation

Validate UCI configuration syntax:

```bash
python3 scripts/validate-uci.py
```

### LuCI UI Validation

Validate LuCI UI metadata:

```bash
python3 scripts/validate-ui.py
```

## Building

### Firmware Build

Build firmware for a registered platform:

```bash
JOBS=2 ./scripts/build-platform.sh x86_64
```

Available platforms are listed in `config/platforms.tsv`.

### SDK Package Build

To build packages against the SDK without building full firmware:

```bash
# Download SDK manually or use CI workflow
# Then build specific packages
make package/feeds/routeros/router-core/compile
```

## Testing

### Host-side Tests

Run host-side regression tests:

```bash
tests/router-core/test-firstboot-network.sh
tests/setup/test-setup-overlay.sh
```

### On-device Tests

After building firmware with router-tests selected:

```bash
/usr/libexec/router-tests/test-config-syntax.sh
/usr/libexec/router-tests/test-hardware-detect.sh
/usr/libexec/router-tests/test-network-validation.sh
/usr/libexec/router-tests/test-connectivity.sh
```

## CI/CD

GitHub Actions workflows:

- `validate.yml`: Source validation
- `openwrt-sdk-build.yml`: SDK package compilation
- `build-and-boot.yml`: Full firmware build and QEMU boot test

## Code Style

### Shell Scripts

- Use `#!/bin/sh` for POSIX compatibility
- Use `set -eu` for error handling
- Prefer BusyBox-compatible commands
- Avoid GNU-specific extensions

### Package Makefiles

- Follow OpenWrt package conventions
- Use proper dependency declarations
- Install files to correct locations
- Set appropriate permissions

### UCI Configuration

- Use UCI for configuration management
- Preserve board-generated configuration
- Avoid hardcoded interface names or addresses

## Debugging

### Build Failures

1. Check build logs in `openwrt/logs/`
2. Verify dependencies are installed
3. Check configuration with `make defconfig`
4. Try with `JOBS=1` for memory-constrained systems

### Runtime Issues

1. Check system logs: `logread`
2. Check service status: `/etc/init.d/<service> status`
3. Validate UCI configuration: `uci show`
4. Check RouterOS status: `/usr/libexec/router-core/router-status`

## Platform Support

RouterOS is designed for multi-platform support:

- Generic x86_64 PCs
- x86_64 virtual machines
- Generic ARM64 platforms
- Board-specific routers (using OpenWrt device profiles)

See `docs/platforms/PLATFORM_DEVELOPMENT.md` for adding platform support.

## DSA Development

DSA (Data Structure Acceleration) development is deferred until the router OS foundation is complete. DSA packages are isolated in the repository but are not required for router OS builds.

See DSA documentation in `docs/DSA_DEVELOPER_GUIDE.md` (if available) when DSA development resumes.

## Common Issues

### Permission Denied on Scripts

Ensure scripts are executable:

```bash
chmod +x scripts/*.sh
```

### Python Not Found

On Windows, install Python or use WSL2 with Python installed.

### Build Fails with Dependency Errors

Run dependency installation:

```bash
./scripts/install-build-deps-ubuntu.sh
```

### QEMU Boot Fails

Check:
- Firmware image exists
- QEMU is installed
- Serial output for error messages

## Contributing

1. Follow the development workflow
2. Write tests for new functionality
3. Update documentation
4. Ensure all validations pass
5. Create descriptive pull requests

## Resources

- OpenWrt Documentation: https://openwrt.org/docs/start
- OpenWrt Package Feed: https://openwrt.org/docs/guide-developer/packages
- LuCI Documentation: https://openwrt.org/docs/guide-developer/luci
