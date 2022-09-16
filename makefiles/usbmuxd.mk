ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS     += usbmuxd
USBMUXD_COMMIT  := f50e52f3393a9149ac65fdda8f0d425109efc7fe
USBMUXD_VERSION := 1.1.1+git20220619.$(shell echo $(USBMUXD_COMMIT) | cut -c -7)
DEB_USBMUXD_V   ?= $(USBMUXD_VERSION)-1

usbmuxd-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,usbmuxd,$(USBMUXD_COMMIT),$(USBMUXD_COMMIT))
	$(call EXTRACT_TAR,usbmuxd-$(USBMUXD_COMMIT).tar.gz,usbmuxd-$(USBMUXD_COMMIT),usbmuxd)

ifneq ($(wildcard $(BUILD_WORK)/usbmuxd/.build_complete),)
usbmuxd:
	@echo "Using previously built usbmuxd."
else
usbmuxd: usbmuxd-setup libusb libplist libimobiledevice-glue libimobiledevice
	cd $(BUILD_WORK)/usbmuxd && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-systemd \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/usbmuxd \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libusb-1.0"
	+$(MAKE) -C $(BUILD_WORK)/usbmuxd install \
		DESTDIR="$(BUILD_STAGE)/usbmuxd"
	mkdir -p $(BUILD_STAGE)/usbmuxd/Library/LaunchDaemons
	sed -e "s|@MEMO_PREFIX@|$(MEMO_PREFIX)|g" -e "s|@MEMO_SUB_PREFIX|$(MEMO_SUB_PREFIX)|g" < $(BUILD_INFO)/org.libimobiledevice.usbmuxd.plist > $(BUILD_STAGE)/usbmuxd/Library/LaunchDaemons
	$(call AFTER_BUILD)
endif

usbmuxd-package: usbmuxd-stage
	# usbmuxd.mk Package Structure
	rm -rf $(BUILD_DIST)/usbmuxd

	# usbmuxd.mk Prep usbmuxd
	cp -a $(BUILD_STAGE)/usbmuxd $(BUILD_DIST)

	# usbmuxd.mk Sign
	$(call SIGN,usbmuxd,usb.xml)

	# usbmuxd.mk Make .debs
	$(call PACK,usbmuxd,DEB_USBMUXD_V)

	# usbmuxd.mk Build cleanup
	rm -rf $(BUILD_DIST)/usbmuxd

.PHONY: usbmuxd usbmuxd-package

endif
