ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxext
LIBXEXT_VERSION := 1.3.4
DEB_LIBXEXT_V   ?= $(LIBXEXT_VERSION)-1

libxext-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXext-$(LIBXEXT_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXext-$(LIBXEXT_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXext-$(LIBXEXT_VERSION).tar.gz,libXext-$(LIBXEXT_VERSION),libxext)

ifneq ($(wildcard $(BUILD_WORK)/libxext/.build_complete),)
libxext:
	@echo "Using previously built libxext."
else
libxext: libxext-setup libx11 xorgproto
	cd $(BUILD_WORK)/libxext && ./configure -C \
		--build=$(BUILD_MISC)/config.guess \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--disable-silent-rules \
		--disable-dependency-tracking \
		--localstatedir=/var \
		--enable-malloc0returnsnull=no \
		--enable-specs=no
	+$(MAKE) -C $(BUILD_WORK)/libxext
	+$(MAKE) -C $(BUILD_WORK)/libxext install \
		DESTDIR=$(BUILD_STAGE)/libxext
	+$(MAKE) -C $(BUILD_WORK)/libxext install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxext/.build_complete
endif

libxext-package: libxext-stage
	# libxext.mk Package Structure
	rm -rf $(BUILD_DIST)/libxext{6,-dev,-doc}
	mkdir -p $(BUILD_DIST)/libxext{6,-dev}/usr/lib \
		$(BUILD_DIST)/libxext-doc/usr
	
	# libxext.mk Prep libxext6
	cp -a $(BUILD_STAGE)/libxext/usr/lib/libXext.6.dylib $(BUILD_DIST)/libxext6/usr/lib

	# libxext.mk Prep libxext-dev
	cp -a $(BUILD_STAGE)/libxext/usr/lib/{libXext.{a,dylib},pkgconfig} $(BUILD_DIST)/libxext-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxext/usr/include $(BUILD_DIST)/libxext-dev/usr

	# libxext.mk Prep libxext-doc
	cp -a $(BUILD_STAGE)/libxext/usr/share $(BUILD_DIST)/libxext-doc/usr
	
	# libxext.mk Sign
	$(call SIGN,libxext6,general.xml)
	
	# libxext.mk Make .debs
	$(call PACK,libxext6,DEB_LIBXEXT_V)
	$(call PACK,libxext-dev,DEB_LIBXEXT_V)
	$(call PACK,libxext-doc,DEB_LIBXEXT_V)
	
	# libxext.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxext{6,-dev,-doc}

.PHONY: libxext libxext-package
