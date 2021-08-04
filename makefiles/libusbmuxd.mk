ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libusbmuxd
LIBUSBMUXD_COMMIT  := e32bf7612912348d7af81afe1e8be2ecc93a93ca
LIBUSBMUXD_VERSION := 2.0.3+git20210629.$(shell echo $(LIBUSBMUXD_COMMIT) | cut -c -7)
DEB_LIBUSBMUXD_V   ?= $(LIBUSBMUXD_VERSION)

libusbmuxd-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,libusbmuxd,$(LIBUSBMUXD_COMMIT),$(LIBUSBMUXD_COMMIT))
	$(call EXTRACT_TAR,libusbmuxd-$(LIBUSBMUXD_COMMIT).tar.gz,libusbmuxd-$(LIBUSBMUXD_COMMIT),libusbmuxd)

ifneq ($(wildcard $(BUILD_WORK)/libusbmuxd/.build_complete),)
libusbmuxd:
	@echo "Using previously built libusbmuxd."
else
libusbmuxd: libusbmuxd-setup libplist
	cd $(BUILD_WORK)/libusbmuxd && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd install \
		DESTDIR="$(BUILD_STAGE)/libusbmuxd"
	+$(MAKE) -C $(BUILD_WORK)/libusbmuxd install \
		DESTDIR="$(BUILD_BASE)"
	$(call AFTER_BUILD)
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
