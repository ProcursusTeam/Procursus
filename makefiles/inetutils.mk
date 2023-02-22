ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += inetutils
INETUTILS_VERSION := 2.0
DEB_INETUTILS_V   ?= $(INETUTILS_VERSION)-1

inetutils-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/inetutils/inetutils-$(INETUTILS_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,inetutils-$(INETUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,inetutils-$(INETUTILS_VERSION).tar.xz,inetutils-$(INETUTILS_VERSION),inetutils)
	$(call DO_PATCH,inetutils,inetutils,-p1)
	mkdir -p $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)/{s,}bin

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
	sed -i 's/-ltermcap/-lncursesw/g' $(BUILD_WORK)/inetutils/telnet/Makefile
	sed -i 's/-ltermcap/-lncursesw/g' $(BUILD_WORK)/inetutils/telnetd/Makefile
	touch $(BUILD_WORK)/inetutils/man/*.8 $(BUILD_WORK)/inetutils/man/*.1
	+$(MAKE) -C $(BUILD_WORK)/inetutils install \
		DESTDIR=$(BUILD_STAGE)/inetutils
	$(LN_SR) $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ping $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)/bin/ping
	$(LN_SR) $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ping $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)/sbin/ping
	$(call AFTER_BUILD)
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
