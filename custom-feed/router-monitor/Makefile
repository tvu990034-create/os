#
# RouterOS monitoring package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-monitor
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-monitor
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=RouterOS System Monitoring
  DEPENDS:=+uci +procd
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-monitor/description
 RouterOS system and network monitoring utilities.
endef

define Build/Compile
endef

define Package/router-monitor/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-monitor
	$(INSTALL_BIN) ./files/libexec/router-monitor-system $(1)/usr/libexec/router-monitor/router-monitor-system
	$(INSTALL_BIN) ./files/libexec/router-monitor-network $(1)/usr/libexec/router-monitor/router-monitor-network
endef

$(eval $(call BuildPackage,router-monitor))
