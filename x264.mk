ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += x264
X264_SOVERSION := 161
X264_VERSION   := 0.$(X264_SOVERSION).3027+git4121277
DEB_X264_V     ?= $(X264_VERSION)

X264_COMMIT    := 4121277b40a667665d4eea1726aefdc55d12d110

x264-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://code.videolan.org/videolan/x264/-/archive/master/x264-$(X264_COMMIT).tar.gz
	$(call EXTRACT_TAR,x264-$(X264_COMMIT).tar.gz,x264-master-$(X264_COMMIT),x264)
	wget -q -nc -P $(BUILD_WORK)/x264 https://raw.githubusercontent.com/libav/gas-preprocessor/master/gas-preprocessor.pl
	chmod 0755 $(BUILD_WORK)/x264/gas-preprocessor.pl

ifneq ($(wildcard $(BUILD_WORK)/x264/.build_complete),)
x264:
	@echo "Using previously built x264."
else
x264: x264-setup
	rm -rf $(BUILD_STAGE)/x264
	cd $(BUILD_WORK)/x264 && AS="$(BUILD_WORK)/x264/gas-preprocessor.pl -arch aarch64 -- $(CC) $(CFLAGS)" ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-lsmash \
		--disable-swscale \
		--disable-ffms \
		--enable-shared \
		--enable-static \
		--enable-strip \
		--system-libx264 \
		--enable-lto
	+$(MAKE) -C $(BUILD_WORK)/x264
	+$(MAKE) -C $(BUILD_WORK)/x264 install \
		DESTDIR=$(BUILD_STAGE)/x264
	+$(MAKE) -C $(BUILD_WORK)/x264 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/x264/.build_complete
endif

x264-package: x264-stage
	# x264.mk Package Structure
	rm -rf $(BUILD_DIST)/libx264-{$(X264_SOVERSION),dev} $(BUILD_DIST)/x264
	mkdir -p $(BUILD_DIST)/libx264-$(X264_SOVERSION)/usr/lib \
		$(BUILD_DIST)/libx264-dev/usr/lib \
		$(BUILD_DIST)/x264/usr/bin
	
	# x264.mk Prep libx264-$(X264_SOVERSION)
	cp -a $(BUILD_STAGE)/x264/usr/lib/libx264.$(X264_SOVERSION).dylib $(BUILD_DIST)/libx264-$(X264_SOVERSION)/usr/lib

	# x264.mk Prep libx264-dev
	cp -a $(BUILD_STAGE)/x264/usr/lib/!(*.$(X264_SOVERSION)*) $(BUILD_DIST)/libx264-dev/usr/lib
	cp -a $(BUILD_STAGE)/x264/usr/include $(BUILD_DIST)/libx264-dev/usr

	# x264.mk Prep x264
	cp -a $(BUILD_STAGE)/x264/usr/bin/x264 $(BUILD_DIST)/x264/usr/bin
	
	# x264.mk Sign
	$(call SIGN,libx264-$(X264_SOVERSION),general.xml)
	$(call SIGN,x264,general.xml)
	
	# x264.mk Make .debs
	$(call PACK,libx264-$(X264_SOVERSION),DEB_X264_V)
	$(call PACK,libx264-dev,DEB_X264_V)
	$(call PACK,x264,DEB_X264_V)
	
	# x264.mk Build cleanup
	rm -rf $(BUILD_DIST)/libx264-{$(X264_SOVERSION),dev} $(BUILD_DIST)/x264

.PHONY: x264 x264-package
