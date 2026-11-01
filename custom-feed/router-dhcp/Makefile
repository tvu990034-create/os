#
# RouterOS DHCP management package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-dhcp
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-dhcp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS DHCP Management
  DEPENDS:=+uci +dnsmasq +odhcpd
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-dhcp/description
 RouterOS DHCP configuration and management utilities.
 Integrates with OpenWrt dnsmasq and odhcpd.
endef

define Build/Compile
endef

define Package/router-dhcp/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-dhcp
	$(INSTALL_BIN) ./files/libexec/router-dhcp-validate $(1)/usr/libexec/router-dhcp/router-dhcp-validate
	$(INSTALL_BIN) ./files/libexec/router-dhcp-status $(1)/usr/libexec/router-dhcp/router-dhcp-status
endef

$(eval $(call BuildPackage,router-dhcp))
