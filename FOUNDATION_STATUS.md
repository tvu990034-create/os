# RouterOS Foundation Status

Last reviewed: 2026-10-30

## Foundation scope

The foundation must provide a reproducible OpenWrt build entry point, valid custom packages and configuration, safe first-boot defaults, testable algorithm interfaces, and a clear boundary between control/algorithm development and live packet forwarding.

## Implemented in source

- OpenWrt v25.12.6 is the default pinned source release.
- setup.sh clones or checks the pinned OpenWrt source and creates the active feeds.conf. It includes the release's feeds.conf.default and adds the custom feed without replacing upstream feed pins.
- The four RouterOS UCI defaults are installed through OpenWrt's standard rootfs `files/` overlay; router-core no longer claims files owned by base-files, dnsmasq or firewall packages.
- The overlay sync is hash-tracked and refuses to overwrite local modifications.
- router-core discovers physical wired NICs on first boot instead of hard-coding eth0/eth1.
- WAN input and forwarding default to REJECT. Explicit DHCPv6 and MLD rules are present, and essential ICMPv6 input/forwarding is rate-limited; this includes echo-request, so IPv6 ping from WAN is allowed within that limit.
- SSH/uhttpd defaults are not forcibly changed by router-core; an unset root password is not converted into a password-authentication policy.
- router-core hardware inventory and startup diagnostics are read-only.
- router-net's observer is opt-in and never runs ifup/ifdown or changes interface configuration.
- router-tests checks UCI parsing, hardware inventory output and LAN/WAN configuration without assuming every device has two NICs.
- router-dsa-sdk defines ABI v1 for classify, route, schedule and observe plugin stages.
- router-dsa-runtime loads a trusted plugin and runs it against synthetic metadata; named inputs cover addresses, ports, packet marks, queues and protocol. It includes an offline callback microbenchmark, clearly separate from live forwarding performance.
- `examples/dsa/protocol-classifier/` provides a tested TCP/UDP mark-setting plugin example; the ABI smoke test compiles and executes TCP, UDP and unclassified-protocol cases.
- Host-side tests compile a shared plugin, load it, validate its descriptor and exercise init/process/destroy.
- Shell, UCI-subset and DSA ABI source checks are included in validate-packages.sh.
- GitHub Actions workflows are included for source validation and pinned x86-64 SDK package compilation.

## Explicitly not implemented

- A live packet-processing dataplane that invokes DSA algorithms for forwarded traffic.
- XDP/eBPF, DPDK, kernel modules or custom kernel patches.
- router-ui now installs a read-only LuCI dashboard with system and network-interface status.
- Full firmware boot validation on QEMU or physical OptiPlex hardware.
- Throughput, PPS, latency, packet-loss or stability benchmarks.
- Secure signed firmware updates, rollback and production recovery.

## Acceptance checklist

| Check | Evidence required | Status |
|---|---|---|
| Repository source validation | validate-packages.sh passes on Linux | Running in GitHub Actions |
| DSA ABI smoke test | C shared-object compile/load/lifecycle test passes | Included in current source CI run |
| Custom package integration | All custom packages compile with OpenWrt 25.12.6 x86-64 SDK | Running in GitHub Actions |
| Full firmware image | Image build completes with RouterOS packages | Not yet run |
| Boot/runtime smoke test | QEMU boot plus router-tests pass | Not yet run |
| Physical hardware | OptiPlex NIC/boot test | Not yet run |

## DSA readiness statement

The development interface is ready for writing and offline-testing DSA algorithm modules once the source and SDK checks pass. This is not the same as live dataplane integration: plugin decisions currently do not alter real forwarded packets. A separate dataplane adapter, safety policy, integration tests and benchmark baseline are required before claiming traffic optimization.
