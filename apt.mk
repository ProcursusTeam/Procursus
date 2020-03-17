ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

APT_DIR := $(PWD)/apt

ifneq ($(wildcard $(APT_DIR)/build/.build_complete),)
apt:
	@echo "Using previously built apt."
else
apt: setup berkeleydb bzip2 dpkg gnutls lz4 xz
	mkdir -p $(APT_DIR)/build
	rm -f $(APT_DIR)/build/iphoneos_toolchain.cmake
	cd $(APT_DIR)/build && echo -e "#set(CMAKE_BUILD_TYPE Release)\nset(CMAKE_SYSTEM_NAME Darwin)\nset(CMAKE_CROSSCOMPILING true)\n#include(CMakeForceCompiler)\nset(CMAKE_SYSTEM_PROCESSOR $(ARCH))\nset(triple $(GNU_HOST_TRIPLE))\nset(CMAKE_FIND_ROOT_PATH $(BUILD_BASE) $(SYSROOT))\nset(CMAKE_LIBRARY_PATH $(BUILD_BASE)/lib $(SYSROOT)/lib)\nset(CMAKE_INCLUDE_PATH $(BUILD_BASE)/include $(SYSROOT)/include)\nset(CMAKE_C_COMPILER $(CC))\nset(CMAKE_CXX_COMPILER $(CXX))\nset(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)\nset(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)\nset(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)\nset(DPKG_DATADIR /usr/share/dpkg)\nset(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG ")\nset(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG ")\n">> iphoneos_toolchain.cmake
	cd $(APT_DIR)/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_TOOLCHAIN_FILE=iphoneos_toolchain.cmake \
		-DSTATE_DIR=/var/lib/apt \
		-DCACHE_DIR=/var/cache/apt \
		-DLOG_DIR=/var/log/apt \
		-DCONF_DIR=/etc/apt \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_SHARED_LINKER_FLAGS="-lresolv -L$(BUILD_BASE)/usr/lib" \
		-DLZ4_INCLUDE_DIRS=$(BUILD_BASE)/include \
		-DLZ4_LIBRARIES=$(BUILD_BASE)/usr/lib/liblz4.dylib \
		-DLZMA_INCLUDE_DIRS=$(BUILD_BASE)/include \
		-DLZMA_LIBRARIES=$(BUILD_BASE)/usr/local/lib/liblzma.dylib \
		-DBERKELEY_DB_INCLUDE_DIRS=$(BUILD_BASE)/usr/include \
		-DBERKELEY_DB_LIBRARIES=$(BUILD_BASE)/usr/lib/libdb.dylib \
		-DGNUTLS_INCLUDE_DIR=$(BUILD_BASE)/usr/include \
		-DGNUTLS_LIBRARY=$(BUILD_BASE)/usr/lib/libgnutls.dylib \
		-DGCRYPT_INCLUDE_DIRS=$(BUILD_BASE)/usr/include \
		-DGCRYPT_LIBRARIES=$(BUILD_BASE)/usr/lib/libgcrypt.dylib \
		-DCURRENT_VENDOR=debian \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DUSE_NLS=0 \
		-DWITH_DOC=0 \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DDPKG_DATADIR=/usr/share/dpkg \
		$(APT_DIR)
	$(MAKE) -C $(APT_DIR)/build VERBOSE=1
	$(FAKEROOT) $(MAKE) -C $(APT_DIR)/build install \
		DESTDIR="$(BUILD_STAGE)/apt"
	touch $(APT_DIR)/build/.build_complete
endif

.PHONY: apt apt-stage
