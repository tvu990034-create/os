#
# RouterOS DSA plugin loader and test runner.
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=router-dsa-runtime
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Router OS Project

include $(INCLUDE_DIR)/package.mk

define Package/router-dsa-runtime
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RouterOS DSA Plugin Runtime
  DEPENDS:=+router-dsa-sdk
  DEFAULT:=y if TARGET_x86||TARGET_armsr
endef

define Package/router-dsa-runtime/description
 User-space shared-object loader and test runner for RouterOS DSA ABI v1 plugins.
 It executes a plugin against supplied packet metadata; it does not intercept
 live packets or alter the Linux forwarding path.
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) ./src/router-dsa-run.c $(PKG_BUILD_DIR)/router-dsa-run.c
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/include/router-os
	# Copy header from router-dsa-sdk source (not from installed location)
	$(CP) $(TOPDIR)/feeds/routeros/router-dsa-sdk/files/include/router-os/dsa.h $(PKG_BUILD_DIR)/include/router-os/dsa.h || \
		$(CP) ../router-dsa-sdk/files/include/router-os/dsa.h $(PKG_BUILD_DIR)/include/router-os/dsa.h
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CPPFLAGS) $(TARGET_CFLAGS) \
		-I$(PKG_BUILD_DIR)/include \
		-o $(PKG_BUILD_DIR)/router-dsa-run \
		$(PKG_BUILD_DIR)/router-dsa-run.c \
		$(TARGET_LDFLAGS) -ldl
endef

define Build/Clean
	rm -rf $(PKG_BUILD_DIR)
endef

define Package/router-dsa-runtime/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/router-dsa-run $(1)/usr/bin/router-dsa-run
endef

$(eval $(call BuildPackage,router-dsa-runtime))
