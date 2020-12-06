ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libass
LIBASS_VERSION := 0.15.0
DEB_LIBASS_V   ?= $(LIBASS_VERSION)

libass-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libass/libass/releases/download/$(LIBASS_VERSION)/libass-$(LIBASS_VERSION).tar.xz
	$(call EXTRACT_TAR,libass-$(LIBASS_VERSION).tar.xz,libass-$(LIBASS_VERSION),libass)

ifneq ($(wildcard $(BUILD_WORK)/libass/.build_complete),)
libass:
	@echo "Using previously built libass."
else
libass: libass-setup freetype fontconfig libfribidi harfbuzz
	cd $(BUILD_WORK)/libass && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		FONTCONFIG_CFLAGS="-I$(BUILD_BASE)/usr/include/freetype2 -I$(BUILD_BASE)/usr/include/libpng16" \
		FREETYPE_CFLAGS="-I$(BUILD_BASE)/usr/include/freetype2 -I$(BUILD_BASE)/usr/include/libpng16" \
		FRIBIDI_CFLAGS="-I$(BUILD_BASE)/usr/include/fribidi" \
		HARFBUZZ_CFLAGS="-I$(BUILD_BASE)/usr/include/harfbuzz"
	+$(MAKE) -C $(BUILD_WORK)/libass
	+$(MAKE) -C $(BUILD_WORK)/libass install \
		DESTDIR="$(BUILD_STAGE)/libass"
	+$(MAKE) -C $(BUILD_WORK)/libass install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libass/.build_complete
endif

libass-package: libass-stage
	# libass.mk Package Structure
	rm -rf $(BUILD_DIST)/libass{9,-dev}
	mkdir -p $(BUILD_DIST)/libass{9,-dev}/usr/lib
	
	# libass.mk Prep libass9
	cp -a $(BUILD_STAGE)/libass/usr/lib/libass.9.dylib $(BUILD_DIST)/libass9/usr/lib
	
	# libass.mk Prep libass-dev
	cp -a $(BUILD_STAGE)/libass/usr/lib/{libass.{dylib,a},pkgconfig} $(BUILD_DIST)/libass-dev/usr/lib
	cp -a $(BUILD_STAGE)/libass/usr/include $(BUILD_DIST)/libass-dev/usr
	
	# libass.mk Sign
	$(call SIGN,libass9,general.xml)
	
	# libass.mk Make .debs
	$(call PACK,libass9,DEB_LIBASS_V)
	$(call PACK,libass-dev,DEB_LIBASS_V)
	
	# libass.mk Build cleanup
	rm -rf $(BUILD_DIST)/libass{9,-dev}

.PHONY: libass libass-package
