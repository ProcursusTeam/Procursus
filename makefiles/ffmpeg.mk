ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += ffmpeg
FFMPEG_VERSION := 4.4
DEB_FFMPEG_V   ?= $(FFMPEG_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
FFMPEG_CONFIGURE_FLAGS := --disable-audiotoolbox
endif

ffmpeg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ffmpeg.org/releases/ffmpeg-$(FFMPEG_VERSION).tar.xz
	$(call EXTRACT_TAR,ffmpeg-$(FFMPEG_VERSION).tar.xz,ffmpeg-$(FFMPEG_VERSION),ffmpeg)

ifneq ($(wildcard $(BUILD_WORK)/ffmpeg/.build_complete),)
ffmpeg:
	@echo "Using previously built ffmpeg."
else
ffmpeg: ffmpeg-setup aom dav1d fontconfig freetype frei0r gnutls lame libass libsoxr libvidstab libvorbis libvpx libopencore-amr openjpeg libopus rav1e rtmpdump rubberband sdl2 libsnappy libspeex libsrt tesseract libtheora libwebp x264 x265 libxvidcore xz libzmq libxcb
	cd $(BUILD_WORK)/ffmpeg && ./configure \
		--cross-prefix="$(GNU_HOST_TRIPLE)-" \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--enable-shared \
		--enable-pthreads \
		--enable-version3 \
		--enable-cross-compile \
		--target-os=darwin \
		--arch=$(MEMO_ARCH) \
		--cc="$(CC)" \
		--cxx="$(CC)" \
		--nm="$(NM)" \
		--ar="$(AR)" \
		--ranlib="$(RANLIB)" \
		--strip="$(STRIP)" \
		--host-cc="$(CC_FOR_BUILD)" \
		--host-cflags="$(BUILD_CFLAGS)" \
		--host-ldflags="$(BUILD_LDFLAGS)" \
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
		--enable-libzmq \
		--disable-libbluray \
		--disable-libjack \
		--disable-indev=jack \
		$(FFMPEG_CONFIGURE_FLAGS)
	$(SED) -i 's/-lSDL2/-lSDL2 -lSDL2main/g' $(BUILD_WORK)/ffmpeg/ffbuild/config.mak
	+$(MAKE) -C $(BUILD_WORK)/ffmpeg
	+$(MAKE) -C $(BUILD_WORK)/ffmpeg install \
		DESTDIR=$(BUILD_STAGE)/ffmpeg
	+$(MAKE) -C $(BUILD_WORK)/ffmpeg install \
		DESTDIR=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/ffmpeg alltools
	cp -a $(BUILD_WORK)/ffmpeg/tools/* $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/ffmpeg/.build_complete
endif

ffmpeg-package: ffmpeg-stage
	# ffmpeg.mk Package Structure
	rm -rf $(BUILD_DIST)/ffmpeg \
		$(BUILD_DIST)/libavcodec{58,-dev} \
		$(BUILD_DIST)/libavdevice{58,-dev} \
		$(BUILD_DIST)/libavfilter{7,-dev} \
		$(BUILD_DIST)/libavformat{58,-dev} \
		$(BUILD_DIST)/libavutil{56,-dev} \
		$(BUILD_DIST)/libpostproc{55,-dev} \
		$(BUILD_DIST)/libswresample{3,-dev} \
		$(BUILD_DIST)/libswscale{5,-dev}
	mkdir -p $(BUILD_DIST)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man} \
		$(BUILD_DIST)/libavcodec58/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libavcodec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/man/man3} \
		$(BUILD_DIST)/libavdevice58/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libavdevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/man/man3} \
		$(BUILD_DIST)/libavfilter7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libavfilter-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/man/man3} \
		$(BUILD_DIST)/libavformat58/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libavformat-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/man/man3} \
		$(BUILD_DIST)/libavutil56/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libavutil-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/man/man3} \
		$(BUILD_DIST)/libpostproc55/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libpostproc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libswresample3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libswresample-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/man/man3} \
		$(BUILD_DIST)/libswscale5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libswscale-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/man/man3}

	# ffmpeg.mk Prep ffmpeg
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{ffmpeg,ffplay,ffprobe,qt-faststart} $(BUILD_DIST)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/ffmpeg $(BUILD_DIST)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# ffmpeg.mk Prep libavcodec58
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavcodec.58*.dylib $(BUILD_DIST)/libavcodec58/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libavcodec-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavcodec.{dylib,a} $(BUILD_DIST)/libavcodec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libavcodec $(BUILD_DIST)/libavcodec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libavcodec.pc $(BUILD_DIST)/libavcodec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/libavcodec.3 $(BUILD_DIST)/libavcodec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3

	# ffmpeg.mk Prep libavdevice58
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavdevice.58*.dylib $(BUILD_DIST)/libavdevice58/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libavdevice-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavdevice.{dylib,a} $(BUILD_DIST)/libavdevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libavdevice $(BUILD_DIST)/libavdevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libavdevice.pc $(BUILD_DIST)/libavdevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/libavdevice.3 $(BUILD_DIST)/libavdevice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3

	# ffmpeg.mk Prep libavfilter7
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavfilter.7*.dylib $(BUILD_DIST)/libavfilter7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libavfilter-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavfilter.{dylib,a} $(BUILD_DIST)/libavfilter-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libavfilter $(BUILD_DIST)/libavfilter-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libavfilter.pc $(BUILD_DIST)/libavfilter-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/libavfilter.3 $(BUILD_DIST)/libavfilter-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3

	# ffmpeg.mk Prep libavformat58
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavformat.58*.dylib $(BUILD_DIST)/libavformat58/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libavformat-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavformat.{dylib,a} $(BUILD_DIST)/libavformat-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libavformat $(BUILD_DIST)/libavformat-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libavformat.pc $(BUILD_DIST)/libavformat-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/libavformat.3 $(BUILD_DIST)/libavformat-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3

	# ffmpeg.mk Prep libavutil56
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavutil.56*.dylib $(BUILD_DIST)/libavutil56/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libavutil-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libavutil.{dylib,a} $(BUILD_DIST)/libavutil-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libavutil $(BUILD_DIST)/libavutil-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libavutil.pc $(BUILD_DIST)/libavutil-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/libavutil.3 $(BUILD_DIST)/libavutil-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3

	# ffmpeg.mk Prep libpostproc55
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpostproc.55*.dylib $(BUILD_DIST)/libpostproc55/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libpostproc-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpostproc.{dylib,a} $(BUILD_DIST)/libpostproc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libpostproc $(BUILD_DIST)/libpostproc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libpostproc.pc $(BUILD_DIST)/libpostproc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# ffmpeg.mk Prep libswresample3
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libswresample.3*.dylib $(BUILD_DIST)/libswresample3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libswresample-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libswresample.{dylib,a} $(BUILD_DIST)/libswresample-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libswresample $(BUILD_DIST)/libswresample-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libswresample.pc $(BUILD_DIST)/libswresample-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/libswresample.3 $(BUILD_DIST)/libswresample-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3

	# ffmpeg.mk Prep libswscale5
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libswscale.5*.dylib $(BUILD_DIST)/libswscale5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpeg.mk Prep libswscale-dev
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libswscale.{dylib,a} $(BUILD_DIST)/libswscale-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libswscale $(BUILD_DIST)/libswscale-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libswscale.pc $(BUILD_DIST)/libswscale-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/ffmpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/libswscale.3 $(BUILD_DIST)/libswscale-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3

	# ffmpeg.mk Sign
	$(call SIGN,ffmpeg,general.xml)
	$(call SIGN,libavcodec58,general.xml)
	$(call SIGN,libavdevice58,general.xml)
	$(call SIGN,libavfilter7,general.xml)
	$(call SIGN,libavformat58,general.xml)
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
		$(BUILD_DIST)/libavutil{56,-dev} \
		$(BUILD_DIST)/libpostproc{55,-dev} \
		$(BUILD_DIST)/libswresample{3,-dev} \
		$(BUILD_DIST)/libswscale{5,-dev}

.PHONY: ffmpeg ffmpeg-package
