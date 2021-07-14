ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += fox1.6
FOX1.6_VERSION := 1.6.56
DEB_FOX1.6_V   ?= $(FOX1.6_VERSION)

fox1.6-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://fox-toolkit.org/ftp/fox-1.6.56.tar.gz
	$(call EXTRACT_TAR,fox-$(FOX1.6_VERSION).tar.gz,fox-$(FOX1.6_VERSION),fox1.6)
	$(call DO_PATCH,fox1.6,fox1.6,-p1)

ifneq ($(wildcard $(BUILD_WORK)/fox1.6/.build_complete),)
fox1.6:
	@echo "Using previously built fox1.6."
else
fox1.6: fox1.6-setup libxft mesa libglu libx11 libxcursor libxext libxrender libxrandr libxfixes libpng16 libtiff libjpeg-turbo libxi freetype fontconfig
	cd $(BUILD_WORK)/fox1.6 && ./configure -C \
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
	+$(MAKE) -C $(BUILD_WORK)/fox1.6 \
		CXXFLAGS+=\ -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/freetype2
	+$(MAKE) -C $(BUILD_WORK)/fox1.6 install \
 		DESTDIR=$(BUILD_STAGE)/fox1.6
	+$(MAKE) -C $(BUILD_WORK)/fox1.6 install \
 		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/fox1.6/.build_complete
endif

fox1.6-package: fox1.6-stage
	# fox1.6.mk Package Structure
	rm -rf $(BUILD_DIST)/libfox-1.6-0 $(BUILD_DIST)/libfox-1.6-dev
	mkdir -p $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,bin}
	mkdir -p $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include,bin}

	# fox1.6.mk Prep libfox-1.6-0
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libCHART-1.6.0.dylib $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libFOX-1.6.0.dylib $(BUILD_DIST)/libfox-1.6-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# fox1.6.mk Prep libfox-1.6-dev
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fox-config $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fox-config-1.6
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/reswrap $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/reswrap-1.6
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libCHART-1.6.{a,dylib} $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libFOX-1.6.{a,dylib} $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/fox-1.6 $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/fox1.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libfox-1.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# fox.mk Sign
	$(call SIGN,libfox-1.6-0,general.xml)
	$(call SIGN,libfox-1.6-dev,general.xml)

	# fox.mk Make .debs
	$(call PACK,libfox-1.6-0,DEB_FOX1.6_V)
	$(call PACK,libfox-1.6-dev,DEB_FOX1.6_V)

	# fox.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfox-1.6-0 $(BUILD_DIST)/libfox-1.6-dev

.PHONY: fox fox-package
