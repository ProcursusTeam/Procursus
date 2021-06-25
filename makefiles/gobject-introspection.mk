ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS                  += gobject-introspection
GOBJECT-INTROSPECTION_VERSION := 1.68.0
DEB_GOBJECT-INTROSPECTION_V   ?= $(GOBJECT-INTROSPECTION_VERSION)

#### This will currently only build for the system you're building on.
# You need libffi-dev, libglib2.0-dev, libpython3.9-dev

gobject-introspection-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.gnome.org/sources/gobject-introspection/$(shell echo $(GOBJECT-INTROSPECTION_VERSION) | cut -f-2 -d.)/gobject-introspection-$(GOBJECT-INTROSPECTION_VERSION).tar.xz
	$(call EXTRACT_TAR,gobject-introspection-$(GOBJECT-INTROSPECTION_VERSION).tar.xz,gobject-introspection-$(GOBJECT-INTROSPECTION_VERSION),gobject-introspection)
	mkdir -p $(BUILD_WORK)/gobject-introspection/build

	echo -e "[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	[binaries]\n \
	pkgconfig = '$(shell which pkg-config)'\n" > $(BUILD_WORK)/gobject-introspection/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/gobject-introspection/.build_complete),)
gobject-introspection:
	@echo "Using previously built gobject-introspection."
else
gobject-introspection: gobject-introspection-setup glib2.0 libffi python3
	$(SED) -i 's|/usr/share|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share|g' $(BUILD_WORK)/gobject-introspection/giscanner/transformer.py
	$(SED) -i -e "s|extra_giscanner_cflags = \[]|extra_giscanner_cflags = ['$(PLATFORM_VERSION_MIN)']|" \
		-e "s|extra_giscanner_args = \[]|extra_giscanner_args = ['--cflags-begin'] + extra_giscanner_cflags + ['--cflags-end']|" $(BUILD_WORK)/gobject-introspection/meson.build
	export GI_SCANNER_DISABLE_CACHE=true; \
	cd $(BUILD_WORK)/gobject-introspection/build && meson \
		--cross-file cross.txt \
		-Dpython="$(shell which python3)" \
		..; \
	cd $(BUILD_WORK)/gobject-introspection/build; \
		DESTDIR="$(BUILD_STAGE)/gobject-introspection" meson install; \
		DESTDIR="$(BUILD_BASE)" meson install
	$(SED) -i "s|$$(cat $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/g-ir-scanner | grep \#! | sed 's/#!//')|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3|" $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	touch $(BUILD_WORK)/gobject-introspection/.build_complete
endif

gobject-introspection-package: gobject-introspection-stage
	# gobject-introspection.mk Package Structure
	rm -rf $(BUILD_DIST)/libgirepository-1.0-{1,dev} $(BUILD_DIST)/gobject-introspection $(BUILD_DIST)/gir1.2-{freedesktop,glib-2.0}
	mkdir -p $(BUILD_DIST)/libgirepository-1.0-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgirepository-1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share} \
		$(BUILD_DIST)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share} \
		$(BUILD_DIST)/gir1.2-{freedesktop,glib-2.0}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0

	# gobject-introspection.mk Prep libgirepository-1.0-1
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgirepository-1.0.1.dylib $(BUILD_DIST)/libgirepository-1.0-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gobject-introspection.mk Prep libgirepository-1.0-dev
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgirepository-1.0.dylib,pkgconfig} $(BUILD_DIST)/libgirepository-1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgirepository-1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gir-1.0 $(BUILD_DIST)/libgirepository-1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gobject-introspection.mk Prep gobject-introspection
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gobject-introspection $(BUILD_DIST)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/!(gir-1.0) $(BUILD_DIST)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gobject-introspection.mk Prep gir1.2-glib-2.0
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/{GIRepository,GLib,GModule,GObject,Gio}-2.0.typelib $(BUILD_DIST)/gir1.2-glib-2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0

	# gobject-introspection.mk Prep gir1.2-freedesktop
	cp -a $(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/cairo-1.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/DBus-1.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/DBusGLib-1.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/fontconfig-2.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/freetype2-2.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/GL-1.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/libxml2-2.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/Vulkan-1.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/xfixes-4.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/xft-2.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/xlib-2.0.typelib \
		$(BUILD_STAGE)/gobject-introspection/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0/xrandr-1.3.typelib $(BUILD_DIST)/gir1.2-freedesktop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/girepository-1.0

	# gobject-introspection.mk Sign
	$(call SIGN,libgirepository-1.0-1,general.xml)
	$(call SIGN,gobject-introspection,general.xml)

	# gobject-introspection.mk Make .debs
	$(call PACK,libgirepository-1.0-1,DEB_GOBJECT-INTROSPECTION_V)
	$(call PACK,libgirepository-1.0-dev,DEB_GOBJECT-INTROSPECTION_V)
	$(call PACK,gobject-introspection,DEB_GOBJECT-INTROSPECTION_V)
	$(call PACK,gir1.2-glib-2.0,DEB_GOBJECT-INTROSPECTION_V)
	$(call PACK,gir1.2-freedesktop,DEB_GOBJECT-INTROSPECTION_V)

	# gobject-introspection.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgirepository-1.0-{1,dev} $(BUILD_DIST)/gobject-introspection $(BUILD_DIST)/gir1.2-{freedesktop,glib-2.0}

.PHONY: gobject-introspection gobject-introspection-package
