ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += usbutils
USBUTILS_VERSION := 007
DEB_USBUTILS_V   ?= $(USBUTILS_VERSION)

usbutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.kernel.org/pub/linux/utils/usb/usbutils/usbutils-$(USBUTILS_VERSION).tar.xz
	$(call EXTRACT_TAR,usbutils-$(USBUTILS_VERSION).tar.xz,usbutils-$(USBUTILS_VERSION),usbutils)

ifneq ($(wildcard $(BUILD_WORK)/usbutils/.build_complete),)
usbutils:
	@echo "Using previously built usbutils."
else
usbutils: usbutils-setup libusb
	cd $(BUILD_WORK)/usbutils && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/usbutils install \
		DESTDIR="$(BUILD_STAGE)/usbutils" \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/usr/include/libusb-1.0" \
		AM_LDFLAGS="" \
		SUBDIRS="" \
		bin_SCRIPTS="" \
		sbin_SCRIPTS="" \
		"man_MANS=lsusb.8"
	rm -f $(BUILD_STAGE)/usbutils/usr/share/usb.ids{,.gz}
	wget -P $(BUILD_STAGE)/usbutils/usr/share http://www.linux-usb.org/usb.ids{,.gz}
	touch $(BUILD_WORK)/usbutils/.build_complete
endif

usbutils-package: DEB_USBIDS_V=$(shell grep Version: $(BUILD_STAGE)/usbutils/usr/share/usb.ids | cut -d' ' -f3 )
usbutils-package: usbutils-stage
	# usbutils.mk Package Structure
	rm -rf $(BUILD_DIST)/usb{utils,.ids}
	mkdir -p $(BUILD_DIST)/usb.ids/usr/share \
		$(BUILD_DIST)/usbutils/usr/share

	# usbutils.mk Prep usb.ids
	cp -a $(BUILD_STAGE)/usbutils/usr/share/usb.ids{,.gz} $(BUILD_DIST)/usb.ids/usr/share

	# usbutils.mk Prep usbutils
	cp -a $(BUILD_STAGE)/usbutils/usr/bin $(BUILD_DIST)/usbutils/usr
	cp -a $(BUILD_STAGE)/usbutils/usr/share/man $(BUILD_DIST)/usbutils/usr/share

	# usbutils.mk Sign
	$(call SIGN,usbutils,general.xml)

	# usbutils.mk Make .debs
	$(call PACK,usb.ids,DEB_USBIDS_V)
	$(call PACK,usbutils,DEB_USBUTILS_V)

	# usbutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/usb{utils,.ids}

.PHONY: usbutils usbutils-package
