ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += inetutils
DOWNLOAD          += https://ftp.gnu.org/gnu/inetutils/inetutils-1.9.4.tar.xz{,.sig}
INETUTILS_VERSION := 1.9.4
DEB_INETUTILS_V   ?= $(INETUTILS_VERSION)

inetutils-setup: setup
	$(call PGP_VERIFY,inetutils-$(INETUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,inetutils-$(INETUTILS_VERSION).tar.xz,inetutils-$(INETUTILS_VERSION),inetutils)
	mkdir -p $(BUILD_STAGE)/inetutils/{s,}bin

ifneq ($(wildcard $(BUILD_WORK)/inetutils/.build_complete),)
inetutils:
	@echo "Using previously built inetutils."
else
inetutils: inetutils-setup ncurses readline
	cd $(BUILD_WORK)/inetutils && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-ifconfig \
		--disable-ping6 \
		--disable-syslogd \
		--disable-talkd \
		--disable-traceroute \
		--disable-whois
	$(SED) -i 's/-ltermcap/-lncursesw/g' $(BUILD_WORK)/inetutils/telnet/Makefile
	$(SED) -i 's/-ltermcap/-lncursesw/g' $(BUILD_WORK)/inetutils/telnetd/Makefile
	+$(MAKE) -C $(BUILD_WORK)/inetutils install \
		DESTDIR=$(BUILD_STAGE)/inetutils
	chmod 0755 $(BUILD_STAGE)/inetutils/usr/bin/*
	$(LN) -sf ../usr/bin/ping $(BUILD_STAGE)/inetutils/bin
	$(LN) -sf ../usr/bin/ping $(BUILD_STAGE)/inetutils/sbin
	touch $(BUILD_WORK)/inetutils/.build_complete
endif

inetutils-package: inetutils-stage
	# inetutils.mk Package Structure
	rm -rf $(BUILD_DIST)/inetutils
	mkdir -p $(BUILD_DIST)/inetutils
	
	# inetutils.mk Prep inetutils
	$(FAKEROOT) cp -a $(BUILD_STAGE)/inetutils/usr $(BUILD_DIST)/inetutils
	
	# inetutils.mk Sign
	$(call SIGN,inetutils,general.xml)
	
	# inetutils.mk Make .debs
	$(call PACK,inetutils,DEB_INETUTILS_V)
	
	# inetutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/inetutils

.PHONY: inetutils inetutils-package
