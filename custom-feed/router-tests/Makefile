#
# Copyright (C) 2026 Router OS Project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-tests
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-tests
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Router OS Test Suite
  DEPENDS:=+bash +coreutils +iproute2 +kmod-nft-core
  DEFAULT:=n
endef

define Package/router-tests/description
  Automated test suite for Router OS including configuration validation,
  hardware detection, and network functionality tests.
endef

define Build/Compile
	# No compilation needed
endef

define Package/router-tests/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-tests
	$(INSTALL_BIN) ./files/test-config-syntax.sh $(1)/usr/libexec/router-tests/
	$(INSTALL_BIN) ./files/test-hardware-detect.sh $(1)/usr/libexec/router-tests/
	$(INSTALL_BIN) ./files/test-network-validation.sh $(1)/usr/libexec/router-tests/
	$(INSTALL_BIN) ./files/test-integration.sh $(1)/usr/libexec/router-tests/
endef

$(eval $(call BuildPackage,router-tests))
