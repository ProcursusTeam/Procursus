ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += libirecovery
LIBIRECOVERY_COMMIT  := ab5b4d8d4c0e90c05d80f80c7e99a6516de9b5c6
LIBIRECOVERY_VERSION := 1.0.0+git20220628.$(shell echo $(LIBIRECOVERY_COMMIT) | cut -c -7)
DEB_LIBIRECOVERY_V   ?= $(LIBIRECOVERY_VERSION)

libirecovery-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,libirecovery,$(LIBIRECOVERY_COMMIT),$(LIBIRECOVERY_COMMIT))
	$(call EXTRACT_TAR,libirecovery-$(LIBIRECOVERY_COMMIT).tar.gz,libirecovery-$(LIBIRECOVERY_COMMIT),libirecovery)

ifneq ($(wildcard $(BUILD_WORK)/libirecovery/.build_complete),)
libirecovery:
	@echo "Using previously built libirecovery."
else
libirecovery: libirecovery-setup readline libusb libimobiledevice-glue
	cd $(BUILD_WORK)/libirecovery && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-iokit=no
	+$(MAKE) -C $(BUILD_WORK)/libirecovery \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libusb-1.0"
	+$(MAKE) -C $(BUILD_WORK)/libirecovery install \
		DESTDIR=$(BUILD_STAGE)/libirecovery
	$(call AFTER_BUILD,copy)
endif

libirecovery-package: libirecovery-stage
	# libirecovery.mk Package Structure
	rm -rf $(BUILD_DIST)/libirecovery{3,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libirecovery3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libirecovery-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libirecovery-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libirecovery.mk Prep libirecovery3
	cp -a $(BUILD_STAGE)/libirecovery/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libirecovery-1.0.3.dylib $(BUILD_DIST)/libirecovery3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libirecovery.mk Prep libirecovery-dev
	cp -a $(BUILD_STAGE)/libirecovery/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libirecovery-1.0.{a,dylib}} $(BUILD_DIST)/libirecovery-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libirecovery/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libirecovery-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libirecovery.mk Prep libirecovery-utils
	cp -a $(BUILD_STAGE)/libirecovery/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libirecovery-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libirecovery.mk Sign
	$(call SIGN,libirecovery3,general.xml)
	$(call SIGN,libirecovery-utils,general.xml)

	# libirecovery.mk Make .debs
	$(call PACK,libirecovery3,DEB_LIBIRECOVERY_V)
	$(call PACK,libirecovery-dev,DEB_LIBIRECOVERY_V)
	$(call PACK,libirecovery-utils,DEB_LIBIRECOVERY_V)

	# libirecovery.mk Build cleanup
	rm -rf $(BUILD_DIST)/libirecovery{3,-dev,-utils}

.PHONY: libirecovery libirecovery-package
