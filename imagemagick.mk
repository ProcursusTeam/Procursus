ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += imagemagick
IMAGEMAGICK_VERSION := 7.0.10-53
DEB_IMAGEMAGICK_V   ?= $(shell echo $(IMAGEMAGICK_VERSION) | sed s/-/./)

###
#
# Packaging should be re-looked at next update, specifically the versioning specific parts. (7, 7.0.10)
#
###

imagemagick-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.imagemagick.org/download/releases/ImageMagick-$(IMAGEMAGICK_VERSION).tar.xz
	$(call EXTRACT_TAR,ImageMagick-$(IMAGEMAGICK_VERSION).tar.xz,ImageMagick-$(IMAGEMAGICK_VERSION),imagemagick)

ifneq ($(wildcard $(BUILD_WORK)/imagemagick/.build_complete),)
imagemagick:
	@echo "Using previously built imagemagick."
else
imagemagick: imagemagick-setup openexr fontconfig freetype glib2.0 ghostscript libheif gettext jbigkit libjemalloc lcms2 liblqr xz openmp openjpeg libpng16 libtiff libwebp libzip
	cd $(BUILD_WORK)/imagemagick && PKG_CONFIG="pkg-config --define-prefix" ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--enable-osx-universal-binary=no \
		--prefix=/usr \
		--sysconfdir=/etc \
		--disable-dependency-tracking \
		--disable-silent-rules \
		--disable-opencl \
		--enable-shared \
		--enable-static \
		--with-jemalloc \
		--with-freetype=yes \
		--with-modules \
		--with-openjp2 \
		--with-openexr \
		--with-webp=yes \
		--with-heic=yes \
		--with-gslib \
		--with-gs-font-dir=/usr/share/ghostscript/fonts \
		--with-lqr \
		--without-fftw \
		--without-pango \
		--without-wmf \
		--enable-openmp \
		ac_cv_prog_c_openmp=-Xpreprocessor\ -fopenmp \
		ac_cv_prog_cxx_openmp=-Xpreprocessor\ -fopenmp \
		LDFLAGS="$(LDFLAGS) -lomp -lz"
	$(SED) -i 's/|-fopenmp//' $(BUILD_WORK)/imagemagick/libtool
	+$(MAKE) -C $(BUILD_WORK)/imagemagick
	+$(MAKE) -C $(BUILD_WORK)/imagemagick install \
		DESTDIR=$(BUILD_STAGE)/imagemagick
	+$(MAKE) -C $(BUILD_WORK)/imagemagick install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/imagemagick/.build_complete
endif

