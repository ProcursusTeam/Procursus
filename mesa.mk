ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mesa
MESA_VERSION := 20.3.4
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
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/mesa/build/cross.txt

	@echo "You need to install Mako with pip3 before building."
	@echo "/usr/bin/pip3 install mako --user"

ifneq ($(wildcard $(BUILD_WORK)/mesa/.build_complete),)
mesa:
	@echo "Using previously built mesa."
else
mesa: mesa-setup libx11 libxext libxcb libxdamage libxxf86vm gettext expat zstd
	cd $(BUILD_WORK)/mesa/build && PKG_CONFIG="pkg-config" meson \
		--cross-file cross.txt \
		-Diconv=auto \
		-Dbsymbolic_functions=false \
		-Ddtrace=false \
		-Db_ndebug=true \
		-Ddri-drivers=swrast \
		-Dgallium-drivers= \
		-Dplatforms=x11 \
		-Dgles1=disabled \
		..
	cd $(BUILD_WORK)/mesa/build; \
		DESTDIR="$(BUILD_STAGE)/mesa" meson install; \
		DESTDIR="$(BUILD_BASE)" meson install
	touch $(BUILD_WORK)/mesa/.build_complete
endif

mesa-package: mesa-stage
	# mesa.mk Package Structure
	rm -rf $(BUILD_DIST)/libgl1-mesa-{glx,dri,dev} $(BUILD_DIST)/libgles2-mesa{,-dev} \
		$(BUILD_DIST)/libglapi-mesa $(BUILD_DIST)/mesa-common-dev
	mkdir -p $(BUILD_DIST)/libgl1-mesa-glx/usr/lib \
		$(BUILD_DIST)/libgl1-mesa-dri/usr/lib \
		$(BUILD_DIST)/libgl1-mesa-dev/usr/lib/pkgconfig \
		$(BUILD_DIST)/libgles2-mesa/usr/lib \
		$(BUILD_DIST)/libgles2-mesa-dev/usr/{include,lib/pkgconfig} \
		$(BUILD_DIST)/libglapi-mesa/usr/lib \
		$(BUILD_DIST)/mesa-common-dev/usr/{include,lib/pkgconfig}
	
	# mesa.mk Prep libgl1-mesa-glx
	cp -a $(BUILD_STAGE)/mesa/usr/lib/libGL.1.dylib $(BUILD_DIST)/libgl1-mesa-glx/usr/lib

	# mesa.mk Prep libgl1-mesa-dri
	cp -a $(BUILD_STAGE)/mesa/usr/lib/dri $(BUILD_DIST)/libgl1-mesa-dri/usr/lib
	cp -a $(BUILD_STAGE)/mesa/usr/share $(BUILD_DIST)/libgl1-mesa-dri/usr

	# mesa.mk Prep libgl1-mesa-dev
	cp -a $(BUILD_STAGE)/mesa/usr/lib/libGL.dylib $(BUILD_DIST)/libgl1-mesa-dri/usr/lib
	cp -a $(BUILD_STAGE)/mesa/usr/lib/pkgconfig/gl.pc $(BUILD_DIST)/libgl1-mesa-dri/usr/lib/pkgconfig

	# mesa.mk Prep libgles2-mesa
	cp -a $(BUILD_STAGE)/mesa/usr/lib/libGLESv2.2.dylib $(BUILD_DIST)/libgles2-mesa/usr/lib

	# mesa.mk Prep libgles2-mesa-dev
	cp -a $(BUILD_STAGE)/mesa/usr/lib/libGLESv2.dylib $(BUILD_DIST)/libgles2-mesa-dev/usr/lib
	cp -a $(BUILD_STAGE)/mesa/usr/lib/pkgconfig/glesv2.pc $(BUILD_DIST)/libgles2-mesa-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/mesa/usr/include/GLES{2,3} $(BUILD_DIST)/libgles2-mesa-dev/usr/include

	# mesa.mk Prep libglapi-mesa
	cp -a $(BUILD_STAGE)/mesa/usr/lib/libglapi.0.dylib $(BUILD_DIST)/libglapi-mesa/usr/lib

	# mesa.mk Prep mesa-common-dev
	cp -a $(BUILD_STAGE)/mesa/usr/include/{GL,KHR} $(BUILD_DIST)/mesa-common-dev/usr/include
	cp -a $(BUILD_STAGE)/mesa/usr/lib/pkgconfig/dri.pc $(BUILD_DIST)/mesa-common-dev/usr/lib/pkgconfig
	
	# mesa.mk Sign
	$(call SIGN,libgl1-mesa-glx,general.xml)
	$(call SIGN,libgl1-mesa-dri,general.xml)
	$(call SIGN,libgles2-mesa,general.xml)
	$(call SIGN,libglapi-mesa,general.xml)
	
	# mesa.mk Make .debs
	$(call PACK,libgl1-mesa-glx,DEB_MESA_V)
	$(call PACK,libgl1-mesa-dri,DEB_MESA_V)
	$(call PACK,libgl1-mesa-dev,DEB_MESA_V)
	$(call PACK,libgles2-mesa,DEB_MESA_V)
	$(call PACK,libgles2-mesa-dev,DEB_MESA_V)
	$(call PACK,libglapi-mesa,DEB_MESA_V)
	$(call PACK,mesa-common-dev,DEB_MESA_V)
	
	# mesa.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgl1-mesa-{glx,dri,dev} $(BUILD_DIST)/libgles2-mesa{,-dev} \
		$(BUILD_DIST)/libglapi-mesa  $(BUILD_DIST)/mesa-common-dev

.PHONY: mesa mesa-package
