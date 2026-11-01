#
# RouterOS on-device smoke-test package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-tests
PKG_RELEASE:=3
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-tests
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=RouterOS Runtime Test Suite
  DEPENDS:=+uci +ip-tiny +router-core +router-net
  DEFAULT:=n
endef

define Package/router-tests/description
 On-device smoke tests for RouterOS configuration, hardware inventory and networking.
endef

define Build/Compile
endef

define Package/router-tests/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-tests
	$(INSTALL_BIN) ./files/test-config-syntax.sh $(1)/usr/libexec/router-tests/test-config-syntax.sh
	$(INSTALL_BIN) ./files/test-hardware-detect.sh $(1)/usr/libexec/router-tests/test-hardware-detect.sh
	$(INSTALL_BIN) ./files/test-network-validation.sh $(1)/usr/libexec/router-tests/test-network-validation.sh
	$(INSTALL_BIN) ./files/test-connectivity.sh $(1)/usr/libexec/router-tests/test-connectivity.sh
endef

$(eval $(call BuildPackage,router-tests))
