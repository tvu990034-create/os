# RouterOS DSA Plugin Development Guide

This guide explains how to implement algorithm modules against the RouterOS DSA ABI v1.

## Scope and boundary

The DSA SDK defines a **user-space plugin contract** for algorithm development. It does not:

- Expose kernel pointers
- Own packet buffers
- Bypass the Linux networking stack
- Intercept live packets

The runtime (`router-dsa-run`) executes a plugin against **synthetic packet metadata**. This is an offline algorithm test/measurement tool, not a live packet dataplane.

A separate dataplane adapter and live forwarding tests are required before plugin decisions can affect traffic or be described as router performance improvements.

Only trusted shared objects should be loaded. Do not treat arbitrary third-party native shared libraries as safe.

## ABI version

Current ABI version: 1

Header file: `custom-feed/router-dsa-sdk/files/include/router-os/dsa.h`

Plugin entry point: `router_dsa_get_algorithm_v1`

ABI compatibility is checked at load time. If the plugin returns NULL for the requested ABI version, the loader rejects it.

## Plugin structure

A plugin is a shared object (`.so`) that exports the entry function:

```c
#include <router-os/dsa.h>

ROUTER_DSA_PLUGIN_EXPORT
const struct router_dsa_algorithm *
router_dsa_get_algorithm_v1(uint32_t requested_abi_version);
```

### Required descriptor fields

```c
struct router_dsa_algorithm {
    uint32_t abi_version;           // Must be ROUTER_DSA_ABI_VERSION (1)
    uint32_t struct_size;           // sizeof(struct router_dsa_algorithm)
    const char *name;               // Algorithm name (e.g., "protocol-classifier")
    const char *version;            // Plugin version (e.g., "1.0.0")
    uint32_t stage;                 // One of ROUTER_DSA_STAGE_*
    uint32_t capabilities;          // Bitmask of ROUTER_DSA_CAP_*
    int (*init)(struct router_dsa_context *context);
    int (*process)(struct router_dsa_context *context,
                   const struct router_dsa_packet *packet,
                   struct router_dsa_decision *decision);
    void (*destroy)(struct router_dsa_context *context);
};
```

### Callbacks

**init(context)**: Called once before any process() calls. Return 0 on success, non-zero on failure.

**process(context, packet, decision)**: Called for each packet. Examine packet metadata, fill in decision. Return 0 on success, non-zero on failure.

**destroy(context)**: Called once after all process() calls. Clean up any resources.

## Stages

| Stage | Value | Purpose |
|-------|-------|---------|
| ROUTER_DSA_STAGE_CLASSIFY | 1 | Classify packets, assign marks or queues |
| ROUTER_DSA_STAGE_ROUTE | 2 | Routing decisions (future) |
| ROUTER_DSA_STAGE_SCHEDULE | 3 | Scheduling decisions (future) |
| ROUTER_DSA_STAGE_OBSERVE | 4 | Read-only observation, no side effects |

Choose the stage that matches your algorithm's purpose. The future dataplane adapter will decide which stages are enabled and in what order.

## Packet metadata

```c
struct router_dsa_packet {
    uint32_t struct_size;           // sizeof(struct router_dsa_packet)
    uint32_t ingress_ifindex;       // Input interface index
    uint32_t packet_length;         // Packet length in bytes
    uint32_t packet_mark;           // Current packet mark
    uint32_t queue_mapping;         // Current queue mapping
    uint16_t eth_protocol;          // Ethernet protocol (network byte order)
    uint16_t source_port;           // Source port (network byte order)
    uint16_t destination_port;      // Destination port (network byte order)
    uint8_t ip_version;             // 4 or 6
    uint8_t ip_protocol;            // IP protocol number
    uint8_t source_address[16];     // Raw bytes; IPv4 uses first 4 bytes
    uint8_t destination_address[16]; // Raw bytes; IPv4 uses first 4 bytes
    uint64_t timestamp_ns;          // Monotonic timestamp in nanoseconds
};
```

Important notes:
- Address arrays contain raw network-order bytes
- IPv4 addresses occupy the first 4 bytes of the 16-byte arrays
- IPv6 uses all 16 bytes
- Ethernet protocol and ports are in network byte order
- No packet payload pointer is exposed in ABI v1
- The packet structure is immutable for the duration of process()

## Decision output

```c
struct router_dsa_decision {
    uint32_t struct_size;           // sizeof(struct router_dsa_decision)
    uint32_t actions;               // Bitmask of ROUTER_DSA_ACTION_*
    uint32_t mark;                  // Packet mark to set
    uint32_t queue_mapping;         // Queue mapping to set
    uint32_t egress_ifindex;        // Egress interface index
};
```

### Actions

| Action | Value | Meaning |
|--------|-------|---------|
| ROUTER_DSA_ACTION_NONE | 0 | No action |
| ROUTER_DSA_ACTION_DROP | 1 << 0 | Drop the packet |
| ROUTER_DSA_ACTION_SET_MARK | 1 << 1 | Set packet mark |
| ROUTER_DSA_ACTION_SET_QUEUE | 1 << 2 | Set queue mapping |
| ROUTER_DSA_ACTION_SET_EGRESS | 1 << 3 | Set egress interface |

Actions are bit-ORed together. If you set ROUTER_DSA_ACTION_SET_MARK, also set the mark field.

## Context

