ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += inetutils
INETUTILS_VERSION := 2.0
DEB_INETUTILS_V   ?= $(INETUTILS_VERSION)

inetutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/inetutils/inetutils-$(INETUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,inetutils-$(INETUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,inetutils-$(INETUTILS_VERSION).tar.xz,inetutils-$(INETUTILS_VERSION),inetutils)
	mkdir -p $(BUILD_STAGE)/inetutils/{s,}bin

ifneq ($(wildcard $(BUILD_WORK)/inetutils/.build_complete),)
inetutils:
	@echo "Using previously built inetutils."
else
inetutils: inetutils-setup ncurses readline
	cd $(BUILD_WORK)/inetutils && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
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
	$(LN) -sf ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ping $(BUILD_STAGE)/inetutils/bin
	$(LN) -sf ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ping $(BUILD_STAGE)/inetutils/sbin
	touch $(BUILD_WORK)/inetutils/.build_complete
endif

inetutils-package: inetutils-stage
	# inetutils.mk Package Structure
	rm -rf $(BUILD_DIST)/inetutils

	# inetutils.mk Prep inetutils
	cp -a $(BUILD_STAGE)/inetutils $(BUILD_DIST)

	# inetutils.mk Sign
	$(call SIGN,inetutils,general.xml)

	# inetutils.mk Permissions
	$(FAKEROOT) chmod 0755 $(BUILD_DIST)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	$(FAKEROOT) chmod 4755 $(BUILD_DIST)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{ping,rcp,rlogin,rsh}

	# inetutils.mk Make .debs
	$(call PACK,inetutils,DEB_INETUTILS_V)

	# inetutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/inetutils

.PHONY: inetutils inetutils-package
