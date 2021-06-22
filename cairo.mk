ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += cairo
CAIRO_VERSION := 1.16.0
DEB_CAIRO_V   ?= $(CAIRO_VERSION)-3

cairo-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://cairographics.org/releases/cairo-$(CAIRO_VERSION).tar.xz
	$(call EXTRACT_TAR,cairo-$(CAIRO_VERSION).tar.xz,cairo-$(CAIRO_VERSION),cairo)

ifneq ($(wildcard $(BUILD_WORK)/cairo/.build_complete),)
cairo:
	@echo "Using previously built cairo."
else
cairo: cairo-setup freetype gettext fontconfig glib2.0 libpng16 liblzo2 libpixman libxcb libxrender libx11 libxext
	cd $(BUILD_WORK)/cairo && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-pdf \
		--enable-ps \
		--enable-png \
		--enable-tee \
		--enable-pref-utils \
		--enable-svg \
		--enable-xcb \
		--enable-xlib \
		--enable-gobject
	+$(MAKE) -C $(BUILD_WORK)/cairo \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/glib-2.0/include"
	+$(MAKE) -C $(BUILD_WORK)/cairo install \
		DESTDIR=$(BUILD_STAGE)/cairo
	+$(MAKE) -C $(BUILD_WORK)/cairo install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/cairo/.build_complete
endif

cairo-package: cairo-stage
	# cairo.mk Package Structure
	rm -rf $(BUILD_DIST)/libcairo2{,-dev} $(BUILD_DIST)/libcairo{-gobject,-script-interpreter}2 #$(BUILD_DIST)/cairo-perf-utils
	mkdir -p $(BUILD_DIST)/libcairo2{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libcairo{-gobject,-script-interpreter}2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib #\
		#$(BUILD_DIST)/cairo-perf-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# cairo.mk Prep libcairo2
	cp -a $(BUILD_STAGE)/cairo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcairo.2.dylib $(BUILD_DIST)/libcairo2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# cairo.mk Prep libcairo-gobject2
	cp -a $(BUILD_STAGE)/cairo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcairo-gobject.2.dylib $(BUILD_DIST)/libcairo-gobject2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# cairo.mk Prep libcairo-script-interpreter2
	cp -a $(BUILD_STAGE)/cairo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcairo-script-interpreter.2.dylib $(BUILD_DIST)/libcairo-script-interpreter2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# cairo.mk Prep libcairo2-dev
	cp -a $(BUILD_STAGE)/cairo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(cairo|*.2.dylib) $(BUILD_DIST)/libcairo2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/cairo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcairo2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# cairo.mk Prep cairo-perf-utils
	#cp -a $(BUILD_STAGE)/cairo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cairo-trace $(BUILD_DIST)/cairo-perf-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

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
