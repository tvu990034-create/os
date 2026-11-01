#
# RouterOS Upgrade package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-upgrade
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-upgrade
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=RouterOS Firmware Upgrade
  DEPENDS:=+uci
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-upgrade/description
 RouterOS firmware upgrade lifecycle management with sysupgrade integration.
endef

define Build/Compile
endef

define Package/router-upgrade/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-upgrade
	$(INSTALL_BIN) ./files/libexec/router-upgrade $(1)/usr/libexec/router-upgrade/router-upgrade
endef

$(eval $(call BuildPackage,router-upgrade))
