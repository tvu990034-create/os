#include <router-os/dsa.h>

static uint32_t invocation_count;

static int sample_init(struct router_dsa_context *context)
{
	if (context == 0 || context->abi_version != ROUTER_DSA_ABI_VERSION)
		return -1;
	context->userdata = &invocation_count;
	return 0;
}

static int sample_process(struct router_dsa_context *context,
                          const struct router_dsa_packet *packet,
                          struct router_dsa_decision *decision)
{
	if (context == 0 || packet == 0 || decision == 0)
		return -1;
	if (packet->struct_size < sizeof(*packet) ||
	    decision->struct_size < sizeof(*decision))
		return -2;

	/* The smoke plugin deliberately makes no forwarding decision. */
	invocation_count++;
	decision->actions = ROUTER_DSA_ACTION_NONE;
	return 0;
}

static void sample_destroy(struct router_dsa_context *context)
{
	if (context != 0)
		context->userdata = 0;
}

static const struct router_dsa_algorithm sample_algorithm = {
	.abi_version = ROUTER_DSA_ABI_VERSION,
	.struct_size = sizeof(struct router_dsa_algorithm),
	.name = "abi-smoke",
	.version = "1.0.0",
	.stage = ROUTER_DSA_STAGE_OBSERVE,
	.capabilities = 0,
	.init = sample_init,
	.process = sample_process,
	.destroy = sample_destroy
};

ROUTER_DSA_PLUGIN_EXPORT
const struct router_dsa_algorithm *
router_dsa_get_algorithm_v1(uint32_t requested_abi_version)
{
	if (requested_abi_version != ROUTER_DSA_ABI_VERSION)
		return 0;
	return &sample_algorithm;
}
