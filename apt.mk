ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += apt
APT_VERSION   := 2.3.5
DEB_APT_V     ?= $(APT_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1500 ] && echo 1),1)
APT_CMAKE_ARGS := -DHAVE_PTSNAME_R=0
else
APT_CMAKE_ARGS :=
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
APT_CMAKE_ARGS += -DUSE_IOSEXEC=true
endif

apt-setup: setup
	# Change this to a git release download sometime.
	wget -q -nc -P $(BUILD_SOURCE) https://salsa.debian.org/apt-team/apt/-/archive/$(APT_VERSION)/apt-$(APT_VERSION).tar.bz2
	$(call EXTRACT_TAR,apt-$(APT_VERSION).tar.bz2,apt-$(APT_VERSION),apt)
	$(call DO_PATCH,apt,apt,-p1)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,apt-macos,apt,-p1)
else
	$(SED) -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_WORK)/apt/apt-pkg/contrib/fileutl.h
endif
	if [ -f "$(BUILD_WORK)/apt/apt-private/private-output.cc" ]; then \
		mv -f $(BUILD_WORK)/apt/apt-private/private-output.{cc,mm}; \
	fi
	if [ -f "$(BUILD_WORK)/apt/apt-pkg/algorithms.cc" ]; then \
		mv -f $(BUILD_WORK)/apt/apt-pkg/algorithms.{cc,mm}; \
	fi
	cp $(BUILD_WORK)/apt/apt-pkg/memrchr.cc $(BUILD_WORK)/apt/ftparchive
	mkdir -p $(BUILD_WORK)/apt/build

ifneq ($(wildcard $(BUILD_WORK)/apt/.build_complete),)
apt:
	@echo "Using previously built apt."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
apt: apt-setup libgcrypt berkeleydb lz4 xxhash xz zstd gnutls
else
apt: apt-setup libgcrypt berkeleydb lz4 xxhash xz zstd gnutls libiosexec
endif
	cd $(BUILD_WORK)/apt/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DSTATE_DIR=$(MEMO_PREFIX)/var/lib/apt \
		-DCACHE_DIR=$(MEMO_PREFIX)/var/cache/apt \
		-DLOG_DIR=$(MEMO_PREFIX)/var/log/apt \
		-DCONF_DIR=$(MEMO_PREFIX)/etc/apt \
		-DROOT_GROUP=wheel \
		-DCURRENT_VENDOR=procursus \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DUSE_NLS=0 \
		-DWITH_DOC=0 \
		-DWITH_TESTS=0 \
		-DDOCBOOK_XSL=$(DOCBOOK_XSL) \
		-DDPKG_DATADIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dpkg \
		-DBERKELEY_INCLUDE_DIRS="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181" \
		$(APT_CMAKE_ARGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/apt/build
	+$(MAKE) -C $(BUILD_WORK)/apt/build install \
		DESTDIR="$(BUILD_STAGE)/apt"
	+$(MAKE) -C $(BUILD_WORK)/apt/build install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/apt/.build_complete
endif

apt-package: apt-stage
	# apt.mk Package Structure
	rm -rf $(BUILD_DIST)/apt{,-utils} $(BUILD_DIST)/libapt*/
	mkdir -p $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,libexec/apt/{planners,solvers}} \
	$(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/man,bin,libexec/apt/{planners,solvers}} \
	$(BUILD_DIST)/libapt-pkg{6.0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# apt.mk Prep apt
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/apt{,-cache,-cdrom,-config,-get,-key,-mark} $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libapt-private*.dylib $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/dpkg $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/{methods,apt-helper} $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/planners/dump $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/planners
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/solvers/dump $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/solvers
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)/{etc,var} $(BUILD_DIST)/apt/$(MEMO_PREFIX)
	rm -f $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/*/man1/apt-{extracttemplates,ftparchive,sortpkgs}.1
	rm -f $(BUILD_DIST)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/apt-{extracttemplates,ftparchive,sortpkgs}.1

	# apt.mk Prep apt-utils
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/apt-{extracttemplates,ftparchive,sortpkgs} $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/planners/apt $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/planners
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/solvers/apt $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/apt/solvers
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	rm -rf $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{5,7,8}
	rm -rf $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion
	for i in $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/!(man1); do \
		rm -rf $$i/man{5,7,8}; \
	done
	rm -f $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/!(man1)/man1/apt-transport*.1
	rm -f $(BUILD_DIST)/apt-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/apt-transport*.1

	# apt.mk Prep libapt-pkg6.0
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libapt-pkg.6.0*.dylib $(BUILD_DIST)/libapt-pkg6.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# apt.mk Prep libapt-pkg-dev
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libapt-pkg.dylib $(BUILD_DIST)/libapt-pkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libapt-pkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/apt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libapt-pkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# apt.mk Sign
	$(call SIGN,apt,general.xml)
	$(call SIGN,apt-utils,general.xml)
	$(call SIGN,libapt-pkg6.0,general.xml)

	# apt.mk Make .debs
	$(call PACK,apt,DEB_APT_V)
	$(call PACK,apt-utils,DEB_APT_V)
	$(call PACK,libapt-pkg6.0,DEB_APT_V)
	$(call PACK,libapt-pkg-dev,DEB_APT_V)

	# apt.mk Build cleanup
	rm -rf $(BUILD_DIST)/apt{,-utils} $(BUILD_DIST)/libapt*/

.PHONY: apt apt-package
