#
# RouterOS DSA plugin development interface (headers only).
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-dsa-sdk
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-dsa-sdk
  SECTION:=devel
  CATEGORY:=Development
  TITLE:=RouterOS DSA Plugin SDK
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-dsa-sdk/description
 Versioned C ABI headers for implementing and testing RouterOS data-structure
 and algorithm plugins. This package contains no packet-processing runtime.
endef

define Build/Compile
endef

define Package/router-dsa-sdk/install
	$(INSTALL_DIR) $(1)/usr/include/router-os
	$(INSTALL_DATA) ./files/include/router-os/dsa.h $(1)/usr/include/router-os/dsa.h
endef

$(eval $(call BuildPackage,router-dsa-sdk))
