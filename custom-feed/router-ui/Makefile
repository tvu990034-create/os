#
# RouterOS LuCI dashboard.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-ui
PKG_RELEASE:=4
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-ui
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=2. Modules
  TITLE:=RouterOS LuCI Dashboard
  DEPENDS:=+luci-base +luci-mod-status
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-ui/description
 RouterOS system overview page showing board, uptime, load and network interfaces.
endef

define Build/Compile
endef

define Package/router-ui/install
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/routeros
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/routeros.json $(1)/usr/share/luci/menu.d/routeros.json
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/routeros-dashboard.json $(1)/usr/share/rpcd/acl.d/routeros-dashboard.json
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/routeros/overview.js $(1)/www/luci-static/resources/view/routeros/overview.js
endef

$(eval $(call BuildPackage,router-ui))
