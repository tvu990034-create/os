#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <router-os/dsa.h>

int main(int argc, char **argv)
{
	void *handle;
	void *symbol;
	router_dsa_get_algorithm_fn get_algorithm;
	const struct router_dsa_algorithm *algorithm;
	struct router_dsa_context context = {
		.abi_version = ROUTER_DSA_ABI_VERSION,
		.struct_size = sizeof(struct router_dsa_context),
		.userdata = 0
	};
	struct router_dsa_packet packet = {
		.struct_size = sizeof(struct router_dsa_packet),
		.ingress_ifindex = 2,
		.packet_length = 64,
		.ip_version = 4,
		.ip_protocol = 17
	};
	struct router_dsa_decision decision = {
		.struct_size = sizeof(struct router_dsa_decision),
		.actions = ROUTER_DSA_ACTION_NONE,
		.mark = 0,
		.queue_mapping = 0,
		.egress_ifindex = 0
	};

	if (argc != 2) {
		fprintf(stderr, "usage: %s plugin.so\n", argv[0]);
		return 2;
	}

	handle = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
	if (handle == 0) {
		fprintf(stderr, "dlopen failed: %s\n", dlerror());
		return 1;
	}

	dlerror();
	symbol = dlsym(handle, ROUTER_DSA_PLUGIN_ENTRY);
	if (symbol == 0 || dlerror() != 0) {
		fprintf(stderr, "plugin entry point not found\n");
		dlclose(handle);
		return 1;
	}

	/* POSIX specifies dlsym() for function symbols; copy the pointer safely. */
	memcpy(&get_algorithm, &symbol, sizeof(get_algorithm));
	algorithm = get_algorithm(ROUTER_DSA_ABI_VERSION);
	if (algorithm == 0 || algorithm->abi_version != ROUTER_DSA_ABI_VERSION ||
	    algorithm->struct_size < sizeof(*algorithm) ||
	    algorithm->stage != ROUTER_DSA_STAGE_OBSERVE ||
	    algorithm->name == 0 || strcmp(algorithm->name, "abi-smoke") != 0) {
		fprintf(stderr, "plugin descriptor validation failed\n");
		dlclose(handle);
		return 1;
	}

	if (get_algorithm(ROUTER_DSA_ABI_VERSION + 1u) != 0) {
		fprintf(stderr, "plugin accepted an unsupported ABI version\n");
		dlclose(handle);
		return 1;
	}

	if (algorithm->init == 0 || algorithm->process == 0 || algorithm->destroy == 0 ||
	    algorithm->init(&context) != 0 ||
	    algorithm->process(&context, &packet, &decision) != 0 ||
	    decision.actions != ROUTER_DSA_ACTION_NONE) {
		fprintf(stderr, "plugin lifecycle smoke test failed\n");
		if (algorithm->destroy != 0)
			algorithm->destroy(&context);
		dlclose(handle);
		return 1;
	}

	algorithm->destroy(&context);
	dlclose(handle);
	puts("DSA plugin ABI v1 smoke test passed.");
	return 0;
}
