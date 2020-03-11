ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

APT_DIR := $(PWD)/apt

ifneq ($(wildcard $(BUILD_WORK)/apt/.build_complete),)
apt:
	@echo "Using previously built apt."
else
apt: 
	mkdir -p $(BUILD_WORK)/apt
	cd $(BUILD_WORK)/apt && echo -e "set(CMAKE_SYSTEM_NAME Darwin)  # Tell CMake we're cross-compiling\nset(CMAKE_CROSSCOMPILING true)\n#include(CMakeForceCompiler)\nset(CMAKE_SYSTEM_PROCESSOR $(ARCH))\nset(triple $(GNU_HOST_TRIPLE))\nset(CMAKE_FIND_ROOT_PATH /)\nset(CMAKE_LIBRARY_PATH )\nset(CMAKE_INCLUDE_PATH )\nset(CMAKE_C_COMPILER $(TRIPLE)clang)\nset(CMAKE_CXX_COMPILER $(TRIPLE)clang++)\nset(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)\nset(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)\nset(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)\n">> iphoneos_toolchain.cmake
	cd $(BUILD_WORK)/apt && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_TOOLCHAIN_FILE=iphoneos_toolchain.cmake \
		-DSTATE_DIR=/var/lib/apt \
		-DCACHE_DIR=/var/cache/apt \
		-DLOG_DIR=/var/log/apt \
		-DCONF_DIR=/etc/apt \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS) -DENABLE_SILEO=1" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS) -DENABLE_SILEO=1" \
		-DCMAKE_SHARED_LINKER_FLAGS="-lresolv -L$(BUILD_BASE)/usr/lib" \
		-DLZ4_INCLUDE_DIRS=$(BUILD_BASE)/include \
		-DLZ4_LIBRARIES=$(BUILD_BASE)/usr/lib/liblz4.dylib \
		-DLZMA_INCLUDE_DIRS=$(BUILD_BASE)/include \
		-DLZMA_LIBRARIES=$(BUILD_BASE)/usr/local/lib/liblzma.dylib \
		-DBERKELEY_DB_LIBRARIES=$(BUILD_BASE)/usr/lib/libdb.dylib \
		-DBERKELEY_DB_INCLUDE_DIRS=$(BUILD_BASE)/usr/include \
		-DCURRENT_VENDOR=debian \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DUSE_NLS=0 \
		-DWITH_DOC=0 \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DDPKG_DATADIR=/usr/share/dpkg \
		$(APT_DIR)
	$(MAKE) -C $(BUILD_WORK)/apt/build
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/apt/build install \
		DESTDIR="$(BUILD_STAGE)/apt"
	touch $(BUILD_WORK)/apt/.build_complete
endif

.PHONY: apt apt-stage
