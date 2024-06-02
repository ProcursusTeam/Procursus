ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libpipeline
LIBPIPELINE_VERSION := 1.5.7
DEB_LIBPIPELINE_V   ?= $(LIBPIPELINE_VERSION)

libpipeline-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://mirrors.sarata.com/non-gnu/libpipeline/libpipeline-$(LIBPIPELINE_VERSION).tar.gz{$(comma).asc})
	$(call PGP_VERIFY,libpipeline-$(LIBPIPELINE_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,libpipeline-$(LIBPIPELINE_VERSION).tar.gz,libpipeline-$(LIBPIPELINE_VERSION),libpipeline)

ifneq ($(wildcard $(BUILD_WORK)/libpipeline/.build_complete),)
libpipeline:
	@echo "Using previously built libpipeline."
else
libpipeline: libpipeline-setup
	cd $(BUILD_WORK)/libpipeline && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libpipeline
	+$(MAKE) -C $(BUILD_WORK)/libpipeline install \
		DESTDIR=$(BUILD_STAGE)/libpipeline
	$(call AFTER_BUILD,copy)
endif

libpipeline-package: libpipeline-stage
	# libpipeline.mk Package Structure
	rm -rf $(BUILD_DIST)/libpipeline{1,-dev}
	mkdir -p $(BUILD_DIST)/libpipeline{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libpipeline.mk Prep libpipeline1
	cp -a $(BUILD_STAGE)/libpipeline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpipeline.1.dylib $(BUILD_DIST)/libpipeline1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libpipeline.mk Prep libpipeline-dev
	cp -a $(BUILD_STAGE)/libpipeline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libpipeline.dylib,pkgconfig} $(BUILD_DIST)/libpipeline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libpipeline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libpipeline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libpipeline.mk Sign
	$(call SIGN,libpipeline1,general.xml)

	# libpipeline.mk Make .debs
	$(call PACK,libpipeline1,DEB_LIBPIPELINE_V)
	$(call PACK,libpipeline-dev,DEB_LIBPIPELINE_V)

	# libpipeline.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpipeline{1,-dev}

.PHONY: libpipeline libpipeline-package
