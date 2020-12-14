ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += ffmpeg
FFMPEG_VERSION := 4.3.1
DEB_FFMPEG_V   ?= $(FFMPEG_VERSION)

ffmpeg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ffmpeg.org/releases/ffmpeg-$(FFMPEG_VERSION).tar.xz
	$(call EXTRACT_TAR,ffmpeg-$(FFMPEG_VERSION).tar.xz,ffmpeg-$(FFMPEG_VERSION),ffmpeg)
	$(call DO_PATCH,ffmpeg,ffmpeg,-p1)

ifneq ($(wildcard $(BUILD_WORK)/ffmpeg/.build_complete),)
ffmpeg:
	@echo "Using previously built ffmpeg."
else
ffmpeg: ffmpeg-setup aom dav1d fontconfig freetype frei0r gnutls lame libass libsoxr libvidstab libvorbis libvpx libopencore-amr openjpeg libopus rav1e rtmpdump rubberband sdl2 libsnappy libspeex libsrt tesseract libtheora libwebp x264 x265 libxvidcore xz
	cd $(BUILD_WORK)/ffmpeg && ./configure \
		--prefix=/usr \
		--enable-shared \
		--enable-pthreads \
		--enable-version3 \
		--enable-avresample \
		--enable-cross-compile \
		--cc="$(CC)" \
		--arch=arm64 \
		--pkg-config-flags="--define-prefix" \
		--host-cflags="$(CFLAGS)" \
		--host-ldflags="$(LDFLAGS)" \
		--enable-ffplay \
		--enable-gnutls \
		--enable-gpl \
		--enable-libaom \
		--enable-libdav1d \
		--enable-libmp3lame \
		--enable-libopus \
		--enable-librav1e \
		--enable-librubberband \
		--enable-libsnappy \
		--enable-libsrt \
		--enable-libtesseract \
		--enable-libtheora \
		--enable-libvidstab \
		--enable-libvorbis \
		--enable-libvpx \
		--enable-libwebp \
		--enable-libx264 \
		--enable-libx265 \
		--enable-libxml2 \
		--enable-libxvid \
		--enable-lzma \
		--enable-libfontconfig \
		--enable-libfreetype \
		--enable-frei0r \
		--enable-libass \
		--enable-libopencore-amrnb \
		--enable-libopencore-amrwb \
		--enable-libopenjpeg \
		--enable-librtmp \
		--enable-libspeex \
		--enable-libsoxr \
		--enable-videotoolbox \
		--disable-libbluray \
		--disable-libjack \
		--disable-indev=jack \
		--disable-doc
		# I want manpages but the cross compiler is what compiles the manpage compiler. Have a look at this another time.
	$(SED) -i 's/-lSDL2/-lSDL2 -lSDL2main/g' $(BUILD_WORK)/ffmpeg/ffbuild/config.mak
	+$(MAKE) -C $(BUILD_WORK)/ffmpeg
	+$(MAKE) -C $(BUILD_WORK)/ffmpeg install \
		DESTDIR=$(BUILD_STAGE)/ffmpeg
	+$(MAKE) -C $(BUILD_WORK)/ffmpeg alltools
	cp -a $(BUILD_WORK)/ffmpeg/tools/* $(BUILD_STAGE)/ffmpeg/usr/bin
	touch $(BUILD_WORK)/ffmpeg/.build_complete
endif

ffmpeg-package: ffmpeg-stage
	# ffmpeg.mk Package Structure
	rm -rf $(BUILD_DIST)/ffmpeg \
		$(BUILD_DIST)/libavcodec{58,-dev} \
		$(BUILD_DIST)/libavdevice{58,-dev} \
		$(BUILD_DIST)/libavfilter{7,-dev} \
		$(BUILD_DIST)/libavformat{58,-dev} \
		$(BUILD_DIST)/libavresample{4,-dev} \
		$(BUILD_DIST)/libavutil{56,-dev} \
		$(BUILD_DIST)/libpostproc{55,-dev} \
		$(BUILD_DIST)/libswresample{3,-dev} \
		$(BUILD_DIST)/libswscale{5,-dev}
	mkdir -p $(BUILD_DIST)/ffmpeg/usr/bin \
		$(BUILD_DIST)/libavcodec58/usr/lib \
		$(BUILD_DIST)/libavcodec-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libavdevice58/usr/lib \
		$(BUILD_DIST)/libavdevice-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libavfilter7/usr/lib \
		$(BUILD_DIST)/libavfilter-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libavformat58/usr/lib \
		$(BUILD_DIST)/libavformat-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libavresample4/usr/lib \
		$(BUILD_DIST)/libavresample-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libavutil56/usr/lib \
		$(BUILD_DIST)/libavutil-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libpostproc55/usr/lib \
		$(BUILD_DIST)/libpostproc-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libswresample3/usr/lib \
		$(BUILD_DIST)/libswresample-dev/usr/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libswscale5/usr/lib \
		$(BUILD_DIST)/libswscale-dev/usr/{lib/pkgconfig,include}
	
	# ffmpeg.mk Prep ffmpeg
	cp -a $(BUILD_STAGE)/ffmpeg/usr/bin/{ffmpeg,ffplay,ffprobe,qt-faststart} $(BUILD_DIST)/ffmpeg/usr/bin
	cp -a $(BUILD_STAGE)/ffmpeg/usr/share $(BUILD_DIST)/ffmpeg/usr
	
	# ffmpeg.mk Prep libavcodec58
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavcodec.58{,.91.100}.dylib $(BUILD_DIST)/libavcodec58/usr/lib
	
	# ffmpeg.mk Prep libavcodec-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavcodec.{dylib,a} $(BUILD_DIST)/libavcodec-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libavcodec $(BUILD_DIST)/libavcodec-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libavcodec.pc $(BUILD_DIST)/libavcodec-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libavdevice58
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavdevice.58{,.10.100}.dylib $(BUILD_DIST)/libavdevice58/usr/lib
	
	# ffmpeg.mk Prep libavdevice-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavdevice.{dylib,a} $(BUILD_DIST)/libavdevice-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libavdevice $(BUILD_DIST)/libavdevice-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libavdevice.pc $(BUILD_DIST)/libavdevice-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libavfilter7
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavfilter.7{,.85.100}.dylib $(BUILD_DIST)/libavfilter7/usr/lib
	
	# ffmpeg.mk Prep libavfilter-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavfilter.{dylib,a} $(BUILD_DIST)/libavfilter-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libavfilter $(BUILD_DIST)/libavfilter-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libavfilter.pc $(BUILD_DIST)/libavfilter-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libavformat58
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavformat.58{,.45.100}.dylib $(BUILD_DIST)/libavformat58/usr/lib
	
	# ffmpeg.mk Prep libavformat-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavformat.{dylib,a} $(BUILD_DIST)/libavformat-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libavformat $(BUILD_DIST)/libavformat-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libavformat.pc $(BUILD_DIST)/libavformat-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libavresample4
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavresample.4{,.0.0}.dylib $(BUILD_DIST)/libavresample4/usr/lib
	
	# ffmpeg.mk Prep libavresample-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavresample.{dylib,a} $(BUILD_DIST)/libavresample-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libavresample $(BUILD_DIST)/libavresample-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libavresample.pc $(BUILD_DIST)/libavresample-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libavutil56
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavutil.56{,.51.100}.dylib $(BUILD_DIST)/libavutil56/usr/lib
	
	# ffmpeg.mk Prep libavutil-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libavutil.{dylib,a} $(BUILD_DIST)/libavutil-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libavutil $(BUILD_DIST)/libavutil-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libavutil.pc $(BUILD_DIST)/libavutil-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libpostproc55
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libpostproc.55{,.7.100}.dylib $(BUILD_DIST)/libpostproc55/usr/lib
	
	# ffmpeg.mk Prep libpostproc-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libpostproc.{dylib,a} $(BUILD_DIST)/libpostproc-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libpostproc $(BUILD_DIST)/libpostproc-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libpostproc.pc $(BUILD_DIST)/libpostproc-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libswresample3
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libswresample.3{,.7.100}.dylib $(BUILD_DIST)/libswresample3/usr/lib
	
	# ffmpeg.mk Prep libswresample-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libswresample.{dylib,a} $(BUILD_DIST)/libswresample-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libswresample $(BUILD_DIST)/libswresample-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libswresample.pc $(BUILD_DIST)/libswresample-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Prep libswscale5
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libswscale.5{,.7.100}.dylib $(BUILD_DIST)/libswscale5/usr/lib
	
	# ffmpeg.mk Prep libswscale-dev
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/libswscale.{dylib,a} $(BUILD_DIST)/libswscale-dev/usr/lib
	cp -a $(BUILD_STAGE)/ffmpeg/usr/include/libswscale $(BUILD_DIST)/libswscale-dev/usr/include
	cp -a $(BUILD_STAGE)/ffmpeg/usr/lib/pkgconfig/libswscale.pc $(BUILD_DIST)/libswscale-dev/usr/lib/pkgconfig
	
	# ffmpeg.mk Sign
	$(call SIGN,ffmpeg,general.xml)
	$(call SIGN,libavcodec58,general.xml)
	$(call SIGN,libavdevice58,general.xml)
	$(call SIGN,libavfilter7,general.xml)
	$(call SIGN,libavformat58,general.xml)
	$(call SIGN,libavresample4,general.xml)
	$(call SIGN,libavutil56,general.xml)
	$(call SIGN,libpostproc55,general.xml)
	$(call SIGN,libswresample3,general.xml)
	$(call SIGN,libswscale5,general.xml)
	
	# ffmpeg.mk Make .debs
	$(call PACK,ffmpeg,DEB_FFMPEG_V)
	$(call PACK,libavcodec58,DEB_FFMPEG_V)
	$(call PACK,libavcodec-dev,DEB_FFMPEG_V)
	$(call PACK,libavdevice58,DEB_FFMPEG_V)
	$(call PACK,libavdevice-dev,DEB_FFMPEG_V)
	$(call PACK,libavfilter7,DEB_FFMPEG_V)
	$(call PACK,libavfilter-dev,DEB_FFMPEG_V)
	$(call PACK,libavformat58,DEB_FFMPEG_V)
	$(call PACK,libavformat-dev,DEB_FFMPEG_V)
	$(call PACK,libavresample4,DEB_FFMPEG_V)
	$(call PACK,libavresample-dev,DEB_FFMPEG_V)
	$(call PACK,libavutil56,DEB_FFMPEG_V)
	$(call PACK,libavutil-dev,DEB_FFMPEG_V)
	$(call PACK,libpostproc55,DEB_FFMPEG_V)
	$(call PACK,libpostproc-dev,DEB_FFMPEG_V)
	$(call PACK,libswresample3,DEB_FFMPEG_V)
	$(call PACK,libswresample-dev,DEB_FFMPEG_V)
	$(call PACK,libswscale5,DEB_FFMPEG_V)
	$(call PACK,libswscale-dev,DEB_FFMPEG_V)
	
	# ffmpeg.mk Build cleanup
	rm -rf $(BUILD_DIST)/ffmpeg \
		$(BUILD_DIST)/libavcodec{58,-dev} \
		$(BUILD_DIST)/libavdevice{58,-dev} \
		$(BUILD_DIST)/libavfilter{7,-dev} \
		$(BUILD_DIST)/libavformat{58,-dev} \
		$(BUILD_DIST)/libavresample{4,-dev} \
		$(BUILD_DIST)/libavutil{56,-dev} \
		$(BUILD_DIST)/libpostproc{55,-dev} \
		$(BUILD_DIST)/libswresample{3,-dev} \
		$(BUILD_DIST)/libswscale{5,-dev}

.PHONY: ffmpeg ffmpeg-package
