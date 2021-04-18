ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libdvdread
LIBDVDREAD_VERSION := 6.1.1
DEB_LIBDVDREAD_V   ?= $(LIBDVDREAD_VERSION)

libdvdread-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libdvdread/$(LIBDVDREAD_VERSION)/libdvdread-$(LIBDVDREAD_VERSION).tar.bz2
	$(call EXTRACT_TAR,libdvdread-$(LIBDVDREAD_VERSION).tar.bz2,libdvdread-$(LIBDVDREAD_VERSION),libdvdread)

ifneq ($(wildcard $(BUILD_WORK)/libdvdread/.build_complete),)
libdvdread: libdvdcss
	@echo "Using previously built libdvdread."
else
libdvdread: libdvdread-setup
	cd $(BUILD_WORK)/libdvdread && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libdvdread
	+$(MAKE) -C $(BUILD_WORK)/libdvdread install \
		DESTDIR=$(BUILD_STAGE)/libdvdread
	+$(MAKE) -C $(BUILD_WORK)/libdvdread install \
		DESTDIR=$(BUILD_BASE)

	touch $(BUILD_WORK)/libdvdread/.build_complete
endif

libdvdread-package: libdvdread-stage
	# libdvdread.mk Package Structure
	rm -rf $(BUILD_DIST)/libdvdread{4-dev}
	mkdir -p $(BUILD_DIST)/libdvdread{4,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc
	
	# libdvdread.mk Prep libdvdread4
	cp -a $(BUILD_STAGE)/libdvdread/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdvdread.8.dylib $(BUILD_DIST)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libdvdread/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdread $(BUILD_DIST)/libdvdread4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/libdvdread4
	
	# libdvdread.mk Prep libdvdread-dev
	cp -a $(BUILD_STAGE)/libdvdread/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdvdread-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libdvdread/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libdvdread.{dylib,la,a},pkgconfig} $(BUILD_DIST)/libdvdread-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvdread.mk Sign
	$(call SIGN,libdvdread4,general.xml)
	
	# libdvdread.mk Make .debs
	$(call PACK,libdvdread4,DEB_LIBDVDREAD_V)
	$(call PACK,libdvdread-dev,DEB_LIBDVDREAD_V)
	
	# libdvdread.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdvdread{4,-dev}

.PHONY: libdvdread libdvdread-package
