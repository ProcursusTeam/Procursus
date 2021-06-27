ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += xcb-util-xrm
XCB-UTIL-XRM_VERSION := 1.3
DEB_XCB-UTIL-XRM_V   ?= $(XCB-UTIL-XRM_VERSION)

xcb-util-xrm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/Airblader/xcb-util-xrm/releases/download/v1.3/xcb-util-xrm-1.3.tar.gz
	$(call EXTRACT_TAR,xcb-util-xrm-$(XCB-UTIL-XRM_VERSION).tar.gz,xcb-util-xrm-$(XCB-UTIL-XRM_VERSION),xcb-util-xrm)

ifneq ($(wildcard $(BUILD_WORK)/xcb-util-xrm/.build_complete),)
xcb-util-xrm:
	@echo "Using previously built xcb-util-xrm."
else
xcb-util-xrm: xcb-util-xrm-setup libxcb xcb-util
	cd $(BUILD_WORK)/xcb-util-xrm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-xrm
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-xrm install \
		DESTDIR=$(BUILD_STAGE)/xcb-util-xrm
	+$(MAKE) -C $(BUILD_WORK)/xcb-util-xrm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xcb-util-xrm/.build_complete
endif

xcb-util-xrm-package: xcb-util-xrm-stage
	rm -rf $(BUILD_DIST)/libxcb-xrm{0,-dev}
	mkdir -p $(BUILD_DIST)/libxcb-xrm{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xcb-util-xrm.mk Prep libxcb-xrm0
	cp -a $(BUILD_STAGE)/xcb-util-xrm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xrm.0.dylib $(BUILD_DIST)/libxcb-xrm0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb-xrm.mk Prep libxcb-xrm-dev
	cp -a $(BUILD_STAGE)/xcb-util-xrm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libxcb-xrm.0.dylib) $(BUILD_DIST)/libxcb-xrm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xcb-util-xrm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxcb-xrm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxcb.mk Sign
	$(call SIGN,libxcb-xrm0,general.xml)

	# libxcb-xrm.mk Make .debs
	$(call PACK,libxcb-xrm0,DEB_XCB-UTIL-XRM_V)
	$(call PACK,libxcb-xrm-dev,DEB_XCB-UTIL-XRM_V)

	# libxcb-xrm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcb-xrm{0,-dev}

.PHONY: xcb-util-xrm xcb-util-xrm-package
