#
# RouterOS Backup package.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-backup
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-backup
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=RouterOS Configuration Backup
  DEPENDS:=+uci
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-backup/description
 RouterOS configuration backup and restore with persistent storage.
endef

define Build/Compile
endef

define Package/router-backup/install
	$(INSTALL_DIR) $(1)/usr/libexec/router-backup
	$(INSTALL_BIN) ./files/libexec/router-backup $(1)/usr/libexec/router-backup/router-backup
	$(INSTALL_DIR) $(1)/etc/cron.d
	$(INSTALL_CONF) ./files/cron.d/router-backup-cron $(1)/etc/cron.d/router-backup
endef

$(eval $(call BuildPackage,router-backup))
