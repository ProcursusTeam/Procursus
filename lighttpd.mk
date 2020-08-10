ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += lighttpd
LIGHTTPD_VERSION := 1.4.55
DEB_LIGHTTPD_V   ?= $(LIGHTTPD_VERSION)
MAJOR_VERSION := $(shell v='$(LIGHTTPD_VERSION)'; echo "$${v%.*}")

lighttpd-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://download.lighttpd.net/lighttpd/releases-$(MAJOR_VERSION).x/lighttpd-$(LIGHTTPD_VERSION).tar.xz
	$(call EXTRACT_TAR,lighttpd-$(LIGHTTPD_VERSION).tar.xz,lighttpd-$(LIGHTTPD_VERSION),lighttpd)
	mkdir -p $(BUILD_WORK)/lighttpd/include/netinet
	wget -nc -P $(BUILD_WORK)/lighttpd/include/netinet \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/netinet/tcp_fsm.h

ifneq ($(wildcard $(BUILD_WORK)/lighttpd/.build_complete),)
lighttpd:
	@echo "Using previously built lighttpd."
else
lighttpd: lighttpd-setup libgdbm libgeoip uuid pcre
	# --with-ldap --with-mysql --with-lua --with-kerberos5 --with-attr   -
	# TODO: add libev
	cd $(BUILD_WORK)/lighttpd && ./autogen.sh && \
		XML_CFLAGS=-I$(TARGET_SYSROOT)/usr/include/libxml2 ./configure -C \
			--host=$(GNU_HOST_TRIPLE) \
			--with-sysroot=$(TARGET_SYSROOT) \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--libdir=/usr/lib/lighttpd/ \
			--libexecdir="/usr/lib/lighttpd" \
			--with-gdbm \
			--with-geoip \
			--with-openssl \
			--with-pcre \
			--with-webdav-locks \
			--with-webdav-props
			#	--with-dbi
			# --with-krb5
			# --with-pgsql
			# --with-mysql
			# --with-sasl
			# --with-ldap
			# --with-pam
			# --with-memcached
			# --with-lua=lua5.1
			# --with-fam
	+$(MAKE) -C $(BUILD_WORK)/lighttpd CFLAGS="$(CFLAGS) -isystem $(BUILD_WORK)/lighttpd/include"
	+$(MAKE) -C $(BUILD_WORK)/lighttpd install \
		DESTDIR=$(BUILD_STAGE)/lighttpd
	touch $(BUILD_WORK)/lighttpd/.build_complete
endif

lighttpd-package: lighttpd-stage
	# lighttpd.mk Package Structure
	rm -rf $(BUILD_DIST)/lighttpd
	mkdir -p $(BUILD_DIST)/lighttpd
	
	# lighttpd.mk Prep lighttpd
	cp -a $(BUILD_STAGE)/lighttpd/usr $(BUILD_DIST)/lighttpd
	
	# lighttpd.mk Sign
	$(call SIGN,lighttpd,general.xml)
	
	# lighttpd.mk Make .debs
	$(call PACK,lighttpd,DEB_LIGHTTPD_V)
	
	# lighttpd.mk Build cleanup
	rm -rf $(BUILD_DIST)/lighttpd

.PHONY: lighttpd lighttpd-package
