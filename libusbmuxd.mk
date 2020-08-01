ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libusbmuxd
LIBUSBMUXD_VERSION := 2.0.2
DEB_LIBUSBMUXD_V   ?= $(LIBUSBMUXD_VERSION)

libusbmuxd-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libimobiledevice/libusbmuxd/archive/$(LIBUSBMUXD_VERSION).tar.gz
	$(call EXTRACT_TAR,$(LIBUSBMUXD_VERSION).tar.gz,libusbmuxd-$(LIBUSBMUXD_VERSION),libusbmuxd)

ifneq ($(wildcard $(BUILD_WORK)/libusbmuxd/.build_complete),)
libusbmuxd:
	@echo "Using previously built libusbmuxd."
else
libusbmuxd: libusbmuxd-setup libplist
	cd $(BUILD_WORK)/libusbmuxd && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd install \
		DESTDIR="$(BUILD_STAGE)/libusbmuxd"
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libusbmuxd/.build_complete
endif

libusbmuxd-package: libusbmuxd-stage
	# libusbmuxd.mk Package Structure
	rm -rf $(BUILD_DIST)/libusbmuxd{6,-dev,-tools}
	mkdir -p $(BUILD_DIST)/libusbmuxd6/usr/lib \
		$(BUILD_DIST)/libusbmuxd-dev/usr/lib \
		$(BUILD_DIST)/libusbmuxd-tools/usr

	# libusbmuxd.mk Prep libusbmuxd6
	cp -a $(BUILD_STAGE)/libusbmuxd/usr/lib/libusbmuxd-2.0.6.dylib $(BUILD_DIST)/libusbmuxd6/usr/lib/
	
	# libusbmuxd.mk Prep libusbmuxd-dev
	cp -a $(BUILD_STAGE)/libusbmuxd/usr/lib/{pkgconfig,libusbmuxd-2.0.{a,dylib}} $(BUILD_DIST)/libusbmuxd-dev/usr/lib
	cp -a $(BUILD_STAGE)/libusbmuxd/usr/include $(BUILD_DIST)/libusbmuxd-dev/usr
	
	# libusbmuxd.mk Prep libusbmuxd-tools
	cp -a $(BUILD_STAGE)/libusbmuxd/usr/{bin,share} $(BUILD_DIST)/libusbmuxd-tools/usr

	# libusbmuxd.mk Sign
	$(call SIGN,libusbmuxd6,general.xml)
	$(call SIGN,libusbmuxd-tools,general.xml)

	# libusbmuxd.mk Make .debs
	$(call PACK,libusbmuxd6,DEB_LIBUSBMUXD_V)
	$(call PACK,libusbmuxd-dev,DEB_LIBUSBMUXD_V)
	$(call PACK,libusbmuxd-tools,DEB_LIBUSBMUXD_V)

	# libusbmuxd.mk Build cleanup
	rm -rf $(BUILD_DIST)/libusbmuxd{6,-dev,-tools}

.PHONY: libusbmuxd libusbmuxd-package
