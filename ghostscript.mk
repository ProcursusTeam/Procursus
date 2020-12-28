ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += ghostscript
GHOSTSCRIPT_VERSION := 9.53.3
DEB_GHOSTSCRIPT_V   ?= $(GHOSTSCRIPT_VERSION)

ghostscript-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs9533/ghostpdl-$(GHOSTSCRIPT_VERSION).tar.gz
	$(call EXTRACT_TAR,ghostpdl-$(GHOSTSCRIPT_VERSION).tar.gz,ghostpdl-$(GHOSTSCRIPT_VERSION),ghostscript)
	$(call DO_PATCH,ghostscript,ghostscript,-p1)
	rm -rf $(BUILD_WORK)/ghostscript/{tiff,jpeg,openjpeg,freetype,expat,libpng,zlib,lcms2mt,jpegxr,jbig2dec}

ifneq ($(wildcard $(BUILD_WORK)/ghostscript/.build_complete),)
ghostscript:
	@echo "Using previously built ghostscript."
else
ghostscript: ghostscript-setup libtiff libpng16 jbig2dec libjpeg-turbo lcms2 libpaper fontconfig freetype openjpeg expat
	cd $(BUILD_WORK)/ghostscript && unset CPP && PKGCONFIG="pkg-config --define-prefix" ./autogen.sh -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-pcl \
		--with-system-libtiff \
		--enable-dynamic \
		--disable-cups \
		--disable-compile-inits \
		--disable-gtk \
		--without-x
	+$(MAKE) -C $(BUILD_WORK)/ghostscript so
	+$(MAKE) -C $(BUILD_WORK)/ghostscript soinstall \
		DESTDIR="$(BUILD_STAGE)/ghostscript"
	+$(MAKE) -C $(BUILD_WORK)/ghostscript soinstall \
		DESTDIR="$(BUILD_BASE)"
	mv $(BUILD_STAGE)/ghostscript/usr/bin/gsc $(BUILD_STAGE)/ghostscript/usr/bin/gs
	touch $(BUILD_WORK)/ghostscript/.build_complete
endif

ghostscript-package: ghostscript-stage
	# ghostscript.mk Package Structure
	rm -rf $(BUILD_DIST)/ghostscript \
		$(BUILD_DIST)/libgs{9{,-common},-dev}
	mkdir -p $(BUILD_DIST)/ghostscript/usr/share \
		$(BUILD_DIST)/libgs-dev/usr/lib \
		$(BUILD_DIST)/libgs9/usr/lib \
		$(BUILD_DIST)/libgs9-common/usr/share
	
	# ghostscript.mk Prep ghostscript
	cp -a $(BUILD_STAGE)/ghostscript/usr/bin $(BUILD_DIST)/ghostscript/usr
	cp -a $(BUILD_STAGE)/ghostscript/usr/share/man $(BUILD_DIST)/ghostscript/usr/share
	
	# ghostscript.mk Prep libgs9
	cp -a $(BUILD_STAGE)/ghostscript/usr/lib/libgs.9*.dylib $(BUILD_DIST)/libgs9/usr/lib

	# ghostscript.mk Prep libgs9-common
	cp -a $(BUILD_STAGE)/ghostscript/usr/share/ghostscript $(BUILD_DIST)/libgs9-common/usr/share
	
	# ghostscript.mk Prep libgs-dev
	cp -a $(BUILD_STAGE)/ghostscript/usr/lib/libgs.dylib $(BUILD_DIST)/libgs-dev/usr/lib
	cp -a $(BUILD_STAGE)/ghostscript/usr/include $(BUILD_DIST)/libgs-dev/usr
	
	# ghostscript.mk Sign
	$(call SIGN,ghostscript,general.xml)
	$(call SIGN,libgs9,general.xml)
	$(call SIGN,libgs-dev,general.xml)
	
	# ghostscript.mk Make .debs
	$(call PACK,ghostscript,DEB_GHOSTSCRIPT_V)
	$(call PACK,libgs9,DEB_GHOSTSCRIPT_V)
	$(call PACK,libgs9-common,DEB_GHOSTSCRIPT_V)
	$(call PACK,libgs-dev,DEB_GHOSTSCRIPT_V)
	
	# ghostscript.mk Build cleanup
	rm -rf $(BUILD_DIST)/ghostscript \
		$(BUILD_DIST)/libgs{9{,-common},-dev}

.PHONY: ghostscript ghostscript-package
