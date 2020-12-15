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
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
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
	mkdir -p $(BUILD_DIST)/libssh-{4,dev}/usr/lib
	
	# libssh.mk Prep libssh-4
	cp -a $(BUILD_STAGE)/libssh/usr/lib/libssh.4*.dylib $(BUILD_DIST)/libssh-4/usr/lib
	
	# libssh.mk Prep liblibssh-dev
	cp -a $(BUILD_STAGE)/libssh/usr/lib/{libssh.dylib,pkgconfig,cmake} $(BUILD_DIST)/libssh-dev/usr/lib
	cp -a $(BUILD_STAGE)/libssh/usr/include $(BUILD_DIST)/libssh-dev/usr
	
	# libssh.mk Sign
	$(call SIGN,libssh-4,general.xml)
	
	# libssh.mk Make .debs
	$(call PACK,libssh-4,DEB_LIBSSH_V)
	$(call PACK,libssh-dev,DEB_LIBSSH_V)
	
	# libssh.mk Build cleanup
	rm -rf $(BUILD_DIST)/libssh-{4,dev}

.PHONY: libssh libssh-package
