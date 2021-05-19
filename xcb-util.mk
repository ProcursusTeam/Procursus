ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += xcb-util
XCB-UTIL_VERSION := 0.4.0
DEB_XCB-UTIL_V   ?= $(XCB-UTIL_VERSION)

xcb-util-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xcb.freedesktop.org/dist/xcb-util-$(XCB-UTIL_VERSION).tar.gz
	$(call EXTRACT_TAR,xcb-util-$(XCB-UTIL_VERSION).tar.gz,xcb-util-$(XCB-UTIL_VERSION),xcb-util)

ifneq ($(wildcard $(BUILD_WORK)/xcb-util/.build_complete),)
xcb-util:
	@echo "Using previously built xcb-util."
else
xcb-util: xcb-util-setup libxcb
	cd $(BUILD_WORK)/xcb-util && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xcb-util install \
		DESTDIR=$(BUILD_STAGE)/xcb-util
	+$(MAKE) -C $(BUILD_WORK)/xcb-util install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xcb-util/.build_complete
endif


xcb-util-package: xcb-util-stage
	rm -rf $(BUILD_DIST)/libxcb-util{1,-dev}
	mkdir -p $(BUILD_DIST)/libxcb-util{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xcb-util.mk Prep libxcb-util1
	cp -a $(BUILD_STAGE)/xcb-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-util.1.dylib $(BUILD_DIST)/libxcb-util1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xcb-util.mk Prep libxcb-util-dev
	cp -a $(BUILD_STAGE)/xcb-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libxcb-util.1.dylib) $(BUILD_DIST)/libxcb-util-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xcb-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxcb-util-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xcb-util.mk Sign
	$(call SIGN,libxcb-util1,general.xml)

	# xcb-util.mk Make .debs
	$(call PACK,libxcb-util1,DEB_XCB-UTIL_V)
	$(call PACK,libxcb-util-dev,DEB_XCB-UTIL_V)

	# xcb-util.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcb-util{1,-dev}

.PHONY: xcb-util xcb-util-package
