ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pango
PANGO_VERSION := 1.50.7
DEB_PANGO_V   ?= $(PANGO_VERSION)

pango-setup: setup
	wget -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/pango/1.50/pango-$(PANGO_VERSION).tar.xz
	$(call EXTRACT_TAR,pango-$(PANGO_VERSION).tar.xz,pango-$(PANGO_VERSION),pango)
	$(call DO_PATCH,pango,pango,-p1)
	mkdir -p $(BUILD_WORK)/pango/build
	echo -e "[host_machine]\n \
	system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/pango/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/pango/.build_complete),)
pango:
	@echo "Using previously built pango."
else
pango: pango-setup cairo fontconfig freetype libfribidi libxft glib2.0 harfbuzz
	cd $(BUILD_WORK)/pango/build && meson \
		--cross-file cross.txt \
		-Dcairo=enabled \
		-Dfontconfig=enabled \
		-Dfreetype=enabled \
		-Dxft=enabled \
		-Dintrospection=disabled \
		-Ddefault_library=both \
		..
	+ninja -C $(BUILD_WORK)/pango/build
	+DESTDIR="$(BUILD_STAGE)/pango" ninja -C $(BUILD_WORK)/pango/build install
	+DESTDIR="$(BUILD_BASE)" ninja -C $(BUILD_WORK)/pango/build install
	$(call AFTER_BUILD)
endif

pango-package: pango-stage
	# pango.mk Package Structure
	rm -rf $(BUILD_DIST)/libpango{,cairo,ft2,xft}-1.0-0
	rm -rf $(BUILD_DIST)/libpango1.0-{0,dev}
	rm -rf $(BUILD_DIST)/pango1.0-tools
	mkdir -p $(BUILD_DIST)/libpango{,cairo,ft2,xft}-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libpango1.0-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/pango1.0-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pango.mk Prep libpangocairo-1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpangocairo-1.0.0.dylib $(BUILD_DIST)/libpangocairo-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpangoft2-1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpangoft2-1.0.0.dylib $(BUILD_DIST)/libpangoft2-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpangoxft-1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpangoxft-1.0.0.dylib $(BUILD_DIST)/libpangoxft-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpango1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpango-1.0.0.dylib $(BUILD_DIST)/libpango1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpango1.0-dev
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpango1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libpango{,cairo,ft2,xft}-1.0.dylib,pkgconfig} $(BUILD_DIST)/libpango1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep pango1.0-tools
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/pango1.0-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pango.mk Sign
	$(call SIGN,libpangocairo-1.0-0,general.xml)
	$(call SIGN,libpangoft2-1.0-0,general.xml)
	$(call SIGN,libpangoxft-1.0-0,general.xml)
	$(call SIGN,libpango1.0-0,general.xml)
	$(call SIGN,pango1.0-tools,general.xml)

	# pango.mk Make .debs
	$(call PACK,libpangocairo-1.0-0,DEB_PANGO_V)
	$(call PACK,libpangoft2-1.0-0,DEB_PANGO_V)
	$(call PACK,libpangoxft-1.0-0,DEB_PANGO_V)
	$(call PACK,libpango1.0-0,DEB_PANGO_V)
	$(call PACK,libpango1.0-dev,DEB_PANGO_V)
	$(call PACK,pango1.0-tools,DEB_PANGO_V)

	# pango.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpango{,cairo,ft2,xft}-1.0-0
	rm -rf $(BUILD_DIST)/libpango1.0-{0,dev}
	rm -rf $(BUILD_DIST)/pango1.0-tools

.PHONY: pango pango-package
