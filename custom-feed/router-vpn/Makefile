#
# RouterOS VPN integration package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-vpn
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-vpn
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS VPN Integration
  DEPENDS:=+uci +kmod-wireguard +wireguard-tools
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-vpn/description
 RouterOS VPN configuration and management, primarily WireGuard integration.
endef

define Build/Compile
endef

define Package/router-vpn/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-vpn
	$(INSTALL_BIN) ./files/libexec/router-vpn-validate $(1)/usr/libexec/router-vpn/router-vpn-validate
	$(INSTALL_BIN) ./files/libexec/router-vpn-status $(1)/usr/libexec/router-vpn/router-vpn-status
endef

$(eval $(call BuildPackage,router-vpn))
