# router-tests

Optional on-device smoke tests for a booted RouterOS image.

## Included checks

- test-config-syntax.sh: asks UCI to parse every RouterOS configuration file.
- test-hardware-detect.sh: runs the read-only hardware inventory and checks its output.
- test-network-validation.sh: validates the LAN bridge and permits WAN to be absent on single-NIC hardware.

## Run on a booted device

    /usr/libexec/router-tests/test-config-syntax.sh
    /usr/libexec/router-tests/test-hardware-detect.sh
    /usr/libexec/router-tests/test-network-validation.sh

The package is optional and is not selected in production images by default.
It depends on router-core and router-net and installs only shell-based diagnostics.

Host-side tests for first-boot NIC discovery and the DSA ABI run from the source repository with ./validate-packages.sh.
