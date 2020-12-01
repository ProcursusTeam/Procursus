ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += cairo
CAIRO_VERSION := 1.16.0
DEB_CAIRO_V   ?= $(CAIRO_VERSION)-1

cairo-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://cairographics.org/releases/cairo-$(CAIRO_VERSION).tar.xz
	$(call EXTRACT_TAR,cairo-$(CAIRO_VERSION).tar.xz,cairo-$(CAIRO_VERSION),cairo)

ifneq ($(wildcard $(BUILD_WORK)/cairo/.build_complete),)
cairo:
	@echo "Using previously built cairo."
else
cairo: cairo-setup freetype fontconfig glib2.0 libpng16 liblzo2 libpixman
	cd $(BUILD_WORK)/cairo && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-pdf \
		--enable-ps \
		--enable-png \
		--enable-tee \
		--enable-pref-utils \
		--enable-svg \
		--disable-xcb \
		--disable-xlib \
		--enable-gobject \
		FONTCONFIG_CFLAGS="-I$(BUILD_BASE)/usr/include/freetype2 -I$(BUILD_BASE)/usr/include/libpng16" \
		FREETYPE_CFLAGS="-I$(BUILD_BASE)/usr/include/freetype2 -I$(BUILD_BASE)/usr/include/libpng16" \
		GOBJECT_CFLAGS="-I$(BUILD_BASE)/usr/include/glib-2.0 -I$(BUILD_BASE)/usr/include/glib-2.0/include" \
		glib_CFLAGS="-I$(BUILD_BASE)/usr/include/glib-2.0 -I$(BUILD_BASE)/usr/include/glib-2.0/include -I$(BUILD_BASE)/usr/lib/glib-2.0/include" \
		pixman_CFLAGS="-I$(BUILD_BASE)/usr/include/pixman-1" \
		png_CFLAGS="-I$(BUILD_BASE)/usr/include/libpng16"
	+$(MAKE) -C $(BUILD_WORK)/cairo \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/usr/lib/glib-2.0/include"
	+$(MAKE) -C $(BUILD_WORK)/cairo install \
		DESTDIR=$(BUILD_STAGE)/cairo
	+$(MAKE) -C $(BUILD_WORK)/cairo install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/cairo/.build_complete
endif

cairo-package: cairo-stage
	# cairo.mk Package Structure
	rm -rf $(BUILD_DIST)/libcairo2{,-dev} $(BUILD_DIST)/libcairo{-gobject,-script-interpreter}2 #$(BUILD_DIST)/cairo-perf-utils
	mkdir -p $(BUILD_DIST)/libcairo2{,-dev}/usr/lib \
		$(BUILD_DIST)/libcairo{-gobject,-script-interpreter}2/usr/lib #\
		#$(BUILD_DIST)/cairo-perf-utils/usr/bin
	
	# cairo.mk Prep libcairo2
	cp -a $(BUILD_STAGE)/cairo/usr/lib/libcairo.2.dylib $(BUILD_DIST)/libcairo2/usr/lib

	# cairo.mk Prep libcairo-gobject2
	cp -a $(BUILD_STAGE)/cairo/usr/lib/libcairo-gobject.2.dylib $(BUILD_DIST)/libcairo-gobject2/usr/lib

	# cairo.mk Prep libcairo-script-interpreter2
	cp -a $(BUILD_STAGE)/cairo/usr/lib/libcairo-script-interpreter.2.dylib $(BUILD_DIST)/libcairo-script-interpreter2/usr/lib

	# cairo.mk Prep libcairo2-dev
	cp -a $(BUILD_STAGE)/cairo/usr/lib/!(cairo|*.2.dylib) $(BUILD_DIST)/libcairo2-dev/usr/lib
	cp -a $(BUILD_STAGE)/cairo/usr/include $(BUILD_DIST)/libcairo2-dev/usr

	# cairo.mk Prep cairo-perf-utils
	#cp -a $(BUILD_STAGE)/cairo/usr/bin/cairo-trace $(BUILD_DIST)/cairo-perf-utils/usr/bin
	
	# cairo.mk Sign
	$(call SIGN,libcairo2,general.xml)
	$(call SIGN,libcairo-gobject2,general.xml)
	$(call SIGN,libcairo-script-interpreter2,general.xml)
	#$(call SIGN,cairo-perf-utils,general.xml)
	
	# cairo.mk Make .debs
	$(call PACK,libcairo2,DEB_CAIRO_V)
	$(call PACK,libcairo2-dev,DEB_CAIRO_V)
	$(call PACK,libcairo-gobject2,DEB_CAIRO_V)
	$(call PACK,libcairo-script-interpreter2,DEB_CAIRO_V)
	#$(call PACK,cairo-perf-utils,DEB_CAIRO_V)
	
	# cairo.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcairo2{,-dev} $(BUILD_DIST)/libcairo{-gobject,-script-interpreter}2 #$(BUILD_DIST)/cairo-perf-utils

.PHONY: cairo cairo-package
