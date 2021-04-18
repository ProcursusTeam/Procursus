ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += fox
FOX_VERSION := 1.6.56
DEB_FOX_V   ?= $(FOX_VERSION)

fox-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://fox-toolkit.org/ftp/fox-1.6.56.tar.gz
	$(call EXTRACT_TAR,fox-$(FOX_VERSION).tar.gz,fox-$(FOX_VERSION),fox)
	$(call DO_PATCH,fox,fox,-p1)

ifneq ($(wildcard $(BUILD_WORK)/fox/.build_complete),)
fox:
	@echo "Using previously built fox."
else
fox: fox-setup slang2 glib2.0 gettext libxft mesa libx11
	cd $(BUILD_WORK)/fox && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-sysroot=$(BUILD_BASE) \
		--with-x \
		--with-xft \
		--with-xshm \
		--with-shape \
		--with-xcursor \
		--with-xrender \
		--with-xrandr \
		--with-opengl=no \
		--with-xim \
		--with-xinput \
		--with-xfixes \
		--x-libraries=$(BUILD_BASE)/usr/lib \
		--x-includes=$(BUILD_BASE)/usr/include 
	+$(MAKE) -C $(BUILD_WORK)/fox
	+$(MAKE) -C $(BUILD_WORK)/fox install \
 		DESTDIR=$(BUILD_STAGE)/fox
	+$(MAKE) -C $(BUILD_WORK)/fox install \
 		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/fox/.build_complete
endif

fox-package: fox-stage
 # fox.mk Package Structure
	rm -rf $(BUILD_DIST)/libfox-1.6-0 $(BUILD_DIST)/libfox-1.6-dev
	mkdir -p $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,bin}
	mkdir -p $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include/fox-1.6,share,bin}

	# fox.mk Prep libfox-1.6-0
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/shutterbug $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/Adie.stx $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/calculator $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/adie $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/PathFinder $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libCHART-1.6.0.dylib $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libFOX-1.6.0.dylib $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libCHART-1.6.dylib $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libFOX-1.6.dylib $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcb-wm.mk Prep libfox-1.6-dev
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fox-config $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/reswrap $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libCHART-1.6.a $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libFOX-1.6.a $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/fox-1.6 $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/fox-1.6
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libxcb.mk Sign
	$(call SIGN,libfox-1.6-0,general.xml)
	$(call SIGN,libfox-1.6-dev,general.xml)

	# libxcb-wm.mk Make .debs
	$(call PACK,libfox-1.6-0,DEB_FOX_V)
	$(call PACK,libfox-1.6-dev,DEB_FOX_V)

	# libxcb-wm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfox-1.6-0 $(BUILD_DIST)/libfox-1.6-dev

.PHONY: fox fox-package
