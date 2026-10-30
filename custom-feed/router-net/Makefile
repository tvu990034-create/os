#
# Copyright (C) 2026 Router OS Project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-net
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-net
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Router OS Networking Extensions
  DEPENDS:=+netifd +procd +uci
  DEFAULT:=n
endef

define Package/router-net/description
  Router OS network interface state monitor, managed as a supervised
  procd service and configured through UCI.
endef

define Build/Compile
	# No compilation needed - shell scripts only
endef

define Package/router-net/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-net
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/*.sh $(1)/usr/libexec/router-net/
	$(INSTALL_CONF) ./files/config/* $(1)/etc/config/
	$(INSTALL_BIN) ./files/init.d/* $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/uci-defaults/* $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,router-net))
