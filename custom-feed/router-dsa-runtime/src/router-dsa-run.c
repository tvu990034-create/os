/*
 * Load one trusted RouterOS DSA ABI v1 plugin and run it against synthetic
 * packet metadata. This is a development/test runner, not a live dataplane.
 *
 * SPDX-License-Identifier: GPL-2.0-only
 */
#include <dlfcn.h>
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <router-os/dsa.h>

static int parse_u32(const char *text, uint32_t *value)
{
	char *end = NULL;
	unsigned long parsed;

	if (text == NULL || value == NULL || *text == '\0' || *text == '-')
		return -1;

	errno = 0;
	parsed = strtoul(text, &end, 10);
	if (errno != 0 || end == text || *end != '\0' || parsed > UINT32_MAX)
		return -1;

	*value = (uint32_t)parsed;
	return 0;
}

static const char *stage_name(uint32_t stage)
{
	switch (stage) {
	case ROUTER_DSA_STAGE_CLASSIFY: return "classify";
	case ROUTER_DSA_STAGE_ROUTE: return "route";
	case ROUTER_DSA_STAGE_SCHEDULE: return "schedule";
	case ROUTER_DSA_STAGE_OBSERVE: return "observe";
	default: return "unknown";
	}
}

int main(int argc, char **argv)
{
	void *handle = NULL;
	void *symbol;
	union {
		void *object;
		router_dsa_get_algorithm_fn function;
	} entry;
	const struct router_dsa_algorithm *algorithm;
	struct router_dsa_context context;
	struct router_dsa_packet packet;
	struct router_dsa_decision decision;
	uint32_t value;
	int initialized = 0;
	int status = EXIT_FAILURE;

	if (argc < 2 || argc > 6) {
		fprintf(stderr,
			"usage: %s plugin.so [ingress-ifindex] [packet-length] [ip-version] [ip-protocol]\n",
			argv[0]);
		return EXIT_FAILURE;
	}

	memset(&packet, 0, sizeof(packet));
	memset(&decision, 0, sizeof(decision));
	memset(&context, 0, sizeof(context));
	packet.struct_size = sizeof(packet);
	packet.ingress_ifindex = 2;
	packet.packet_length = 64;
	packet.ip_version = 4;
	packet.ip_protocol = 17;
	decision.struct_size = sizeof(decision);
	context.abi_version = ROUTER_DSA_ABI_VERSION;
	context.struct_size = sizeof(context);

	if (argc > 2) {
		if (parse_u32(argv[2], &value) != 0 || value == 0) {
			fprintf(stderr, "invalid ingress-ifindex\n");
			goto out;
		}
		packet.ingress_ifindex = value;
	}
	if (argc > 3) {
		if (parse_u32(argv[3], &value) != 0 || value == 0) {
			fprintf(stderr, "invalid packet-length\n");
			goto out;
		}
		packet.packet_length = value;
	}
	if (argc > 4) {
		if (parse_u32(argv[4], &value) != 0 || (value != 4 && value != 6)) {
			fprintf(stderr, "ip-version must be 4 or 6\n");
			goto out;
		}
		packet.ip_version = (uint8_t)value;
	}
	if (argc > 5) {
		if (parse_u32(argv[5], &value) != 0 || value > UINT8_MAX) {
			fprintf(stderr, "invalid ip-protocol (expected 0..255)\n");
			goto out;
		}
		packet.ip_protocol = (uint8_t)value;
	}

	handle = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
	if (handle == NULL) {
		fprintf(stderr, "cannot load plugin: %s\n", dlerror());
		goto out;
	}

	dlerror();
	symbol = dlsym(handle, ROUTER_DSA_PLUGIN_ENTRY);
	if (symbol == NULL || dlerror() != NULL) {
		fprintf(stderr, "plugin does not export %s\n", ROUTER_DSA_PLUGIN_ENTRY);
		goto out;
	}
	entry.object = symbol;
	algorithm = entry.function(ROUTER_DSA_ABI_VERSION);
	if (algorithm == NULL) {
		fprintf(stderr, "plugin does not support DSA ABI v%u\n", ROUTER_DSA_ABI_VERSION);
		goto out;
	}

	if (algorithm->abi_version != ROUTER_DSA_ABI_VERSION ||
	    algorithm->struct_size < sizeof(*algorithm) ||
	    algorithm->name == NULL || algorithm->version == NULL ||
	    algorithm->stage < ROUTER_DSA_STAGE_CLASSIFY ||
	    algorithm->stage > ROUTER_DSA_STAGE_OBSERVE ||
	    algorithm->init == NULL || algorithm->process == NULL ||
	    algorithm->destroy == NULL) {
		fprintf(stderr, "plugin descriptor is invalid or incompatible\n");
		goto out;
	}

	if (algorithm->init(&context) != 0) {
		fprintf(stderr, "plugin initialization failed\n");
		goto out;
	}
	initialized = 1;

	if (algorithm->process(&context, &packet, &decision) != 0) {
		fprintf(stderr, "plugin process callback failed\n");
		goto out;
	}

	printf("plugin=%s version=%s stage=%s\n",
	       algorithm->name, algorithm->version, stage_name(algorithm->stage));
	printf("ingress_ifindex=%" PRIu32 " packet_length=%" PRIu32
	       " ip_version=%u ip_protocol=%u\n",
	       packet.ingress_ifindex, packet.packet_length,
	       packet.ip_version, packet.ip_protocol);
	printf("actions=0x%08" PRIx32 " mark=%" PRIu32
	       " queue=%" PRIu32 " egress_ifindex=%" PRIu32 "\n",
	       decision.actions, decision.mark,
	       decision.queue_mapping, decision.egress_ifindex);
	status = EXIT_SUCCESS;

out:
	if (initialized)
		algorithm->destroy(&context);
	if (handle != NULL)
		dlclose(handle);
	return status;
}
