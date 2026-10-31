#
# RouterOS device discovery package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-device
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-device
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=RouterOS Hardware Discovery
  DEPENDS:=+uci
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-device/description
 RouterOS hardware discovery and platform capability reporting.
endef

define Build/Compile
endef

define Package/router-device/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-device
	$(INSTALL_BIN) ./files/libexec/router-device-info $(1)/usr/libexec/router-device/router-device-info
	$(INSTALL_BIN) ./files/libexec/router-device-capabilities $(1)/usr/libexec/router-device/router-device-capabilities
endef

$(eval $(call BuildPackage,router-device))
