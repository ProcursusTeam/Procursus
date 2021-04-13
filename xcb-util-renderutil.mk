ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xcb-util-renderutil
XCB-UTIL-RENDERUTIL_VERSION := 0.3.9
DEB_XCB-UTIL-RENDERUTIL_V   ?= $(XCB-UTIL-RENDERUTIL_VERSION)

xcb-util-renderutil-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/xcb/xcb-util-renderutil-$(XCB-UTIL-RENDERUTIL_VERSION).tar.gz
	$(call EXTRACT_TAR,xcb-util-renderutil-$(XCB-UTIL-RENDERUTIL_VERSION).tar.gz,xcb-util-renderutil-$(XCB-UTIL-RENDERUTIL_VERSION),xcb-util-renderutil)

ifneq ($(wildcard $(BUILD_WORK)/xcb-util-renderutil/.build_complete),)
xcb-util-renderutil:
	@echo "Using previously built xcb-util-renderutil."
else
xcb-util-renderutil: xcb-util-renderutil-setup libxcb libXres
	cd $(BUILD_WORK)/xcb-util-renderutil && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-renderutil
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-renderutil install \
		DESTDIR=$(BUILD_STAGE)/xcb-util-renderutil
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-renderutil install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xcb-util-renderutil/.build_complete
endif

xcb-util-renderutil-package: xcb-util-renderutil-stage
	rm -rf $(BUILD_DIST)/libxcb-renderutil{1,-dev}
	mkdir -p $(BUILD_DIST)/libxcb-renderutil{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xcb-util-renderutil.mk Prep libutil-xrm1
	cp -a $(BUILD_STAGE)/libxcb-renderutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib-xrm.1.dylib $(BUILD_DIST)/libxcb-renderutil1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb-renderutil.mk Prep libxcb-renderutil-dev
	cp -a $(BUILD_STAGE)/libxcb-renderutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libxcb-renderutil.1.dylib) $(BUILD_DIST)/libxcb-renderutil-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb-renderutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxcb-renderutil-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxcb.mk Sign
	$(call SIGN,libxcb-renderutil1,general.xml)

	# libxcb-renderutil.mk Make .debs
	$(call PACK,libxcb-renderutil1,DEB_xcb-renderutil_V)
	$(call PACK,libxcb-renderutil-dev,DEB_xcb-renderutil_V)

	# libxcb-renderutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcb-renderutil{1,-dev}

.PHONY: xcb-util-renderutil xcb-util-renderutil-package
