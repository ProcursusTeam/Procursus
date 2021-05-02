ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libusb
LIBUSB_VERSION := 1.0.23
DEB_LIBUSB_V   ?= $(LIBUSB_VERSION)-1

libusb-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libusb/libusb/releases/download/v$(LIBUSB_VERSION)/libusb-$(LIBUSB_VERSION).tar.bz2
	$(call EXTRACT_TAR,libusb-$(LIBUSB_VERSION).tar.bz2,libusb-$(LIBUSB_VERSION),libusb)

ifneq ($(wildcard $(BUILD_WORK)/libusb/.build_complete),)
libusb:
	@echo "Using previously built libusb."
else
libusb: libusb-setup
	cd $(BUILD_WORK)/libusb && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libusb install \
		CFLAGS="$(CFLAGS) -D__OPEN_SOURCE__ -DMAC_OS_X_VERSION_MIN_REQUIRED=101500" \
		DESTDIR="$(BUILD_STAGE)/libusb"
	+$(MAKE) -C $(BUILD_WORK)/libusb install \
		CFLAGS="$(CFLAGS) -D__OPEN_SOURCE__ -DMAC_OS_X_VERSION_MIN_REQUIRED=101500" \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libusb/.build_complete
endif

libusb-package: libusb-stage
	# libusb.mk Package Structure
	rm -rf $(BUILD_DIST)/libusb-1.0-0{,-dev}
	mkdir -p $(BUILD_DIST)/libusb-1.0-0{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libusb.mk Prep libusb-1.0-0
	cp -a $(BUILD_STAGE)/libusb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libusb-1.0.0.dylib $(BUILD_DIST)/libusb-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libusb.mk Prep libusb-1.0-0-dev
	cp -a $(BUILD_STAGE)/libusb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libusb-1.0.dylib} $(BUILD_DIST)/libusb-1.0-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libusb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libusb-1.0-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libusb.mk Sign
	$(call SIGN,libusb-1.0-0,general.xml)

	# libusb.mk Make .debs
	$(call PACK,libusb-1.0-0,DEB_LIBUSB_V)
	$(call PACK,libusb-1.0-0-dev,DEB_LIBUSB_V)

	# libusb.mk Build cleanup
	rm -rf $(BUILD_DIST)/libusb-1.0-0{,-dev}

.PHONY: libusb libusb-package
