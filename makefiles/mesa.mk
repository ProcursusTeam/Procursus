ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mesa
MESA_VERSION := 21.0.2
DEB_MESA_V   ?= $(MESA_VERSION)

mesa-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mesa.freedesktop.org/archive/mesa-$(MESA_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,mesa-$(MESA_VERSION).tar.xz)
	$(call EXTRACT_TAR,mesa-$(MESA_VERSION).tar.xz,mesa-$(MESA_VERSION),mesa)
	$(SED) -i -e "s/with_dri_platform = 'apple'/with_dri_platform = 'none'/" \
		-e "/dep_xcb_shm = dependency('xcb-shm')/a dep_xxf86vm = dependency('xxf86vm')" $(BUILD_WORK)/mesa/meson.build
	$(SED) -i "s|OpenGL/gl.h|GL/gl.h|" $(BUILD_WORK)/mesa/src/mesa/main/texcompress_s3tc_tmp.h
	mkdir -p $(BUILD_WORK)/mesa/build

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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/mesa/build/cross.txt

	@echo "You need to install Mako with pip3 before building."
	@echo "/usr/bin/pip3 install mako --user"

### TODO: Let's do a Zink driver using MoltenVK sometime!

ifneq ($(wildcard $(BUILD_WORK)/mesa/.build_complete),)
mesa:
	@echo "Using previously built mesa."
else
mesa: mesa-setup libx11 libxext libxcb libxdamage libxxf86vm gettext expat zstd
	cd $(BUILD_WORK)/mesa/build && meson \
		--cross-file cross.txt \
		-Dbuildtype=release \
		-Db_ndebug=true \
		-Dplatforms=x11 \
		-Dglx=gallium-xlib \
		-Dgallium-drivers=swrast \
		-Dosmesa=true \
		-Dgles1=disabled \
		..
#		-Dglx=dri
	cd $(BUILD_WORK)/mesa/build; \
		DESTDIR="$(BUILD_STAGE)/mesa" meson install; \
		DESTDIR="$(BUILD_BASE)" meson install
	touch $(BUILD_WORK)/mesa/.build_complete
endif

mesa-package: mesa-stage
	# mesa.mk Package Structure
	rm -rf $(BUILD_DIST)/libgl1-mesa-{glx,dri,dev} $(BUILD_DIST)/libgles2-mesa{,-dev} \
		$(BUILD_DIST)/libglapi-mesa $(BUILD_DIST)/mesa-common-dev
	mkdir -p $(BUILD_DIST)/libgl1-mesa-glx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgl1-mesa-dri/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgl1-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig \
		$(BUILD_DIST)/libgles2-mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgles2-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig} \
		$(BUILD_DIST)/libglapi-mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/mesa-common-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig}

	# mesa.mk Prep libgl1-mesa-glx
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGL.1.dylib $(BUILD_DIST)/libgl1-mesa-glx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mesa.mk Prep libgl1-mesa-dri
#	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/dri $(BUILD_DIST)/libgl1-mesa-dri/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libgl1-mesa-dri/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# mesa.mk Prep libgl1-mesa-dev
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGL.dylib $(BUILD_DIST)/libgl1-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/gl.pc $(BUILD_DIST)/libgl1-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# mesa.mk Prep libgles2-mesa
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGLESv2.2.dylib $(BUILD_DIST)/libgles2-mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mesa.mk Prep libgles2-mesa-dev
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGLESv2.dylib $(BUILD_DIST)/libgles2-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/glesv2.pc $(BUILD_DIST)/libgles2-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/GLES{2,3} $(BUILD_DIST)/libgles2-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# mesa.mk Prep libglapi-mesa
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libglapi.0.dylib $(BUILD_DIST)/libglapi-mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mesa.mk Prep mesa-common-dev
	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{GL,KHR} $(BUILD_DIST)/mesa-common-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
#	cp -a $(BUILD_STAGE)/mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/dri.pc $(BUILD_DIST)/mesa-common-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# mesa.mk Sign
	$(call SIGN,libgl1-mesa-glx,general.xml)
#	$(call SIGN,libgl1-mesa-dri,general.xml)
	$(call SIGN,libgles2-mesa,general.xml)
	$(call SIGN,libglapi-mesa,general.xml)

	# mesa.mk Make .debs
	$(call PACK,libgl1-mesa-glx,DEB_MESA_V)
#	$(call PACK,libgl1-mesa-dri,DEB_MESA_V)
	$(call PACK,libgl1-mesa-dev,DEB_MESA_V)
	$(call PACK,libgles2-mesa,DEB_MESA_V)
	$(call PACK,libgles2-mesa-dev,DEB_MESA_V)
	$(call PACK,libglapi-mesa,DEB_MESA_V)
	$(call PACK,mesa-common-dev,DEB_MESA_V)

	# mesa.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgl1-mesa-{glx,dri,dev} $(BUILD_DIST)/libgles2-mesa{,-dev} \
		$(BUILD_DIST)/libglapi-mesa $(BUILD_DIST)/mesa-common-dev

.PHONY: mesa mesa-package
