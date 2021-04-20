ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += xcb-util-wm
XCB-UTIL-WM_VERSION := 0.4.0
DEB_XCB-UTIL-WM_V   ?= $(XCB-UTIL-WM_VERSION)

xcb-util-wm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/xcb/xcb-util-wm-$(XCB-UTIL-WM_VERSION).tar.gz
	$(call EXTRACT_TAR,xcb-util-wm-$(XCB-UTIL-WM_VERSION).tar.gz,xcb-util-wm-$(XCB-UTIL-WM_VERSION),xcb-util-wm)

ifneq ($(wildcard $(BUILD_WORK)/xcb-util-wm/.build_complete),)
xcb-util-wm:
	@echo "Using previously built xcb-util-wm."
else
xcb-util-wm: xcb-util-wm-setup libxcb xcb-util
	cd $(BUILD_WORK)/xcb-util-wm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-wm
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-wm install \
		DESTDIR=$(BUILD_STAGE)/xcb-util-wm
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-wm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xcb-util-wm/.build_complete
endif

xcb-util-wm-package: xcb-util-wm-stage
	rm -rf $(BUILD_DIST)/libxcb-ewmh{2,-dev} $(BUILD_DIST)/libxcb-icccm4{,-dev}
	mkdir -p $(BUILD_DIST)/libxcb-ewmh2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxcb-ewmh-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include/xcb}
	mkdir -p $(BUILD_DIST)/libxcb-icccm4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxcb-icccm4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include/xcb}

	# xcb-util-wm.mk Prep libxcb-ewmh2
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-ewmh.2.dylib $(BUILD_DIST)/libxcb-ewmh2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb-wm.mk Prep libxcb-ewmh-dev
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-ewmh.{a,dylib} $(BUILD_DIST)/libxcb-ewmh-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-ewmh.pc $(BUILD_DIST)/libxcb-ewmh-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xcb_ewmh.h $(BUILD_DIST)/libxcb-ewmh-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb

	# xcb-util-wm.mk Prep libxcb-icccm4
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-icccm.4.dylib $(BUILD_DIST)/libxcb-icccm4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb-wm.mk Prep libxcb-icccm4-dev
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-icccm.{a,dylib} $(BUILD_DIST)/libxcb-icccm4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-icccm.pc $(BUILD_DIST)/libxcb-icccm4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/xcb-util-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xcb_icccm.h $(BUILD_DIST)/libxcb-icccm4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb

	# libxcb.mk Sign
	$(call SIGN,libxcb-ewmh2,general.xml)
	$(call SIGN,libxcb-icccm4,general.xml)

	# libxcb-wm.mk Make .debs
	$(call PACK,libxcb-ewmh2,DEB_XCB-UTIL-WM_V)
	$(call PACK,libxcb-ewmh-dev,DEB_XCB-UTIL-WM_V)
	$(call PACK,libxcb-icccm4,DEB_XCB-UTIL-WM_V)
	$(call PACK,libxcb-icccm4-dev,DEB_XCB-UTIL-WM_V)

	# libxcb-wm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcb-ewmh{2,-dev} $(BUILD_DIST)/libxcb-icccm4{,-dev}

.PHONY: xcb-util-wm xcb-util-wm-package
