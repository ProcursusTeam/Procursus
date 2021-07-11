ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libconfig
LIBCONFIG_VERSION := 1.7.2
DEB_LIBCONFIG_V   ?= $(LIBCONFIG_VERSION)

libconfig-setup: setup
	$(call GITHUB_ARCHIVE,hyperrealm,libconfig,$(LIBCONFIG_VERSION),v$(LIBCONFIG_VERSION))
	$(call EXTRACT_TAR,libconfig-$(LIBCONFIG_VERSION).tar.gz,libconfig-$(LIBCONFIG_VERSION),libconfig)

ifneq ($(wildcard $(BUILD_WORK)/libconfig/.build_complete),)
libconfig:
	@echo "Using previously built libconfig."
else
libconfig: libconfig-setup
	cd $(BUILD_WORK)/libconfig && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libconfig
	+$(MAKE) -C $(BUILD_WORK)/libconfig install \
		DESTDIR=$(BUILD_STAGE)/libconfig
	+$(MAKE) -C $(BUILD_WORK)/libconfig install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libconfig/.build_complete
endif

libconfig-package: libconfig-stage
	# libconfig.mk Package Structure
	rm -rf $(BUILD_DIST)/libconfig{++{-dev,11},-{dev,doc},11}
	mkdir -p \
		$(BUILD_DIST)/libconfig{,++}11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libconfig{,++}-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/{cmake,pkgconfig}}


	# libconfig.mk Prep libconfig++-dev
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libconfig.h++ $(BUILD_DIST)/libconfig++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libconfig++.{a,dylib} $(BUILD_DIST)/libconfig++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake/libconfig++ $(BUILD_DIST)/libconfig++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libconfig++.pc $(BUILD_DIST)/libconfig++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libconfig.mk Prep libconfig++11
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libconfig++.*.dylib $(BUILD_DIST)/libconfig++11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libconfig.mk Prep libconfig-dev
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libconfig.h $(BUILD_DIST)/libconfig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libconfig.{a,dylib} $(BUILD_DIST)/libconfig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake/libconfig $(BUILD_DIST)/libconfig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libconfig.pc $(BUILD_DIST)/libconfig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libconfig.mk Prep libconfig11
	cp -a $(BUILD_STAGE)/libconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libconfig.*.dylib $(BUILD_DIST)/libconfig11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib


	# libconfig.mk Sign
	$(call SIGN,libconfig11,general.xml)
	$(call SIGN,libconfig++11,general.xml)

	# libconfig.mk Make .debs
	$(call PACK,libconfig11,DEB_LIBCONFIG_V)
	$(call PACK,libconfig++11,DEB_LIBCONFIG_V)
	$(call PACK,libconfig-dev,DEB_LIBCONFIG_V)
	$(call PACK,libconfig++-dev,DEB_LIBCONFIG_V)

	# libconfig.mk Build cleanup
	rm -rf $(BUILD_DIST)/libconfig{++{-dev,11},-{dev,doc},11}

.PHONY: libconfig libconfig-package
