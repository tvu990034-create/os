#
# RouterOS Management API package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-api
PKG_RELEASE:=3
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-api
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS Management API
  DEPENDS:=+uci +rpcd +libubox +uhttpd-mod-ubus
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-api/description
 Executable rpcd plugin exposing JSON-based RouterOS status and configuration
 methods through ubus. Network requests are validated before UCI is changed.
endef

define Package/router-api/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || /etc/init.d/rpcd reload
endef

define Build/Compile
endef

define Package/router-api/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_CONF) ./files/acl.d/router-api-acl.json $(1)/usr/share/rpcd/acl.d/router-api-acl.json
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./files/router-api $(1)/usr/libexec/rpcd/router-api
endef

$(eval $(call BuildPackage,router-api))
