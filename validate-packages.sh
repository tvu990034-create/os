#!/bin/bash
# Validate Router OS Package Structure
# This script validates package Makefiles and file structure without building

echo "=== Router OS Package Validation ==="
echo ""

VALIDATION_FAILED=0

# Function to check package
check_package() {
	local pkg_dir=$1
	local pkg_name=$(basename "$pkg_dir")
	
	echo "Checking package: $pkg_name"
	
	# Check for Makefile
	if [ ! -f "$pkg_dir/Makefile" ]; then
		echo "  ✗ Makefile missing"
		VALIDATION_FAILED=1
		return
	fi
	echo "  ✓ Makefile exists"
	
	# Check Makefile syntax (basic)
	if grep -q "include \$(TOPDIR)/rules.mk" "$pkg_dir/Makefile"; then
		echo "  ✓ Makefile includes rules.mk"
	else
		echo "  ✗ Makefile doesn't include rules.mk"
		VALIDATION_FAILED=1
	fi
	
	if grep -q "include \$(INCLUDE_DIR)/package.mk" "$pkg_dir/Makefile"; then
		echo "  ✓ Makefile includes package.mk"
	else
		echo "  ✗ Makefile doesn't include package.mk"
		VALIDATION_FAILED=1
	fi
	
	if grep -q "\$(eval \$(call BuildPackage," "$pkg_dir/Makefile"; then
		echo "  ✓ Makefile calls BuildPackage"
	else
		echo "  ✗ Makefile doesn't call BuildPackage"
		VALIDATION_FAILED=1
	fi
	
	# Check for files directory
	if [ -d "$pkg_dir/files" ]; then
		echo "  ✓ files/ directory exists"
		
		# Check for executable scripts
		for script in $(find "$pkg_dir/files" -type f -name "*.sh"); do
			if [ -x "$script" ]; then
				echo "    ✓ $(basename $script) is executable"
			else
				echo "    ⚠ $(basename $script) is not executable"
			fi
		done
	else
		echo "  ℹ files/ directory not present (OK for skeleton packages)"
	fi
	
	# Check for README
	if [ -f "$pkg_dir/README.md" ]; then
		echo "  ✓ README.md exists"
	else
		echo "  ℹ README.md not present (optional)"
	fi
	
	echo ""
}

# Check all packages in custom-feed
for pkg_dir in custom-feed/*/; do
	if [ -d "$pkg_dir" ]; then
		check_package "$pkg_dir"
	fi
done

# Check custom directory structure
echo "Checking custom/ directory structure"
if [ -d "custom" ]; then
	echo "  ✓ custom/ exists"
	
	if [ -d "custom/build" ]; then
		echo "  ✓ custom/build/ exists"
	else
		echo "  ✗ custom/build/ missing"
		VALIDATION_FAILED=1
	fi
	
	if [ -d "custom/configs" ]; then
		echo "  ✓ custom/configs/ exists"
	else
		echo "  ✗ custom/configs/ missing"
		VALIDATION_FAILED=1
	fi
	
	if [ -d "custom/kernel" ]; then
		echo "  ✓ custom/kernel/ exists"
	else
		echo "  ✗ custom/kernel/ missing"
		VALIDATION_FAILED=1
	fi
	
	if [ -d "custom/docs" ]; then
		echo "  ✓ custom/docs/ exists"
	else
		echo "  ✗ custom/docs/ missing"
		VALIDATION_FAILED=1
	fi
else
	echo "  ✗ custom/ missing"
	VALIDATION_FAILED=1
fi

echo ""

# Check setup script
if [ -f "setup.sh" ]; then
	if [ -x "setup.sh" ]; then
		echo "✓ setup.sh exists and is executable"
	else
		echo "⚠ setup.sh exists but is not executable"
	fi
else
	echo "✗ setup.sh missing"
	VALIDATION_FAILED=1
fi

echo ""

# Check documentation
echo "Checking documentation"
for doc in README.md BUILD_INSTRUCTIONS.md ARCHITECTURE.md; do
	if [ -f "$doc" ]; then
		echo "  ✓ $doc exists"
	else
		echo "  ✗ $doc missing"
		VALIDATION_FAILED=1
	fi
done

echo ""

# Summary
if [ $VALIDATION_FAILED -eq 0 ]; then
	echo "=== Validation PASSED ==="
	exit 0
else
	echo "=== Validation FAILED ==="
	exit 1
fi
