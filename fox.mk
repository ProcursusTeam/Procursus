ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += fox
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
fox: fox-setup libxft mesa libglu libx11 libxcursor libxext libxrender libxrandr libxfixes libpng16 libtiff libjpeg-turbo libxi freetype fontconfig
	cd $(BUILD_WORK)/fox && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-release \
		--with-x \
		--with-xft \
		--with-xshm \
		--with-shape \
		--with-xcursor \
		--with-xrender \
		--with-xrandr \
		--with-opengl=yes \
		--with-xim \
		--with-xinput \
		--with-xfixes
	+$(MAKE) -C $(BUILD_WORK)/fox \
		CXXFLAGS+=\ -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/freetype2
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

	# fox.mk Prep libfox-1.6-dev
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fox-config $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/reswrap $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libCHART-1.6.{a,dylib} $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libFOX-1.6.{a,dylib} $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/fox-1.6 $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/fox-1.6
	cp -a $(BUILD_STAGE)/fox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# fox.mk Sign
	$(call SIGN,libfox-1.6-0,general.xml)
	$(call SIGN,libfox-1.6-dev,general.xml)

	# fox.mk Make .debs
	$(call PACK,libfox-1.6-0,DEB_FOX_V)
	$(call PACK,libfox-1.6-dev,DEB_FOX_V)

	# fox.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfox-1.6-0 $(BUILD_DIST)/libfox-1.6-dev

.PHONY: fox fox-package
