#
# Copyright (C) 2014 JH de Wolff (jaap@de-wolff.org)
#
# This file is a part of the open-giethoorn project 
#	http://github.com/de-wolff/OpenGiethoorn
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id$

include $(TOPDIR)/rules.mk

PKG_NAME:=open-giethoorn
PKG_VERSION:=0.1.0
PKG_RELEASE:=0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git://github.com/de-wolff/OpenGiethoorn.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=c44a160956ba80371439050551e6370ab8680698
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MIRROR_MD5SUM:=

include $(INCLUDE_DIR)/package.mk

define Package/open-giethoorn
	SECTION:=network
	CATEGORY:=Network
	TITLE:=open-giethoorn
	DEPENDS:= +dnsmasq +firewall +openvpn-openssl +openvpn-easy-rsa +netcat +ip +ebtables +uci
endef

define Build/Configure
endef


define Build/Compile
endef

define Package/open-giethoorn/description
	Internet bridging utility
	Manage openvpn bridging; a way to connect networks together 
	over the internet, to form a larger network
endef

define Package/open-giethoorn/install
	$(INSTALL_DIR) $(1)/sbin
	$(CP)  $(PKG_BUILD_DIR)/sbin $(1)/
	$(INSTALL_DIR) $(1)/usr/share/open-giethoorn/bin
	$(CP)  $(PKG_BUILD_DIR)/bin $(1)/usr/share/open-giethoorn
	$(INSTALL_DIR) $(1)/usr/share/open-giethoorn/data
	$(CP)  $(PKG_BUILD_DIR)/data $(1)/usr/share/open-giethoorn
	$(INSTALL_DIR) $(1)/etc/init.d
	$(CP)  $(PKG_BUILD_DIR)/init.d $(1)/etc
endef

$(eval $(call BuildPackage,open-giethoorn))

