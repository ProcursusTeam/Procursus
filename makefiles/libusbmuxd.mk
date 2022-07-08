ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libusbmuxd
LIBUSBMUXD_COMMIT := 36ffb7ab6e2a7e33bd1b56398a88895b7b8c615a
LIBUSBMUXD_VERSION := 2.0.2+git20220504.$(shell echo $(LIBUSBMUXD_COMMIT) | cut -c -7)
DEB_LIBUSBMUXD_V   ?= $(LIBUSBMUXD_VERSION)

libusbmuxd-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,libusbmuxd,$(LIBUSBMUXD_COMMIT),$(LIBUSBMUXD_COMMIT))
	$(call EXTRACT_TAR,libusbmuxd-$(LIBUSBMUXD_COMMIT).tar.gz,libusbmuxd-$(LIBUSBMUXD_COMMIT),libusbmuxd)

ifneq ($(wildcard $(BUILD_WORK)/libusbmuxd/.build_complete),)
libusbmuxd:
	@echo "Using previously built libusbmuxd."
else
libusbmuxd: libusbmuxd-setup libplist libimobiledevice-glue
	cd $(BUILD_WORK)/libusbmuxd && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		PACKAGE_VERSION="$(LIBUSBMUXD_VERSION)"
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd install \
		DESTDIR="$(BUILD_STAGE)/libusbmuxd"
	$(call AFTER_BUILD,copy)
endif

libusbmuxd-package: libusbmuxd-stage
	# libusbmuxd.mk Package Structure
	rm -rf $(BUILD_DIST)/libusbmuxd{6,-dev,-tools}
	mkdir -p $(BUILD_DIST)/libusbmuxd6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libusbmuxd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libusbmuxd-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libusbmuxd.mk Prep libusbmuxd6
	cp -a $(BUILD_STAGE)/libusbmuxd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libusbmuxd-2.0.6.dylib $(BUILD_DIST)/libusbmuxd6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libusbmuxd.mk Prep libusbmuxd-dev
	cp -a $(BUILD_STAGE)/libusbmuxd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libusbmuxd-2.0.{a,dylib}} $(BUILD_DIST)/libusbmuxd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libusbmuxd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libusbmuxd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libusbmuxd.mk Prep libusbmuxd-tools
	cp -a $(BUILD_STAGE)/libusbmuxd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libusbmuxd-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

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
