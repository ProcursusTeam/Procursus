ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

APT_DIR     := $(BUILD_ROOT)/apt
APT_VERSION := 2.0.0
DEB_APT_V   ?= $(APT_VERSION)

ifneq ($(wildcard $(APT_DIR)/build/.build_complete),)
apt:
	@echo "Using previously built apt."
else
apt: setup libgcrypt berkeleydb lz4 xz zstd
	mkdir -p $(APT_DIR)/build
	cd $(APT_DIR)/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
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
		-DCURRENT_VENDOR=debian \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DUSE_NLS=0 \
		-DWITH_DOC=0 \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DDPKG_DATADIR=/usr/share/dpkg \
		$(APT_DIR)
	$(MAKE) -C $(APT_DIR)/build
	$(FAKEROOT) $(MAKE) -C $(APT_DIR)/build install \
		DESTDIR="$(BUILD_STAGE)/apt"
	touch $(APT_DIR)/build/.build_complete
endif

apt-stage: apt
	# apt.mk Package Structure
	rm -rf $(BUILD_DIST)/apt{,-utils,-dev}
	mkdir -p $(BUILD_DIST)/apt/usr/{bin,lib,libexec/apt/{planners,solvers}}
	mkdir -p $(BUILD_DIST)/apt-utils/usr/{bin,libexec/apt/{planners,solvers}}
	mkdir -p $(BUILD_DIST)/apt-dev/usr/lib
	
	# apt.mk Prep APT
	cp -a $(BUILD_STAGE)/apt/usr/bin/apt{,-cache,-cdrom,-config,-get,-key,-mark} $(BUILD_DIST)/apt/usr/bin
	cp -a $(BUILD_STAGE)/apt/usr/lib/*dylib $(BUILD_DIST)/apt/usr/lib
	cp -a $(BUILD_STAGE)/apt/usr/libexec/dpkg $(BUILD_DIST)/apt/usr/libexec
	cp -a $(BUILD_STAGE)/apt/usr/libexec/apt/{methods,apt-helper} $(BUILD_DIST)/apt/usr/libexec/apt
	cp -a $(BUILD_STAGE)/apt/usr/libexec/apt/planners/dump $(BUILD_DIST)/apt/usr/libexec/apt/planners
	cp -a $(BUILD_STAGE)/apt/usr/libexec/apt/solvers/dump $(BUILD_DIST)/apt/usr/libexec/apt/solvers
	cp -a $(BUILD_STAGE)/apt/usr/share $(BUILD_DIST)/apt/usr
	
	# apt.mk Prep APT-Utils
	cp -a $(BUILD_STAGE)/apt/usr/bin/apt-{extracttemplates,ftparchive,sortpkgs} $(BUILD_DIST)/apt-utils/usr/bin
	cp -a $(BUILD_STAGE)/apt/usr/libexec/apt/planners/apt $(BUILD_DIST)/apt-utils/usr/libexec/apt/planners
	cp -a $(BUILD_STAGE)/apt/usr/libexec/apt/solvers/apt $(BUILD_DIST)/apt-utils/usr/libexec/apt/solvers
	
	# apt.mk Prep APT-Dev
	cp -a $(BUILD_STAGE)/apt/usr/lib/pkgconfig $(BUILD_DIST)/apt-dev/usr/lib
	cp -a $(BUILD_STAGE)/apt/usr/include $(BUILD_DIST)/apt-dev/usr
	
	#apt.mk Sign
	$(call SIGN,apt,general.xml)
	$(call SIGN,apt-utils,general.xml)
	
	# apt.mk Make .debs
	$(call PACK,apt,DEB_APT_V)
	$(call PACK,apt-utils,DEB_APT_V)
	$(call PACK,apt-dev,DEB_APT_V)
	
	# apt.mk Build cleanup
	#rm -rf $(BUILD_DIST)/apt{,-utils,-dev}

.PHONY: apt apt-stage
