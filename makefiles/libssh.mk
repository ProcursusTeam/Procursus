ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += libssh
LIBSSH_VERSION          := 0.10.6
ARGP-STANDALONE_VERSION := 1.0.2
DEB_LIBSSH_V            ?= $(LIBSSH_VERSION)

libssh-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.libssh.org/files/0.10/libssh-$(LIBSSH_VERSION).tar.xz)
	$(call GITHUB_ARCHIVE,tom42,argp-standalone,$(ARGP-STANDALONE_VERSION),v$(ARGP-STANDALONE_VERSION))
	$(call EXTRACT_TAR,libssh-$(LIBSSH_VERSION).tar.xz,libssh-$(LIBSSH_VERSION),libssh)
	$(call EXTRACT_TAR,argp-standalone-$(ARGP-STANDALONE_VERSION).tar.gz,argp-standalone-$(ARGP-STANDALONE_VERSION),libssh/argp-standalone)
	sed -i 's|return "";|return getprogname();|g' $(BUILD_WORK)/libssh/argp-standalone/src/argp-help.c
	mkdir -p $(BUILD_WORK)/libssh/{,argp-standalone}/build

ifneq ($(wildcard $(BUILD_WORK)/libssh/.build_complete),)
libssh:
	@echo "Using previously built libssh."
else
libssh: libssh-setup openssl
	cd $(BUILD_WORK)/libssh/argp-standalone/build && cmake .. \
		$(DEFAULT_CMAKE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libssh/argp-standalone/build
	cd $(BUILD_WORK)/libssh/build && cmake .. \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_STATIC_LIB=ON \
		-DUNIT_TESTING=OFF \
		-DOPENSSL_ROOT_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		-DARGP_LIBRARIES="$(BUILD_WORK)/libssh/argp-standalone/build/src/libargp-standalone.a" \
		-DARGP_INCLUDE_DIR="$(BUILD_WORK)/libssh/argp-standalone/include/argp-standalone"
	+$(MAKE) -C $(BUILD_WORK)/libssh/build
	+$(MAKE) -C $(BUILD_WORK)/libssh/build install \
		DESTDIR="$(BUILD_STAGE)/libssh"
	$(call AFTER_BUILD,copy)
endif

libssh-package: libssh-stage
	# libssh.mk Package Structure
	rm -rf $(BUILD_DIST)/libssh-{4,dev}
	mkdir -p $(BUILD_DIST)/libssh-{4,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libssh.mk Prep libssh-4
	cp -a $(BUILD_STAGE)/libssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libssh.4*.dylib $(BUILD_DIST)/libssh-4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libssh.mk Prep liblibssh-dev
	cp -a $(BUILD_STAGE)/libssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libssh.dylib,pkgconfig,cmake} $(BUILD_DIST)/libssh-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libssh-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libssh.mk Sign
	$(call SIGN,libssh-4,general.xml)

	# libssh.mk Make .debs
	$(call PACK,libssh-4,DEB_LIBSSH_V)
	$(call PACK,libssh-dev,DEB_LIBSSH_V)

	# libssh.mk Build cleanup
	rm -rf $(BUILD_DIST)/libssh-{4,dev}

.PHONY: libssh libssh-package
