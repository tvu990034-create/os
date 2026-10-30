# router-dsa-runtime

A small user-space DSA plugin loader and test runner.

## Usage

After installing the package, run a trusted plugin against synthetic packet metadata:

    router-dsa-run /path/to/plugin.so [ingress-ifindex] [packet-length] [ip-version] [ip-protocol]

Defaults are ingress ifindex 2, 64 bytes, IPv4 and UDP. The runner checks the ABI descriptor, initializes the plugin, invokes its process callback once, prints the returned decision, destroys the context and unloads the shared object.

## Build a plugin

Include /usr/include/router-os/dsa.h and export router_dsa_get_algorithm_v1(). Compile the plugin as a shared object with the target OpenWrt toolchain and install it in a location readable by the operator.

## Safety and scope

Only load plugins you trust: shared objects execute with the permissions of the process that loads them. This runner is for development and offline algorithm testing. It supplies synthetic packet metadata; it does not capture packets, steer traffic, run as a privileged daemon, or modify Linux routing/forwarding. A live dataplane adapter remains a separate implementation and validation task.