```c
struct router_dsa_context {
    uint32_t abi_version;           // ROUTER_DSA_ABI_VERSION
    uint32_t struct_size;           // sizeof(struct router_dsa_context)
    void *userdata;                 // Private to the plugin; host never dereferences
};
```

Use `userdata` to store plugin-private state. The host does not read or write this pointer.

## Capabilities

| Capability | Value | Meaning |
|------------|-------|---------|
| ROUTER_DSA_CAP_THREAD_SAFE | 1 << 0 | Plugin can be called from multiple threads simultaneously |

If your plugin is not thread-safe, do not set this flag. The future dataplane adapter may use this to decide whether to serialize calls.

## Building a plugin

### Host build (for testing)

```bash
cd examples/dsa/protocol-classifier
make CC=cc
```

### Cross-build for OpenWrt

```bash
make clean
make CC=x86_64-openwrt-linux-musl-gcc \
     ABI_INCLUDE=/path/to/os/custom-feed/router-dsa-sdk/files/include
```

The Makefile uses `-fPIC -shared` to produce a shared object.

## Testing a plugin

Use the runtime to test your plugin against synthetic metadata:

```bash
# Basic test
router-dsa-run plugin.so 3 128 6 58

# Extended options
router-dsa-run plugin.so \
    --ingress 3 \
    --length 128 \
    --ip-version 6 \
    --protocol 6 \
    --src-ip 2001:db8::1 \
    --dst-ip 2001:db8::2 \
    --src-port 12345 \
    --dst-port 443 \
    --mark 7 \
    --queue 2 \
    --iterations 1000 \
    --warmup 100
```

The runner validates:
- Plugin ABI version compatibility
- Descriptor validity
- Argument ranges (ingress > 0, ip-version 4 or 6, ports 0..65535)
- Address consistency (IPv4 vs IPv6)

It reports:
- Plugin name, version, stage
- Packet metadata
- Decision actions and values
- Warmup and iteration counts
- Elapsed time and average callback time

## Example plugin

See `examples/dsa/protocol-classifier/` for a working example:

- **protocol-classifier.c**: Classifies TCP/UDP traffic and assigns marks
- **Makefile**: Build script for host and cross-compilation
- **README.md**: Plugin documentation

The classifier:
- Runs at ROUTER_DSA_STAGE_CLASSIFY
- Assigns mark 4097 to TCP, 4098 to UDP
- Sets ROUTER_DSA_ACTION_SET_MARK in the decision
- Does not modify queue or egress interface

## ABI compatibility

When the ABI version changes, the entry function name will change (e.g., `router_dsa_get_algorithm_v2`). Old plugins will continue to work with old runtimes; new runtimes will reject them if they request a newer ABI version.

Do not assume structure layout will never change. Always set struct_size to sizeof() and check abi_version matches your expectations.

## Error handling

- **init()**: Return non-zero on failure. The loader will reject the plugin.
- **process()**: Return non-zero on failure. The runner will stop the test.
- **destroy()**: Called even if init() or process() failed. Clean up any resources allocated.

Do not call exit() or abort() from a plugin. Return error codes instead.

## Memory ownership

- The host owns the packet and decision structures
- The plugin owns its userdata pointer
- The plugin must not free any host-allocated memory
- The plugin must free any memory it allocated before destroy() returns

## Performance measurement

The runner measures only the callback time, not packet forwarding or router throughput. This is for algorithm comparison, not absolute throughput claims.

Use `--warmup` to allow the CPU to reach steady state before measured iterations.

The measured figure is average nanoseconds per callback. Use this to compare different algorithms, not to claim router performance.

## Security

Only load plugins from trusted sources. The runtime does not sandbox plugins or restrict their system calls. A malicious plugin can:
- Read arbitrary memory
- Write arbitrary memory
- Execute arbitrary code
- Connect to the network
- Modify files

The security boundary is: **only load trusted shared objects**.

Future work may add a sandbox or signature verification, but that is not present in ABI v1.

## Adding a new algorithm module

1. Create a new directory under `examples/dsa/` or in your own workspace
2. Write a `.c` file that implements the ABI
3. Create a Makefile that builds a `.so` with `-fPIC -shared`
4. Include the ABI header: `#include <router-os/dsa.h>`
5. Test with `router-dsa-run` on the host
6. Cross-compile for the target architecture
7. Measure performance with `--iterations` and `--warmup`
8. Document the algorithm's purpose, expected inputs, and decision logic

You do not need to modify the RouterOS foundation to add a new algorithm. The ABI is stable and documented.

## Integration into dataplane (future)

The current runtime is for offline testing only. To integrate a plugin into the actual packet forwarding path, a dataplane adapter must be written that:

1. Intercepts packets at the appropriate Linux hook point (XDP, tc, netfilter)
2. Extracts metadata matching the packet structure
3. Calls the plugin process() callback
4. Applies the decision actions (drop, mark, queue, egress)
5. Ensures thread safety if the plugin claims ROUTER_DSA_CAP_THREAD_SAFE
6. Handles plugin failures gracefully

This adapter does not yet exist. Do not assume your plugin will automatically process live packets.

## Summary

- The DSA SDK provides a stable C ABI for algorithm development
- Plugins are shared objects that implement init/process/destroy callbacks
- The runtime tests plugins against synthetic metadata
- Only trusted plugins should be loaded
- A dataplane adapter is required for live packet processing
- ABI v1 is the current version; future versions will have different entry points
