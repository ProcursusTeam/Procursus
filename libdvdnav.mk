ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libdvdnav
LIBDVDNAV_VERSION := 6.1.0
DEB_LIBDVDNAV_V   ?= $(LIBDVDNAV_VERSION)

libdvdnav-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libdvdnav/$(LIBDVDNAV_VERSION)/libdvdnav-$(LIBDVDNAV_VERSION).tar.bz2
	$(call EXTRACT_TAR,libdvdnav-$(LIBDVDNAV_VERSION).tar.bz2,libdvdnav-$(LIBDVDNAV_VERSION),libdvdnav)

ifneq ($(wildcard $(BUILD_WORK)/libdvdnav/.build_complete),)
libdvdnav:
	@echo "Using previously built libdvdnav."
else
libdvdnav: libdvdnav-setup libdvdread
	cd $(BUILD_WORK)/libdvdnav && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libdvdnav
	+$(MAKE) -C $(BUILD_WORK)/libdvdnav install \
		DESTDIR=$(BUILD_STAGE)/libdvdnav
	+$(MAKE) -C $(BUILD_WORK)/libdvdnav install \
		DESTDIR=$(BUILD_WORK)

	touch $(BUILD_WORK)/libdvdnav/.build_complete
endif

libdvdnav-package: libdvdnav-stage
	# libdvdnav.mk Package Structure
	rm -rf $(BUILD_DIST)/libdvdnav{4-dev}
	mkdir -p $(BUILD_DIST)/libdvdnav{4,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc
	
	# libdvdnav.mk Prep libdvdnav
	cp -a $(BUILD_STAGE)/libdvdnav/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdvdnav.4.dylib $(BUILD_DIST)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libdvdnav/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdnav $(BUILD_DIST)/libdvdnav4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdnav4
	
	# libdvdnav.mk Prep libdvdnav-dev
	cp -a $(BUILD_STAGE)/libdvdnav/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdvdnav-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libdvdnav/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libdvdnav.{dylib,la,a},pkgconfig} $(BUILD_DIST)/libdvdnav-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvdnav.mk Sign
	$(call SIGN,libdvdnav4,general.xml)
	
	# libdvdnav.mk Make .debs
	$(call PACK,libdvdnav4,DEB_LIBDVDNAV_V)
	$(call PACK,libdvdnav-dev,DEB_LIBDVDNAV_V)
	
	# libdvdnav.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdvdnav{4,-dev}

.PHONY: libdvdnav libdvdnav-package
