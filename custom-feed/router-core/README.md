# router-core

Core RouterOS package for first-boot defaults, hardware inventory and startup diagnostics.

## Network defaults

- LAN bridge: br-lan, static 192.168.1.1/24.
- The first physical wired interface discovered at first boot is assigned to LAN.
- The second physical wired interface, when present, is configured as a DHCP WAN client (with DHCPv6).
- Additional detected wired NICs are placed on the LAN bridge.
- A one-NIC device is configured as LAN-only. A separate WAN NIC must be added for routed WAN/LAN separation.

The static UCI files are installed through `custom/overlay/etc/config/` and OpenWrt's rootfs overlay. `setup.sh` syncs them to `openwrt/files/etc/config/` and tracks their hashes. The first-boot UCI defaults only attaches detected NICs to the stock `br-lan` bridge and preserves an existing WAN setup.

## Firewall

The default policy rejects unsolicited input and forwarding. LAN is trusted, WAN input is rejected, and LAN-to-WAN forwarding uses masquerading. DHCPv6 replies and MLD are allowed from WAN; essential IPv6 ICMP input and forwarding error messages are rate-limited and allowed.

## Diagnostics

- /usr/libexec/router-core/router-hw-detect prints network, PCI (when lspci is installed), CPU, memory and block-device inventory.
- /etc/init.d/router-core writes a startup inventory to /tmp/router-core/hardware.txt.

The scripts are read-only with respect to network configuration.

## First boot security

router-core does not force SSH password options or rewrite uhttpd listen addresses. Set a root password on the local console before enabling remote administration.
