ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

APT_DIR     := $(BUILD_ROOT)/apt
APT_VERSION := 2.0.0

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
	@# TODO Need to ldid this stuff... I'll do it in the morning.
	# apt.mk Package Structure
	rm -rf $(BUILD_DIST)/apt{,-utils,-dev}
	mkdir -p $(BUILD_DIST)/apt/usr/{bin,lib,libexec/apt/{planners,solvers}}
	mkdir -p $(BUILD_DIST)/apt-utils/usr/{bin,libexec/apt/{planners,solvers}}
	mkdir -p $(BUILD_DIST)/apt-dev/usr/lib
	
	# apt.mk Prep APT
	cp -ar $(BUILD_STAGE)/apt/usr/bin/apt{,-cache,-cdrom,-config,-get,-key,-mark} $(BUILD_DIST)/apt/usr/bin
	cp -ar $(BUILD_STAGE)/apt/usr/lib/*dylib $(BUILD_DIST)/apt/usr/lib
	cp -ar $(BUILD_STAGE)/apt/usr/libexec/dpkg $(BUILD_DIST)/apt/usr/libexec
	cp -ar $(BUILD_STAGE)/apt/usr/libexec/apt/{methods,apt-helper} $(BUILD_DIST)/apt/usr/libexec/apt
	cp -ar $(BUILD_STAGE)/apt/usr/libexec/apt/planners/dump $(BUILD_DIST)/apt/usr/libexec/apt/planners
	cp -ar $(BUILD_STAGE)/apt/usr/libexec/apt/solvers/dump $(BUILD_DIST)/apt/usr/libexec/apt/solvers
	cp -ar $(BUILD_STAGE)/apt/usr/share $(BUILD_DIST)/apt/usr
	
	# apt.mk Prep APT-Utils
	cp -ar $(BUILD_STAGE)/apt/usr/bin/apt-{extracttemplates,ftparchive,sortpkgs} $(BUILD_DIST)/apt-utils/usr/bin
	cp -ar $(BUILD_STAGE)/apt/usr/libexec/apt/planners/apt $(BUILD_DIST)/apt-utils/usr/libexec/apt/planners
	cp -ar $(BUILD_STAGE)/apt/usr/libexec/apt/solvers/apt $(BUILD_DIST)/apt-utils/usr/libexec/apt/solvers
	
	# apt.mk Prep APT-Dev
	cp -ar $(BUILD_STAGE)/apt/usr/lib/pkgconfig $(BUILD_DIST)/apt-dev/usr/lib
	cp -ar $(BUILD_STAGE)/apt/usr/include $(BUILD_DIST)/apt-dev/usr
	
	# apt.mk Make .debs
	mkdir -p $(BUILD_DIST)/apt{,-dev,-utils}/DEBIAN
	cp $(BUILD_INFO)/apt.control $(BUILD_DIST)/apt/DEBIAN/control
	cp $(BUILD_INFO)/apt-utils.control $(BUILD_DIST)/apt-utils/DEBIAN/control
	cp $(BUILD_INFO)/apt-dev.control $(BUILD_DIST)/apt-dev/DEBIAN/control
	$(SED) -i ':a; s/$$APT_VERSION/$(APT_VERSION)/g; ta' $(BUILD_DIST)/apt{,-dev,-utils}/DEBIAN/control
	$(SED) -i ':a; s/$$DEB_MAINTAINER/$(DEB_MAINTAINER)/g; ta' $(BUILD_DIST)/apt{,-dev,-utils}/DEBIAN/control
	$(SED) -i ':a; s/$$DEB_ARCH/$(DEB_ARCH)/g; ta' $(BUILD_DIST)/apt{,-dev,-utils}/DEBIAN/control
	$(DPKG_DEB) -b $(BUILD_DIST)/apt $(BUILD_DIST)/apt_$(APT_VERSION)_$(DEB_ARCH).deb
	$(DPKG_DEB) -b $(BUILD_DIST)/apt-utils $(BUILD_DIST)/apt-utils_$(APT_VERSION)_$(DEB_ARCH).deb
	$(DPKG_DEB) -b $(BUILD_DIST)/apt-dev $(BUILD_DIST)/apt-dev_$(APT_VERSION)_$(DEB_ARCH).deb
	
	# apt.mk Build cleanup
	rm -rf $(BUILD_DIST)/apt{,-utils,-dev}

.PHONY: apt apt-stage
