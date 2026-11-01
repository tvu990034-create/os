# RouterOS Performance Foundation and Optimization Research

This document outlines performance optimization strategies for RouterOS. All optimizations require baseline measurement before implementation.

## Current Performance Baseline

**Not yet established.** A baseline must be established before any optimization.

### Required Baseline Metrics

- Throughput (Gbps)
- Latency (ms)
- CPU usage (%)
- Memory usage (MB)
- Packet processing rate (pps)
- Connection handling capacity

### Measurement Tools

- `iperf3` - Network throughput
- `ping` - Latency
- `top`/`htop` - CPU/memory usage
- `ethtool` - Interface statistics
- `tcpdump` - Packet capture and analysis
- `perf` - Linux performance profiling

## Linux Networking Stack Optimization

### Current Implementation
RouterOS uses standard Linux networking stack via OpenWrt.

### Optimization Opportunities

#### 1. Interrupt Moderation
- Reduce interrupt rate by increasing interrupt moderation
- Trade-off: Higher latency, lower CPU
- Implementation: `ethtool -C <interface> <value>`

#### 2. RPS (Receive Packet Steering)
- Distribute packet processing across CPU cores
- Implementation: Configure `/sys/class/net/<if>/queues/rx-<q>/rps_cpus`
- Requires kernel module support

#### 3. RFS (Receive Flow Steering)
- Direct flows to specific CPU cores
- Better cache locality
- Implementation: Configure `/sys/class/net/<if>/queues/rx-<q>/rps_flow_cnt`

#### 4. Generic Receive Offload (GRO)
- Coalesce packets before processing
- Reduces CPU overhead
- Implementation: `ethtool -K <interface> gro on`

#### 5. Generic Segmentation Offload (GSO)
- Reduce segmentation overhead
- Implementation: `ethtool -K <interface> gso on`

