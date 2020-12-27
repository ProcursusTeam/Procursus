ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libxau
LIBXAU_VERSION := 1.0.9
DEB_LIBXAU_V   ?= $(LIBXAU_VERSION)

libxau-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXau-$(LIBXAU_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libxau-$(LIBXAU_VERSION).tar.gz)
	$(call EXTRACT_TAR,libxau-$(LIBXAU_VERSION).tar.gz,libxau-$(LIBXAU_VERSION),libxau)

ifneq ($(wildcard $(BUILD_WORK)/libxau/.build_complete),)
libxau:
	@echo "Using previously built libxau."
else
libxau: libxau-setup xorgproto
	cd $(BUILD_WORK)/libxau && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var
	+$(MAKE) -C $(BUILD_WORK)/libxau
	+$(MAKE) -C $(BUILD_WORK)/libxau install \
		DESTDIR=$(BUILD_STAGE)/libxau
	+$(MAKE) -C $(BUILD_WORK)/libxau install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxau/.build_complete
endif

libxau-package: libxau-stage
	# libxau.mk Package Structure
	rm -rf $(BUILD_DIST)/libxau{6,-dev}
	mkdir -p $(BUILD_DIST)/libxau6/usr/lib
	mkdir -p $(BUILD_DIST)/libxau-dev/usr/{include,lib}
	
	# libxau.mk Prep libxau6
	cp -a $(BUILD_STAGE)/libxau/usr/lib/libxau.6.dylib $(BUILD_DIST)/libxau6/usr/lib

	# libxau.mk Prep libxau-dev
	cp -a $(BUILD_STAGE)/libxau/usr/lib/{libXau{.a,.dylib},pkgconfig} $(BUILD_DIST)/libxau-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxau/usr/include $(BUILD_DIST)/libxau-dev/usr
	
	# libxau.mk Sign
	$(call SIGN,libxau6,general.xml)
	
	# libxau.mk Make .debs
	$(call PACK,libxau6,DEB_LIBXAU_V)
	$(call PACK,libxau-dev,DEB_LIBXAU_V)
	
	# libxau.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxau{6,-dev}

.PHONY: libxau libxau-package