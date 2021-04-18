ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libdvdnav4
LIBDVDNAV4_VERSION := 6.1.0
DEB_LIBDVDNAV4_V   ?= $(LIBDVDNAV4_VERSION)

libdvdnav4-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libdvdnav/$(LIBDVDNAV4_VERSION)/libdvdnav-$(LIBDVDNAV4_VERSION).tar.bz2
	$(call EXTRACT_TAR,libdvdnav-$(LIBDVDNAV4_VERSION).tar.bz2,libdvdnav-$(LIBDVDNAV4_VERSION),libdvdnav4)

ifneq ($(wildcard $(BUILD_WORK)/libdvdnav4/.build_complete),)
libdvdnav4: libdvdcss2 libdvdread4
	@echo "Using previously built libdvdnav4."
else
libdvdnav4: libdvdnav4-setup
	cd $(BUILD_WORK)/libdvdnav4 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libdvdnav4
	+$(MAKE) -C $(BUILD_WORK)/libdvdnav4 install \
		DESTDIR=$(BUILD_STAGE)/libdvdnav4
	+$(MAKE) -C $(BUILD_WORK)/libdvdnav4 install \
		DESTDIR=$(BUILD_WORK)

	touch $(BUILD_WORK)/libdvdnav4/.build_complete
endif

libdvdnav4-package: libdvdnav4-stage
	# libdvdnav4.mk Package Structure
	rm -rf $(BUILD_DIST)/libdvdnav{4-dev}
	mkdir -p $(BUILD_DIST)/libdvdnav{4,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc
	
	# libdvdnav4.mk Prep libdvdnav4
	cp -a $(BUILD_STAGE)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdvdnav.4.dylib $(BUILD_DIST)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdnav $(BUILD_DIST)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdnav4
	
	# libdvdnav4.mk Prep libdvdnav-dev
	cp -a $(BUILD_STAGE)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdvdnav-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libdvdnav.{dylib,la,a},pkgconfig} $(BUILD_DIST)/libdvdnav-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvdnav4.mk Sign
	$(call SIGN,libdvdnav4,general.xml)
	
	# libdvdnav4.mk Make .debs
	$(call PACK,libdvdnav4,DEB_LIBDVDNAV4_V)
	$(call PACK,libdvdnav-dev,DEB_LIBDVDNAV4_V)
	
	# libdvdnav4.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdvdnav{4,-dev}

.PHONY: libdvdnav4 libdvdnav4-package
