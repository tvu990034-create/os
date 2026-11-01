#
# RouterOS QoS and traffic management package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-qos
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-qos
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS QoS and Traffic Management
  DEPENDS:=+uci +kmod-sched-core +kmod-sched-cake +kmod-sched-htb +tc
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-qos/description
 RouterOS QoS configuration, traffic classification and bandwidth management.
 Integrates with Linux tc and Cake/HTB schedulers.
endef

define Build/Compile
endef

define Package/router-qos/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-qos
	$(INSTALL_BIN) ./files/libexec/router-qos-validate $(1)/usr/libexec/router-qos/router-qos-validate
	$(INSTALL_BIN) ./files/libexec/router-qos-apply $(1)/usr/libexec/router-qos/router-qos-apply
	$(INSTALL_BIN) ./files/libexec/router-qos-status $(1)/usr/libexec/router-qos/router-qos-status
endef

$(eval $(call BuildPackage,router-qos))
