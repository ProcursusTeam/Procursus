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

ifneq ($(wildcard $(BUILD_WORK)/fontconfig/.build_complete),)
fontconfig:
	@echo "Using previously built fontconfig."
else
fontconfig: fontconfig-setup gettext freetype uuid expat
	cd $(BUILD_WORK)/fontconfig && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--with-add-fonts="/System/Library/Fonts,~/Library/UserFonts" \
		FREETYPE_CFLAGS="-I$(BUILD_BASE)/usr/include/freetype2 -I$(BUILD_BASE)/usr/include/libpng16"
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
	mkdir -p $(BUILD_DIST)/fontconfig{,-config}/usr/share/man \
		$(BUILD_DIST)/libfontconfig{1,-dev}/usr/lib
	
	# fontconfig.mk Prep fontconfig
	cp -a $(BUILD_STAGE)/fontconfig/usr/bin $(BUILD_DIST)/fontconfig/usr
	cp -a $(BUILD_STAGE)/fontconfig/usr/share/man/man1 $(BUILD_DIST)/fontconfig/usr/share/man
	
	# fontconfig.mk Prep fontconfig-config
	cp -a $(BUILD_STAGE)/fontconfig/usr/share/{fontconfig,xml} $(BUILD_DIST)/fontconfig-config/usr/share
	cp -a $(BUILD_STAGE)/fontconfig/etc $(BUILD_DIST)/fontconfig-config/
	cp -a $(BUILD_STAGE)/fontconfig/usr/share/man/man5 $(BUILD_DIST)/fontconfig-config/usr/share/man
	
	# fontconfig.mk Prep libfontconfig1
	cp -a $(BUILD_STAGE)/fontconfig/usr/lib/libfontconfig.1.dylib $(BUILD_DIST)/libfontconfig1/usr/lib
	
	# fontconfig.mk Prep libfontconfig-dev
	cp -a $(BUILD_STAGE)/fontconfig/usr/lib/{libfontconfig.dylib,pkgconfig} $(BUILD_DIST)/libfontconfig-dev/usr/lib
	cp -a $(BUILD_STAGE)/fontconfig/usr/include $(BUILD_DIST)/libfontconfig-dev/usr/
	
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
