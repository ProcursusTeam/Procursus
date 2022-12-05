ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libusb
LIBUSB_VERSION := 1.0.26
DEB_LIBUSB_V   ?= $(LIBUSB_VERSION)

libusb-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/libusb/libusb/releases/download/v$(LIBUSB_VERSION)/libusb-$(LIBUSB_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libusb-$(LIBUSB_VERSION).tar.bz2,libusb-$(LIBUSB_VERSION),libusb)
#	Ensure this patch is up to date on each release.
	$(call DO_PATCH,libusb,libusb,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libusb/.build_complete),)
libusb:
	@echo "Using previously built libusb."
else
libusb: libusb-setup
	cd $(BUILD_WORK)/libusb && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libusb install \
		DESTDIR="$(BUILD_STAGE)/libusb"
	$(call AFTER_BUILD,copy)
endif

libusb-package: libusb-stage
	# libusb.mk Package Structure
	rm -rf $(BUILD_DIST)/libusb-1.0-0{,-dev}
	mkdir -p $(BUILD_DIST)/libusb-1.0-0{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libusb.mk Prep libusb-1.0-0
	cp -a $(BUILD_STAGE)/libusb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libusb-1.0.0.dylib $(BUILD_DIST)/libusb-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libusb.mk Prep libusb-1.0-0-dev
	cp -a $(BUILD_STAGE)/libusb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libusb-1.0.0.dylib) $(BUILD_DIST)/libusb-1.0-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libusb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libusb-1.0-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libusb.mk Sign
	$(call SIGN,libusb-1.0-0,general.xml)

	# libusb.mk Make .debs
	$(call PACK,libusb-1.0-0,DEB_LIBUSB_V)
	$(call PACK,libusb-1.0-0-dev,DEB_LIBUSB_V)

	# libusb.mk Build cleanup
	rm -rf $(BUILD_DIST)/libusb-1.0-0{,-dev}

.PHONY: libusb libusb-package
