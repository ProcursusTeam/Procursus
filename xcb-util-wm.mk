ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xcb-util-wm
XCB-UTIL-WM_VERSION := 0.4.0
DEB_XCB-UTIL-WM_V   ?= $(XCB-UTIL-WM_VERSION)

xcb-util-wm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/xcb/xcb-util-wm-$(XCB-UTIL-WM_VERSION).tar.gz
	$(call EXTRACT_TAR,xcb-util-wm-$(XCB-UTIL-WM_VERSION).tar.gz,xcb-util-wm-$(XCB-UTIL-WM_VERSION),xcb-util-wm)

ifneq ($(wildcard $(BUILD_WORK)/xcb-util-wm/.build_complete),)
xcb-util-wm:
	@echo "Using previously built xcb-util-wm."
else
xcb-util-wm: xcb-util-wm-setup libxcb
	cd $(BUILD_WORK)/xcb-util-wm && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-wm
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-wm install \
		DESTDIR=$(BUILD_STAGE)/xcb-util-wm
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-wm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xcb-util-wm/.build_complete
endif

xcb-util-wm-package: xcb-util-wm-stage
	rm -rf $(BUILD_DIST)/libxcb-wm{1,-dev}
	mkdir -p $(BUILD_DIST)/libxcb-wm{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xcb-util-wm.mk Prep libutil-xrm1
	cp -a $(BUILD_STAGE)/libxcb-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib-xrm.1.dylib $(BUILD_DIST)/libxcb-wm1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb-wm.mk Prep libxcb-wm-dev
	cp -a $(BUILD_STAGE)/libxcb-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libxcb-wm.1.dylib) $(BUILD_DIST)/libxcb-wm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb-wm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxcb-wm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxcb.mk Sign
	$(call SIGN,libxcb-wm1,general.xml)

	# libxcb-wm.mk Make .debs
	$(call PACK,libxcb-wm1,DEB_xcb-wm_V)
	$(call PACK,libxcb-wm-dev,DEB_xcb-wm_V)

	# libxcb-wm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcb-wm{1,-dev}

.PHONY: xcb-util-wm xcb-util-wm-package