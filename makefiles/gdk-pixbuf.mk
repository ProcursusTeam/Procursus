ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += gdk-pixbuf
GDK-PIXBUF_VERSION := 2.42.6
DEB_GDK-PIXBUF_V   ?= $(GDK-PIXBUF_VERSION)

gdk-pixbuf-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mirror.umd.edu/gnome/sources/gdk-pixbuf/$(shell echo $(GOBJECT-INTROSPECTION_VERSION) | cut -f-2 -d.)/gdk-pixbuf-$(GDK-PIXBUF_VERSION).tar.xz
	$(call EXTRACT_TAR,gdk-pixbuf-$(GDK-PIXBUF_VERSION).tar.xz,gdk-pixbuf-$(GDK-PIXBUF_VERSION),gdk-pixbuf)
	mkdir -p $(BUILD_WORK)/gdk-pixbuf/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/gdk-pixbuf/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/gdk-pixbuf/.build_complete),)
gdk-pixbuf:
	@echo "Using previously built gdk-pixbuf."
else
gdk-pixbuf: gdk-pixbuf-setup glib2.0 libpng16 gettext libtiff libjpeg-turbo
	cd $(BUILD_WORK)/gdk-pixbuf/build && \
	PKG_CONFIG="pkg-config" meson \
		--cross-file cross.txt \
		--wrap-mode=nofallback \
    	-Ddocs=false \
    	-Dintrospection=disabled \
		..
	ninja -C $(BUILD_WORK)/gdk-pixbuf/build
	+DESTDIR="$(BUILD_STAGE)/gdk-pixbuf" ninja -C $(BUILD_WORK)/gdk-pixbuf/build install
	$(call AFTER_BUILD,copy)
endif

gdk-pixbuf-package: gdk-pixbuf-stage
	# gdk-pixbuf.mk Package Structure
	rm -rf $(BUILD_DIST)/libgdk-pixbuf-2.0-{0,dev} $(BUILD_DIST)/libgdk-pixbuf2.0-{bin,common}
	mkdir -p $(BUILD_DIST)/libgdk-pixbuf-2.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgdk-pixbuf-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include} \
		$(BUILD_DIST)/libgdk-pixbuf2.0-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libgdk-pixbuf2.0-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gdk-pixbuf.mk libgdk-pixbuf-2.0-0
	cp -a $(BUILD_STAGE)/gdk-pixbuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(pkgconfig|libgdk_pixbuf-2.0.dylib) \
		$(BUILD_DIST)/libgdk-pixbuf-2.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gdk-pixbuf.mk Prep libgdk-pixbuf-2.0-dev
	cp -a $(BUILD_STAGE)/gdk-pixbuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libgdk_pixbuf-2.0.0.dylib|gdk-pixbuf-2.0) \
		$(BUILD_DIST)/libgdk-pixbuf-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gdk-pixbuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/gdk-pixbuf-2.0 \
		$(BUILD_DIST)/libgdk-pixbuf-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# gdk-pixbuf.mk Prep libgdk-pixbuf2.0-bin
	cp -a $(BUILD_STAGE)/gdk-pixbuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libgdk-pixbuf2.0-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# gdk-pixbuf.mk Prep libgdk-pixbuf2.0-common
	cp -a $(BUILD_STAGE)/gdk-pixbuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale \
		$(BUILD_DIST)/libgdk-pixbuf2.0-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gdk-pixbuf.mk Sign
	$(call SIGN,libgdk-pixbuf-2.0-0,general.xml)
	$(call SIGN,libgdk-pixbuf2.0-bin,general.xml)

	# gdk-pixbuf.mk Make .debs
	$(call PACK,libgdk-pixbuf-2.0-0,DEB_GDK-PIXBUF_V)
	$(call PACK,libgdk-pixbuf-2.0-dev,DEB_GDK-PIXBUF_V)
	$(call PACK,libgdk-pixbuf2.0-bin,DEB_GDK-PIXBUF_V)
	$(call PACK,libgdk-pixbuf2.0-common,DEB_GDK-PIXBUF_V)

	# gdk-pixbuf.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgdk-pixbuf-2.0-{0,dev} $(BUILD_DIST)/libgdk-pixbuf2.0-{bin,common}

.PHONY: gdk-pixbuf gdk-pixbuf-package
