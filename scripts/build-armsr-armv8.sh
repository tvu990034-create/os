#!/bin/sh
# Convenience entry point for the experimental generic ARMv8 EFI profile.

set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$ROOT_DIR/scripts/build-platform.sh" armsr_armv8
