ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libsoxr
LIBSOXR_VERSION := 0.1.3
DEB_LIBSOXR_V   ?= $(LIBSOXR_VERSION)

libsoxr-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/project/soxr/soxr-$(LIBSOXR_VERSION)-Source.tar.xz
	$(call EXTRACT_TAR,soxr-$(LIBSOXR_VERSION)-Source.tar.xz,soxr-$(LIBSOXR_VERSION)-Source,libsoxr)
	mkdir -p $(BUILD_WORK)/libsoxr/build

ifneq ($(wildcard $(BUILD_WORK)/libsoxr/.build_complete),)
libsoxr:
	@echo "Using previously built libsoxr."
else
libsoxr: libsoxr-setup
	cd $(BUILD_WORK)/libsoxr/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_TESTS=0 \
		-DBUILD_EXAMPLES=0 \
		-DBUILD_SHARED_LIBS=1 \
		-DWITH_LSR_BINDINGS=1 \
		..
	+$(MAKE) -C $(BUILD_WORK)/libsoxr/build
	+$(MAKE) -C $(BUILD_WORK)/libsoxr/build install \
		DESTDIR="$(BUILD_STAGE)/libsoxr"
	+$(MAKE) -C $(BUILD_WORK)/libsoxr/build install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libsoxr/.build_complete
endif

libsoxr-package: libsoxr-stage
	# libsoxr.mk Package Structure
	rm -rf $(BUILD_DIST)/libsoxr{{,-lsr}0,-dev}
	mkdir -p $(BUILD_DIST)/libsoxr{{,-lsr}0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsoxr.mk Prep libsoxr0
	cp -a $(BUILD_STAGE)/libsoxr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsoxr.0*.dylib $(BUILD_DIST)/libsoxr0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsoxr.mk Prep libsoxr-lsr0
	cp -a $(BUILD_STAGE)/libsoxr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsoxr-lsr.0*.dylib $(BUILD_DIST)/libsoxr-lsr0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsoxr.mk Prep liblibsoxr-pkg-dev
	cp -a $(BUILD_STAGE)/libsoxr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsoxr.dylib $(BUILD_DIST)/libsoxr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsoxr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsoxr-lsr.dylib $(BUILD_DIST)/libsoxr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsoxr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libsoxr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsoxr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsoxr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsoxr.mk Sign
	$(call SIGN,libsoxr0,general.xml)
	$(call SIGN,libsoxr-lsr0,general.xml)

	# libsoxr.mk Make .debs
	$(call PACK,libsoxr0,DEB_LIBSOXR_V)
	$(call PACK,libsoxr-lsr0,DEB_LIBSOXR_V)
	$(call PACK,libsoxr-dev,DEB_LIBSOXR_V)

	# libsoxr.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsoxr{{,-lsr}0,-dev}

.PHONY: libsoxr libsoxr-package
