ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += apt
APT_VERSION   := 2.1.7
DEB_APT_V     ?= $(APT_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1500 ] && echo 1),1)
APT_CMAKE_ARGS += -DHAVE_PTSNAME_R=0
endif

apt-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/a/apt/apt_$(APT_VERSION).tar.xz
	$(call EXTRACT_TAR,apt_$(APT_VERSION).tar.xz,apt-$(APT_VERSION),apt)
	$(call DO_PATCH,apt,apt,-p1)
	mkdir -p $(BUILD_WORK)/apt/build
	rm -rf $(BUILD_WORK)/apt/apt-private/private-output.cc \
		$(BUILD_WORK)/apt/apt-pkg/algorithms.cc

ifneq ($(wildcard $(BUILD_WORK)/apt/.build_complete),)
apt:
	@echo "Using previously built apt."
else
apt: apt-setup libgcrypt berkeleydb lz4 xz zstd
	cd $(BUILD_WORK)/apt/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
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
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_SHARED_LINKER_FLAGS="-lresolv -L$(BUILD_BASE)/usr/lib" \
		-DCURRENT_VENDOR=debian \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DUSE_NLS=0 \
		-DWITH_DOC=0 \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DDPKG_DATADIR=/usr/share/dpkg \
		$(APT_CMAKE_ARGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/apt/build
	+$(MAKE) -C $(BUILD_WORK)/apt/build install \
		DESTDIR="$(BUILD_STAGE)/apt"
	touch $(BUILD_WORK)/apt/.build_complete
endif

apt-package: apt-stage
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
	cp -a $(BUILD_STAGE)/apt/{etc,var} $(BUILD_DIST)/apt
	rm -f $(BUILD_DIST)/apt/usr/lib/libapt-pkg.dylib
	
	# apt.mk Prep APT-Utils
	cp -a $(BUILD_STAGE)/apt/usr/bin/apt-{extracttemplates,ftparchive,sortpkgs} $(BUILD_DIST)/apt-utils/usr/bin
	cp -a $(BUILD_STAGE)/apt/usr/libexec/apt/planners/apt $(BUILD_DIST)/apt-utils/usr/libexec/apt/planners
	cp -a $(BUILD_STAGE)/apt/usr/libexec/apt/solvers/apt $(BUILD_DIST)/apt-utils/usr/libexec/apt/solvers
	
	# apt.mk Prep APT-Dev
	cp -a $(BUILD_STAGE)/apt/usr/lib/libapt-pkg.dylib $(BUILD_DIST)/apt-dev/usr/lib
	cp -a $(BUILD_STAGE)/apt/usr/lib/pkgconfig $(BUILD_DIST)/apt-dev/usr/lib
	cp -a $(BUILD_STAGE)/apt/usr/include $(BUILD_DIST)/apt-dev/usr
	
	# apt.mk Sign
	$(call SIGN,apt,general.xml)
	$(call SIGN,apt-utils,general.xml)
	
	# apt.mk Make .debs
	$(call PACK,apt,DEB_APT_V)
	$(call PACK,apt-utils,DEB_APT_V)
	$(call PACK,apt-dev,DEB_APT_V)
	
	# apt.mk Build cleanup
	rm -rf $(BUILD_DIST)/apt{,-utils,-dev}

.PHONY: apt apt-package
