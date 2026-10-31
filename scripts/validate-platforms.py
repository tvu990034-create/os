#!/usr/bin/env python3
"""Validate RouterOS platform registry entries and their OpenWrt config selectors."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "config/platforms.tsv"
REQUIRED_PACKAGES = (
    "router-core",
    "router-net",
    "router-dsa-sdk",
    "router-dsa-runtime",
    "router-ui",
)
VALID_STATUSES = {"development", "experimental"}


def main() -> int:
    if not REGISTRY.is_file():
        print(f"FAIL: missing platform registry: {REGISTRY}")
        return 1

    seen: set[str] = set()
    rows = 0
    failed = False

    for line_number, raw_line in enumerate(REGISTRY.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        fields = line.split()
        if len(fields) != 5:
            print(f"FAIL: {REGISTRY}:{line_number}: expected 5 fields")
            failed = True
            continue

        profile, target, subtarget, config_rel, status = fields
        if not re.fullmatch(r"[a-z0-9_]+", profile):
            print(f"FAIL: invalid profile name at line {line_number}: {profile}")
            failed = True
            continue
        if profile in seen:
            print(f"FAIL: duplicate profile name: {profile}")
            failed = True
            continue
        seen.add(profile)
        rows += 1

        if not re.fullmatch(r"[a-z0-9_]+", target) or not re.fullmatch(r"[a-z0-9_]+", subtarget):
            print(f"FAIL: invalid target/subtarget for {profile}")
            failed = True
            continue
        if status not in VALID_STATUSES:
            print(f"FAIL: invalid profile status for {profile}: {status}")
            failed = True

        config_path = (ROOT / config_rel).resolve()
        if ROOT not in config_path.parents or not config_path.is_file():
            print(f"FAIL: {profile} references a missing or out-of-repository config: {config_rel}")
            failed = True
            continue

        config_lines = {
            item.strip()
            for item in config_path.read_text(encoding="utf-8").splitlines()
            if item.strip() and not item.lstrip().startswith("#")
        }
        required_selectors = {
            f"CONFIG_TARGET_{target}=y",
            f"CONFIG_TARGET_{target}_{subtarget}=y",
        }
        missing_selectors = sorted(required_selectors - config_lines)
        if missing_selectors:
            print(f"FAIL: {profile} is missing target selectors: {', '.join(missing_selectors)}")
            failed = True

        devices = [
            item for item in config_lines
            if item.startswith("CONFIG_TARGET_DEVICE_") and item.endswith("=y")
        ]
        if len(devices) != 1:
            print(f"FAIL: {profile} must select exactly one generic/device profile; found {len(devices)}")
            failed = True

        missing_packages = [
            package for package in REQUIRED_PACKAGES
            if f"CONFIG_PACKAGE_{package}=y" not in config_lines
        ]
        if missing_packages:
            print(f"FAIL: {profile} is missing RouterOS packages: {', '.join(missing_packages)}")
            failed = True

        print(f"{'FAIL' if failed else 'PASS'}: {profile} -> {target}/{subtarget} ({status})")

    if rows == 0:
        print("FAIL: platform registry contains no profiles")
        return 1
    if failed:
        return 1

    print(f"PASS: validated {rows} RouterOS platform profiles")
    return 0


if __name__ == "__main__":
    sys.exit(main())
