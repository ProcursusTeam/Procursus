ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libxfont2
LIBXFONT2_VERSION := 2.0.4
DEB_LIBXFONT2_V   ?= $(LIBXFONT2_VERSION)

libxfont2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXfont2-$(LIBXFONT2_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXfont2-$(LIBXFONT2_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXfont2-$(LIBXFONT2_VERSION).tar.gz,libXfont2-$(LIBXFONT2_VERSION),libxfont2)

ifneq ($(wildcard $(BUILD_WORK)/libxfont2/.build_complete),)
libxfont2:
	@echo "Using previously built libxfont2."
else
libxfont2: libxfont2-setup xorgproto xtrans util-macros freetype libfontenc
	cd $(BUILD_WORK)/libxfont2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-silent-rules \
		--disable-dependency-tracking \
		--enable-devel-docs=no \
		--with-bzip2 \
		FREETYPE_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/freetype2" \
		FREETYPE_LIBS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lfreetype"
	+$(MAKE) -C $(BUILD_WORK)/libxfont2
	+$(MAKE) -C $(BUILD_WORK)/libxfont2 install \
		DESTDIR=$(BUILD_STAGE)/libxfont2
	+$(MAKE) -C $(BUILD_WORK)/libxfont2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxfont2/.build_complete
endif

libxfont2-package: libxfont2-stage
	# libxfont2.mk Package Structure
	rm -rf $(BUILD_DIST)/libxfont{2,-dev}
	mkdir -p $(BUILD_DIST)/libxfont{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxfont2.mk Prep libxfont2
	cp -a $(BUILD_STAGE)/libxfont2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXfont2.2.dylib $(BUILD_DIST)/libxfont2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxfont2.mk Prep libxfont-dev
	cp -a $(BUILD_STAGE)/libxfont2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libXfont2.{a,dylib},pkgconfig} $(BUILD_DIST)/libxfont-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxfont2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxfont-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxfont2.mk Sign
	$(call SIGN,libxfont2,general.xml)

	# libxfont2.mk Make .debs
	$(call PACK,libxfont2,DEB_LIBXFONT2_V)
	$(call PACK,libxfont-dev,DEB_LIBXFONT2_V)

	# libxfont2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxfont{2,-dev}

.PHONY: libxfont2 libxfont2-package
