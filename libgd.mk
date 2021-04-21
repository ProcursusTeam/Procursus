ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libgd
LIBGD_VERSION := 2.3.2
DEB_LIBGD_V   ?= $(LIBGD_VERSION)-1

libgd-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://github.com/libgd/libgd/releases/download/gd-$(LIBGD_VERSION)/libgd-$(LIBGD_VERSION).tar.xz
	$(call EXTRACT_TAR,libgd-$(LIBGD_VERSION).tar.xz,libgd-$(LIBGD_VERSION),libgd)

# TODO: build all bins
ifneq ($(wildcard $(BUILD_WORK)/libgd/.build_complete),)
libgd:
	@echo "Using previously built libgd."
else
libgd: libgd-setup fontconfig freetype libjpeg-turbo libpng16 libtiff libwebp libxpm
	cd $(BUILD_WORK)/libgd && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS=1 \
		-DENABLE_FONTCONFIG=ON \
		-DENABLE_FREETYPE=ON \
		-DENABLE_ICONV=ON \
		-DENABLE_GD_FORMATS=ON \
		-DENABLE_JPEG=ON \
		-DENABLE_PNG=ON \
		-DENABLE_TIFF=ON \
		-DENABLE_WEBP=ON \
		-DENABLE_XPM=ON \
		-DXPM_XPM_INCLUDE_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		.

	+$(MAKE) -C $(BUILD_WORK)/libgd
	+$(MAKE) -C $(BUILD_WORK)/libgd install \
		DESTDIR="$(BUILD_STAGE)/libgd"
	+$(MAKE) -C $(BUILD_WORK)/libgd install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libgd/.build_complete
endif

libgd-package: libgd-stage
	# libgd.mk Package Structure
	rm -rf $(BUILD_DIST)/libgd{3,-dev,-tools}
	mkdir -p \
		$(BUILD_DIST)/libgd{3,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgd-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgd.mk Prep libgd3
	cp -a $(BUILD_STAGE)/libgd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgd.3*.dylib $(BUILD_DIST)/libgd3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgd.mk Prep libgd-dev
	cp -a $(BUILD_STAGE)/libgd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libgd.3*.dylib) $(BUILD_DIST)/libgd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgd.mk Prep libgd-tools
	cp -a $(BUILD_STAGE)/libgd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libgd-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgd.mk Sign
	$(call SIGN,libgd3,general.xml)
	$(call SIGN,libgd-tools,general.xml)

	# libgd.mk Make .debs
	$(call PACK,libgd3,DEB_LIBGD_V)
	$(call PACK,libgd-dev,DEB_LIBGD_V)
	$(call PACK,libgd-tools,DEB_LIBGD_V)

	# libgd.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgd{3,-{dev,tools}}

.PHONY: libgd libgd-package
