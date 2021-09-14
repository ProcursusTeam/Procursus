ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pango
PANGO_VERSION := 1.49.1
DEB_PANGO_V   ?= $(PANGO_VERSION)

pango-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.gnome.org/sources/pango/$(shell echo $(PANGO_VERSION) | cut -f-2 -d.)/pango-$(PANGO_VERSION).tar.xz
	$(call EXTRACT_TAR,pango-$(PANGO_VERSION).tar.xz,pango-$(PANGO_VERSION),pango)
	$(call DO_PATCH,pango,pango,-p1)
	mkdir -p $(BUILD_WORK)/pango/build
	echo -e "[host_machine]\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	system = 'darwin'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	needs_exe_wrapper = true\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	objc = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/pango/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/pango/.build_complete),)
pango:
	@echo "Using previously built pango."
else
pango: pango-setup glib2.0 libffi python3 harfbuzz fontconfig libfribidi cairo libxft
	cd $(BUILD_WORK)/pango/build && meson \
		--cross-file cross.txt \
		-Dintrospection=disabled \
		..
	+ninja -C $(BUILD_WORK)/pango/build
	+DESTDIR="$(BUILD_STAGE)/pango" ninja -C $(BUILD_WORK)/pango/build install
	+DESTDIR="$(BUILD_BASE)" ninja -C $(BUILD_WORK)/pango/build install
	$(call AFTER_BUILD)
endif

pango-package: pango-stage
	# pango.mk Package Structure
	rm -rf $(BUILD_DIST)/{pango1.0-tools,libpango{1.0-0,cairo-1.0-0,ft2-1.0-0,xft-1.0-0}}
	mkdir -p $(BUILD_DIST)/pango1.0-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	$(BUILD_DIST)/libpango{1.0-0,cairo-1.0-0,ft2-1.0-0,xft-1.0-0}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
	$(BUILD_DIST)/libpango1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include}

	# pango.mk Prep pango1.0-tools
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/pango1.0-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# pango.mk Prep libpango1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpango-1.0.0.dylib $(BUILD_DIST)/libpango1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpangocario-1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpangocairo-1.0.0.dylib $(BUILD_DIST)/libpangocairo-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpangoft2-1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpangoft2-1.0.0.dylib $(BUILD_DIST)/libpangoft2-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpangoxft-1.0-0
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpangoxft-1.0.0.dylib $(BUILD_DIST)/libpangoxft-1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pango.mk Prep libpango1.0-dev
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*1.0.0*) $(BUILD_DIST)/libpango1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/pango/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpango1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# pango.mk Sign
	$(call SIGN,pango1.0-tools,general.xml)
	$(call SIGN,libpango1.0-0,general.xml)
	$(call SIGN,libpangocairo-1.0-0,general.xml)
	$(call SIGN,libpangoft2-1.0-0,general.xml)
	$(call SIGN,libpangoxft-1.0-0,general.xml)

	# pango.mk Make .debs
	$(call PACK,pango1.0-tools,DEB_PANGO_V)
	$(call PACK,libpango1.0-0,DEB_PANGO_V)
	$(call PACK,libpangocairo-1.0-0,DEB_PANGO_V)
	$(call PACK,libpangoft2-1.0-0,DEB_PANGO_V)
	$(call PACK,libpangoxft-1.0-0,DEB_PANGO_V)
	$(call PACK,libpango1.0-dev,DEB_PANGO_V)

	# pango.mk Build cleanup
	rm -rf $(BUILD_DIST)/{pango1.0-tools,libpango{1.0-0,cairo-1.0-0,ft2-1.0-0,xft-1.0-0,1.0-dev}}

.PHONY: pango pango-package