### Available Source: iproute2
Location: `F:\router-os-source\iproute2\`

Relevant components:
- `ip/` - IP configuration
- `tc/` - Traffic control
- `ethtool` equivalents via `ip link`

## Traffic Control and QoS Optimization

### Current Implementation
RouterOS uses tc with Cake and HTB schedulers via router-qos package.

### Optimization Opportunities

#### 1. Offload Support
- Hardware offload for traffic classification
- TC flower offload to NIC hardware
- Implementation: Use `tcfilter` package (already integrated)

#### 2. BQL (Byte Queue Limits)
- Reduce bufferbloat
- Dynamic queue sizing
- Implementation: Configure `/sys/class/net/<if>/queues/tx-<q>/byte_queue_limits`

#### 3. FQ-CoDel (Fair Queuing Controlled Delay)
- Alternative to Cake for latency optimization
- Better for mixed traffic
- Implementation: Use fq_codel qdisc

### Available Source: iproute2/tc
Location: `F:\router-os-source\iproute2\tc\`

## XDP/eBPF Optimization

### Current Implementation
Not integrated. Available for future work.

### Optimization Opportunities

#### 1. XDP (eXpress Data Path)
- Bypass kernel networking stack for packet processing
- Dramatically improves throughput
- Use cases: DDoS mitigation, firewall, load balancing

#### 2. eBPF Maps
- High-performance packet classification
- Connection tracking in kernel space
- Flow offload to userspace

#### 3. XDP Drop Monitor
- Monitor dropped packets
- Debug performance issues

### Available Source: xdp-tutorial
Location: `F:\router-os-source\xdp-tutorial\`

Relevant examples:
- `basic01-xdp-pass/` - Basic XDP pass
- `basic03-map-counter/` - Map usage
- `packet01-parsing/` - Packet parsing
- `packet02-rewriting/` - Packet rewriting

### Implementation Requirements
- Custom kernel compilation with BPF support
- XDP-capable NIC drivers
- eBPF toolchain (clang, bpftool)

### Not Recommended For
- RouterOS foundation - XDP is complex and kernel-specific
- Use only when benchmarks justify overhead

## DPDK Optimization

### Current Implementation
Not integrated. Available for future work.

### Optimization Opportunities

#### 1. Poll-Mode Drivers (PMD)
- Bypass kernel entirely
- Zero-copy packet processing
- Extremely high throughput

#### 2. CPU Affinity
- Pin DPDK threads to specific cores
- Reduce context switching
- Better cache locality

#### 3. Hugepages
- Reduce TLB misses
- Improve memory access performance

### Available Source: DPDK
Location: `F:\router-os-source\dpdk\`

Relevant components:
- `drivers/` - PMD drivers
- `app/` - Example applications
- `examples/` - Usage examples

### Implementation Requirements
- DPDK-compatible NICs (Intel, Mellanox, etc.)
- Custom kernel with DPDK support
- Significant code changes to RouterOS
- Custom build system integration

### Not Recommended For
- RouterOS foundation - DPDK requires major architectural changes
- Generic x86 PCs may not have supported NICs
- Use only for specific high-performance hardware

## CPU Affinity and Multicore Optimization

### Current Implementation
Default Linux scheduler.

### Optimization Opportunities

#### 1. IRQ Affinity
- Pin interrupts to specific CPUs
- Reduces cache thrashing
- Implementation: `/proc/irq/<irq>/smp_affinity`

#### 2. Process Affinity
- Pin critical processes (dnsmasq, netifd) to specific cores
- Implementation: `taskset` or `cset`

#### 3. Isolcpus
- Reserve CPUs for critical networking tasks
- Implementation: Kernel boot parameter `isolcpus=`

## Memory and Packet Buffer Optimization

### Current Implementation
Default Linux memory management.

### Optimization Opportunities

#### 1. Socket Buffer Tuning
- Increase socket buffers for high throughput
- Implementation: `/proc/sys/net/core/rmem_max`, `wmem_max`

#### 2. TCP Buffer Tuning
- Optimize TCP window sizes
- Implementation: `/proc/sys/net/ipv4/tcp_rmem`, `tcp_wmem`

#### 3. Reduce Skb Truesize
- Reduce memory overhead per packet
- Trade-off: More allocations, less memory waste

## Hardware Offloading

### Current Implementation
Depends on NIC capabilities.

### Optimization Opportunities

#### 1. TSO (TCP Segmentation Offload)
- Offload TCP segmentation to NIC
- Reduces CPU overhead
- Implementation: `ethtool -K <interface> tso on`

#### 2. LRO (Large Receive Offload)
- Coalesce packets on receive
- Reduces CPU overhead
- Implementation: `ethtool -K <interface> lro on`

#### 3. Checksum Offload
- Offload checksum calculation to NIC
- Implementation: `ethtool -K <interface> tx on rx on`

## Performance Testing Strategy

### Benchmark Tools

1. **iperf3**
   - Server: `iperf3 -s`
   - Client: `iperf3 -c <server> -t 60 -P 8`
   - Measures throughput and parallel connections

2. **ping**
   - Latency measurement: `ping -i 0.1 <target>`

3. **netperf**
   - TCP/UDP performance testing
   - More detailed than iperf3

4. **stress-ng**
   - System load generation
   - Test under load

### Test Scenarios

1. **Baseline Test**
   - Default RouterOS configuration
   - Measure all metrics
   - Save as baseline

2. **Single Optimization Test**
   - Apply one optimization
   - Measure all metrics
   - Compare to baseline
   - Keep if improvement > 10%

3. **Combined Optimization Test**
   - Apply multiple optimizations
   - Measure all metrics
   - Check for interactions
   - Keep if net improvement

4. **Real-World Traffic Test**
   - Simulate mixed traffic (HTTP, video, gaming)
   - Measure latency under load
   - Ensure QoS policies work

## Performance Audit Checklist

Before claiming performance improvements:

- [ ] Baseline measured and documented
- [ ] Optimization implemented with configuration persistence
- [ ] Benchmark run before and after
- [ ] Results show measurable improvement
- [ ] No regression in other metrics
- [ ] Stability tested under load
- [ ] Documentation updated
- [ ] Rollback procedure documented

## Recommendations for RouterOS

### Phase 1: Foundation (Current Priority)
1. Establish baseline metrics with standard configuration
2. Document current performance characteristics
3. Test with typical router workloads

### Phase 2: Linux Stack Optimization
1. Enable GRO/GSO (low risk, high benefit)
2. Tune socket buffers
3. Configure RPS for multicore systems
4. Test interrupt moderation

### Phase 3: Traffic Control Optimization
1. Use Cake scheduler with proper parameters
2. Enable hardware offload where supported
3. Configure BQL to reduce bufferbloat
4. Integrate with tcfilter for hardware offload

### Phase 4: Advanced Optimization (Future)
1. Evaluate XDP for specific use cases (firewall, DDoS)
2. Consider DPDK only for specific high-performance hardware
3. Custom kernel optimization if benchmarks justify

## Hardware-Specific Optimizations

### Dell OptiPlex 3050
- Intel NIC (likely e1000 or igb)
- Supports RSS, TSO, LRO
- Enable hardware offloading

### Generic x86_64 PCs
- NIC support varies
- Detect capabilities with `ethtool`
- Enable offloading only if supported

### ARM64 Devices
- May have different NIC capabilities
- Test per device
- Don't assume x86 optimizations apply

## Not Recommended

1. **DPDK for generic use**
   - Requires specific NICs
   - Complex integration
   - Not needed for typical router workloads

2. **Custom kernel without benchmarks**
   - High maintenance burden
   - May introduce instability
   - Only if measurements prove necessity

3. **Premature XDP integration**
   - Complex debugging
   - Kernel version dependencies
   - Only for specific high-performance needs

## Conclusion

Performance optimization requires:
1. Baseline measurement
2. Controlled experiments
3. Measurable improvements
4. Stability testing

Start with low-risk, high-benefit Linux stack optimizations.
Progress to XDP/DPDK only when benchmarks justify complexity.
Always measure before and after.

Current priority: Establish baseline and implement Phase 1 foundation optimizations.
