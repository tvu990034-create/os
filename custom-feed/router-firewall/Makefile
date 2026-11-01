#
# RouterOS firewall management package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-firewall
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-firewall
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS Firewall Management
  DEPENDS:=+uci +firewall4 +kmod-nft-core
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-firewall/description
 RouterOS firewall configuration, validation and management utilities.
 Integrates with OpenWrt firewall4 and nftables.
endef

define Package/router-firewall/conffiles
/etc/config/router-firewall
endef

define Build/Compile
endef

define Package/router-firewall/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/usr/libexec/router-firewall
	$(INSTALL_CONF) ./files/config/router-firewall $(1)/etc/config/router-firewall
	$(INSTALL_BIN) ./files/libexec/router-firewall-validate $(1)/usr/libexec/router-firewall/router-firewall-validate
	$(INSTALL_BIN) ./files/libexec/router-firewall-diagnostics $(1)/usr/libexec/router-firewall/router-firewall-diagnostics
endef

$(eval $(call BuildPackage,router-firewall))
