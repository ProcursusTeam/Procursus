ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libxmu
LIBXMU_VERSION := 1.1.3
DEB_LIBXMU_V   ?= $(LIBXMU_VERSION)-1

libxmu-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXmu-$(LIBXMU_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libXmu-$(LIBXMU_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libXmu-$(LIBXMU_VERSION).tar.bz2,libXmu-$(LIBXMU_VERSION),libxmu)

ifneq ($(wildcard $(BUILD_WORK)/libxmu/.build_complete),)
libxmu:
	@echo "Using previously built libxmu."
else
libxmu: libxmu-setup libxext libxt
	cd $(BUILD_WORK)/libxmu && unset CPP CPPFLAGS && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no \
		--enable-specs=no \
		--disable-silent-rules
	+$(MAKE) -C $(BUILD_WORK)/libxmu
	+$(MAKE) -C $(BUILD_WORK)/libxmu install \
		DESTDIR=$(BUILD_STAGE)/libxmu
	+$(MAKE) -C $(BUILD_WORK)/libxmu install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxmu/.build_complete
endif

libxmu-package: libxmu-stage
	# libxmu.mk Package Structure
	rm -rf $(BUILD_DIST)/libxmu{6,-dev} $(BUILD_DIST)/libxmuu1
	mkdir -p $(BUILD_DIST)/libxmu6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxmu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxmuu1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxmu.mk Prep libxmu6 and libxmuu1
	cp -a $(BUILD_STAGE)/libxmu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXmu.6.dylib $(BUILD_DIST)/libxmu6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxmu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXmuu.1.dylib $(BUILD_DIST)/libxmuu1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxmu.mk Prep libxmu-dev
	cp -a $(BUILD_STAGE)/libxmu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libXmu.6.dylib|libXmuu.1.dylib) $(BUILD_DIST)/libxmu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxmu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxmu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxmu.mk Sign
	$(call SIGN,libxmu6,general.xml)
	$(call SIGN,libxmuu1,general.xml)

	# libxmu.mk Make .debs
	$(call PACK,libxmu6,DEB_LIBXMU_V)
	$(call PACK,libxmuu1,DEB_LIBXMU_V)
	$(call PACK,libxmu-dev,DEB_LIBXMU_V)

	# libxmu.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxmu{6,-dev} $(BUILD_DIST)/libxmuu1

.PHONY: libxmu libxmu-package
