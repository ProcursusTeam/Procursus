ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += libmd
LIBMD_VERSION := 1.0.4
DEB_LIBMD_V   ?= $(LIBMD_VERSION)-1

libmd-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://archive.hadrons.org/software/libmd/libmd-$(LIBMD_VERSION).tar.xz)
	$(call EXTRACT_TAR,libmd-$(LIBMD_VERSION).tar.xz,libmd-$(LIBMD_VERSION),libmd)
	sed -i 's|_MSC_VER|__APPLE__|' $(BUILD_WORK)/libmd/src/local-link.h

ifneq ($(wildcard $(BUILD_WORK)/libmd/.build_complete),)
libmd:
	@echo "Using previously built libmd."
else
libmd: libmd-setup
	cd $(BUILD_WORK)/libmd && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libmd
	+$(MAKE) -C $(BUILD_WORK)/libmd install \
		DESTDIR=$(BUILD_STAGE)/libmd
	$(call AFTER_BUILD,copy)
endif

libmd-package: libmd-stage
	# libmd.mk Package Structure
	rm -rf $(BUILD_DIST)/libmd{0,-dev}
	mkdir -p $(BUILD_DIST)/libmd{0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib,-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib}

	# libmd.mk Prep libmd0
	cp -a $(BUILD_STAGE)/libmd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmd.0.dylib $(BUILD_DIST)/libmd0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmd.mk Prep libmd-dev
	cp -a $(BUILD_STAGE)/libmd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libmd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libmd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libmd.a,libmd.dylib} $(BUILD_DIST)/libmd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmd.mk Sign
	$(call SIGN,libmd0,general.xml)

	# libmd.mk Make .debs
	$(call PACK,libmd0,DEB_LIBMD_V)
	$(call PACK,libmd-dev,DEB_LIBMD_V)

	# libmd.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmd{0,-dev}

.PHONY: libmd libmd-package
