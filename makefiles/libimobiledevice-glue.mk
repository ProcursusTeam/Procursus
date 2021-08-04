ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += libimobiledevice-glue
LIBIMOBILEDEVICEGLUE_COMMIT  := 4b34ad0f047abb441573177480d8baed312e930e
LIBIMOBILEDEVICEGLUE_VERSION := 1.0.0+git20210629.$(shell echo $(LIBIMOBILEDEVICEGLUE_COMMIT) | cut -c -7)
DEB_LIBIMOBILEDEVICEGLUE_V   ?= $(LIBIMOBILEDEVICEGLUE_VERSION)

libimobiledevice-glue-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,libimobiledevice-glue,$(LIBIMOBILEDEVICEGLUE_COMMIT),$(LIBIMOBILEDEVICEGLUE_COMMIT))
	$(call EXTRACT_TAR,libimobiledevice-glue-$(LIBIMOBILEDEVICEGLUE_COMMIT).tar.gz,libimobiledevice-glue-$(LIBIMOBILEDEVICEGLUE_COMMIT),libimobiledevice-glue)

ifneq ($(wildcard $(BUILD_WORK)/libimobiledevice-glue/.build_complete),)
libimobiledevice-glue:
	@echo "Using previously built libimobiledevice-glue."
else
libimobiledevice-glue: libimobiledevice-glue-setup libplist
	cd $(BUILD_WORK)/libimobiledevice-glue && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-cython
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice-glue
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice-glue install \
		DESTDIR="$(BUILD_STAGE)/libimobiledevice-glue"
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice-glue install \
		DESTDIR="$(BUILD_BASE)"
	$(call AFTER_BUILD)
endif

libimobiledevice-glue-package: libimobiledevice-glue-stage
	# libimobiledevice-glue.mk Package Structure
	rm -rf $(BUILD_DIST)/libimobiledevice-glue{,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libimobiledevice-glue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libimobiledevice-glue-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \

	# libimobiledevice-glue.mk Prep libimobiledevice-glue
	cp -a $(BUILD_STAGE)/libimobiledevice-glue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libimobiledevice-glue-1.0.0.dylib $(BUILD_DIST)/libimobiledevice-glue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libimobiledevice-glue.mk Prep libimobiledevice-glue-dev
	cp -a $(BUILD_STAGE)/libimobiledevice-glue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libimobiledevice-glue-1.0.{a,dylib}} $(BUILD_DIST)/libimobiledevice-glue-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libimobiledevice-glue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libimobiledevice-glue-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libimobiledevice-glue.mk Sign
	$(call SIGN,libimobiledevice,general.xml)

	# libimobiledevice-glue.mk Make .debs
	$(call PACK,libimobiledevice-glue,DEB_LIBIMOBILEDEVICEGLUE_V)
	$(call PACK,libimobiledevice-glue-dev,DEB_LIBIMOBILEDEVICEGLUE_V)

	# libimobiledevice-glue.mk Build cleanup
	rm -rf $(BUILD_DIST)/libimobiledevice-glue{,-dev,-utils}

.PHONY: libimobiledevice-glue libimobiledevice-glue-package
