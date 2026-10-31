#!/bin/sh
# Backwards-compatible convenience entry point for the generic x86-64 profile.

set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$ROOT_DIR/scripts/build-platform.sh" x86_64
