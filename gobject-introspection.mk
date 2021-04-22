ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += gobject-introspection
GOBJECT-INTROSPECTION_VERSION := 1.68.0
DEB_GOBJECT-INTROSPECTION_V   ?= $(GOBJECT-INTROSPECTION_VERSION)

gobject-introspection-setup: setup bison glib2.0
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/gobject-introspection/1.68/gobject-introspection-1.68.0.tar.xz
	$(call EXTRACT_TAR,gobject-introspection-$(GOBJECT-INTROSPECTION_VERSION).tar.xz,gobject-introspection-$(GOBJECT-INTROSPECTION_VERSION),gobject-introspection)
	mkdir -p $(BUILD_WORK)/gobject-introspection/build
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
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/gobject-introspection/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/gobject-introspection/.build_complete),)
gobject-introspection:
	@echo "Using previously built gobject-introspection."
else
gobject-introspection: gobject-introspection-setup libx11 mesa
	cd $(BUILD_WORK)/gobject-introspection/build && PKG_CONFIG="pkg-config" meson \
		--cross-file cross.txt \
		-Dbuild_introspection_data=true \
		-Dgi_cross_use_prebuilt_gi=true \
		..
	+ninja -C $(BUILD_WORK)/gobject-introspection/build
	+DESTDIR="$(BUILD_STAGE)/gobject-introspection" ninja -C $(BUILD_WORK)/gobject-introspection/build install
	+DESTDIR="$(BUILD_BASE)" ninja -C $(BUILD_WORK)/gobject-introspection/build install
	touch $(BUILD_WORK)/gobject-introspection/.build_complete
endif

gobject-introspection-package: gobject-introspection-stage
	# gobject-introspection.mk Package Structure
	rm -rf $(BUILD_DIST)/gobject-introspection
	mkdir -p $(BUILD_DIST)/gobject-introspection
	
	# gobject-introspection.mk Prep gobject-introspection
	cp -a $(BUILD_STAGE)/gobject-introspection $(BUILD_DIST)
	
	# gobject-introspection.mk Sign
	$(call SIGN,gobject-introspection,general.xml)
	
	# gobject-introspection.mk Make .debs
	$(call PACK,gobject-introspection,DEB_GOBJECT-INTROSPECTION_V)
	
	# gobject-introspection.mk Build cleanup
	rm -rf $(BUILD_DIST)/gobject-introspection

.PHONY: gobject-introspection gobject-introspection-package

