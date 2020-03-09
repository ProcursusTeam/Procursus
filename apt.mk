ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

apt: setup dpkg berkeleydb gnupg
	mkdir -p apt-build
	cd apt-build && echo -e "set(CMAKE_SYSTEM_NAME Darwin)  # Tell CMake we're cross-compiling\nset(CMAKE_CROSSCOMPILING true)\n#include(CMakeForceCompiler)\nset(CMAKE_SYSTEM_PROCESSOR $(ARCH))\nset(triple $(GNU_HOST_TRIPLE))\nset(CMAKE_FIND_ROOT_PATH /)\nset(CMAKE_LIBRARY_PATH )\nset(CMAKE_INCLUDE_PATH )\nset(CMAKE_C_COMPILER $(TRIPLE)clang)\nset(CMAKE_CXX_COMPILER $(TRIPLE)clang++)\nset(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)\nset(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)\nset(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)\n">> iphoneos_toolchain.cmake
	cd apt-build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_TOOLCHAIN_FILE=iphoneos_toolchain.cmake \
		-DSTATE_DIR=/var/lib/apt \
		-DCACHE_DIR=/var/cache/apt \
		-DLOG_DIR=/var/log/apt \
		-DCONF_DIR=/etc/apt \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(SYSROOT)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_SHARED_LINKER_FLAGS="-lresolv -L$(PWD)/dist/usr/lib/" \
		-DLZ4_INCLUDE_DIRS=$(PWD)/dist/usr/include \
		-DLZ4_LIBRARIES=$(PWD)/dist/usr/lib/liblz4.dylib \
		-DLZMA_INCLUDE_DIRS=$(PWD)/dist/usr/include \
		-DLZMA_LIBRARIES=$(PWD)/dist/usr/lib/liblzma.dylib \
		-DCURRENT_VENDOR=debian \
		-DUSE_NLS=0 \
		-DWITH_DOC=0 \
		-DCMAKE_FIND_ROOT_PATH=$(PWD)/dist \
		-DDPKG_DATADIR=/usr/share/dpkg \
		../apt
	sed -i -- s/'#define COMMON_ARCH \"darwin-amd64\"'/'#define COMMON_ARCH \"$(DEB_ARCH)\"'/ apt/build/include/config.h
	$(MAKE) -C apt/build
	$(FAKEROOT) $(MAKE) -C apt/build install DESTDIR="$(DESTDIR)"

.PHONY: apt
