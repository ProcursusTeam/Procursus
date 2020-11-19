ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += usbmuxd
USBMUXD_VERSION := 1.1.1
DEB_USBMUXD_V   ?= $(USBMUXD_VERSION)

usbmuxd-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libimobiledevice/usbmuxd/releases/download/$(USBMUXD_VERSION)/usbmuxd-$(USBMUXD_VERSION).tar.bz2
	$(call EXTRACT_TAR,usbmuxd-$(USBMUXD_VERSION).tar.bz2,usbmuxd-$(USBMUXD_VERSION),usbmuxd)

ifneq ($(wildcard $(BUILD_WORK)/usbmuxd/.build_complete),)
usbmuxd:
	@echo "Using previously built usbmuxd."
else
usbmuxd: usbmuxd-setup libusb libimobiledevice libplist
	cd $(BUILD_WORK)/usbmuxd && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--without-systemd \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/usbmuxd \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/usr/include/libusb-1.0"
	+$(MAKE) -C $(BUILD_WORK)/usbmuxd install \
		DESTDIR="$(BUILD_STAGE)/usbmuxd"
	mkdir -p $(BUILD_STAGE)/usbmuxd/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_INFO)/org.libimobiledevice.usbmuxd.plist $(BUILD_STAGE)/usbmuxd/$(MEMO_PREFIX)/Library/LaunchDaemons
	touch $(BUILD_WORK)/usbmuxd/.build_complete
endif

usbmuxd-package: usbmuxd-stage
	# usbmuxd.mk Package Structure
	rm -rf $(BUILD_DIST)/usbmuxd

	# usbmuxd.mk Prep usbmuxd
	cp -a $(BUILD_STAGE)/usbmuxd $(BUILD_DIST)

	# usbmuxd.mk Sign
	$(call SIGN,usbmuxd,general.xml)

	# usbmuxd.mk Make .debs
	$(call PACK,usbmuxd,DEB_USBMUXD_V)

	# usbmuxd.mk Build cleanup
	rm -rf $(BUILD_DIST)/usbmuxd

.PHONY: usbmuxd usbmuxd-package
