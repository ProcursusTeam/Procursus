ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libsnappy
LIBSNAPPY_VERSION := 1.1.8
DEB_LIBSNAPPY_V   ?= $(LIBSNAPPY_VERSION)

libsnappy-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libsnappy-$(LIBSNAPPY_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/libsnappy-$(LIBSNAPPY_VERSION).tar.gz \
			https://github.com/google/snappy/archive/$(LIBSNAPPY_VERSION).tar.gz
	$(call EXTRACT_TAR,libsnappy-$(LIBSNAPPY_VERSION).tar.gz,snappy-$(LIBSNAPPY_VERSION),libsnappy)
	$(call DO_PATCH,libsnappy,libsnappy,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libsnappy/.build_complete),)
libsnappy:
	@echo "Using previously built libsnappy."
else
libsnappy: libsnappy-setup
	cd $(BUILD_WORK)/libsnappy && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DBUILD_SHARED_LIBS=true \
		-DSNAPPY_BUILD_TESTS=false
	+$(MAKE) -C $(BUILD_WORK)/libsnappy all
	+$(MAKE) -C $(BUILD_WORK)/libsnappy install \
		DESTDIR="$(BUILD_STAGE)/libsnappy"
	+$(MAKE) -C $(BUILD_WORK)/libsnappy install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libsnappy/.build_complete
endif

libsnappy-package: libsnappy-stage
	# libsnappy.mk Package Structure
	rm -rf $(BUILD_DIST)/libsnappy{1v5,-dev}
	mkdir -p $(BUILD_DIST)/libsnappy{1v5,-dev}/usr/lib

	# libsnappy.mk Prep libsnappy-dev
	cp -a $(BUILD_STAGE)/libsnappy/usr/lib/{libsnappy.{a,dylib},cmake,pkgconfig} $(BUILD_DIST)/libsnappy-dev/usr/lib
	cp -a $(BUILD_STAGE)/libsnappy/usr/include $(BUILD_DIST)/libsnappy-dev/usr

	# libsnappy.mk Prep libsnappy1v5
	cp -a $(BUILD_STAGE)/libsnappy/usr/lib/libsnappy.*.dylib $(BUILD_DIST)/libsnappy1v5/usr/lib


	# libsnappy.mk Sign
	$(call SIGN,libsnappy1v5,general.xml)
	$(call SIGN,libsnappy-dev,general.xml)


	# libsnappy.mk Make .debs
	$(call PACK,libsnappy1v5,DEB_LIBSNAPPY_V)
	$(call PACK,libsnappy-dev,DEB_LIBSNAPPY_V)

	# libsnappy.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsnappy{1v5,-dev}

.PHONY: libsnappy libsnappy-package