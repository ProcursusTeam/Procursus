ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libx11
LIBX11_VERSION := 1.7.0
DEB_LIBX11_V   ?= $(LIBX11_VERSION)

libx11-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libX11-$(LIBX11_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libx11-$(LIBX11_VERSION).tar.gz)
	$(call EXTRACT_TAR,libx11-$(LIBX11_VERSION).tar.gz,libx11-$(LIBX11_VERSION),libx11)

ifneq ($(wildcard $(BUILD_WORK)/libx11/.build_complete),)
libx11:
	@echo "Using previously built libx11."
else
libx11: libx11-setup xorgproto libxcb xtrans
	unset MACOSX_DEPLOYMENT_TARGET && \
	cd $(BUILD_WORK)/libx11 && unset MACOSX_DEPLOYMENT_TARGET && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-unix-transport \
		--enable-tcp-transport \
		--enable-ipv6 \
		--enable-local-transport \
		--enable-xlocaledir \
		--enable-xthreads \
		--enable-specs=no \
		--enable-malloc0returnsnull=no \
		--with-keysymdefdir=$(BUILD_BASE)/usr/include/X11 
	+$(MAKE) -C $(BUILD_WORK)/libx11 V=1
	+$(MAKE) -C $(BUILD_WORK)/libx11 install \
		DESTDIR=$(BUILD_STAGE)/libx11
	+$(MAKE) -C $(BUILD_WORK)/libx11 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libx11/.build_complete
endif

libx11-package: libx11-stage
	# libx11.mk Package Structure
	rm -rf $(BUILD_DIST)/libx11-{6,dev,data,doc,xcb{1,-dev}}
	mkdir -p $(BUILD_DIST)/libx11-6/usr/lib \
		$(BUILD_DIST)/libx11-dev/usr/{include/X11,lib/pkgconfig} \
		$(BUILD_DIST)/libx11-{doc,data}/usr/share \
		$(BUILD_DIST)/libx11-xcb1/usr/lib/pkg \
		$(BUILD_DIST)/libx11-xcb-dev/usr/{include/X11,lib/pkgconfig}
	
	# libx11.mk Prep libx11-6
	cp -a $(BUILD_STAGE)/libx11/usr/lib/libX11.6.dylib $(BUILD_DIST)/libx11-6/usr/lib

	# libx11.mk Prep libx11-dev
	cp -a $(BUILD_STAGE)/libx11/usr/lib/libX11{.a,.dylib} $(BUILD_DIST)/libx11-dev/usr/lib
	cp -a $(BUILD_STAGE)/libx11/usr/lib/pkgconfig/x11.pc $(BUILD_DIST)/libx11-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libx11/usr/include/X11/!(Xlib-xcb.h) $(BUILD_DIST)/libx11-dev/usr/include/X11

	# libx11.mk Prep libx11-data
	cp -a $(BUILD_STAGE)/libx11/usr/share/X11 $(BUILD_DIST)/libx11-data/usr/share

	# libx11.mk Prep libx11-doc
	cp -a $(BUILD_STAGE)/libx11/usr/share/man $(BUILD_DIST)/libx11-doc/usr/share

	# libx11.mk Prep libx11-xcb1
	cp -a $(BUILD_STAGE)/libx11/usr/lib/libX11-xcb.1.dylib $(BUILD_DIST)/libx11-xcb1/usr/lib

	# libx11.mk Prep libx11-xcb-dev
	cp -a $(BUILD_STAGE)/libx11/usr/lib/libX11-xcb{.a,.dylib} $(BUILD_DIST)/libx11-xcb-dev/usr/lib
	cp -a $(BUILD_STAGE)/libx11/usr/lib/pkgconfig/x11-xcb.pc $(BUILD_DIST)/libx11-xcb-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libx11/usr/include/X11/Xlib-xcb.h $(BUILD_DIST)/libx11-xcb-dev/usr/include/X11
	
	# libx11.mk Sign
	$(call SIGN,libx11-6,general.xml)
	$(call SIGN,libx11-xcb1,general.xml)
	
	# libx11.mk Make .debs
	$(call PACK,libx11-6,DEB_LIBX11_V)
	$(call PACK,libx11-dev,DEB_LIBX11_V)
	$(call PACK,libx11-data,DEB_LIBX11_V)
	$(call PACK,libx11-doc,DEB_LIBX11_V)
	$(call PACK,libx11-xcb1,DEB_LIBX11_V)
	$(call PACK,libx11-xcb-dev,DEB_LIBX11_V)
	
	# libx11.mk Build cleanup
	rm -rf $(BUILD_DIST)/libx11-{6,dev,data,doc,xcb{1,-dev}}

.PHONY: libx11 libx11-package