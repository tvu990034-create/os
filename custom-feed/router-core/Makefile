#
# Copyright (C) 2026 Router OS Project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-core
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-core
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Router OS Core Components
  DEPENDS:=+procd +uci +ubus +netifd +firewall4 +kmod-nft-core +dnsmasq +odhcpd
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-core/description
  Core components for Router OS including system initialization,
  hardware detection, and configuration management.
endef

define Build/Compile
	# No compilation needed for this package
endef

define Package/router-core/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/libexec/router-core
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_BIN) ./files/uci-defaults/* $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/init.d/* $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/libexec/* $(1)/usr/libexec/router-core/
	$(INSTALL_CONF) ./files/config/* $(1)/etc/config/
	$(INSTALL_BIN) ./files/hotplug.d/iface/* $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) ./files/hotplug.d/net/* $(1)/etc/hotplug.d/net/
endef

$(eval $(call BuildPackage,router-core))
