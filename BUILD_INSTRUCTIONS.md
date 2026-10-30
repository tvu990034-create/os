# Build Instructions for Router OS

## Prerequisites

### Required Tools

The OpenWrt build system requires a Linux environment with the following tools:

```
binutils bzip2 diff find flex gawk gcc-6+ getopt grep install libc-dev libz-dev
make4.1+ perl python3.8+ rsync subversion unzip which
```

### Supported Environments

- Linux (native)
- WSL2 (Windows Subsystem for Linux 2)
- macOS (with case-sensitive filesystem)
- BSD (with case-sensitive filesystem)

**Note**: Cygwin is NOT supported due to lack of case-sensitive filesystem.

## Repository Setup

### 1. Clone the Repository

```bash
git clone https://github.com/tvu990034-create/os.git
cd os
```

### 2. Clone Required External Repositories

The repository structure expects these external repositories as siblings:

```bash
# From the os directory
git clone https://github.com/openwrt/openwrt.git
git clone https://github.com/torvalds/linux.git
git clone https://github.com/openwrt/luci.git
git clone https://github.com/openwrt/packages.git
git clone https://github.com/openwrt/routing.git
git clone https://github.com/iproute2/iproute2.git
git clone https://github.com/DPDK/dpdk.git
git clone https://github.com/xdp-project/xdp-tutorial.git
git clone https://github.com/buildroot/buildroot.git
git clone https://github.com/u-boot/u-boot.git
git clone https://github.com/coreboot/coreboot.git
```

### 3. Run Setup Script

```bash
./setup.sh
```

This will:
- Copy custom configuration to `openwrt/custom/`
- Generate `openwrt/feeds.conf.local`

## Build Process

### 1. Navigate to OpenWrt Directory

```bash
cd openwrt
```

### 2. Update Feeds

```bash
./scripts/feeds update custom-feed
./scripts/feeds update packages
./scripts/feeds update luci
./scripts/feeds update routing
```

### 3. Install Packages

```bash
./scripts/feeds install router-core
./scripts/feeds install router-net
./scripts/feeds install router-tests
./scripts/feeds install -a
```

### 4. Configure Build

```bash
make menuconfig
```

**Required Configuration**:

1. **Target System**:
   - For x86: Target System → x86
   - For ARM: Target System → ARM (armsr)

2. **Target Profile**:
   - For x86: Generic x86/VMware/Containers
   - For ARM: Generic ARMv8

3. **Base System**:
   - Ensure `router-core` is selected (should be default for x86/armsr)

4. **Network**:
   - Ensure firewall4 is selected
   - Ensure dnsmasq is selected
   - Ensure odhcpd is selected

5. **Utilities**:
   - Select router-tests if you want test utilities

6. **Save Configuration**: Save and exit

### 5. Build Image

```bash
make -j$(nproc)
```

This will:
- Download toolchain
- Build cross-compiler
- Build kernel
- Build packages
- Generate firmware image

The build will take time (30 minutes to several hours depending on your system).

## Build Output

After successful build, images will be in:

```
openwrt/bin/targets/<target>/<subtarget>/
```

For x86:
```
openwrt/bin/targets/x86/64/
```

Common image files:
- `openwrt-x86-64-generic-ext4-combined.img.gz` - Combined image
- `openwrt-x86-64-generic-kernel.bin` - Kernel
- `openwrt-x86-64-generic-rootfs.tar.gz` - Root filesystem

## Testing the Image

### In QEMU (x86)

```bash
# Extract image
gunzip openwrt-x86-64-generic-ext4-combined.img.gz

# Run in QEMU
qemu-system-x86_64 \
  -m 512M \
  -drive file=openwrt-x86-64-generic-ext4-combined.img,format=raw \
  -net nic,model=e1000 \
  -net user,hostfwd=tcp::2222-:22 \
  -nographic
```

### In VirtualBox

1. Create new VM
2. Type: Linux, Other Linux (64-bit)
3. Memory: 512MB
4. Disk: Use existing disk, select the extracted .img file
5. Start VM

### In VMware

1. Create new VM
2. Select "Use an existing virtual disk"
3. Browse to the extracted .img file
4. Start VM

## First Boot Configuration

On first boot:

1. The system will use default configuration
2. Login via console (user: root, no password set initially)
3. Run hardware detection:
   ```bash
   /usr/libexec/router-core/router-hw-detect
   ```
4. Check network interfaces:
   ```bash
   ip link show
   ```
5. Adjust network configuration if needed:
   ```bash
   uci set network.wan.device=<your-wan-device>
   uci set network.lan.device.br-lan
   uci add_list device.br-lan.ports=<your-lan-device>
   uci commit network
   /etc/init.d/network restart
   ```
6. Set root password:
   ```bash
   passwd
   ```

## Running Tests

After boot, run the test suite:

```bash
/usr/libexec/router-tests/test-config-syntax.sh
/usr/libexec/router-tests/test-hardware-detect.sh
/usr/libexec/router-tests/test-network-validation.sh
```

## Troubleshooting

### Build Fails

**Missing tools**: Install required tools (see Prerequisites)

**Space issues**: Ensure at least 10GB free space

**Network issues**: Use a local mirror for downloads

### Image Won't Boot

**Check architecture**: Ensure target matches your hardware/VM

**Check image format**: Ensure you're using the correct image for your hypervisor

**Console access**: Use serial console if VGA console doesn't work

### Network Not Working

**Check device names**: Run `ip link show` to see actual device names

**Check configuration**: Run `uci show network` to verify configuration

**Check firewall**: Run `uci show firewall` to verify firewall rules

**Check logs**: Run `logread` to see system logs

## Cleaning Build

To clean the build:

```bash
cd openwrt
make clean
```

To clean everything including downloaded sources:

```bash
make dirclean
```

## Reproducible Builds

For reproducible builds, use:

```bash
make IGNORE_ERRORS=0
```

Document your exact configuration by saving `.config`:

```bash
cp .config my-router-config
```

## Support

For OpenWrt-specific issues:
- OpenWrt Wiki: https://openwrt.org
- OpenWrt Forum: https://forum.openwrt.org

For Router OS-specific issues:
- Check logs: `logread`
- Check hardware detection: `/usr/libexec/router-core/router-hw-detect`
- Check configuration: `uci show`