imagemagick-package: imagemagick-stage
	# imagemagick.mk Package Structure
	rm -rf $(BUILD_DIST)/*magick*7*/ $(BUILD_DIST)/imagemagick
	mkdir -p $(BUILD_DIST)/imagemagick/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/imagemagick-7-common/usr/share \
		$(BUILD_DIST)/libmagick++-7.q16hdri-4/usr/lib \
		$(BUILD_DIST)/libmagick++-7.q16hdri-dev/usr/lib/{pkgconfig,ImageMagick-7.0.10/bin} \
		$(BUILD_DIST)/libmagick++-7-headers/usr/include/ImageMagick-7 \
		$(BUILD_DIST)/libmagickcore-7.q16hdri-8/usr/lib \
		$(BUILD_DIST)/libmagickcore-7.q16hdri-dev/usr/lib/{pkgconfig,ImageMagick-7.0.10/bin} \
		$(BUILD_DIST)/libmagickcore-7-headers/usr/include/ImageMagick-7 \
		$(BUILD_DIST)/libmagickwand-7.q16hdri-8/usr/lib \
		$(BUILD_DIST)/libmagickwand-7.q16hdri-dev/usr/lib/{pkgconfig,ImageMagick-7.0.10/bin} \
		$(BUILD_DIST)/libmagickwand-7-headers/usr/include/ImageMagick-7
	
	# imagemagick.mk Prep imagemagick
	cp -a $(BUILD_STAGE)/imagemagick/usr/bin/!(Magick++-config|MagickCore-config|MagickWand-config) $(BUILD_DIST)/imagemagick/usr/bin
	cp -a $(BUILD_STAGE)/imagemagick/usr/share/man/man1/!(Magick++-config.1|MagickCore-config.1|MagickWand-config.1) $(BUILD_DIST)/imagemagick/usr/share/man/man1
	
	# imagemagick.mk Prep imagemagick-7-common
	cp -a $(BUILD_STAGE)/imagemagick/etc $(BUILD_DIST)/imagemagick-7-common
	cp -a $(BUILD_STAGE)/imagemagick/usr/share/ImageMagick-7 $(BUILD_DIST)/imagemagick-7-common/usr/share

	# imagemagick.mk Prep libmagick++-7.q16hdri-4
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/libMagick++-7.Q16HDRI.4.dylib $(BUILD_DIST)/libmagick++-7.q16hdri-4/usr/lib

	# imagemagick.mk Prep libmagick++-7.q16hdri-dev
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/libMagick++-7.Q16HDRI.{a,dylib} $(BUILD_DIST)/libmagick++-7.q16hdri-dev/usr/lib
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/pkgconfig/Magick++-7.Q16HDRI.pc $(BUILD_DIST)/libmagick++-7.q16hdri-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/imagemagick/usr/bin/Magick++-config $(BUILD_DIST)/libmagick++-7.q16hdri-dev/usr/lib/ImageMagick-7.0.10/bin

	# imagemagick.mk Prep libmagick++-7-headers
	cp -a $(BUILD_STAGE)/imagemagick/usr/include/ImageMagick-7/Magick++* $(BUILD_DIST)/libmagick++-7-headers/usr/include/ImageMagick-7

	# imagemagick.mk Prep libmagickcore-7.q16hdri-8
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/libMagickCore-7.Q16HDRI.8.dylib $(BUILD_DIST)/libmagickcore-7.q16hdri-8/usr/lib
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/ImageMagick-7.0.10 $(BUILD_DIST)/libmagickcore-7.q16hdri-8/usr/lib

	# imagemagick.mk Prep libmagickcore-7.q16hdri-dev
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/libMagickCore-7.Q16HDRI.{a,dylib} $(BUILD_DIST)/libmagickcore-7.q16hdri-dev/usr/lib
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/pkgconfig/{MagickCore,ImageMagick}-7.Q16HDRI.pc $(BUILD_DIST)/libmagickcore-7.q16hdri-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/imagemagick/usr/bin/MagickCore-config $(BUILD_DIST)/libmagickcore-7.q16hdri-dev/usr/lib/ImageMagick-7.0.10/bin

	# imagemagick.mk Prep libmagickcore-7-headers
	cp -a $(BUILD_STAGE)/imagemagick/usr/include/ImageMagick-7/MagickCore $(BUILD_DIST)/libmagickcore-7-headers/usr/include/ImageMagick-7

	# imagemagick.mk Prep libmagickwand-7.q16hdri-8
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/libMagickWand-7.Q16HDRI.8.dylib $(BUILD_DIST)/libmagickwand-7.q16hdri-8/usr/lib

	# imagemagick.mk Prep libmagickwand-7.q16hdri-dev
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/libMagickWand-7.Q16HDRI.{a,dylib} $(BUILD_DIST)/libmagickwand-7.q16hdri-dev/usr/lib
	cp -a $(BUILD_STAGE)/imagemagick/usr/lib/pkgconfig/MagickWand-7.Q16HDRI.pc $(BUILD_DIST)/libmagickwand-7.q16hdri-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/imagemagick/usr/bin/MagickWand-config $(BUILD_DIST)/libmagickwand-7.q16hdri-dev/usr/lib/ImageMagick-7.0.10/bin

	# imagemagick.mk Prep libmagickwand-7-headers
	cp -a $(BUILD_STAGE)/imagemagick/usr/include/ImageMagick-7/MagickWand $(BUILD_DIST)/libmagickwand-7-headers/usr/include/ImageMagick-7
	
	# imagemagick.mk Sign
	$(call SIGN,imagemagick,general.xml)
	$(call SIGN,libmagick++-7.q16hdri-4,general.xml)
	$(call SIGN,libmagickcore-7.q16hdri-8,general.xml)
	$(call SIGN,libmagickwand-7.q16hdri-8,general.xml)
	
	# imagemagick.mk Make .debs
	$(call PACK,imagemagick,DEB_IMAGEMAGICK_V)
	$(call PACK,imagemagick-7-common,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagick++-7.q16hdri-4,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagick++-7.q16hdri-dev,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagick++-7-headers,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagickcore-7.q16hdri-8,DEB_IMAGEMAGICK_V,,SettingFourthVar)
	$(call PACK,libmagickcore-7.q16hdri-dev,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagickcore-7-headers,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagickwand-7.q16hdri-8,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagickwand-7.q16hdri-dev,DEB_IMAGEMAGICK_V)
	$(call PACK,libmagickwand-7-headers,DEB_IMAGEMAGICK_V)
	
	# imagemagick.mk Build cleanup
	rm -rf $(BUILD_DIST)/*magick*7*/ $(BUILD_DIST)/imagemagick

.PHONY: imagemagick imagemagick-package
