ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += openjpeg
OPENJPEG_VERSION := 2.4.0
DEB_OPENJPEG_V   ?= $(OPENJPEG_VERSION)

openjpeg-setup: setup
	$(call GITHUB_ARCHIVE,uclouvain,openjpeg,$(OPENJPEG_VERSION),v$(OPENJPEG_VERSION))
	$(call EXTRACT_TAR,openjpeg-$(OPENJPEG_VERSION).tar.gz,openjpeg-$(OPENJPEG_VERSION),openjpeg)

ifneq ($(wildcard $(BUILD_WORK)/openjpeg/.build_complete),)
openjpeg:
	@echo "Using previously built openjpeg."
else
openjpeg: openjpeg-setup libpng16 libtiff lcms2
	cd $(BUILD_WORK)/openjpeg && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCOMMON_ARCH=$(DEB_ARCH)
	+$(MAKE) -C $(BUILD_WORK)/openjpeg
	+$(MAKE) -C $(BUILD_WORK)/openjpeg install \
		DESTDIR="$(BUILD_STAGE)/openjpeg"
	+$(MAKE) -C $(BUILD_WORK)/openjpeg install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/openjpeg/.build_complete
endif

openjpeg-package: openjpeg-stage
	# openjpeg.mk Package Structure
	rm -rf $(BUILD_DIST)/libopenjp2-{7{,-dev},tools}
	mkdir -p \
		$(BUILD_DIST)/libopenjp2-7{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libopenjp2-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# openjpeg.mk Prep libopenjp2-7-dev
	cp -a $(BUILD_STAGE)/openjpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libopenjp2-7-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/openjpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libopenjp2.*.dylib) $(BUILD_DIST)/libopenjp2-7-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openjpeg.mk Prep libopenjp2-tools
	cp -a $(BUILD_STAGE)/openjpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libopenjp2-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# openjpeg.mk Prep libopenjp2-7
	cp -a $(BUILD_STAGE)/openjpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libopenjp2.{7,$(OPENJPEG_VERSION)}.dylib $(BUILD_DIST)/libopenjp2-7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openjpeg.mk Sign
	$(call SIGN,libopenjp2-7,general.xml)
	$(call SIGN,libopenjp2-tools,general.xml)

	# openjpeg.mk Make .debs
	$(call PACK,libopenjp2-7-dev,DEB_OPENJPEG_V)
	$(call PACK,libopenjp2-tools,DEB_OPENJPEG_V)
	$(call PACK,libopenjp2-7,DEB_OPENJPEG_V)

	# openjpeg.mk Build cleanup
	rm -rf $(BUILD_DIST)/libopenjp2-{7{,-dev},tools}

.PHONY: openjpeg openjpeg-package
