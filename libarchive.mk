ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libarchive
LIBARCHIVE_VERSION := 3.5.1
DEB_LIBARCHIVE_V   ?= $(LIBARCHIVE_VERSION)

libarchive-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.libarchive.org/downloads/libarchive-$(LIBARCHIVE_VERSION).tar.xz
	$(call EXTRACT_TAR,libarchive-$(LIBARCHIVE_VERSION).tar.xz,libarchive-$(LIBARCHIVE_VERSION),libarchive)

ifneq ($(wildcard $(BUILD_WORK)/libarchive/.build_complete),)
libarchive:
	@echo "Using previously built libarchive."
else
libarchive: libarchive-setup lz4 liblzo2 zstd xz nettle
	cd $(BUILD_WORK)/libarchive && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--without-openssl \
		--with-nettle \
		--with-lzo2 \
		--enable-bsdtar=shared \
		--enable-bsdcpio=shared \
		--enable-bsdcat=shared
	+$(MAKE) -C $(BUILD_WORK)/libarchive
	+$(MAKE) -C $(BUILD_WORK)/libarchive install \
		DESTDIR="$(BUILD_STAGE)/libarchive"
	+$(MAKE) -C $(BUILD_WORK)/libarchive install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libarchive/.build_complete
endif

libarchive-package: libarchive-stage
	# libarchive.mk Package Structure
	rm -rf $(BUILD_DIST)/libarchive{13,-tools,-dev}
	mkdir -p $(BUILD_DIST)/libarchive13/usr/lib
	mkdir -p $(BUILD_DIST)/libarchive-tools/usr/share/man
	mkdir -p $(BUILD_DIST)/libarchive-dev/usr/{lib,share/man}
	
	# libarchive.mk Prep libarchive13
	cp -a $(BUILD_STAGE)/libarchive/usr/lib/libarchive.*.dylib $(BUILD_DIST)/libarchive13/usr/lib
	
	# libarchive.mk Prep libarchive-tools
	cp -a $(BUILD_STAGE)/libarchive/usr/bin $(BUILD_DIST)/libarchive-tools/usr
	cp -a $(BUILD_STAGE)/libarchive/usr/share/man/man1 $(BUILD_DIST)/libarchive-tools/usr/share/man/
	
	# libarchive.mk Prep libarchive-dev
	cp -a $(BUILD_STAGE)/libarchive/usr/include $(BUILD_DIST)/libarchive-dev/usr
	cp -a $(BUILD_STAGE)/libarchive/usr/lib/{libarchive.dylib,pkgconfig} $(BUILD_DIST)/libarchive-dev/usr/lib
	cp -a $(BUILD_STAGE)/libarchive/usr/share/man/man{3,5} $(BUILD_DIST)/libarchive-dev/usr/share/man
	
	# libarchive.mk Sign
	$(call SIGN,libarchive13,general.xml)
	$(call SIGN,libarchive-tools,general.xml)
	
	# libarchive.mk Make .debs
	$(call PACK,libarchive13,DEB_LIBARCHIVE_V)
	$(call PACK,libarchive-tools,DEB_LIBARCHIVE_V)
	$(call PACK,libarchive-dev,DEB_LIBARCHIVE_V)
	
	# libarchive.mk Build cleanup
	rm -rf $(BUILD_DIST)/libarchive{13,-dev,-tools}

.PHONY: libarchive libarchive-package
