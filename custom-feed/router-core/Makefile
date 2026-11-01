#
# RouterOS core package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-core
PKG_RELEASE:=18
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-core
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=RouterOS Core Components
  DEPENDS:=+procd +uci
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-core/description
 RouterOS first-boot network defaults, hardware inventory and startup diagnostics.
 Network and system configuration are installed as a rootfs overlay to avoid
 package file ownership conflicts with OpenWrt base and service packages.
endef

define Build/Compile
endef

define Package/router-core/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_DIR) $(1)/usr/libexec/router-core
	$(INSTALL_BIN) ./files/uci-defaults/98_router-security $(1)/etc/uci-defaults/98_router-security
	$(INSTALL_BIN) ./files/uci-defaults/99_router-core $(1)/etc/uci-defaults/99_router-core
	$(INSTALL_BIN) ./files/uci-defaults/99_router-logging $(1)/etc/uci-defaults/99_router-logging
	$(INSTALL_BIN) ./files/init.d/router-core $(1)/etc/init.d/router-core
	$(INSTALL_BIN) ./files/libexec/router-hw-detect $(1)/usr/libexec/router-core/router-hw-detect
	$(INSTALL_BIN) ./files/libexec/router-status $(1)/usr/libexec/router-core/router-status
	$(INSTALL_BIN) ./files/libexec/router-shutdown $(1)/usr/libexec/router-core/router-shutdown
	$(INSTALL_BIN) ./files/libexec/router-config $(1)/usr/libexec/router-core/router-config
	$(INSTALL_BIN) ./files/libexec router-supervisor $(1)/usr/libexec/router-core/router-supervisor
	$(INSTALL_BIN) ./files/libexec router-setup-wizard $(1)/usr/libexec/router-core/router-setup-wizard
	$(INSTALL_BIN) ./files/hotplug.d/iface/99_router-core $(1)/etc/hotplug.d/iface/99_router-core
	$(INSTALL_BIN) ./files/hotplug.d/net/99_router-core $(1)/etc/hotplug.d/net/99_router-core
endef

$(eval $(call BuildPackage,router-core))
