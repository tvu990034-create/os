# router-dsa-sdk

Header-only development package that establishes the first versioned C ABI for RouterOS algorithm plugins.

## ABI v1

Plugins implement one explicit stage:

- CLASSIFY: classify flows and set marks.
- ROUTE: request an egress interface.
- SCHEDULE: select a queue mapping.
- OBSERVE: compute read-only metadata or counters.

A plugin exports router_dsa_get_algorithm_v1(), returns a static descriptor, and supplies init, process, and destroy callbacks. The header is installed at /usr/include/router-os/dsa.h.

## Contract

- The ABI uses fixed-width integer fields and an explicit ABI version.
- Packet metadata is immutable during the callback. Address arrays are raw network-order bytes; Ethernet protocol and port fields are in network byte order.
- A plugin must not retain pointers to host-owned structures after process() returns.
- Callbacks must be bounded and non-blocking. The host may invoke callbacks concurrently only when the descriptor advertises ROUTER_DSA_CAP_THREAD_SAFE.
- Return 0 for success and a negative value for failure.
- A plugin must not alter the host's networking configuration or manage interfaces itself.

## Important boundary

This package defines the development ABI only. It does not yet load plugins, intercept packets, or change the Linux/OpenWrt forwarding path. Those runtime and dataplane pieces must be implemented and benchmarked separately before an algorithm can affect live traffic. The SDK lets algorithm code be developed and ABI-tested without pretending that a data path already exists.

Run the host ABI smoke test with tests/dsa-sdk/test-plugin.sh.
