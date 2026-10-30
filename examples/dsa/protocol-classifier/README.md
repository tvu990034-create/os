# RouterOS DSA example: protocol classifier

This example is a small, complete ABI v1 plugin. It classifies synthetic IPv4/IPv6 packet metadata by IP protocol:

| Protocol | Action | Mark |
|---|---|---:|
| TCP (6) | SET_MARK | 0x1001 |
| UDP (17) | SET_MARK | 0x1002 |
| Other | NONE | 0 |

The plugin is deliberately stateless and advertises the thread-safe capability.

## Build on the host

    make CC=cc

This builds `protocol-classifier.so` against the public header under `custom-feed/router-dsa-sdk/files/include/`.

## Cross-compile for the x86-64 OpenWrt target

With the OpenWrt source tree prepared by `setup.sh`, use its target toolchain:

    OPENWRT_DIR=/path/to/os/openwrt
    export PATH="$OPENWRT_DIR/staging_dir/toolchain-x86_64_gcc-14.3.0_musl/bin:$PATH"
    make clean
    make CC=x86_64-openwrt-linux-musl-gcc

The plugin only needs the DSA public header; it does not link to internal OpenWrt symbols.

## Execute on a RouterOS test device

Copy the shared object to the router after installing `router-dsa-runtime`, then run:

    router-dsa-run /tmp/protocol-classifier.so 3 128 6 6
    router-dsa-run /tmp/protocol-classifier.so 4 512 4 17

The first call supplies IPv6/TCP metadata and should print mark 4097. The second supplies IPv4/UDP metadata and should print mark 4098.

## Boundary

`router-dsa-run` invokes the plugin once with synthetic metadata. This is an ABI development/test loop, not live packet inspection or forwarding. The returned marks do not affect network traffic until a separately designed and tested dataplane adapter consumes plugin decisions.
