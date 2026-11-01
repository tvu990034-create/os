#
# RouterOS DNS management package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-dns
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-dns
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS DNS Management
  DEPENDS:=+uci +dnsmasq
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-dns/description
 RouterOS DNS configuration and diagnostics utilities.
 Integrates with OpenWrt dnsmasq.
endef

define Build/Compile
endef

define Package/router-dns/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-dns
	$(INSTALL_BIN) ./files/libexec/router-dns-validate $(1)/usr/libexec/router-dns/router-dns-validate
	$(INSTALL_BIN) ./files/libexec/router-dns-status $(1)/usr/libexec/router-dns/router-dns-status
endef

$(eval $(call BuildPackage,router-dns))
