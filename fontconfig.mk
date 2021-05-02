ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += fontconfig
FONTCONFIG_VERSION := 2.13.1
DEB_FONTCONFIG_V   ?= $(FONTCONFIG_VERSION)-1

fontconfig-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.freedesktop.org/software/fontconfig/release/fontconfig-$(FONTCONFIG_VERSION).tar.bz2
	$(call EXTRACT_TAR,fontconfig-$(FONTCONFIG_VERSION).tar.bz2,fontconfig-$(FONTCONFIG_VERSION),fontconfig)
	$(call DO_PATCH,fontconfig,fontconfig,-p1) # Remove this patch after next release.
	sed -i 's/use_jsonc=yes/use_jsonc=no/' $(BUILD_WORK)/fontconfig/configure

ifneq ($(wildcard $(BUILD_WORK)/fontconfig/.build_complete),)
fontconfig:
	@echo "Using previously built fontconfig."
else
fontconfig: fontconfig-setup gettext freetype uuid expat
	cd $(BUILD_WORK)/fontconfig && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-add-fonts="/System/Library/Fonts,~/Library/UserFonts" \
		FREETYPE_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/freetype2 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libpng16" \
		FREETYPE_LIBS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lfreetype"
	+$(MAKE) -C $(BUILD_WORK)/fontconfig
	+$(MAKE) -C $(BUILD_WORK)/fontconfig install \
		DESTDIR=$(BUILD_STAGE)/fontconfig
	+$(MAKE) -C $(BUILD_WORK)/fontconfig install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/fontconfig/.build_complete
endif

fontconfig-package: fontconfig-stage
	# fontconfig.mk Package Structure
	rm -rf $(BUILD_DIST)/fontconfig{,-config} \
		$(BUILD_DIST)/libfontconfig{1,-dev}
	mkdir -p $(BUILD_DIST)/fontconfig{,-config}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libfontconfig{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# fontconfig.mk Prep fontconfig
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# fontconfig.mk Prep fontconfig-config
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{fontconfig,xml} $(BUILD_DIST)/fontconfig-config/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)/etc $(BUILD_DIST)/fontconfig-config/
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5 $(BUILD_DIST)/fontconfig-config/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# fontconfig.mk Prep libfontconfig1
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfontconfig.1.dylib $(BUILD_DIST)/libfontconfig1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# fontconfig.mk Prep libfontconfig-dev
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libfontconfig.dylib,pkgconfig} $(BUILD_DIST)/libfontconfig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fontconfig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libfontconfig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# fontconfig.mk Sign
	$(call SIGN,fontconfig,general.xml)
	$(call SIGN,libfontconfig1,general.xml)

	# fontconfig.mk Make .debs
	$(call PACK,fontconfig,DEB_FONTCONFIG_V)
	$(call PACK,fontconfig-config,DEB_FONTCONFIG_V)
	$(call PACK,libfontconfig1,DEB_FONTCONFIG_V)
	$(call PACK,libfontconfig-dev,DEB_FONTCONFIG_V)

	# fontconfig.mk Build cleanup
	rm -rf $(BUILD_DIST)/fontconfig{,-config} \
		$(BUILD_DIST)/libfontconfig{1,-dev}

.PHONY: fontconfig fontconfig-package
