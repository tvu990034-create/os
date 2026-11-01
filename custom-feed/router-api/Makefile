#
# RouterOS Management API package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-api
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-api
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS Management API
  DEPENDS:=+uci +rpcd +uhttpd-mod-ubus
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-api/description
 RouterOS structured management API for LuCI integration.
 Provides RPC methods for system and network management.
endef

define Build/Compile
endef

define Package/router-api/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_CONF) ./files/acl.d/router-api-acl.json $(1)/usr/share/rpcd/acl.d/router-api-acl.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd
	$(INSTALL_CONF) ./files/router-api $(1)/usr/share/rpcd/router-api
endef

$(eval $(call BuildPackage,router-api))
