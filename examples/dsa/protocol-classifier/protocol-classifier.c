/*
 * Example RouterOS DSA v1 classifier.
 *
 * Marks TCP flows as 0x1001 and UDP flows as 0x1002. This example consumes
 * synthetic packet metadata in the test runner; it is not attached to the
 * live packet-forwarding path.
 *
 * SPDX-License-Identifier: GPL-2.0-only
 */
#include <router-os/dsa.h>

#define MARK_TCP 0x1001u
#define MARK_UDP 0x1002u

static int classifier_init(struct router_dsa_context *context)
{
	if (context == 0 || context->abi_version != ROUTER_DSA_ABI_VERSION ||
	    context->struct_size < sizeof(*context))
		return -1;

	context->userdata = 0;
	return 0;
}

static int classifier_process(struct router_dsa_context *context,
                              const struct router_dsa_packet *packet,
                              struct router_dsa_decision *decision)
{
	(void)context;

	if (packet == 0 || decision == 0)
		return -1;
	if (packet->struct_size < sizeof(*packet) ||
	    decision->struct_size < sizeof(*decision))
		return -2;
	if (packet->ip_version != 4 && packet->ip_version != 6)
		return -3;

	decision->actions = ROUTER_DSA_ACTION_NONE;
	decision->mark = 0;

	switch (packet->ip_protocol) {
	case 6: /* TCP */
		decision->actions = ROUTER_DSA_ACTION_SET_MARK;
		decision->mark = MARK_TCP;
		break;
	case 17: /* UDP */
		decision->actions = ROUTER_DSA_ACTION_SET_MARK;
		decision->mark = MARK_UDP;
		break;
	default:
		break;
	}

	return 0;
}

static void classifier_destroy(struct router_dsa_context *context)
{
	(void)context;
}

static const struct router_dsa_algorithm classifier_algorithm = {
	.abi_version = ROUTER_DSA_ABI_VERSION,
	.struct_size = sizeof(struct router_dsa_algorithm),
	.name = "protocol-classifier",
	.version = "1.0.0",
	.stage = ROUTER_DSA_STAGE_CLASSIFY,
	.capabilities = ROUTER_DSA_CAP_THREAD_SAFE,
	.init = classifier_init,
	.process = classifier_process,
	.destroy = classifier_destroy
};

ROUTER_DSA_PLUGIN_EXPORT
const struct router_dsa_algorithm *
router_dsa_get_algorithm_v1(uint32_t requested_abi_version)
{
	if (requested_abi_version != ROUTER_DSA_ABI_VERSION)
		return 0;

	return &classifier_algorithm;
}
