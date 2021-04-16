ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libdvdcss2
LIBDVDCSS2_VERSION := 1.4.2
DEB_LIBDVDCSS2_V   ?= $(LIBDVDCSS2_VERSION)

libdvdcss2-setup: setup
	-[ ! -f $(BUILD_SOURCE)/libdvdcss2-$(LIBDVDCSS2_VERSION).tar.bz2 ] && 
			wget -q -nc -O$(BUILD_SOURCE)/libdvdcss2-$(LIBDVDCSS2_VERSION).tar.bz2  https://download.videolan.org/pub/libdvdcss/$(LIBDVDCSS2_VERSION)/libdvdcss-$(LIBDVDCSS2_VERSION).tar.bz2
	$(call EXTRACT_TAR,libdvdcss2-$(LIBDVDCSS2_VERSION).tar.bz2,libdvdcss2-$(LIBDVDCSS2_VERSION),libdvdcss2)
	rm -rf $(BUILD_WORK)/libdvdcss2
	mv $(BUILD_WORK)/libdvdcss-$(LIBDVDCSS2_VERSION) $(BUILD_WORK)/libdvdcss2
	#$(call DO_PATCH,libdvdcss2,libdvdcss2,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libdvdcss2/.build_complete),)
libdvdcss2:
	@echo "Using previously built libdvdcss2."
else
libdvdcss2: libdvdcss2-setup
	cd $(BUILD_WORK)/libdvdcss2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libdvdcss2
	+$(MAKE) -C $(BUILD_WORK)/libdvdcss2 install \
		DESTDIR=$(BUILD_STAGE)/libdvdcss2
	touch $(BUILD_WORK)/libdvdcss2/.build_complete
endif

libdvdcss2-package: libdvdcss2-stage
	# libdvdcss2.mk Package Structure
	rm -rf $(BUILD_DIST)/libdvdcss2
	mkdir -p $(BUILD_DIST)/libdvdcss2
	
	# libdvdcss2.mk Prep libdvdcss2
	cp -a $(BUILD_STAGE)/libdvdcss2 $(BUILD_DIST)
	
	# libdvdcss2.mk Sign
	$(call SIGN,libdvdcss2,general.xml)
	
	# libdvdcss2.mk Make .debs
	$(call PACK,libdvdcss2,DEB_LIBDVDCSS2_V)
	
	# libdvdcss2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdvdcss2

.PHONY: libdvdcss2 libdvdcss2-package
