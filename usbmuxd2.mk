ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += usbmuxd2
USBMUXD2_VERSION := 37
DEB_USBMUXD2_V   ?= $(USBMUXD2_VERSION)

USBMUXD2_COMMIT  := 8bff9068f0245659bb4f10b33a6a1b2ea4630dfe

usbmuxd2-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/usbmuxd2-$(USBMUXD2_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/usbmuxd2-$(USBMUXD2_VERSION).tar.gz \
			https://github.com/tihmstar/usbmuxd2/archive/$(USBMUXD2_COMMIT).tar.gz
	$(call EXTRACT_TAR,usbmuxd2-$(USBMUXD2_VERSION).tar.gz,usbmuxd2-$(USBMUXD2_COMMIT),usbmuxd2)
	$(SED) -i 's/2.2.1/2.2.0/' $(BUILD_WORK)/usbmuxd2/configure.ac
	$(SED) -i '/-lstdc++fs/d' $(BUILD_WORK)/usbmuxd2/configure.ac
	$(SED) -i 's/va_list ap = {}/va_list ap = NULL/' $(BUILD_WORK)/usbmuxd2/usbmuxd2/log.c

ifneq ($(wildcard $(BUILD_WORK)/usbmuxd2/.build_complete),)
usbmuxd2:
	@echo "Using previously built usbmuxd2."
else
usbmuxd2: usbmuxd2-setup libgeneral libusb libimobiledevice libplist
	cd $(BUILD_WORK)/usbmuxd2 && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-systemd \
		--without-wifi
	+$(MAKE) -C $(BUILD_WORK)/usbmuxd2 \
		CFLAGS="-DVERSION_COMMIT_COUNT=\\\"$(USBMUXD2_VERSION)\\\" -DVERSION_COMMIT_SHA=\\\"$(USBMUXD2_COMMIT)\\\" $(CFLAGS) -DHAVE_WIFI_MDNS -DHAVE_WIFI_SUPPORT" \
		CXXFLAGS="-std=c++17 -DVERSION_COMMIT_COUNT=\\\"$(USBMUXD2_VERSION)\\\" -DVERSION_COMMIT_SHA=\\\"$(USBMUXD2_COMMIT)\\\" $(CXXFLAGS) -DHAVE_WIFI_MDNS -DHAVE_WIFI_SUPPORT"
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
