ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += cairo
CAIRO_VERSION := 1.16.0
DEB_CAIRO_V   ?= $(CAIRO_VERSION)-3

cairo-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://cairographics.org/releases/cairo-$(CAIRO_VERSION).tar.xz
	$(call EXTRACT_TAR,cairo-$(CAIRO_VERSION).tar.xz,cairo-$(CAIRO_VERSION),cairo)
	$(call DO_PATCH,cairo,cairo,-p1)

ifneq ($(wildcard $(BUILD_WORK)/cairo/.build_complete),)
cairo:
	@echo "Using previously built cairo."
else
cairo: cairo-setup freetype gettext fontconfig glib2.0 libpng16 liblzo2 libpixman libxcb libxrender libx11 libxext
	cd $(BUILD_WORK)/cairo && NOCONFIGURE=1 ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-pdf \
		--enable-ps \
		--enable-png \
		--enable-tee \
		--enable-pref-utils \
		--enable-svg \
		--enable-xcb \
		--enable-xlib \
		--enable-gobject \
		--enable-xlib-xrender \
		--enable-xlib-xcb \
		--enable-xml \
		--enable-quartz \
		--enable-quartz-text \
		--enable-quartz-image \
		ac_cv_func_FT_Done_MM_Var=yes \
		ac_cv_func_FT_Get_Var_Design_Coordinates=yes \
		ac_cv_func_FT_Get_X11_Font_Format=yes \
		ac_cv_func_FT_GlyphSlot_Embolden=yes \
		ac_cv_func_FT_GlyphSlot_Oblique=yes \
		ac_cv_func_FT_Library_SetLcdFilter=yes \
		ac_cv_func_FT_Load_Sfnt_Table=yes \
		ac_cv_func_FcFini=yes \
		ac_cv_func_FcInit=yes \
		ac_cv_func_XRenderCreateConicalGradient=yes \
		ac_cv_func_XRenderCreateLinearGradient=yes \
		ac_cv_func_XRenderCreateRadialGradient=yes \
		ac_cv_func_XRenderCreateSolidFill=yes \
		ac_cv_header_X11_extensions_XShm_h=yes \
		ac_cv_header_X11_extensions_shmproto_h=yes \
		ac_cv_header_X11_extensions_shmstr_h=yes \
		ac_cv_header_lzo_lzo2a_h=yes \
		ac_cv_header_memory_h=yes \
		ac_cv_header_stdc=yes \
		lt_cv_prog_compiler_c_o_CXX=yes \
		lt_cv_prog_compiler_pic_CXX='-fno-common -DPIC' \
		lt_cv_prog_compiler_pic_works_CXX=yes \
		ac_cv_have_x='have_x=yes       ac_x_includes='\'''\''  ac_x_libraries='\'''\'''
	+$(MAKE) -C $(BUILD_WORK)/cairo \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/glib-2.0/include"
	+$(MAKE) -C $(BUILD_WORK)/cairo install \
		DESTDIR=$(BUILD_STAGE)/cairo
	$(call AFTER_BUILD,copy)
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
