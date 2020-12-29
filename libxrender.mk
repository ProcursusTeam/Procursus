ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libxrender
LIBXRENDER_VERSION := 0.9.10
DEB_LIBXRENDER_V   ?= $(LIBXRENDER_VERSION)

libxrender-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXrender-$(LIBXRENDER_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXrender-$(LIBXRENDER_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXrender-$(LIBXRENDER_VERSION).tar.gz,libXrender-$(LIBXRENDER_VERSION),libxrender)

ifneq ($(wildcard $(BUILD_WORK)/libxrender/.build_complete),)
libxrender:
	@echo "Using previously built libxrender."
else
libxrender: libxrender-setup libx11
	cd $(BUILD_WORK)/libxrender && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxrender
	+$(MAKE) -C $(BUILD_WORK)/libxrender install \
		DESTDIR=$(BUILD_STAGE)/libxrender
	+$(MAKE) -C $(BUILD_WORK)/libxrender install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxrender/.build_complete
endif

libxrender-package: libxrender-stage
	# libxrender.mk Package Structure
	rm -rf $(BUILD_DIST)/libxrender{1,-dev}
	mkdir -p $(BUILD_DIST)/libxrender{1,-dev}/usr/lib
	
	# libxrender.mk Prep libxrender1
	cp -a $(BUILD_STAGE)/libxrender/usr/lib/libXrender.1.dylib $(BUILD_DIST)/libxrender1/usr/lib
	
	# libxrender.mk Prep libxrender-dev
	cp -a $(BUILD_STAGE)/libxrender/usr/lib/libXrender{.a,.dylib} $(BUILD_DIST)/libxrender-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxrender/usr/lib/pkgconfig $(BUILD_DIST)/libxrender-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libxrender/usr/include $(BUILD_DIST)/libxrender-dev/usr
	
	# libxrender.mk Sign
	$(call SIGN,libxrender1,general.xml)
	
	# libxrender.mk Make .debs
	$(call PACK,libxrender1,DEB_LIBXRENDER_V)
	$(call PACK,libxrender-dev,DEB_LIBXRENDER_V)
	
	# libxrender.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxrender{1,-dev}

.PHONY: libxrender libxrender-package
