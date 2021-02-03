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

ifneq ($(wildcard $(BUILD_WORK)/mesa/.build_complete),)
mesa:
	@echo "Using previously built mesa."
else
mesa: mesa-setup libx11 libxext libxcb libxdamage libxxf86vm gettext expat
	cd $(BUILD_WORK)/mesa/build && PKG_CONFIG="pkg-config" meson \
		--cross-file cross.txt \
		-Diconv=auto \
		-Dbsymbolic_functions=false \
		-Ddtrace=false \
		-Db_ndebug=true \
		-Ddri-drivers=swrast \
		-Dgallium-drivers= \
		-Dplatforms=x11 \
		..
	cd $(BUILD_WORK)/mesa/build; \
		DESTDIR="$(BUILD_STAGE)/mesa" meson install; \
		DESTDIR="$(BUILD_BASE)" meson install
	touch $(BUILD_WORK)/mesa/.build_complete
endif


.PHONY: mesa mesa-package
