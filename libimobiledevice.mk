ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += libimobiledevice
LIBIMOBILEDEVICE_COMMIT  := 25059d4c7d75e03aab516af2929d7c6e6d4c17de
LIBIMOBILEDEVICE_VERSION := 1.3.0+git20210304.$(shell echo $(LIBIMOBILEDEVICE_COMMIT) | cut -c -7)
DEB_LIBIMOBILEDEVICE_V   ?= $(LIBIMOBILEDEVICE_VERSION)

libimobiledevice-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,libimobiledevice,$(LIBIMOBILEDEVICE_COMMIT),$(LIBIMOBILEDEVICE_COMMIT))
	$(call EXTRACT_TAR,libimobiledevice-$(LIBIMOBILEDEVICE_COMMIT).tar.gz,libimobiledevice-$(LIBIMOBILEDEVICE_COMMIT),libimobiledevice)

ifneq ($(wildcard $(BUILD_WORK)/libimobiledevice/.build_complete),)
libimobiledevice:
	@echo "Using previously built libimobiledevice."
else
libimobiledevice: libimobiledevice-setup libusbmuxd libplist openssl
	cd $(BUILD_WORK)/libimobiledevice && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-cython
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice install \
		DESTDIR="$(BUILD_STAGE)/libimobiledevice"
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libimobiledevice/.build_complete
endif

libimobiledevice-package: libimobiledevice-stage
	# libimobiledevice.mk Package Structure
	rm -rf $(BUILD_DIST)/libimobiledevice{6,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libimobiledevice6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libimobiledevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libimobiledevice-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libimobiledevice.mk Prep libimobiledevice6
	cp -a $(BUILD_STAGE)/libimobiledevice/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libimobiledevice-1.0.6.dylib $(BUILD_DIST)/libimobiledevice6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libimobiledevice.mk Prep libimobiledevice-dev
	cp -a $(BUILD_STAGE)/libimobiledevice/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libimobiledevice-1.0.{a,dylib}} $(BUILD_DIST)/libimobiledevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libimobiledevice/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libimobiledevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libimobiledevice.mk Prep libimobiledevice-utils
	cp -a $(BUILD_STAGE)/libimobiledevice/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libimobiledevice-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libimobiledevice.mk Sign
	$(call SIGN,libimobiledevice6,general.xml)
	$(call SIGN,libimobiledevice-utils,general.xml)

	# libimobiledevice.mk Make .debs
	$(call PACK,libimobiledevice6,DEB_LIBIMOBILEDEVICE_V)
	$(call PACK,libimobiledevice-dev,DEB_LIBIMOBILEDEVICE_V)
	$(call PACK,libimobiledevice-utils,DEB_LIBIMOBILEDEVICE_V)

	# libimobiledevice.mk Build cleanup
	rm -rf $(BUILD_DIST)/libimobiledevice{6,-dev,-utils}

.PHONY: libimobiledevice libimobiledevice-package
