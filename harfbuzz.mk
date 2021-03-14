ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += harfbuzz
HARFBUZZ_VERSION := 2.7.4
DEB_HARFBUZZ_V   ?= $(HARFBUZZ_VERSION)-1

harfbuzz-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/harfbuzz-$(HARFBUZZ_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/harfbuzz-$(HARFBUZZ_VERSION).tar.gz \
			https://github.com/harfbuzz/harfbuzz/archive/$(HARFBUZZ_VERSION).tar.gz
	$(call EXTRACT_TAR,harfbuzz-$(HARFBUZZ_VERSION).tar.gz,harfbuzz-$(HARFBUZZ_VERSION),harfbuzz)

ifneq ($(wildcard $(BUILD_WORK)/harfbuzz/.build_complete),)
harfbuzz:
	@echo "Using previously built harfbuzz."
else
harfbuzz: harfbuzz-setup cairo freetype glib2.0 graphite2 icu4c fontconfig
	cd $(BUILD_WORK)/harfbuzz && ./autogen.sh \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--with-cairo \
		--with-freetype \
		--with-fontconfig \
		--with-glib \
		--with-gobject \
		--with-icu \
		--with-graphite2 \
		--with-coretext \
		FONTCONFIG_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/freetype2 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/libpng16" \
		FREETYPE_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/freetype2 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/libpng16" \
		GOBJECT_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/glib-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/glib-2.0/include" \
		GLIB_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/glib-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/glib-2.0/include -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/glib-2.0/include" \
		CAIRO_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/cairo -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/glib-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/glib-2.0/include -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/pixman-1 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/freetype2 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/libpng16" \
		CAIRO_FT_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/cairo -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/glib-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/glib-2.0/include -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/pixman-1 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/freetype2 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/libpng16"
	+$(MAKE) -C $(BUILD_WORK)/harfbuzz
	+$(MAKE) -C $(BUILD_WORK)/harfbuzz install \
		DESTDIR="$(BUILD_STAGE)/harfbuzz"
	+$(MAKE) -C $(BUILD_WORK)/harfbuzz install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/harfbuzz/.build_complete
endif

harfbuzz-package: harfbuzz-stage
	# harfbuzz.mk Package Structure
	rm -rf $(BUILD_DIST)/libharfbuzz-{bin,dev,icu0,gobject0,subset0} \
		$(BUILD_DIST)/libharfbuzz0b
	mkdir -p $(BUILD_DIST)/libharfbuzz-bin/$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		$(BUILD_DIST)/libharfbuzz-{dev,icu0,gobject0,subset0}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
		$(BUILD_DIST)/libharfbuzz0b/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# harfbuzz.mk Prep libharfbuzz0b
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libharfbuzz.0.dylib $(BUILD_DIST)/libharfbuzz0b/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# harfbuzz.mk Prep libharfbuzz-icu0
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libharfbuzz-icu.0.dylib $(BUILD_DIST)/libharfbuzz-icu0/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# harfbuzz.mk Prep libharfbuzz-gobject0
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libharfbuzz-gobject.0.dylib $(BUILD_DIST)/libharfbuzz-gobject0/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# harfbuzz.mk Prep libharfbuzz-subset0
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libharfbuzz-subset.0.dylib $(BUILD_DIST)/libharfbuzz-subset0/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# harfbuzz.mk Prep libharfbuzz-dev
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/libharfbuzz-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/!(*.0.*) $(BUILD_DIST)/libharfbuzz-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# harfbuzz.mk Prep libharfbuzz-bin
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin $(BUILD_DIST)/libharfbuzz-bin/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	
	# harfbuzz.mk Sign
	$(call SIGN,libharfbuzz0b,general.xml)
	$(call SIGN,libharfbuzz-icu0,general.xml)
	$(call SIGN,libharfbuzz-gobject0,general.xml)
	$(call SIGN,libharfbuzz-subset0,general.xml)
	$(call SIGN,libharfbuzz-bin,general.xml)
	
	# harfbuzz.mk Make .debs
	$(call PACK,libharfbuzz0b,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-icu0,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-gobject0,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-subset0,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-bin,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-dev,DEB_HARFBUZZ_V)
	
	# harfbuzz.mk Build cleanup
	rm -rf $(BUILD_DIST)/libharfbuzz-{bin,dev,icu0,gobject0,subset0} \
		$(BUILD_DIST)/libharfbuzz0b

.PHONY: harfbuzz harfbuzz-package
