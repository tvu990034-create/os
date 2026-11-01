/*
 * Load one trusted RouterOS DSA ABI v1 plugin and run it against synthetic
 * packet metadata. This is an offline algorithm test/measurement tool, not
 * a live packet dataplane.
 *
 * SPDX-License-Identifier: GPL-2.0-only
 */
#define _POSIX_C_SOURCE 200809L

#include <arpa/inet.h>
#include <dlfcn.h>
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <router-os/dsa.h>

#define DEFAULT_INGRESS_IFINDEX 2u
#define DEFAULT_PACKET_LENGTH 64u
#define DEFAULT_IP_VERSION 4u
#define DEFAULT_IP_PROTOCOL 17u
#define DEFAULT_ITERATIONS 1u
#define MAX_ITERATIONS UINT64_C(100000000)

static void print_usage(const char *program)
{
	fprintf(stderr,
		"Usage:\n"
		"  %s plugin.so [ingress-ifindex] [packet-length] [ip-version] [ip-protocol]\n"
		"  %s plugin.so [options]\n"
		"Options:\n"
		"  --ingress N       ingress interface index (default: 2)\n"
		"  --length N        packet length in bytes (default: 64)\n"
		"  --ip-version N    4 or 6 (default: 4)\n"
		"  --protocol N      IP protocol number, 0..255 (default: 17)\n"
		"  --src-ip ADDR     source IPv4/IPv6 address\n"
		"  --dst-ip ADDR     destination IPv4/IPv6 address\n"
		"  --src-port N      source port, 0..65535\n"
		"  --dst-port N      destination port, 0..65535\n"
		"  --mark N          input packet mark (default: 0)\n"
		"  --queue N         input queue mapping (default: 0)\n"
		"  --eth-protocol N  Ethernet protocol in host order\n"
		"  --timestamp-ns N  synthetic monotonic timestamp in nanoseconds\n"
		"  --warmup N        warmup callback count (default: 0)\n"
		"  --iterations N    measured callback count (default: 1)\n"
		"  --help            show this help\n"
		"\n"
		"Only trusted shared objects should be loaded. Measurement figures cover\n"
		"the offline callback only, not packet forwarding or router throughput.\n",
		program, program);
}

static int parse_u64(const char *text, uint64_t maximum, uint64_t *value)
{
	char *end = NULL;
	unsigned long long parsed;

	if (text == NULL || value == NULL || *text == '\0' || *text == '-')
		return -1;

	errno = 0;
	parsed = strtoull(text, &end, 10);
	if (errno != 0 || end == text || *end != '\0' ||
	    (uint64_t)parsed > maximum)
		return -1;

	*value = (uint64_t)parsed;
	return 0;
}

