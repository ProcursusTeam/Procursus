ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libdvdread4
LIBDVDREAD4_VERSION := 6.1.1
DEB_LIBDVDREAD4_V   ?= $(LIBDVDREAD4_VERSION)

libdvdread4-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libdvdread/$(LIBDVDREAD4_VERSION)/libdvdread-$(LIBDVDREAD4_VERSION).tar.bz2
	$(call EXTRACT_TAR,libdvdread-$(LIBDVDREAD4_VERSION).tar.bz2,libdvdread-$(LIBDVDREAD4_VERSION),libdvdread4)

ifneq ($(wildcard $(BUILD_WORK)/libdvdread4/.build_complete),)
libdvdread4: libdvdcss2
	@echo "Using previously built libdvdread4."
else
libdvdread4: libdvdread4-setup
	cd $(BUILD_WORK)/libdvdread4 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libdvdread4
	+$(MAKE) -C $(BUILD_WORK)/libdvdread4 install \
		DESTDIR=$(BUILD_STAGE)/libdvdread4
	+$(MAKE) -C $(BUILD_WORK)/libdvdread4 install \
		DESTDIR=$(BUILD_BASE)

	touch $(BUILD_WORK)/libdvdread4/.build_complete
endif

libdvdread4-package: libdvdread4-stage
	# libdvdread4.mk Package Structure
	rm -rf $(BUILD_DIST)/libdvdread{4-dev}
	mkdir -p $(BUILD_DIST)/libdvdread{4,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc
	
	# libdvdread4.mk Prep libdvdread4
	cp -a $(BUILD_STAGE)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdvdread.8.dylib $(BUILD_DIST)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdread $(BUILD_DIST)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdread4
	
	# libdvdread4.mk Prep libdvdread-dev
	cp -a $(BUILD_STAGE)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdvdread-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libdvdread.{dylib,la,a},pkgconfig} $(BUILD_DIST)/libdvdread-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvdread4.mk Sign
	$(call SIGN,libdvdread4,general.xml)
	
	# libdvdread4.mk Make .debs
	$(call PACK,libdvdread4,DEB_LIBDVDREAD4_V)
	$(call PACK,libdvdread-dev,DEB_LIBDVDREAD4_V)
	
	# libdvdread4.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdvdread{4,-dev}

.PHONY: libdvdread4 libdvdread4-package
