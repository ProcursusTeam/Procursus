ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libwebp
LIBWEBP_VERSION := 1.1.0
DEB_LIBWEBP_V   ?= $(LIBWEBP_VERSION)-1

libwebp-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libwebp-$(LIBWEBP_VERSION).tar.gz" ] && wget -q -nc -L -O$(BUILD_SOURCE)/libwebp-$(LIBWEBP_VERSION).tar.gz \
		https://chromium.googlesource.com/webm/libwebp/+archive/refs/heads/$(LIBWEBP_VERSION).tar.gz
	# Fuck this lib.
	mkdir -p $(BUILD_WORK)/libwebp
	$(TAR) xf $(BUILD_SOURCE)/libwebp-$(LIBWEBP_VERSION).tar.gz -C $(BUILD_WORK)/libwebp

ifneq ($(wildcard $(BUILD_WORK)/libwebp/.build_complete),)
libwebp:
	@echo "Using previously built libwebp."
else
libwebp: libwebp-setup libpng16 libgif libtiff libjpeg-turbo
	cd $(BUILD_WORK)/libwebp && ./autogen.sh && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-{sdl,gl} \
		--enable-libwebp{mux,demux,decoder,extras}
	+$(MAKE) -C $(BUILD_WORK)/libwebp
	+$(MAKE) -C $(BUILD_WORK)/libwebp install \
		DESTDIR="$(BUILD_STAGE)/libwebp"
	+$(MAKE) -C $(BUILD_WORK)/libwebp install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libwebp/.build_complete
endif

libwebp-package: libwebp-stage
  # libwebp.mk Package Structure
	rm -rf \
		$(BUILD_DIST)/libwebp{7,-dev} \
		$(BUILD_DIST)/libwebp{demux2,mux3} \
		$(BUILD_DIST)/webp
	mkdir -p \
		$(BUILD_DIST)/libwebp-dev/usr/{include,lib/pkgconfig} \
		$(BUILD_DIST)/libwebp{7,demux2,mux3}/usr/lib \
		$(BUILD_DIST)/webp/usr/bin

  # libwebp.mk Prep libwebp-dev
	cp -a $(BUILD_STAGE)/libwebp/usr/include $(BUILD_DIST)/libwebp-dev/usr
	cp -a $(BUILD_STAGE)/libwebp/usr/lib/*.a $(BUILD_DIST)/libwebp-dev/usr/lib
	cp -a $(BUILD_STAGE)/libwebp/usr/lib/libwebp{,decoder,demux,mux}.dylib $(BUILD_DIST)/libwebp-dev/usr/lib
	cp -a $(BUILD_STAGE)/libwebp/usr/lib/pkgconfig $(BUILD_DIST)/libwebp-dev/usr/lib

	# libwebp.mk Prep libwebp7
	cp -a $(BUILD_STAGE)/libwebp/usr/lib/libwebp.*.dylib $(BUILD_DIST)/libwebp7/usr/lib

	# libwebp.mk Prep libwebpdemux2
	cp -a $(BUILD_STAGE)/libwebp/usr/lib/libwebpdemux.*.dylib $(BUILD_DIST)/libwebpdemux2/usr/lib

	# libwebp.mk Prep libwebpmux3
	cp -a $(BUILD_STAGE)/libwebp/usr/lib/libwebpmux.*.dylib $(BUILD_DIST)/libwebpmux3/usr/lib

	# libwebp.mk Prep webp
	cp -a $(BUILD_STAGE)/libwebp/usr/bin $(BUILD_DIST)/webp/usr

  # libwebp.mk Sign
	$(call SIGN,libwebp-dev,general.xml)
	$(call SIGN,libwebp7,general.xml)
	$(call SIGN,libwebpdemux2,general.xml)
	$(call SIGN,libwebpmux3,general.xml)
	$(call SIGN,webp,general.xml)

  # libwebp.mk Make .debs
	$(call PACK,libwebp-dev,DEB_LIBWEBP_V)
	$(call PACK,libwebp7,DEB_LIBWEBP_V)
	$(call PACK,libwebpdemux2,DEB_LIBWEBP_V)
	$(call PACK,libwebpmux3,DEB_LIBWEBP_V)
	$(call PACK,webp,DEB_LIBWEBP_V)

  # libwebp.mk Build cleanup
	rm -rf $(BUILD_DIST)/libwebp{7,-dev,demux2,mux3} $(BUILD_DIST)/webp

.PHONY: libwebp libwebp-package