static int parse_u32(const char *text, uint32_t *value)
{
	uint64_t parsed;

	if (parse_u64(text, UINT32_MAX, &parsed) != 0)
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

static uint64_t timespec_ns(const struct timespec *value)
{
	return (uint64_t)value->tv_sec * UINT64_C(1000000000) +
	       (uint64_t)value->tv_nsec;
}

static void reset_decision(struct router_dsa_decision *decision)
{
	memset(decision, 0, sizeof(*decision));
	decision->struct_size = sizeof(*decision);
}

static int parse_packet_arguments(int argc, char **argv,
                                  struct router_dsa_packet *packet,
                                  uint64_t *warmup, uint64_t *iterations)
{
	const char *source_ip = NULL;
	const char *destination_ip = NULL;
	uint32_t value;
	uint32_t eth_protocol = 0;
	int eth_protocol_set = 0;
	int timestamp_set = 0;
	int i;

	packet->ingress_ifindex = DEFAULT_INGRESS_IFINDEX;
	packet->packet_length = DEFAULT_PACKET_LENGTH;
	packet->ip_version = DEFAULT_IP_VERSION;
	packet->ip_protocol = DEFAULT_IP_PROTOCOL;
	*warmup = 0;
	*iterations = DEFAULT_ITERATIONS;

	/* Keep the original positional interface working for existing examples. */
	if (argc > 2 && strncmp(argv[2], "--", 2) != 0) {
		if (argc > 6) {
			fprintf(stderr, "too many positional arguments\n");
			return -1;
		}
		if (argc > 2) {
			if (parse_u32(argv[2], &value) != 0 || value == 0)
				goto invalid_ingress;
			packet->ingress_ifindex = value;
		}
		if (argc > 3) {
			if (parse_u32(argv[3], &value) != 0 || value == 0)
				goto invalid_length;
			packet->packet_length = value;
		}
		if (argc > 4) {
			if (parse_u32(argv[4], &value) != 0 ||
			    (value != 4 && value != 6))
				goto invalid_ip_version;
			packet->ip_version = (uint8_t)value;
		}
		if (argc > 5) {
			if (parse_u32(argv[5], &value) != 0 ||
			    value > UINT8_MAX)
				goto invalid_protocol;
			packet->ip_protocol = (uint8_t)value;
		}
	} else {
		for (i = 2; i < argc; i++) {
			const char *option = argv[i];
			const char *argument;

			if (strcmp(option, "--help") == 0) {
				print_usage(argv[0]);
				return 1;
			}
			if (i + 1 >= argc) {
				fprintf(stderr, "missing value for option %s\n", option);
				return -1;
			}
			argument = argv[++i];

			if (strcmp(option, "--ingress") == 0) {
				if (parse_u32(argument, &value) != 0 || value == 0)
					goto invalid_ingress;
				packet->ingress_ifindex = value;
			} else if (strcmp(option, "--length") == 0) {
				if (parse_u32(argument, &value) != 0 || value == 0)
					goto invalid_length;
				packet->packet_length = value;
			} else if (strcmp(option, "--ip-version") == 0) {
				if (parse_u32(argument, &value) != 0 ||
				    (value != 4 && value != 6))
					goto invalid_ip_version;
				packet->ip_version = (uint8_t)value;
			} else if (strcmp(option, "--protocol") == 0) {
				if (parse_u32(argument, &value) != 0 ||
				    value > UINT8_MAX)
					goto invalid_protocol;
				packet->ip_protocol = (uint8_t)value;
			} else if (strcmp(option, "--src-ip") == 0) {
				source_ip = argument;
			} else if (strcmp(option, "--dst-ip") == 0) {
				destination_ip = argument;
			} else if (strcmp(option, "--src-port") == 0) {
				if (parse_u32(argument, &value) != 0 ||
				    value > UINT16_MAX)
					goto invalid_source_port;
				packet->source_port = htons((uint16_t)value);
			} else if (strcmp(option, "--dst-port") == 0) {
				if (parse_u32(argument, &value) != 0 ||
				    value > UINT16_MAX)
					goto invalid_destination_port;
				packet->destination_port = htons((uint16_t)value);
			} else if (strcmp(option, "--mark") == 0) {
				if (parse_u32(argument, &packet->packet_mark) != 0)
					goto invalid_mark;
			} else if (strcmp(option, "--queue") == 0) {
				if (parse_u32(argument, &packet->queue_mapping) != 0)
					goto invalid_queue;
			} else if (strcmp(option, "--eth-protocol") == 0) {
				if (parse_u32(argument, &eth_protocol) != 0 ||
				    eth_protocol > UINT16_MAX)
					goto invalid_eth_protocol;
				eth_protocol_set = 1;
			} else if (strcmp(option, "--timestamp-ns") == 0) {
				if (parse_u64(argument, UINT64_MAX,
				              &packet->timestamp_ns) != 0)
					goto invalid_timestamp;
				timestamp_set = 1;
			} else if (strcmp(option, "--warmup") == 0) {
				if (parse_u64(argument, MAX_ITERATIONS, warmup) != 0)
					goto invalid_warmup;
			} else if (strcmp(option, "--iterations") == 0) {
				if (parse_u64(argument, MAX_ITERATIONS, iterations) != 0 ||
				    *iterations == 0)
					goto invalid_iterations;
			} else {
				fprintf(stderr, "unknown option: %s\n", option);
				return -1;
			}
		}
	}

	if (source_ip != NULL) {
		int family = packet->ip_version == 4 ? AF_INET : AF_INET6;
		if (inet_pton(family, source_ip, packet->source_address) != 1) {
			fprintf(stderr,
			        "source address does not match IP version %u: %s\n",
			        (unsigned)packet->ip_version, source_ip);
			return -1;
		}
	}
	if (destination_ip != NULL) {
		int family = packet->ip_version == 4 ? AF_INET : AF_INET6;
		if (inet_pton(family, destination_ip,
		              packet->destination_address) != 1) {
			fprintf(stderr,
			        "destination address does not match IP version %u: %s\n",
			        (unsigned)packet->ip_version, destination_ip);
			return -1;
		}
	}

	if (!eth_protocol_set)
		eth_protocol = packet->ip_version == 4 ? 0x0800u : 0x86ddu;
	packet->eth_protocol = htons((uint16_t)eth_protocol);

	if (!timestamp_set) {
		struct timespec now;
		if (clock_gettime(CLOCK_MONOTONIC, &now) == 0)
			packet->timestamp_ns = timespec_ns(&now);
	}

	return 0;

invalid_ingress:
	fprintf(stderr, "invalid ingress ifindex (expected 1..%u)\n", UINT32_MAX);
	return -1;
invalid_length:
	fprintf(stderr, "invalid packet length (expected 1..%u)\n", UINT32_MAX);
	return -1;
invalid_ip_version:
	fprintf(stderr, "ip-version must be 4 or 6\n");
	return -1;
invalid_protocol:
	fprintf(stderr, "invalid IP protocol (expected 0..255)\n");
	return -1;
invalid_source_port:
	fprintf(stderr, "invalid source port (expected 0..65535)\n");
	return -1;
invalid_destination_port:
	fprintf(stderr, "invalid destination port (expected 0..65535)\n");
	return -1;
invalid_mark:
	fprintf(stderr, "invalid packet mark (expected 0..%u)\n", UINT32_MAX);
	return -1;
invalid_queue:
	fprintf(stderr, "invalid queue mapping (expected 0..%u)\n", UINT32_MAX);
	return -1;
invalid_eth_protocol:
	fprintf(stderr, "invalid Ethernet protocol (expected 0..65535)\n");
	return -1;
invalid_timestamp:
	fprintf(stderr, "invalid timestamp (expected an unsigned 64-bit integer)\n");
	return -1;
invalid_warmup:
	fprintf(stderr, "invalid warmup count (expected 0..%" PRIu64 ")\n",
	        MAX_ITERATIONS);
	return -1;
invalid_iterations:
	fprintf(stderr, "invalid iteration count (expected 1..%" PRIu64 ")\n",
	        MAX_ITERATIONS);
	return -1;
}

static void print_address(const char *label, const uint8_t address[16],
                          uint8_t ip_version)
{
	char text[INET6_ADDRSTRLEN];
	int family = ip_version == 4 ? AF_INET : AF_INET6;

	if (inet_ntop(family, address, text, sizeof(text)) == NULL)
		strcpy(text, "unavailable");
	printf("%s=%s", label, text);
}

int main(int argc, char **argv)
{
	void *handle = NULL;
	void *symbol;
	union {
		void *object;
		router_dsa_get_algorithm_fn function;
	} entry;
	const struct router_dsa_algorithm *algorithm = NULL;
	struct router_dsa_context context;
	struct router_dsa_packet packet;
	struct router_dsa_decision decision;
	struct timespec start_time;
	struct timespec end_time;
	uint64_t warmup;
	uint64_t iterations;
	uint64_t start_ns;
	uint64_t end_ns;
	uint64_t elapsed_ns;
	uint64_t average_ns;
	uint64_t i;
	int initialized = 0;
	int parse_result;
	int status = EXIT_FAILURE;

	if (argc == 2 && strcmp(argv[1], "--help") == 0) {
		print_usage(argv[0]);
		return EXIT_SUCCESS;
	}
	if (argc < 2) {
		print_usage(argv[0]);
		return EXIT_FAILURE;
	}

	memset(&packet, 0, sizeof(packet));
	memset(&context, 0, sizeof(context));
	packet.struct_size = sizeof(packet);
	reset_decision(&decision);
	context.abi_version = ROUTER_DSA_ABI_VERSION;
	context.struct_size = sizeof(context);

	parse_result = parse_packet_arguments(argc, argv, &packet,
	                                      &warmup, &iterations);
	if (parse_result == 1)
		return EXIT_SUCCESS;
	if (parse_result != 0) {
		print_usage(argv[0]);
		return EXIT_FAILURE;
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
		fprintf(stderr, "plugin does not support DSA ABI v%u\n",
		        ROUTER_DSA_ABI_VERSION);
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

	for (i = 0; i < warmup; i++) {
		reset_decision(&decision);
		if (algorithm->process(&context, &packet, &decision) != 0) {
			fprintf(stderr, "plugin failed during warmup iteration %" PRIu64 "\n", i);
			goto out;
		}
	}

	if (clock_gettime(CLOCK_MONOTONIC, &start_time) != 0) {
		perror("clock_gettime");
		goto out;
	}
	start_ns = timespec_ns(&start_time);

	for (i = 0; i < iterations; i++) {
		reset_decision(&decision);
		if (algorithm->process(&context, &packet, &decision) != 0) {
			fprintf(stderr, "plugin failed during measured iteration %" PRIu64 "\n", i);
			goto out;
		}
	}

	if (clock_gettime(CLOCK_MONOTONIC, &end_time) != 0) {
		perror("clock_gettime");
		goto out;
	}
	end_ns = timespec_ns(&end_time);
	elapsed_ns = end_ns >= start_ns ? end_ns - start_ns : 0;
	average_ns = elapsed_ns / iterations;

	printf("plugin=%s version=%s stage=%s\n",
	       algorithm->name, algorithm->version, stage_name(algorithm->stage));
	printf("ingress_ifindex=%" PRIu32 " packet_length=%" PRIu32
	       " ip_version=%u ip_protocol=%u eth_protocol=0x%04x\n",
	       packet.ingress_ifindex, packet.packet_length,
	       (unsigned)packet.ip_version, (unsigned)packet.ip_protocol,
	       ntohs(packet.eth_protocol));
	print_address("source_ip", packet.source_address, packet.ip_version);
	printf(" ");
	print_address("destination_ip", packet.destination_address, packet.ip_version);
	printf("\nsource_port=%u destination_port=%u packet_mark=%" PRIu32
	       " queue_mapping=%" PRIu32 " timestamp_ns=%" PRIu64 "\n",
	       (unsigned)ntohs(packet.source_port),
	       (unsigned)ntohs(packet.destination_port),
	       packet.packet_mark, packet.queue_mapping, packet.timestamp_ns);
	printf("actions=0x%08" PRIx32 " mark=%" PRIu32
	       " queue=%" PRIu32 " egress_ifindex=%" PRIu32 "\n",
	       decision.actions, decision.mark,
	       decision.queue_mapping, decision.egress_ifindex);
	printf("warmup=%" PRIu64 " iterations=%" PRIu64
	       " elapsed_ns=%" PRIu64 " average_ns_per_callback=%" PRIu64 "\n",
	       warmup, iterations, elapsed_ns, average_ns);
	status = EXIT_SUCCESS;

out:
	if (initialized)
		algorithm->destroy(&context);
	if (handle != NULL)
		dlclose(handle);
	return status;
}
