# RouterOS foundation status

Last reviewed: 2026-10-31

## Foundation scope

The foundation must provide a reproducible multi-platform OpenWrt build
entry point, valid custom packages and configuration, safe first-boot defaults,
a stable boundary for user-written algorithm modules, and repeatable tests.
The foundation is not complete until full images build, boot and pass runtime
network checks on each claimed hardware profile.

## Platform/build foundation

- OpenWrt v25.12.6 is the pinned source release.
- config/platforms.tsv is the source of truth for profile names, OpenWrt
  targets/subtargets, config files and maturity status.
- x86_64 is the primary generic PC/VM development profile.
- armsr_armv8 is an experimental generic ARMv8 EFI profile. It is intended
  for compatible Arm SystemReady systems and QEMU, not every ARM router or SBC.
- scripts/build-platform.sh selects a registered profile, preserves an
  existing OpenWrt .config once, applies the tracked config deterministically,
  and supports low-memory builds with JOBS=1.
- GitHub Actions is configured to validate source on every pushed branch and
  compile custom packages against pinned x86-64 and ARMv8 SDKs. Results are
  pending until the workflows complete successfully.

## Implemented in source

- setup.sh checks the pinned OpenWrt ref and registers the local custom feed
  without replacing upstream feed pins.
- The common RouterOS UCI defaults are installed through OpenWrt's rootfs
  files/ overlay; overlay sync is hash-tracked and refuses local overwrites.
- router-core discovers physical wired NICs on first boot rather than
  hard-coding eth0/eth1.
- WAN input and forwarding default to REJECT. Explicit DHCPv6 and MLD rules are
  present. Essential ICMPv6 input and forwarding error messages are rate-limited.
- SSH/uhttpd defaults are not forcibly rewritten by router-core.
- router-core hardware inventory and startup diagnostics are read-only.
- router-net's observer is opt-in and never runs ifup/ifdown or changes
  interface configuration.
- router-tests exercises UCI parsing, hardware inventory output, first-boot
  network assignment and safe overlay synchronization.
- router-dsa-sdk defines ABI v1 for classify, route, schedule and observe
  plugin stages.
- router-dsa-runtime loads a trusted plugin against synthetic packet metadata;
  it includes an offline callback microbenchmark that is not a forwarding
  performance benchmark.
- Host-side tests compile a shared plugin, load it and test its descriptor
  and init/process/destroy lifecycle.
- Source validation checks shell syntax, UCI syntax, LuCI metadata and the DSA
  ABI test.
- CI package compilation is configured for two OpenWrt SDK targets.

## Explicitly not implemented or not yet verified

- Full firmware image build for either registered profile in the current
  acceptance run.
- QEMU boot and network smoke test for x86-64 and ARMv8 generic images.
- Physical OptiPlex NIC/boot testing.
- Boot and LAN/WAN mapping on any specific embedded router board.
- Board-specific switch/DSA and Wi-Fi integration for individual SoCs/devices.
- A live packet-processing dataplane that invokes user algorithms for
  forwarded traffic.
- XDP/eBPF, DPDK, custom kernel modules or custom kernel patches.
- Throughput, PPS, latency, packet-loss and long-duration stability benchmarks.
- Signed firmware updates, rollback and production recovery.

## Acceptance checklist

| Check | Required evidence | Current status |
|---|---|---|
| Repository source validation | validate-packages.sh passes on Linux | CI configured; result pending |
| Platform registry | Each profile config matches its OpenWrt target/device selector | Added; static validator included |
| x86-64 package SDK build | All custom packages compile against pinned x86-64 SDK | Workflow configured; result pending |
| ARMv8 package SDK build | All custom packages compile against pinned ARMv8 SDK | Workflow configured; result pending |
| x86-64 full image | Complete firmware image build | Not yet verified |
| ARMv8 full image | Complete generic EFI firmware image build | Not yet verified |
| QEMU boot | Image boots and router-tests pass | Not yet verified |
| Physical hardware | Boot, NIC mapping and sustained network tests | Not yet verified |
| DSA readiness | ABI header and offline host test pass | Included; CI result pending |

## DSA development boundary

The DSA ABI and offline test runner already provide an interface for writing
and testing algorithm plugins. The ABI is not a live forwarding hook. User
algorithms must not be considered integrated into traffic until a separately
reviewed dataplane adapter exists and passes packet-level correctness,
isolation, stability and performance tests.

The foundation is not declared complete by this status file. DSA algorithm
development can proceed offline against the SDK, but live router integration
must wait for the image-build, boot and network acceptance gates above.
