#!/bin/sh
# Validate package structure, registered platform profiles, shell, UCI and DSA ABI.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FAILED=0

fail() {
	echo "FAIL: $1"
	FAILED=1
}

pass() {
	echo "PASS: $1"
}

echo "=== RouterOS source validation ==="

for package in router-core router-net router-tests router-ui router-dsa-sdk router-dsa-runtime; do
	if [ -f "$ROOT_DIR/custom-feed/$package/Makefile" ]; then
		pass "$package Makefile exists"
		if grep -Fq 'include $(TOPDIR)/rules.mk' "$ROOT_DIR/custom-feed/$package/Makefile" &&
		   grep -Fq 'include $(INCLUDE_DIR)/package.mk' "$ROOT_DIR/custom-feed/$package/Makefile" &&
		   grep -Fq '$(eval $(call BuildPackage,' "$ROOT_DIR/custom-feed/$package/Makefile"; then
			pass "$package Makefile has the required OpenWrt package structure"
		else
			fail "$package Makefile is missing a required OpenWrt include or BuildPackage call"
		fi
	else
		fail "$package Makefile is missing"
	fi
done

SDK_CONFIG="$ROOT_DIR/config/sdk-package-build.config"
if [ -f "$SDK_CONFIG" ]; then
	for package in router-core router-net router-dsa-sdk router-dsa-runtime router-tests router-ui; do
		if grep -Fqx "CONFIG_PACKAGE_${package}=y" "$SDK_CONFIG"; then
			pass "SDK profile selects $package"
		else
			fail "SDK profile does not select $package"
		fi
	done
else
	fail "minimal SDK package-build configuration is missing"
fi

for script in \
	"$ROOT_DIR/setup.sh" \
	"$ROOT_DIR/validate-packages.sh" \
	"$ROOT_DIR/scripts/build-platform.sh" \
	"$ROOT_DIR/scripts/build-x86_64.sh" \
	"$ROOT_DIR/scripts/build-armsr-armv8.sh" \
	"$ROOT_DIR/scripts/install-build-deps-ubuntu.sh" \
	"$ROOT_DIR/custom-feed/router-core/files/init.d/router-core" \
	"$ROOT_DIR/custom-feed/router-core/files/libexec/router-hw-detect" \
	"$ROOT_DIR/custom-feed/router-core/files/uci-defaults/99_router-core" \
	"$ROOT_DIR/custom-feed/router-net/files/init.d/router-net" \
	"$ROOT_DIR/custom-feed/router-net/files/monitor-interfaces.sh" \
	"$ROOT_DIR/custom-feed/router-tests/files/test-config-syntax.sh" \
	"$ROOT_DIR/custom-feed/router-tests/files/test-hardware-detect.sh" \
	"$ROOT_DIR/custom-feed/router-tests/files/test-network-validation.sh" \
	"$ROOT_DIR/tests/dsa-sdk/test-plugin.sh" \
	"$ROOT_DIR/tests/router-core/test-firstboot-network.sh" \
	"$ROOT_DIR/tests/setup/test-setup-overlay.sh"; do
	if [ -f "$script" ] && sh -n "$script"; then
		relative_path=${script#"$ROOT_DIR"/}
		pass "shell syntax: $relative_path"
	else
		fail "shell syntax: $script"
	fi
done

if command -v python3 >/dev/null 2>&1; then
	if python3 "$ROOT_DIR/scripts/validate-platforms.py"; then
		pass "registered platform profiles"
	else
		fail "registered platform profiles"
	fi
	if python3 "$ROOT_DIR/scripts/validate-uci.py"; then
		pass "UCI configuration syntax"
	else
		fail "UCI configuration syntax"
	fi
	if python3 "$ROOT_DIR/scripts/validate-ui.py"; then
		pass "LuCI dashboard metadata and read-only ACL"
	else
		fail "LuCI dashboard metadata and read-only ACL"
	fi
else
	fail "python3 is required for platform, UCI and UI validation"
fi

if [ -x "$ROOT_DIR/tests/setup/test-setup-overlay.sh" ]; then
	if "$ROOT_DIR/tests/setup/test-setup-overlay.sh"; then
		pass "board-aware overlay synchronization and conflict protection"
	else
		fail "board-aware overlay synchronization and conflict protection"
	fi
else
	fail "rootfs overlay setup test is not executable"
fi

if [ -x "$ROOT_DIR/tests/router-core/test-firstboot-network.sh" ]; then
	if "$ROOT_DIR/tests/router-core/test-firstboot-network.sh"; then
		pass "first-boot defaults and board-network preservation"
	else
		fail "first-boot network test"
	fi
else
	fail "first-boot network test is not executable"
fi

if command -v node >/dev/null 2>&1; then
	if node --check "$ROOT_DIR/custom-feed/router-ui/files/www/luci-static/resources/view/routeros/overview.js"; then
		pass "LuCI dashboard JavaScript syntax"
	else
		fail "LuCI dashboard JavaScript syntax"
	fi
else
	fail "nodejs is required for LuCI JavaScript validation"
fi

if [ -x "$ROOT_DIR/tests/dsa-sdk/test-plugin.sh" ]; then
	if "$ROOT_DIR/tests/dsa-sdk/test-plugin.sh"; then
		pass "DSA plugin ABI and runner tests"
	else
		fail "DSA plugin ABI test"
	fi
else
	fail "DSA plugin ABI test script is not executable"
fi

if [ "$FAILED" -eq 0 ]; then
	echo "=== RouterOS source validation PASSED ==="
	exit 0
fi

echo "=== RouterOS source validation FAILED ==="
exit 1
