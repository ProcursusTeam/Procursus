ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libusb
DOWNLOAD         += https://github.com/libusb/libusb/archive/v$(LIBUSB_VERSION).tar.gz
LIBUSB_VERSION   := 1.0.23
DEB_LIBUSB_V     ?= $(LIBUSB_VERSION)

libusb-setup: setup
	$(call EXTRACT_TAR,libusb-$(LIBUSB_VERSION).tar.gz,libusb-$(LIBUSB_VERSION),libusb)

ifneq ($(wildcard $(BUILD_WORK)/libusb/.build_complete),)
libusb:
	@echo "Using previously built libusb."
else
libusb: libusb-setup
	cd $(BUILD_WORK)/libusb && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--disable-dependency-tracking \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libusb
	+$(MAKE) -C $(BUILD_WORK)/libusb install \
		DESTDIR="$(BUILD_STAGE)/libusb"
	touch $(BUILD_WORK)/libusb/.build_complete
endif

libusb-package: libusb-stage
	# libusb.mk Package Structure
	rm -rf $(BUILD_DIST)/libusb
	mkdir -p $(BUILD_DIST)/libusb
	
	# libusb.mk Prep libusb
	cp -a $(BUILD_STAGE)/libusb/usr $(BUILD_DIST)/libusb
	
	# libusb.mk Sign
	$(call SIGN,libusb,general.xml)
	
	# libusb.mk Make .debs
	$(call PACK,libusb,DEB_LIBUSB_V)
	
	# libusb.mk Build cleanup
	rm -rf $(BUILD_DIST)/libusb

.PHONY: libusb libusb-package
