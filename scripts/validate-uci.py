#!/usr/bin/env python3
"""Validate the small UCI subset used by RouterOS config files."""

from __future__ import annotations

import shlex
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIGS = [
    # Service overlays only. network/system are generated from OpenWrt board data.
    "custom/overlay/etc/config/firewall",
    "custom/overlay/etc/config/dhcp",
    "custom-feed/router-net/files/config/router-net",
]


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    current_section = False

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        try:
            tokens = shlex.split(raw_line, comments=True, posix=True)
        except ValueError as exc:
            errors.append(f"line {line_number}: {exc}")
            continue

        if not tokens:
            continue

        directive = tokens[0]
        if directive == "config":
            if len(tokens) not in (2, 3):
                errors.append(f"line {line_number}: config expects a type and optional name")
            else:
                current_section = True
        elif directive in ("option", "list"):
            if not current_section:
                errors.append(f"line {line_number}: {directive} appears before any config section")
            if len(tokens) != 3:
                errors.append(f"line {line_number}: {directive} expects a name and one value")
        else:
            errors.append(
                f"line {line_number}: unsupported directive {directive!r}; "
                "expected config, option, list, or comment"
            )

    return errors


def main() -> int:
    failed = False
    for relative in CONFIGS:
        path = ROOT / relative
        if not path.is_file():
            print(f"FAIL: missing {relative}")
            failed = True
            continue

        errors = validate(path)
        if errors:
            failed = True
            for error in errors:
                print(f"FAIL: {relative}:{error}")
        else:
            print(f"PASS: {relative}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
