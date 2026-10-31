# RouterOS foundation status

Last reviewed: 2026-10-31

## Foundation scope

The foundation must provide a reproducible multi-platform OpenWrt build entry
point, valid custom packages and configuration, board-aware first-boot
behavior, a stable interface for user-written algorithm modules, and repeatable
tests. It is not complete until images build, boot and pass runtime network
checks on each claimed hardware profile.

## Implemented in source

- OpenWrt v25.12.6 is the pinned source release.
- config/platforms.tsv is the source of truth for registered profile names,
  OpenWrt targets/subtargets, config files and maturity status.
- x86_64 is the generic PC/VM development baseline.
- armsr_armv8 is an experimental generic ARMv8 EFI profile for compatible Arm
  SystemReady systems and QEMU, not every ARM router or SBC.
- scripts/build-platform.sh builds registered profiles, preserves an original
  OpenWrt .config once, reapplies the selected tracked config and supports
  JOBS=1 for low-memory development hosts.
- setup.sh removes only byte-identical legacy network/system overlays owned by
  older RouterOS setup runs. It refuses to delete unknown or locally modified
  files.
- Shared rootfs overlay installs DHCP and firewall service defaults only.
  OpenWrt generates network/system configuration from board metadata.
- router-core preserves board-generated network interfaces and switch topology;
  its generic NIC discovery path only applies when an explicit RouterOS
  generic bridge marker is present.
- router-core brands only default OpenWrt hostname/timezone values and leaves
  operator or board-provided values intact.
- WAN input/forwarding defaults to REJECT. DHCPv6 and MLD rules are present;
  essential ICMPv6 input and forwarding error messages are rate-limited.
- router-core hardware inventory and startup diagnostics are read-only.
- router-net's observer is opt-in and does not change interface configuration.
- router-tests checks UCI parsing, hardware inventory and network behavior.
- router-dsa-sdk defines ABI v1 for classify, route, schedule and observe stages.
- router-dsa-runtime loads a trusted plugin against synthetic packet metadata;
  this is an offline algorithm test runner, not a live forwarding dataplane.
- Host-side tests compile a shared plugin and test descriptor and callback
  lifecycle.
- Source validation checks package skeletons, registered platform configs,
  shell syntax, UCI syntax, LuCI metadata, overlay migration and first-boot
  board-topology preservation.

## Explicitly not implemented or not yet verified

- Full firmware image build for either registered profile.
- QEMU boot and network smoke test for x86-64 and ARMv8 generic images.
- Physical OptiPlex NIC/boot testing.
- Boot, NIC mapping, switch/DSA, Wi-Fi and VLAN validation on specific embedded
  router boards.
- A live packet-processing dataplane that invokes user algorithms for
  forwarded traffic.
- XDP/eBPF, DPDK, custom kernel modules or custom kernel patches.
- Throughput, PPS, latency, packet-loss and long-duration stability benchmarks.
- Signed firmware updates, rollback and production recovery.

## Acceptance checklist

| Check | Required evidence | Current status |
|---|---|---|
| Repository source validation | validate-packages.sh passes on Linux | CI run pending |
| Platform registry | Every profile config maps to its target/device selector | Static validator added |
| x86-64 SDK build | All custom packages compile against pinned x86 SDK | Workflow running |
| ARMv8 SDK build | All custom packages compile against pinned ARMv8 SDK | Workflow running |
| x86-64 full image | Complete firmware image build | Not yet verified |
| ARMv8 full image | Complete generic EFI image build | Not yet verified |
| QEMU boot | Image boots and router-tests pass | Not yet verified |
| Board topology | First boot preserves generated port/switch configuration | Host regression test added; QEMU/physical verification pending |
| Physical hardware | Boot, NIC mapping and sustained network tests | Not yet verified |
| DSA readiness | ABI and offline host test pass | Included; CI result pending |

## DSA development boundary

The DSA ABI and offline test runner provide a development interface for
algorithm plugins. The ABI does not connect plugins to live forwarding. User
algorithms must not be considered integrated into traffic until a separately
reviewed dataplane adapter passes packet-level correctness, isolation,
stability and performance tests.

The foundation is not declared complete by this status file. Offline DSA
algorithm development can use the current SDK, but live forwarding integration
must wait for full-image build, boot and network acceptance.
