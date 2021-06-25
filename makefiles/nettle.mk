ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += nettle
NETTLE_VERSION := 3.7.2
DEB_NETTLE_V   ?= $(NETTLE_VERSION)

nettle-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/nettle/nettle-$(NETTLE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,nettle-$(NETTLE_VERSION).tar.gz)
	$(call EXTRACT_TAR,nettle-$(NETTLE_VERSION).tar.gz,nettle-$(NETTLE_VERSION),nettle)
	$(call DO_PATCH,nettle,nettle,-p1)

ifneq ($(wildcard $(BUILD_WORK)/nettle/.build_complete),)
nettle:
	@echo "Using previously built nettle."
else
nettle: nettle-setup libgmp10
	cd $(BUILD_WORK)/nettle && autoreconf -iv
	cd $(BUILD_WORK)/nettle && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CC_FOR_BUILD='$(shell which cc) $(BUILD_CFLAGS)' \
		CPP_FOR_BUILD='$(shell which cc) -E $(BUILD_CPPFLAGS)'
	+$(MAKE) -C $(BUILD_WORK)/nettle
	+$(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_STAGE)/nettle
	+$(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/nettle/.build_complete
endif

nettle-package: nettle-stage
	# nettle.mk Package Structure
	rm -rf $(BUILD_DIST)/nettle-bin \
		$(BUILD_DIST)/nettle-dev \
		$(BUILD_DIST)/libnettle8 \
		$(BUILD_DIST)/libhogweed6
	mkdir -p $(BUILD_DIST)/nettle-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/nettle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libnettle8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libhogweed6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nettle.mk Prep nettle-bin
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/nettle-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nettle.mk Prep libnettle8
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libnettle.8*.dylib $(BUILD_DIST)/libnettle8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nettle.mk Prep libhogweed6
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libhogweed.6*.dylib $(BUILD_DIST)/libhogweed6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nettle.mk Prep nettle-dev
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,lib{nettle,hogweed}.{dylib,a}} $(BUILD_DIST)/nettle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/nettle/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/nettle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nettle.mk Sign
	$(call SIGN,nettle-bin,general.xml)
	$(call SIGN,libnettle8,general.xml)
	$(call SIGN,libhogweed6,general.xml)

	# nettle.mk Make .debs
	$(call PACK,nettle-bin,DEB_NETTLE_V)
	$(call PACK,nettle-dev,DEB_NETTLE_V)
	$(call PACK,libnettle8,DEB_NETTLE_V)
	$(call PACK,libhogweed6,DEB_NETTLE_V)

	# nettle.mk Build cleanup
	rm -rf $(BUILD_DIST)/nettle-bin \
		$(BUILD_DIST)/nettle-dev \
		$(BUILD_DIST)/libnettle8 \
		$(BUILD_DIST)/libhogweed6

.PHONY: nettle nettle-package
