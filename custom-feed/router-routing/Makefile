#
# RouterOS routing management package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-routing
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-routing
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS Routing Management
  DEPENDS:=+uci +ip-full
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-routing/description
 RouterOS routing configuration and route diagnostics utilities.
endef

define Build/Compile
endef

define Package/router-routing/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-routing
	$(INSTALL_BIN) ./files/libexec/router-routing-status $(1)/usr/libexec/router-routing/router-routing-status
	$(INSTALL_BIN) ./files/libexec/router-routing-diagnostics $(1)/usr/libexec/router-routing/router-routing-diagnostics
endef

$(eval $(call BuildPackage,router-routing))
