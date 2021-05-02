ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libxcb
LIBXCB_VERSION := 1.14
DEB_LIBXCB_V   ?= $(LIBXCB_VERSION)

libxcb-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libxcb-$(LIBXCB_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libxcb-$(LIBXCB_VERSION).tar.gz)
	$(call EXTRACT_TAR,libxcb-$(LIBXCB_VERSION).tar.gz,libxcb-$(LIBXCB_VERSION),libxcb)

ifneq ($(wildcard $(BUILD_WORK)/libxcb/.build_complete),)
libxcb:
	@echo "Using previously built libxcb."
else
libxcb: libxcb-setup xcb-proto libxau libxdmcp libpthread-stubs
	cd $(BUILD_WORK)/libxcb && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-launchd \
		--enable-dri3 \
		--enable-xevie
	+$(MAKE) -C $(BUILD_WORK)/libxcb \
		XCBPROTO_XCBPYTHONDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages" \
		XCBPROTO_XCBINCLUDEDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xcb"
	+$(MAKE) -C $(BUILD_WORK)/libxcb install \
		DESTDIR=$(BUILD_STAGE)/libxcb \
		XCBPROTO_XCBPYTHONDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages" \
		XCBPROTO_XCBINCLUDEDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xcb"
	+$(MAKE) -C $(BUILD_WORK)/libxcb install \
		DESTDIR=$(BUILD_BASE) \
		XCBPROTO_XCBPYTHONDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages" \
		XCBPROTO_XCBINCLUDEDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xcb"
	touch $(BUILD_WORK)/libxcb/.build_complete
endif

