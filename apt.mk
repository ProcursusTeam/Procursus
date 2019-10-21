ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

apt:
	mkdir -p apt/build
	cd apt/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
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
		..
	sed -i -- s/'#define COMMON_ARCH \"darwin-amd64\"'/'#define COMMON_ARCH \"$(DEB_ARCH)\"'/ apt/build/include/config.h
	$(MAKE) -C apt/build
	$(FAKEROOT) $(MAKE) -C apt/build install DESTDIR="$(DESTDIR)"

.PHONY: apt
