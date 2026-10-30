# OpenWrt Revision Pinning

## Current OpenWrt Revision

**Commit**: ca454c0
**Repository**: https://github.com/openwrt/openwrt.git
**Date Pinned**: 2026-10-30

## How to Update OpenWrt Revision

To update to a newer OpenWrt revision:

1. Check OpenWrt stable releases: https://openwrt.org/downloads
2. Find the desired commit hash
3. Update this file with the new commit
4. Update the OPENWRT_COMMIT environment variable in `.github/workflows/build-and-test.yml`
5. Update the OPENWRT_COMMIT in any local build scripts

## Why Pin the Revision

Pinning the OpenWrt revision ensures:
- Reproducible builds across different environments
- Consistent dependency resolution
- Known working configuration
- Ability to track when OpenWrt changes might break compatibility

## Current Branch

The pinned commit is on the main branch of OpenWrt.

## Known Issues with This Revision

None known at this time.

## Testing Performed

- Package structure validation: PASSED
- Feed configuration: Validated

## Notes

This revision was chosen as it represents a stable, recent commit from the OpenWrt main branch at the time of Router OS initial development.
