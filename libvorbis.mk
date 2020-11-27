ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libvorbis
LIBVORBIS_VERSION := 1.3.7
DEB_LIBVORBIS_V   ?= $(LIBVORBIS_VERSION)

libvorbis-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.xiph.org/releases/vorbis/libvorbis-$(LIBVORBIS_VERSION).tar.xz
	$(call EXTRACT_TAR,libvorbis-$(LIBVORBIS_VERSION).tar.xz,libvorbis-$(LIBVORBIS_VERSION),libvorbis)

	# don't build the html docs
	$(SED) -ri 's/(SUBDIRS = .*)doc(.*)/\1 \2/' $(BUILD_WORK)/libvorbis/Makefile.in

ifneq ($(wildcard $(BUILD_WORK)/libvorbis/.build_complete),)
libvorbis:
	@echo "Using previously built libvorbis."
else
libvorbis: libvorbis-setup libogg
	cd $(BUILD_WORK)/libvorbis && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--with-pic \
		--disable-docs
	+$(MAKE) -C $(BUILD_WORK)/libvorbis
	+$(MAKE) -C $(BUILD_WORK)/libvorbis install \
		DESTDIR=$(BUILD_STAGE)/libvorbis
	+$(MAKE) -C $(BUILD_WORK)/libvorbis install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libvorbis/.build_complete
endif

libvorbis-package: libvorbis-stage
	# libvorbis.mk Package Structure
	rm -rf $(BUILD_DIST)/libvorbis{0a,enc2,file3,-dev}
	mkdir -p $(BUILD_DIST)/libvorbis{0a,enc2,file3,-dev}/usr/lib
	mkdir -p $(BUILD_DIST)/libvorbis-dev/usr/share
	
	# libvorbis.mk Prep libvorbis0a
	cp -a $(BUILD_STAGE)/libvorbis/usr/lib/libvorbis.0.dylib $(BUILD_DIST)/libvorbis0a/usr/lib
	
	# libvorbis.mk Prep libvorbisenc2
	cp -a $(BUILD_STAGE)/libvorbis/usr/lib/libvorbisenc.2.dylib $(BUILD_DIST)/libvorbisenc2/usr/lib
	
	# libvorbis.mk Prep libvorbisfile3
	cp -a $(BUILD_STAGE)/libvorbis/usr/lib/libvorbisfile.3.dylib $(BUILD_DIST)/libvorbisfile3/usr/lib

	# libvorbis.mk Prep libvorbis-dev
	cp -a $(BUILD_STAGE)/libvorbis/usr/lib/pkgconfig $(BUILD_DIST)/libvorbis-dev/usr/lib
	cp -a $(BUILD_STAGE)/libvorbis/usr/lib/libvorbis{,enc,file}.{dylib,a} $(BUILD_DIST)/libvorbis-dev/usr/lib
	cp -a $(BUILD_STAGE)/libvorbis/usr/include $(BUILD_DIST)/libvorbis-dev/usr
	cp -a $(BUILD_STAGE)/libvorbis/usr/share/aclocal $(BUILD_DIST)/libvorbis-dev/usr/share
	
	# libvorbis.mk Sign
	$(call SIGN,libvorbis0a,general.xml)
	$(call SIGN,libvorbisenc2,general.xml)
	$(call SIGN,libvorbisfile3,general.xml)
	
	# libvorbis.mk Make .debs
	$(call PACK,libvorbis0a,DEB_LIBVORBIS_V)
	$(call PACK,libvorbisenc2,DEB_LIBVORBIS_V)
	$(call PACK,libvorbisfile3,DEB_LIBVORBIS_V)
	$(call PACK,libvorbis-dev,DEB_LIBVORBIS_V)
	
	# libvorbis.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvorbis{0a,enc2,file3,-dev}

.PHONY: libvorbis libvorbis-package
