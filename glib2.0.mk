ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += glib2.0
GLIB2.0_MAJOR_V := 2.68
GLIB2.0_VERSION := $(GLIB2.0_MAJOR_V).2
DEB_GLIB2.0_V   ?= $(GLIB2.0_VERSION)-1

glib2.0-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnome.org/pub/gnome/sources/glib/$(GLIB2.0_MAJOR_V)/glib-$(GLIB2.0_VERSION).tar.xz
	$(call EXTRACT_TAR,glib-$(GLIB2.0_VERSION).tar.xz,glib-$(GLIB2.0_VERSION),glib2.0)
	$(call DO_PATCH,glib2.0,glib2.0,-p1)
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_WORK)/glib2.0/{gio/xdgmime/xdgmime.c,glib/gutils.c}
	mkdir -p $(BUILD_WORK)/glib2.0/build

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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/glib2.0/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/glib2.0/.build_complete),)
glib2.0:
	@echo "Using previously built glib2.0."
else
glib2.0: glib2.0-setup gettext pcre libffi
	cd $(BUILD_WORK)/glib2.0/build && meson \
		--cross-file cross.txt \
		-Diconv=auto \
		-Dbsymbolic_functions=false \
		-Ddtrace=false \
		..
	sed -i '/HAVE_LIBELF/d' $(BUILD_WORK)/glib2.0/build/config.h
	cd $(BUILD_WORK)/glib2.0/build; \
		DESTDIR="$(BUILD_STAGE)/glib2.0" meson install; \
		DESTDIR="$(BUILD_BASE)" meson install
	$(SED) -i 's/, zlib//;s/\(Libs\.private:.*\)/\1 -lz/' \
		$(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/gio-2.0.pc \
		$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/gio-2.0.pc
	touch $(BUILD_WORK)/glib2.0/.build_complete
endif

glib2.0-package: glib2.0-stage
	# glib2.0.mk Package Structure
	rm -rf $(BUILD_DIST)/libglib2.0-{0,bin,dev{,-bin}}
	mkdir -p $(BUILD_DIST)/libglib2.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share} \
		$(BUILD_DIST)/libglib2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/glib-2.0} \
		$(BUILD_DIST)/libglib2.0-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} \
		$(BUILD_DIST)/libglib2.0-dev-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/glib-2.0}

	# glib2.0.mk Prep libglib2.0-0
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/*2.0.0.dylib $(BUILD_DIST)/libglib2.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libglib2.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# glib2.0.mk Prep libglib2.0-dev
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libglib2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*2.0.0*) $(BUILD_DIST)/libglib2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{gdb,gettext} $(BUILD_DIST)/libglib2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/glib-2.0/{gdb,schemas,valgrind} $(BUILD_DIST)/libglib2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/glib-2.0

	# glib2.0.mk Prep libglib2.0-bin
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{gdbus,gio,gresource,gsettings,glib-compile-schemas} $(BUILD_DIST)/libglib2.0-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion $(BUILD_DIST)/libglib2.0-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# glib2.0.mk Prep libglib2.0-dev-bin
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{gdbus-codegen,glib-{compile-resources,genmarshal,gettextize,mkenums},gobject-query,gtester{,-report}} $(BUILD_DIST)/libglib2.0-dev-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal $(BUILD_DIST)/libglib2.0-dev-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/glib2.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/glib-2.0/{codegen,gettext} $(BUILD_DIST)/libglib2.0-dev-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/glib-2.0

	# glib2.0.mk Sign
	$(call SIGN,libglib2.0-0,general.xml)
	$(call SIGN,libglib2.0-bin,general.xml)
	$(call SIGN,libglib2.0-dev-bin,general.xml)

	# glib2.0.mk Make .debs
	$(call PACK,libglib2.0-0,DEB_GLIB2.0_V)
	$(call PACK,libglib2.0-dev,DEB_GLIB2.0_V)
	$(call PACK,libglib2.0-bin,DEB_GLIB2.0_V)
	$(call PACK,libglib2.0-dev-bin,DEB_GLIB2.0_V)

	# glib2.0.mk Build cleanup
	rm -rf $(BUILD_DIST)/libglib2.0-{0,bin,dev{,-bin}}

.PHONY: glib2.0 glib2.0-package
