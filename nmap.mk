ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nmap
NMAP_VERSION := 7.91
DEB_NMAP_V   ?= $(NMAP_VERSION)

nmap-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://nmap.org/dist/nmap-$(NMAP_VERSION).tar.bz2
	$(call EXTRACT_TAR,nmap-$(NMAP_VERSION).tar.bz2,nmap-$(NMAP_VERSION),nmap)

ifneq ($(wildcard $(BUILD_WORK)/nmap/.build_complete),)
nmap:
	@echo "Using previously built nmap."
else
nmap: nmap-setup lua5.3 openssl pcre libssh2
	cd $(BUILD_WORK)/nmap && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-liblua=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--without-nmap-update \
		--disable-universal \
		--without-zenmap \
		--without-ndiff
	+$(MAKE) -C $(BUILD_WORK)/nmap
	+$(MAKE) -C $(BUILD_WORK)/nmap install -j1 \
		DESTDIR=$(BUILD_STAGE)/nmap
	touch $(BUILD_WORK)/nmap/.build_complete
endif

nmap-package: nmap-stage
	# nmap.mk Package Structure
	rm -rf $(BUILD_DIST)/nmap{-utils,-common}
	mkdir -p $(BUILD_DIST)/nmap{-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX),-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share}

	# nmap.mk Prep nmap-utils
	cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/nmap-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nmap.mk Prep nmap-common
	cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{ncat,nmap} $(BUILD_DIST)/nmap-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# nmap.mk Sign
	$(call SIGN,nmap-utils,general.xml)

	# nmap.mk Make .debs
	$(call PACK,nmap-utils,DEB_NMAP_V)
	$(call PACK,nmap-common,DEB_NMAP_V)

	# nmap.mk Build cleanup
	rm -rf $(BUILD_DIST)/nmap{-utils,-common}

.PHONY: nmap nmap-package
