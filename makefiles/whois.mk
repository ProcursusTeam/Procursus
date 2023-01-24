ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += whois
WHOIS_VERSION := 5.5.10
DEB_WHOIS_V   ?= $(WHOIS_VERSION)

whois-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),http://deb.debian.org/debian/pool/main/w/whois/whois_$(WHOIS_VERSION).tar.xz)
	$(call EXTRACT_TAR,whois_$(WHOIS_VERSION).tar.xz,whois-$(WHOIS_VERSION),whois)
	sed -i '/_XOPEN_SOURCE/d' $(BUILD_WORK)/whois/utils.c
	sed -i '/_XOPEN_SOURCE/d' $(BUILD_WORK)/whois/mkpasswd.c

ifneq ($(wildcard $(BUILD_WORK)/whois/.build_complete),)
whois:
	@echo "Using previously built whois."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
whois: whois-setup libidn2 libxcrypt
else
whois: whois-setup libidn2
endif
	+$(MAKE) -C $(BUILD_WORK)/whois \
		prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		HAVE_ICONV=1 \
		CC="$(CC)" \
		CFLAGS='$(CFLAGS) -Wall -I.' \
		LDFLAGS='$(LDFLAGS) -liconv'
	+$(MAKE) -C $(BUILD_WORK)/whois install \
		prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR=$(BUILD_STAGE)/whois
	$(call AFTER_BUILD)
endif

whois-package: whois-stage
	# whois.mk Package Structure
	rm -rf $(BUILD_DIST)/whois

	# whois.mk Prep WHOIS
	cp -a $(BUILD_STAGE)/whois $(BUILD_DIST)/

	#whois.mk Sign
	$(call SIGN,whois,general.xml)

	# whois.mk Make .debs
	$(call PACK,whois,DEB_WHOIS_V)

	# whois.mk Build cleanup
	rm -rf $(BUILD_DIST)/whois

.PHONY: whois whois-package

