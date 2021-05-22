ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += usbmuxd2
USBMUXD2_VERSION := 38
DEB_USBMUXD2_V   ?= $(USBMUXD2_VERSION)

USBMUXD2_COMMIT  := 101def817e8763f5bee4a67abf2c976e1fb9e4ee

usbmuxd2-setup: setup
	$(call GITHUB_ARCHIVE,tihmstar,usbmuxd2,$(USBMUXD2_VERSION),$(USBMUXD2_COMMIT))
	$(call EXTRACT_TAR,usbmuxd2-$(USBMUXD2_VERSION).tar.gz,usbmuxd2-$(USBMUXD2_COMMIT),usbmuxd2)
	$(SED) -i 's/2.2.1/2.2.0/' $(BUILD_WORK)/usbmuxd2/configure.ac
	$(SED) -i 's/va_list ap = {}/va_list ap = NULL/' $(BUILD_WORK)/usbmuxd2/usbmuxd2/log.c

ifneq ($(wildcard $(BUILD_WORK)/usbmuxd2/.build_complete),)
usbmuxd2:
	@echo "Using previously built usbmuxd2."
else
usbmuxd2: usbmuxd2-setup libgeneral libusb libimobiledevice libplist
	cd $(BUILD_WORK)/usbmuxd2 && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-systemd
	+$(MAKE) -C $(BUILD_WORK)/usbmuxd2
	+$(MAKE) -C $(BUILD_WORK)/usbmuxd2 install \
		DESTDIR="$(BUILD_STAGE)/usbmuxd2"
	mkdir -p $(BUILD_STAGE)/usbmuxd2/Library/LaunchDaemons
	cp -a $(BUILD_INFO)/org.libimobiledevice.usbmuxd.plist $(BUILD_STAGE)/usbmuxd2/Library/LaunchDaemons
	touch $(BUILD_WORK)/usbmuxd2/.build_complete
endif

usbmuxd2-package: usbmuxd2-stage
	# usbmuxd2.mk Package Structure
	rm -rf $(BUILD_DIST)/usbmuxd2

	# usbmuxd2.mk Prep usbmuxd2
	cp -a $(BUILD_STAGE)/usbmuxd2 $(BUILD_DIST)

	# usbmuxd2.mk Sign
	$(call SIGN,usbmuxd2,general.xml)

	# usbmuxd2.mk Make .debs
	$(call PACK,usbmuxd2,DEB_USBMUXD2_V)

	# usbmuxd2.mk Build cleanup
	rm -rf $(BUILD_DIST)/usbmuxd2

.PHONY: usbmuxd2 usbmuxd2-package
