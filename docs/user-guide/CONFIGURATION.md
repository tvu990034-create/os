# RouterOS Configuration Guide

## Overview

This guide covers RouterOS configuration for typical router scenarios.

## Accessing Configuration

### Web Interface (LuCI)

Access at: `http://<router-ip>`

### Command Line

SSH to the router or use console:
```bash
ssh root@<router-ip>
```

### UCI Command Line

```bash
uci show network
uci set network.lan.ipaddr='192.168.1.1/24'
uci commit network
/etc/init.d/network reload
```

## Network Configuration

### LAN Configuration

Default LAN is usually configured by board metadata. To change:

```bash
# View current LAN config
uci show network.lan

# Change LAN IP
uci set network.lan.ipaddr='192.168.1.1/24'
uci commit network
/etc/init.d/network reload
```

### WAN Configuration

For DHCP (typical cable/DSL modem):
```bash
uci set network.wan='interface'
uci set network.wan.device='eth1'  # Replace with actual WAN interface
uci set network.wan.proto='dhcp'
uci commit network
/etc/init.d/network reload
```

For static IP:
```bash
uci set network.wan='interface'
uci set network.wan.device='eth1'
uci set network.wan.proto='static'
uci set network.wan.ipaddr='203.0.113.1'
uci set network.wan.netmask='255.255.255.0'
uci set network.wan.gateway='203.0.113.254'
uci set network.wan.dns='8.8.8.8 8.8.4.4'
uci commit network
/etc/init.d/network reload
```

### Identify Interfaces

List available interfaces:
```bash
ip link show
```

## DHCP Configuration

### Enable DHCP Server on LAN

```bash
uci set dhcp.lan='dhcp'
uci set dhcp.lan.interface='lan'
uci set dhcp.lan.start='100'
uci set dhcp.lan.limit='150'
uci set dhcp.lan.leasetime='12h'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

### Disable DHCP

```bash
uci set dhcp.lan.ignore='1'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

### View DHCP Leases

```bash
cat /tmp/dhcp.leases
```

## DNS Configuration

### Configure DNS Forwarding

RouterOS uses dnsmasq for DNS forwarding. Configure:

```bash
uci set dhcp.@dnsmasq[0].server='8.8.8.8'
uci set dhcp.@dnsmasq[0].server='8.8.4.4'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

### Local DNS Entries

```bash
uci add dhcp domain
uci set dhcp.@domain[-1].name='mynetwork.local'
uci set dhcp.@domain[-1].ip='192.168.1.10'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

## Firewall Configuration

### Default Zones

RouterOS typically has:
- **LAN zone**: Trusted internal network
- **WAN zone**: Untrusted external network

### View Firewall Rules

```bash
uci show firewall
```

### Open Port on WAN

```bash
# Add forwarding rule
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-HTTP'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='80'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart
```

### Port Forwarding

```bash
uci add firewall redirect
uci set firewall.@redirect[-1].name='Forward-HTTP'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='80'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.1.100'
uci set firewall.@redirect[-1].dest_port='80'
uci set firewall.@redirect[-1].proto='tcp'
uci commit firewall
/etc/init.d/firewall restart
```

## Wireless Configuration (WiFi)

### Enable WiFi (if hardware supports)

```bash
# Configure radio
uci set wireless.radio0.disabled='0'
uci set wireless.@wifi-iface[0].ssid='MyNetwork'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='my-password'
uci commit wireless
wifi reload
```

## System Configuration

### Hostname

```bash
uci set system.@system[0].hostname='myrouter'
uci commit system
/etc/init.d/system reload
```

### Timezone

```bash
uci set system.@system[0].timezone='America/New_York'
uci set system.@system[0].zonename='America/New_York'
uci commit system
/etc/init.d/system reload
```

### Root Password

```bash
passwd
```

### SSH Configuration

Enable SSH key authentication:
```bash
# Add SSH key
mkdir -p /etc/dropbear
echo "ssh-rsa AAAA... user@host" >> /etc/dropbear/authorized_keys
```

## Backup and Restore

### Backup Configuration

```bash
/usr/libexec/router-core/router-backup backup
```

Backups are stored in `/etc/routeros-backups/`.

### Restore Configuration

```bash
/usr/libexec/router-core/router-backup restore /etc/routeros-backups/config-backup-<timestamp>.tar.gz
```

## Monitoring

### System Status

```bash
/usr/libexec/router-core/router-status
```

### Network Health

```bash
/usr/libexec/router-net/check-network-health.sh
```

### System Monitoring

```bash
/usr/libexec/router-monitor/router-monitor-system all
```

### Network Monitoring

```bash
/usr/libexec/router-monitor/router-monitor-network interfaces
```

### Hardware Information

```bash
/usr/libexec/router-device/router-device-info all
```

### Device Capabilities

```bash
/usr/libexec/router-device/router-device-capabilities all
```

## Routing

### View Routing Table

```bash
/usr/libexec/router-routing/router-routing-status table
```

### Default Route

```bash
/usr/libexec/router-routing/router-routing-status default
```

### Test Connectivity

```bash
/usr/libexec/router-routing/router-routing-diagnostics ping 8.8.8.8
```

## Firewall Diagnostics

### Validate Firewall

```bash
/usr/libexec/router-firewall/router-firewall-validate validate
```

### Firewall Status

```bash
/usr/libexec/router-firewall/router-firewall-diagnostics status
```

### View Active Rules

```bash
/usr/libexec/router-firewall/router-firewall-diagnostics rules
```

## Service Management

### Restart Network

```bash
/etc/init.d/network restart
```

### Restart Firewall

```bash
/etc/init.d/firewall restart
```

### Restart DHCP/DNS

```bash
/etc/init.d/dnsmasq restart
```

### Service Supervision

```bash
/usr/libexec/router-core/router-supervisor check
```

## Troubleshooting

### Check Logs

```bash
logread
```

### Check Service Status

```bash
/etc/init.d/<service> status
```

### Run Diagnostics

```bash
/usr/libexec/router-core/router-status
```

### Reboot Router

```bash
/usr/libexec/router-core/router-shutdown reboot
```

### Safe Shutdown

```bash
/usr/libexec/router-core/router-shutdown poweroff
```

## Best Practices

1. **Always commit UCI changes** after modifying configuration
2. **Backup before major changes** using router-backup
3. **Test changes incrementally** rather than changing everything at once
4. **Preserve board-generated configuration** for embedded devices
5. **Use LuCI for simple changes**, CLI for complex automation
6. **Monitor system resources** after configuration changes
7. **Keep firmware updated** following upgrade procedures

## Platform-Specific Notes

### Generic x86_64

- Interface names may vary (eth0, enp2s0, etc.)
- No board-generated network config for generic systems
- Use `ip link show` to identify interfaces

### Board-Specific Devices

- Board metadata generates network configuration
- Interface names and topology are device-specific
- Preserve board-generated config unless you know the changes are safe

## Additional Resources

- OpenWrt UCI Configuration: https://openwrt.org/docs/guide-user/base-system/uci
- Firewall Configuration: https://openwrt.org/docs/guide-user/firewall
- Network Configuration: https://openwrt.org/docs/guide-user/network
