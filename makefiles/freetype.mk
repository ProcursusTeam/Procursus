ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += freetype
FREETYPE_VERSION := 2.13.1
DEB_FREETYPE_V   ?= $(FREETYPE_VERSION)

freetype-setup: setup
	$(call GIT_CLONE_COMMIT,https://github.com/freetype/freetype,VER-$(shell echo ${FREETYPE_VERSION} | tr '.' '-' ),freetype)

ifneq ($(wildcard $(BUILD_WORK)/freetype/.build_complete),)
freetype:
	@echo "Using previously built freetype."
else
freetype: freetype-setup brotli libpng16
	cd $(BUILD_WORK)/freetype && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-harfbuzz \
		CC_BUILD="$(CC_FOR_BUILD)"
	+$(MAKE) -C $(BUILD_WORK)/freetype
	+$(MAKE) -C $(BUILD_WORK)/freetype install \
		DESTDIR=$(BUILD_STAGE)/freetype
	$(call AFTER_BUILD,copy)
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
