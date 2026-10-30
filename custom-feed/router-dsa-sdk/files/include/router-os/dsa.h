/*
 * RouterOS DSA plugin ABI, version 1.
 *
 * This is a user-space plugin contract for algorithm development. It does not
 * expose kernel pointers, own packet buffers, or bypass the Linux networking
 * stack. The future runtime is responsible for validating descriptors and
 * deciding which stages are enabled.
 *
 * SPDX-License-Identifier: GPL-2.0-only
 */
#ifndef ROUTER_OS_DSA_H
#define ROUTER_OS_DSA_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ROUTER_DSA_ABI_VERSION 1u
#define ROUTER_DSA_PLUGIN_ENTRY "router_dsa_get_algorithm_v1"

#if defined(__GNUC__) || defined(__clang__)
#define ROUTER_DSA_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define ROUTER_DSA_PLUGIN_EXPORT
#endif

enum router_dsa_stage {
	ROUTER_DSA_STAGE_CLASSIFY = 1,
	ROUTER_DSA_STAGE_ROUTE = 2,
	ROUTER_DSA_STAGE_SCHEDULE = 3,
	ROUTER_DSA_STAGE_OBSERVE = 4
};

enum router_dsa_action {
	ROUTER_DSA_ACTION_NONE = 0u,
	ROUTER_DSA_ACTION_DROP = 1u << 0,
	ROUTER_DSA_ACTION_SET_MARK = 1u << 1,
	ROUTER_DSA_ACTION_SET_QUEUE = 1u << 2,
	ROUTER_DSA_ACTION_SET_EGRESS = 1u << 3
};

enum router_dsa_capability {
	ROUTER_DSA_CAP_THREAD_SAFE = 1u << 0
};

/*
 * Metadata is immutable for the duration of process(). Address and port
 * fields are in network byte order. IPv4 addresses occupy the first 4 bytes
 * of the 16-byte address arrays; IPv6 uses all 16 bytes. No packet payload
 * pointer is exposed in ABI v1.
 */
struct router_dsa_packet {
	uint32_t struct_size;
	uint32_t ingress_ifindex;
	uint32_t packet_length;
	uint32_t packet_mark;
	uint32_t queue_mapping;
	uint16_t eth_protocol;
	uint16_t source_port;
	uint16_t destination_port;
	uint8_t ip_version;
	uint8_t ip_protocol;
	uint8_t source_address[16];
	uint8_t destination_address[16];
	uint64_t timestamp_ns;
};

struct router_dsa_decision {
	uint32_t struct_size;
	uint32_t actions;
	uint32_t mark;
	uint32_t queue_mapping;
	uint32_t egress_ifindex;
};

struct router_dsa_context {
	uint32_t abi_version;
	uint32_t struct_size;
	void *userdata; /* Private to the plugin; the host never dereferences it. */
};

struct router_dsa_algorithm {
	uint32_t abi_version;
	uint32_t struct_size;
	const char *name;
	const char *version;
	uint32_t stage;
	uint32_t capabilities;
	int (*init)(struct router_dsa_context *context);
	int (*process)(struct router_dsa_context *context,
	               const struct router_dsa_packet *packet,
	               struct router_dsa_decision *decision);
	void (*destroy)(struct router_dsa_context *context);
};

/*
 * Every plugin exports this function. Return NULL when the requested ABI
 * version is unsupported. Return a pointer to static, read-only descriptor
 * storage whose lifetime is the lifetime of the loaded shared object.
 */
typedef const struct router_dsa_algorithm *
(*router_dsa_get_algorithm_fn)(uint32_t requested_abi_version);

ROUTER_DSA_PLUGIN_EXPORT
const struct router_dsa_algorithm *
router_dsa_get_algorithm_v1(uint32_t requested_abi_version);

#ifdef __cplusplus
}
#endif

#endif /* ROUTER_OS_DSA_H */
