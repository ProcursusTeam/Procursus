ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += wayland
WAYLAND_VERSION := 1.20.0
DEB_WAYLAND_V   ?= $(WAYLAND_VERSION)

wayland-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://wayland.freedesktop.org/releases/wayland-$(WAYLAND_VERSION).tar.xz
	$(call EXTRACT_TAR,wayland-$(WAYLAND_VERSION).tar.xz,wayland-$(WAYLAND_VERSION),wayland)
	$(call DO_PATCH,wayland,wayland,-p1)
	mkdir -p $(BUILD_WORK)/wayland/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/wayland/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/wayland/.build_complete),)
wayland:
	@echo "Using previously built wayland."
else
wayland: wayland-setup epoll-shim expat libffi
	cd $(BUILD_WORK)/wayland/build && meson \
		--cross-file cross.txt \
		-Dtests=false \
		-Ddocumentation=false \
		..
	+ninja -C $(BUILD_WORK)/wayland/build
	+ninja -C $(BUILD_WORK)/wayland/build install \
		DESTDIR="$(BUILD_STAGE)/wayland"
	$(call AFTER_BUILD)
endif

wayland-package: wayland-stage
	# wayland.mk Package Structure
	rm -rf $(BUILD_DIST)/libwayland-{bin,client0,cursor0,{,egl-backend-}dev,egl1,server0}
	mkdir -p $(BUILD_DIST)/libwayland-{bin,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wayland
	mkdir -p $(BUILD_DIST)/libwayland-{,egl-backend-}dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig}
	mkdir -p $(BUILD_DIST)/libwayland-{client0,cursor0,egl1,server0}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# wayland.mk Prep libwayland-bin
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libwayland-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal $(BUILD_DIST)/libwayland-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wayland/wayland-scanner.mk $(BUILD_DIST)/libwayland-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wayland

	# wayland.mk Prep libwayland-client0
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwayland-client.0.dylib $(BUILD_DIST)/libwayland-client0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# wayland.mk Prep libwayland-cursor0
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwayland-cursor.0.dylib $(BUILD_DIST)/libwayland-cursor0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# wayland.mk Prep libwayland-egl1
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwayland-egl.1.dylib $(BUILD_DIST)/libwayland-egl1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# wayland.mk Prep libwayland-server0
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwayland-server.0.dylib $(BUILD_DIST)/libwayland-server0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# wayland.mk Prep libwayland-dev
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/wayland-{client{,-core,-protocol},cursor,egl{,-core},server{,-core,-protocol},util,version}.h $(BUILD_DIST)/libwayland-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwayland-{client,cursor,egl,server}.dylib $(BUILD_DIST)/libwayland-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/wayland-{client,cursor,egl,scanner,server}.pc $(BUILD_DIST)/libwayland-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wayland/wayland.{dtd,xml} $(BUILD_DIST)/libwayland-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wayland

	# wayland.mk Prep libwayland-egl-backend-dev
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/wayland-egl-backend.h $(BUILD_DIST)/libwayland-egl-backend-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/wayland/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/wayland-egl-backend.pc $(BUILD_DIST)/libwayland-egl-backend-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# wayland.mk Sign
	$(call SIGN,libwayland-bin,general.xml)
	$(call SIGN,libwayland-client0,general.xml)
	$(call SIGN,libwayland-cursor0,general.xml)
	$(call SIGN,libwayland-egl1,general.xml)
	$(call SIGN,libwayland-server0,general.xml)

	# wayland.mk Make .debs
	$(call PACK,libwayland-bin,DEB_WAYLAND_V)
	$(call PACK,libwayland-client0,DEB_WAYLAND_V)
	$(call PACK,libwayland-cursor0,DEB_WAYLAND_V)
	$(call PACK,libwayland-egl1,DEB_WAYLAND_V)
	$(call PACK,libwayland-server0,DEB_WAYLAND_V)
	$(call PACK,libwayland-dev,DEB_WAYLAND_V)
	$(call PACK,libwayland-egl-backend-dev,DEB_WAYLAND_V)

	# wayland.mk Build cleanup
	rm -rf $(BUILD_DIST)/libwayland-{bin,client0,cursor0,{,egl-backend-}dev,egl1,server0}

.PHONY: wayland wayland-package
