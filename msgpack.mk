ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += msgpack
MSGPACK_VERSION := 3.3.0
DEB_MSGPACK_V   ?= $(MSGPACK_VERSION)

msgpack-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/msgpack/msgpack-c/releases/download/cpp-3.3.0/msgpack-$(MSGPACK_VERSION).tar.gz
	$(call EXTRACT_TAR,msgpack-$(MSGPACK_VERSION).tar.gz,msgpack-$(MSGPACK_VERSION),msgpack)

ifneq ($(wildcard $(BUILD_WORK)/msgpack/.build_complete),)
msgpack:
	@echo "Using previously built msgpack."
else
msgpack: msgpack-setup
	cd $(BUILD_WORK)/msgpack && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DMSGPACK_BUILD_TESTS=OFF \
		-DMSGPACK_ENABLE_CXX=ON
	+$(MAKE) -C $(BUILD_WORK)/msgpack
	+$(MAKE) -C $(BUILD_WORK)/msgpack install \
		DESTDIR="$(BUILD_STAGE)/msgpack"
	+$(MAKE) -C $(BUILD_WORK)/msgpack install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/msgpack/.build_complete
endif

msgpack-package: msgpack-stage
	# msgpack.mk Package Structure
	rm -rf $(BUILD_DIST)/libmsgpack{-dev,c2}
	mkdir -p $(BUILD_DIST)/libmsgpack{-dev,c2}/usr/lib
	
	# msgpack.mk Prep libmsgpack-dev
	cp -a $(BUILD_STAGE)/msgpack/usr/include/ $(BUILD_DIST)/libmsgpack-dev/usr
	cp -a $(BUILD_STAGE)/msgpack/usr/lib/{libmsgpackc.{a,dylib},pkgconfig,cmake} $(BUILD_DIST)/libmsgpack-dev/usr/lib
	
	# msgpack.mk Prep libmsgpackc2
	cp -a $(BUILD_STAGE)/msgpack/usr/lib/libmsgpackc.2*.dylib $(BUILD_DIST)/libmsgpackc2/usr/lib
	
	# msgpack.mk Sign
	$(call SIGN,libmsgpackc2,general.xml)
	
	# msgpack.mk Make .debs
	$(call PACK,libmsgpack-dev,DEB_MSGPACK_V)
	$(call PACK,libmsgpackc2,DEB_MSGPACK_V)
	
	# msgpack.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmsgpack{-dev,c2}

.PHONY: msgpack msgpack-package
