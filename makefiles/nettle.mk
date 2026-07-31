ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += nettle
NETTLE_VERSION := 4.0
DEB_NETTLE_V   ?= $(NETTLE_VERSION)

nettle-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://mirror.techrich.hk/gnu/nettle/nettle-$(NETTLE_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,nettle-$(NETTLE_VERSION).tar.gz)
	$(call EXTRACT_TAR,nettle-$(NETTLE_VERSION).tar.gz,nettle-$(NETTLE_VERSION),nettle)

ifneq ($(wildcard $(BUILD_WORK)/nettle/.build_complete),)
nettle:
	@echo "Using previously built nettle."
else
nettle: nettle-setup libgmp10
	cd $(BUILD_WORK)/nettle && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CC_FOR_BUILD='$(shell command -v cc) $(CFLAGS_FOR_BUILD)' \
		CPP_FOR_BUILD='$(shell command -v cc) -E $(CPPFLAGS_FOR_BUILD)'
	+$(MAKE) -C $(BUILD_WORK)/nettle
	+$(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_STAGE)/nettle
	$(call AFTER_BUILD,copy)
endif

nettle-package: nettle-stage
	# nettle.mk Package Structure
	rm -rf $(BUILD_DIST)/nettle-bin \
		$(BUILD_DIST)/nettle-dev \
		$(BUILD_DIST)/libnettle9 \
		$(BUILD_DIST)/libhogweed7
	mkdir -p $(BUILD_DIST)/nettle-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/nettle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libnettle9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libhogweed7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nettle.mk Prep nettle-bin
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/nettle-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nettle.mk Prep libnettle9
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libnettle.9*.dylib $(BUILD_DIST)/libnettle9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nettle.mk Prep libhogweed7
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libhogweed.7*.dylib $(BUILD_DIST)/libhogweed7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nettle.mk Prep nettle-dev
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,lib{nettle,hogweed}.{dylib,a}} $(BUILD_DIST)/nettle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/nettle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nettle.mk Sign
	$(call SIGN,nettle-bin,general.xml)
	$(call SIGN,libnettle9,general.xml)
	$(call SIGN,libhogweed7,general.xml)

	# nettle.mk Make .debs
	$(call PACK,nettle-bin,DEB_NETTLE_V)
	$(call PACK,nettle-dev,DEB_NETTLE_V)
	$(call PACK,libnettle9,DEB_NETTLE_V)
	$(call PACK,libhogweed7,DEB_NETTLE_V)

	# nettle.mk Build cleanup
	rm -rf $(BUILD_DIST)/nettle-bin \
		$(BUILD_DIST)/nettle-dev \
		$(BUILD_DIST)/libnettle9 \
		$(BUILD_DIST)/libhogweed7

.PHONY: nettle nettle-package
