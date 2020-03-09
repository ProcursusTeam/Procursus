ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

APT_DIR := $(PWD)/apt

apt:
	mkdir -p $(BUILD_WORK)/apt/build
	cd $(BUILD_WORK)/apt/build && cmake . \
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

.PHONY: apt apt-stage