libxcb-package: libxcb-stage
	# libxcb.mk Package Structure
	rm -rf $(BUILD_DIST)/libxcb*/
	mkdir -p $(BUILD_DIST)/libxcb{1,-{composite0,damage0,dpms0,dri2-0,dri3-0,glx0,present0,randr0,record0,render0,res0,screensaver0,shape0,shm0,sync1,xf86dri0,xfixes0,xinerama0,xinput0,xkb1,xtest0,xv0,xvmc0}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxcb{1,-{composite0,damage0,dpms0,dri2-0,dri3,glx0,present,randr0,record0,render0,res0,screensaver0,shape0,shm0,sync,xf86dri0,xfixes0,xinerama0,xinput,xkb,xtest0,xv0,xvmc0}}-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/xcb,lib/pkgconfig}

	# libxcb.mk Prep libxcb1
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb.1* $(BUILD_DIST)/libxcb1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb1-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/{bigreq,xc_misc,xcb,xcbext,xproto}.h $(BUILD_DIST)/libxcb1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb.{a,dylib} $(BUILD_DIST)/libxcb1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb.pc $(BUILD_DIST)/libxcb1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-composite0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-composite.0* $(BUILD_DIST)/libxcb-composite0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-composite0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-composite.{a,dylib} $(BUILD_DIST)/libxcb-composite0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/composite.h $(BUILD_DIST)/libxcb-composite0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-composite.pc $(BUILD_DIST)/libxcb-composite0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-damage0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-damage.0* $(BUILD_DIST)/libxcb-damage0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-damage0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-damage.{a,dylib} $(BUILD_DIST)/libxcb-damage0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/damage.h $(BUILD_DIST)/libxcb-damage0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-damage.pc $(BUILD_DIST)/libxcb-damage0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-dpms0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-dpms.0* $(BUILD_DIST)/libxcb-dpms0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-dpms0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-dpms.{a,dylib} $(BUILD_DIST)/libxcb-dpms0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/dpms.h $(BUILD_DIST)/libxcb-dpms0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-dpms.pc $(BUILD_DIST)/libxcb-dpms0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-dri2-0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-dri2.0* $(BUILD_DIST)/libxcb-dri2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-dri2-0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-dri2.{a,dylib} $(BUILD_DIST)/libxcb-dri2-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/dri2.h $(BUILD_DIST)/libxcb-dri2-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-dri2.pc $(BUILD_DIST)/libxcb-dri2-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-dri3-0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-dri3.0* $(BUILD_DIST)/libxcb-dri3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-dri3-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-dri3.{a,dylib} $(BUILD_DIST)/libxcb-dri3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/dri3.h $(BUILD_DIST)/libxcb-dri3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-dri3.pc $(BUILD_DIST)/libxcb-dri3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-glx0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-glx.0* $(BUILD_DIST)/libxcb-glx0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-glx0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-glx.{a,dylib} $(BUILD_DIST)/libxcb-glx0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/glx.h $(BUILD_DIST)/libxcb-glx0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-glx.pc $(BUILD_DIST)/libxcb-glx0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-present0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-present.0* $(BUILD_DIST)/libxcb-present0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-present-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-present.{a,dylib} $(BUILD_DIST)/libxcb-present-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/present.h $(BUILD_DIST)/libxcb-present-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-present.pc $(BUILD_DIST)/libxcb-present-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-randr0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-randr.0* $(BUILD_DIST)/libxcb-randr0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-randr0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-randr.{a,dylib} $(BUILD_DIST)/libxcb-randr0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/randr.h $(BUILD_DIST)/libxcb-randr0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-randr.pc $(BUILD_DIST)/libxcb-randr0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-record0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-record.0* $(BUILD_DIST)/libxcb-record0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-record0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-record.{a,dylib} $(BUILD_DIST)/libxcb-record0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/record.h $(BUILD_DIST)/libxcb-record0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-record.pc $(BUILD_DIST)/libxcb-record0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-render0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-render.0* $(BUILD_DIST)/libxcb-render0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-render0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-render.{a,dylib} $(BUILD_DIST)/libxcb-render0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/render.h $(BUILD_DIST)/libxcb-render0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-render.pc $(BUILD_DIST)/libxcb-render0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-res0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-res.0* $(BUILD_DIST)/libxcb-res0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-res0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-res.{a,dylib} $(BUILD_DIST)/libxcb-res0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/res.h $(BUILD_DIST)/libxcb-res0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-res.pc $(BUILD_DIST)/libxcb-res0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-screensaver0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-screensaver.0* $(BUILD_DIST)/libxcb-screensaver0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-screensaver0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-screensaver.{a,dylib} $(BUILD_DIST)/libxcb-screensaver0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/screensaver.h $(BUILD_DIST)/libxcb-screensaver0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-screensaver.pc $(BUILD_DIST)/libxcb-screensaver0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-shape0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-shape.0* $(BUILD_DIST)/libxcb-shape0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-shape0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-shape.{a,dylib} $(BUILD_DIST)/libxcb-shape0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/shape.h $(BUILD_DIST)/libxcb-shape0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-shape.pc $(BUILD_DIST)/libxcb-shape0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-shm0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-shm.0* $(BUILD_DIST)/libxcb-shm0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-shm0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-shm.{a,dylib} $(BUILD_DIST)/libxcb-shm0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/shm.h $(BUILD_DIST)/libxcb-shm0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-shm.pc $(BUILD_DIST)/libxcb-shm0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-sync1
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-sync.1* $(BUILD_DIST)/libxcb-sync1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-sync-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-sync.{a,dylib} $(BUILD_DIST)/libxcb-sync-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/sync.h $(BUILD_DIST)/libxcb-sync-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-sync.pc $(BUILD_DIST)/libxcb-sync-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xf86dri0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xf86dri.0* $(BUILD_DIST)/libxcb-xf86dri0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xf86dri0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xf86dri.{a,dylib} $(BUILD_DIST)/libxcb-xf86dri0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xf86dri.h $(BUILD_DIST)/libxcb-xf86dri0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xf86dri.pc $(BUILD_DIST)/libxcb-xf86dri0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xfixes0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xfixes.0* $(BUILD_DIST)/libxcb-xfixes0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xfixes0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xfixes.{a,dylib} $(BUILD_DIST)/libxcb-xfixes0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xfixes.h $(BUILD_DIST)/libxcb-xfixes0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xfixes.pc $(BUILD_DIST)/libxcb-xfixes0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xinerama0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xinerama.0* $(BUILD_DIST)/libxcb-xinerama0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xinerama0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xinerama.{a,dylib} $(BUILD_DIST)/libxcb-xinerama0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xinerama.h $(BUILD_DIST)/libxcb-xinerama0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xinerama.pc $(BUILD_DIST)/libxcb-xinerama0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xinput0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xinput.0* $(BUILD_DIST)/libxcb-xinput0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xinput-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xinput.{a,dylib} $(BUILD_DIST)/libxcb-xinput-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xinput.h $(BUILD_DIST)/libxcb-xinput-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xinput.pc $(BUILD_DIST)/libxcb-xinput-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xkb1
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xkb.1* $(BUILD_DIST)/libxcb-xkb1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xkb-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xkb.{a,dylib} $(BUILD_DIST)/libxcb-xkb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xkb.h $(BUILD_DIST)/libxcb-xkb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xkb.pc $(BUILD_DIST)/libxcb-xkb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xtest0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xtest.0* $(BUILD_DIST)/libxcb-xtest0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xtest0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xtest.{a,dylib} $(BUILD_DIST)/libxcb-xtest0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xtest.h $(BUILD_DIST)/libxcb-xtest0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xtest.pc $(BUILD_DIST)/libxcb-xtest0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xv0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xv.0* $(BUILD_DIST)/libxcb-xv0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xv0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xv.{a,dylib} $(BUILD_DIST)/libxcb-xv0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xv.h $(BUILD_DIST)/libxcb-xv0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xv.pc $(BUILD_DIST)/libxcb-xv0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Prep libxcb-xvmc0
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xvmc.0* $(BUILD_DIST)/libxcb-xvmc0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb.mk Prep libxcb-xvmc0-dev
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcb-xvmc.{a,dylib} $(BUILD_DIST)/libxcb-xvmc0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb/xvmc.h $(BUILD_DIST)/libxcb-xvmc0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xcb
	cp -a $(BUILD_STAGE)/libxcb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xcb-xvmc.pc $(BUILD_DIST)/libxcb-xvmc0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libxcb.mk Sign
	$(call SIGN,libxcb1,general.xml)
	$(call SIGN,libxcb-composite0,general.xml)
	$(call SIGN,libxcb-damage0,general.xml)
	$(call SIGN,libxcb-dpms0,general.xml)
	$(call SIGN,libxcb-dri2-0,general.xml)
	$(call SIGN,libxcb-dri3-0,general.xml)
	$(call SIGN,libxcb-glx0,general.xml)
	$(call SIGN,libxcb-present0,general.xml)
	$(call SIGN,libxcb-randr0,general.xml)
	$(call SIGN,libxcb-record0,general.xml)
	$(call SIGN,libxcb-render0,general.xml)
	$(call SIGN,libxcb-res0,general.xml)
	$(call SIGN,libxcb-screensaver0,general.xml)
	$(call SIGN,libxcb-shape0,general.xml)
	$(call SIGN,libxcb-shm0,general.xml)
	$(call SIGN,libxcb-sync1,general.xml)
	$(call SIGN,libxcb-xf86dri0,general.xml)
	$(call SIGN,libxcb-xfixes0,general.xml)
	$(call SIGN,libxcb-xinerama0,general.xml)
	$(call SIGN,libxcb-xinput0,general.xml)
	$(call SIGN,libxcb-xkb1,general.xml)
	$(call SIGN,libxcb-xtest0,general.xml)
	$(call SIGN,libxcb-xv0,general.xml)
	$(call SIGN,libxcb-xvmc0,general.xml)

	# libxcb.mk Make .debs
	$(call PACK,libxcb1,DEB_LIBXCB_V)
	$(call PACK,libxcb-composite0,DEB_LIBXCB_V)
	$(call PACK,libxcb-damage0,DEB_LIBXCB_V)
	$(call PACK,libxcb-dpms0,DEB_LIBXCB_V)
	$(call PACK,libxcb-dri2-0,DEB_LIBXCB_V)
	$(call PACK,libxcb-dri3-0,DEB_LIBXCB_V)
	$(call PACK,libxcb-glx0,DEB_LIBXCB_V)
	$(call PACK,libxcb-present0,DEB_LIBXCB_V)
	$(call PACK,libxcb-randr0,DEB_LIBXCB_V)
	$(call PACK,libxcb-record0,DEB_LIBXCB_V)
	$(call PACK,libxcb-render0,DEB_LIBXCB_V)
	$(call PACK,libxcb-res0,DEB_LIBXCB_V)
	$(call PACK,libxcb-screensaver0,DEB_LIBXCB_V)
	$(call PACK,libxcb-shape0,DEB_LIBXCB_V)
	$(call PACK,libxcb-shm0,DEB_LIBXCB_V)
	$(call PACK,libxcb-sync1,DEB_LIBXCB_V)
	$(call PACK,libxcb-xf86dri0,DEB_LIBXCB_V)
	$(call PACK,libxcb-xfixes0,DEB_LIBXCB_V)
	$(call PACK,libxcb-xinerama0,DEB_LIBXCB_V)
	$(call PACK,libxcb-xinput0,DEB_LIBXCB_V)
	$(call PACK,libxcb-xkb1,DEB_LIBXCB_V)
	$(call PACK,libxcb-xtest0,DEB_LIBXCB_V)
	$(call PACK,libxcb-xv0,DEB_LIBXCB_V)
	$(call PACK,libxcb-xvmc0,DEB_LIBXCB_V)
	$(call PACK,libxcb1-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-composite0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-damage0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-dpms0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-dri2-0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-dri3-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-glx0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-present-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-randr0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-record0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-render0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-res0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-screensaver0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-shape0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-shm0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-sync-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xf86dri0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xfixes0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xinerama0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xinput-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xkb-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xtest0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xv0-dev,DEB_LIBXCB_V)
	$(call PACK,libxcb-xvmc0-dev,DEB_LIBXCB_V)

	# libxcb.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcb*/

.PHONY: libxcb libxcb-package