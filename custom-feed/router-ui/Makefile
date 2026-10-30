#
# RouterOS LuCI integration placeholder.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-ui
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-ui
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=2. Modules
  TITLE:=RouterOS LuCI Integration Placeholder
  DEPENDS:=+luci-base
  DEFAULT:=n
endef

define Package/router-ui/description
 Reserved package for future RouterOS LuCI views and controls. No custom UI
 files are included yet; the package intentionally remains disabled by default.
endef

define Build/Compile
endef

define Package/router-ui/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/www/luci-static/resources
endef

$(eval $(call BuildPackage,router-ui))
