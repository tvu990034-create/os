# router-dsa-runtime

A user-space loader and offline test runner for trusted RouterOS DSA ABI v1 shared-object plugins.

## Usage

The original positional form remains supported:

    router-dsa-run /path/to/plugin.so [ingress-ifindex] [packet-length] [ip-version] [ip-protocol]

For richer test vectors, use named options:

    router-dsa-run /path/to/plugin.so \
      --ingress 3 --length 128 --ip-version 6 --protocol 6 \
      --src-ip 2001:db8::1 --dst-ip 2001:db8::2 \
      --src-port 12345 --dst-port 443 --mark 7 --queue 2

Input supports ingress ifindex, packet length, IPv4/IPv6 source and destination addresses, IP protocol, source/destination ports, Ethernet protocol, packet mark, queue mapping and timestamp. Address bytes, ports and Ethernet protocol are placed in network byte order in the ABI packet structure. The IP version defaults to IPv4; addresses supplied on the command line must match it.

## Offline callback measurement

Add `--warmup N` and `--iterations N` to call the plugin repeatedly with the same synthetic packet metadata. The tool prints elapsed time and average nanoseconds per callback. This is a local callback microbenchmark only; it excludes real packet parsing, kernel forwarding, NIC interrupts, queueing and network I/O. It must not be reported as router throughput or end-to-end latency.

## Build a plugin

Include `/usr/include/router-os/dsa.h` and export `router_dsa_get_algorithm_v1()`. Implement the descriptor's `init`, `process` and `destroy` callbacks. The sample `examples/dsa/protocol-classifier/` builds a TCP/UDP classifier that can be tested with the runner.

## Safety and scope

Only load plugins you trust: shared objects execute with the permissions of the process that loads them. The runner supplies synthetic packet metadata and invokes one algorithm synchronously. It does not capture packets, steer traffic, run as a privileged daemon or modify Linux routing/forwarding. A separately designed dataplane adapter is still required before algorithm decisions can affect real traffic.
