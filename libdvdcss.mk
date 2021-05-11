ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libdvdcss
LIBDVDCSS_VERSION := 1.4.2
DEB_LIBDVDCSS_V   ?= $(LIBDVDCSS_VERSION)

libdvdcss-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.videolan.org/pub/libdvdcss/$(LIBDVDCSS_VERSION)/libdvdcss-$(LIBDVDCSS_VERSION).tar.bz2
	$(call EXTRACT_TAR,libdvdcss-$(LIBDVDCSS_VERSION).tar.bz2,libdvdcss-$(LIBDVDCSS_VERSION),libdvdcss)

ifneq ($(wildcard $(BUILD_WORK)/libdvdcss/.build_complete),)
libdvdcss:
	@echo "Using previously built libdvdcss."
else
libdvdcss: libdvdcss-setup
	cd $(BUILD_WORK)/libdvdcss && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libdvdcss
	+$(MAKE) -C $(BUILD_WORK)/libdvdcss install \
		DESTDIR=$(BUILD_STAGE)/libdvdcss
	+$(MAKE) -C $(BUILD_WORK)/libdvdcss install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libdvdcss/.build_complete
endif

libdvdcss-package: libdvdcss-stage
	# libdvdcss.mk Package Structure
	rm -rf $(BUILD_DIST)/libdvdcss{2,-dev}
	mkdir -p $(BUILD_DIST)/libdvdcss{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvdcss.mk Prep libdvdcss
	cp -a $(BUILD_STAGE)/libdvdcss/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdvdcss.2.dylib $(BUILD_DIST)/libdvdcss2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvdcss.mk Prep libdvdcss-dev
	cp -a $(BUILD_STAGE)/libdvdcss/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdvdcss-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libdvdcss/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libdvdcss.{a,dylib},pkgconfig} $(BUILD_DIST)/libdvdcss-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvdcss.mk Sign
	$(call SIGN,libdvdcss2,general.xml)
	
	# libdvdcss.mk Make .debs
	$(call PACK,libdvdcss2,DEB_LIBDVDCSS_V)
	$(call PACK,libdvdcss-dev,DEB_LIBDVDCSS_V)
	
	# libdvdcss.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdvdcss{2,-dev}

.PHONY: libdvdcss libdvdcss-package
