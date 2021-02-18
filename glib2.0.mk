ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += glib2.0
GLIB2.0_MAJOR_V := 2.67
GLIB2.0_VERSION := $(GLIB2.0_MAJOR_V).2
DEB_GLIB2.0_V   ?= $(GLIB2.0_VERSION)

glib2.0-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnome.org/pub/gnome/sources/glib/$(GLIB2.0_MAJOR_V)/glib-$(GLIB2.0_VERSION).tar.xz
	$(call EXTRACT_TAR,glib-$(GLIB2.0_VERSION).tar.xz,glib-$(GLIB2.0_VERSION),glib2.0)
	mkdir -p $(BUILD_WORK)/glib2.0/build

	echo -e "[host_machine]\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	system = 'darwin'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='/usr'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/glib2.0/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/glib2.0/.build_complete),)
glib2.0:
	@echo "Using previously built glib2.0."
else
glib2.0: glib2.0-setup gettext pcre libffi
	cd $(BUILD_WORK)/glib2.0/build && PKG_CONFIG="pkg-config" meson \
		--cross-file cross.txt \
		-Diconv=auto \
		-Dbsymbolic_functions=false \
		-Ddtrace=false \
		..
	cd $(BUILD_WORK)/glib2.0/build; \
		DESTDIR="$(BUILD_STAGE)/glib2.0" meson install; \
		DESTDIR="$(BUILD_BASE)" meson install
	touch $(BUILD_WORK)/glib2.0/.build_complete
endif

glib2.0-package: glib2.0-stage
	# glib2.0.mk Package Structure
	rm -rf $(BUILD_DIST)/libglib2.0-{0,bin,dev{,-bin}}
	mkdir -p $(BUILD_DIST)/libglib2.0-0/usr/{lib,share} \
		$(BUILD_DIST)/libglib2.0-dev/usr/{lib,share/glib-2.0} \
		$(BUILD_DIST)/libglib2.0-bin/usr/{bin,share} \
		$(BUILD_DIST)/libglib2.0-dev-bin/usr/{bin,share/glib-2.0}
	
	# glib2.0.mk Prep libglib2.0-0
	cp -a $(BUILD_STAGE)/glib2.0/usr/lib/*2.0.0.dylib $(BUILD_DIST)/libglib2.0-0/usr/lib
	cp -a $(BUILD_STAGE)/glib2.0/usr/share/locale $(BUILD_DIST)/libglib2.0-0/usr/share
	
	# glib2.0.mk Prep libglib2.0-dev
	cp -a $(BUILD_STAGE)/glib2.0/usr/include $(BUILD_DIST)/libglib2.0-dev/usr
	cp -a $(BUILD_STAGE)/glib2.0/usr/lib/!(*2.0.0*) $(BUILD_DIST)/libglib2.0-dev/usr/lib
	cp -a $(BUILD_STAGE)/glib2.0/usr/share/{gdb,gettext} $(BUILD_DIST)/libglib2.0-dev/usr/share
	cp -a $(BUILD_STAGE)/glib2.0/usr/share/glib-2.0/{gdb,schemas,valgrind} $(BUILD_DIST)/libglib2.0-dev/usr/share/glib-2.0

	# glib2.0.mk Prep libglib2.0-bin
	cp -a $(BUILD_STAGE)/glib2.0/usr/bin/{gapplication,gdbus,gio,gresource,gsettings} $(BUILD_DIST)/libglib2.0-bin/usr/bin
	cp -a $(BUILD_STAGE)/glib2.0/usr/share/bash-completion $(BUILD_DIST)/libglib2.0-bin/usr/share

	# glib2.0.mk Prep libglib2.0-dev-bin
	cp -a $(BUILD_STAGE)/glib2.0/usr/bin/{gdbus-codegen,glib-{compile-resources,genmarshal,gettextize,mkenums},gobject-query,gtester{,-report}} $(BUILD_DIST)/libglib2.0-dev-bin/usr/bin
	cp -a $(BUILD_STAGE)/glib2.0/usr/share/aclocal $(BUILD_DIST)/libglib2.0-dev-bin/usr/share
	cp -a $(BUILD_STAGE)/glib2.0/usr/share/glib-2.0/{codegen,gettext} $(BUILD_DIST)/libglib2.0-dev-bin/usr/share/glib-2.0
	
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
