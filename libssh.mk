ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libssh
LIBSSH_VERSION := 0.9.5
DEB_LIBSSH_V   ?= $(LIBSSH_VERSION)

libssh-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.libssh.org/files/0.9/libssh-0.9.5.tar.xz
	$(call EXTRACT_TAR,libssh-$(LIBSSH_VERSION).tar.xz,libssh-$(LIBSSH_VERSION),libssh)
	mkdir -p $(BUILD_WORK)/libssh/build

ifneq ($(wildcard $(BUILD_WORK)/libssh/.build_complete),)
libssh:
	@echo "Using previously built libssh."
else
libssh: libssh-setup openssl
	cd $(BUILD_WORK)/libssh/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_STATIC_LIB=ON \
		-DUNIT_TESTING=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/libssh/build
	+$(MAKE) -C $(BUILD_WORK)/libssh/build install \
		DESTDIR="$(BUILD_STAGE)/libssh"
	+$(MAKE) -C $(BUILD_WORK)/libssh/build install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libssh/.build_complete
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
