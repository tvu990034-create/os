#
# RouterOS network extensions.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-net
PKG_RELEASE:=3
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-net
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS Networking Extensions
  DEPENDS:=+procd +uci +router-dsa-runtime
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-net/description
 Optional network-device observer and DSA plugin integration tools for RouterOS.
endef

define Package/router-net/conffiles
/etc/config/router-net
endef

define Build/Compile
endef

define Package/router-net/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/libexec/router-net
	$(INSTALL_CONF) ./files/config/router-net $(1)/etc/config/router-net
	$(INSTALL_BIN) ./files/init.d/router-net $(1)/etc/init.d/router-net
	$(INSTALL_BIN) ./files/monitor-interfaces.sh $(1)/usr/libexec/router-net/monitor-interfaces.sh
endef

$(eval $(call BuildPackage,router-net))
