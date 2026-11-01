#!/usr/bin/env python3
"""Validate RouterOS LuCI menu metadata and its read-only RPC ACL."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "custom-feed/router-ui/files/usr/share/luci/menu.d/routeros.json"
ACL = ROOT / "custom-feed/router-ui/files/usr/share/rpcd/acl.d/routeros-dashboard.json"
VIEW = ROOT / "custom-feed/router-ui/files/www/luci-static/resources/view/routeros/overview.js"


def main() -> int:
    try:
        menu = json.loads(MENU.read_text(encoding="utf-8"))
        acl = json.loads(ACL.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"FAIL: invalid or missing LuCI metadata: {exc}")
        return 1

    page = menu.get("admin/status/routeros")
    if not isinstance(page, dict):
        print("FAIL: RouterOS menu entry is missing")
        return 1
    if page.get("action", {}).get("type") != "view":
        print("FAIL: RouterOS menu entry is not a LuCI view")
        return 1
    if page.get("action", {}).get("path") != "routeros/overview":
        print("FAIL: RouterOS view path is incorrect")
        return 1
    if "routeros-dashboard" not in page.get("depends", {}).get("acl", []):
        print("FAIL: RouterOS page does not require its dedicated ACL")
        return 1

    policy = acl.get("routeros-dashboard")
    if not isinstance(policy, dict):
        print("FAIL: RouterOS RPC ACL is missing")
        return 1
    if policy.get("write"):
        print("FAIL: dashboard ACL unexpectedly grants write permissions")
        return 1

    allowed = policy.get("read", {}).get("ubus", {})
    expected = {
        "system": {"board", "info"},
        "network.interface": {"dump"},
    }
    for object_name, methods in expected.items():
        configured = set(allowed.get(object_name, []))
        if not methods.issubset(configured):
            print(f"FAIL: dashboard ACL is missing read methods for {object_name}")
            return 1

    if not VIEW.is_file():
        print("FAIL: RouterOS LuCI JavaScript view is missing")
        return 1

    print("PASS: RouterOS LuCI menu, read-only RPC ACL and view files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
