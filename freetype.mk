ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += freetype
FREETYPE_VERSION := 2.10.4
DEB_FREETYPE_V   ?= $(FREETYPE_VERSION)

freetype-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.savannah.gnu.org/releases/freetype/freetype-$(FREETYPE_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,freetype-$(FREETYPE_VERSION).tar.xz)
	$(call EXTRACT_TAR,freetype-$(FREETYPE_VERSION).tar.xz,freetype-$(FREETYPE_VERSION),freetype)

ifneq ($(wildcard $(BUILD_WORK)/freetype/.build_complete),)
freetype:
	@echo "Using previously built freetype."
else
freetype: freetype-setup brotli libpng16
	cd $(BUILD_WORK)/freetype && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-harfbuzz \
		CC_BUILD="$(CC_FOR_BUILD)"
	+$(MAKE) -C $(BUILD_WORK)/freetype
	+$(MAKE) -C $(BUILD_WORK)/freetype install \
		DESTDIR=$(BUILD_STAGE)/freetype
	+$(MAKE) -C $(BUILD_WORK)/freetype install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/freetype/.build_complete
endif

freetype-package: freetype-stage
	# freetype.mk Package Structure
	rm -rf $(BUILD_DIST)/libfreetype{6,-dev}
	mkdir -p $(BUILD_DIST)/libfreetype{6,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# freetype.mk Prep freetype6
	cp -a $(BUILD_STAGE)/freetype/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfreetype.6.dylib $(BUILD_DIST)/libfreetype6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# freetype.mk Prep freetype6-dev
	cp -a $(BUILD_STAGE)/freetype/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libfreetype.{a,dylib},pkgconfig} $(BUILD_DIST)/libfreetype-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/freetype/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libfreetype-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# freetype.mk Sign
	$(call SIGN,libfreetype6,general.xml)

	# freetype.mk Make .debs
	$(call PACK,libfreetype6,DEB_FREETYPE_V)
	$(call PACK,libfreetype-dev,DEB_FREETYPE_V)

	# freetype.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfreetype{6,-dev}

.PHONY: freetype freetype-package
