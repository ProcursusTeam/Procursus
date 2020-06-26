ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += libzip
LIBZIP_VERSION       := 1.7.0
DEB_LIBZIP_V         ?= $(LIBZIP_VERSION)

libzip-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://libzip.org/download/libzip-$(LIBZIP_VERSION).tar.gz
	$(call EXTRACT_TAR,libzip-$(LIBZIP_VERSION).tar.gz,libzip-$(LIBZIP_VERSION),libzip)

ifneq ($(wildcard $(BUILD_WORK)/libzip/.build_complete),)
libzip:
	@echo "Using previously built libzip."
else
libzip: libzip-setup
	cd $(BUILD_WORK)/libzip && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) 
	+$(MAKE) -C $(BUILD_WORK)/libzip
	+$(MAKE) -C $(BUILD_WORK)/libzip install \
		DESTDIR="$(BUILD_STAGE)/libzip"
	touch $(BUILD_WORK)/libzip/.build_complete
endif

libzip-package: libzip-stage
	# libzip.mk Package Structure
	rm -rf $(BUILD_DIST)/nano
	mkdir -p $(BUILD_DIST)/nano

	# libzip.mk Prep libzip
	cp -a $(BUILD_STAGE)/libzip/usr $(BUILD_DIST)/libzip

	# libzip.mk Sign
	$(call SIGN,libzip,general.xml)

	# libzip.mk Make .debs
	$(call PACK,libzip,DEB_LIBZIP_V)

	# libzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/nano

.PHONY: libzip libzip-package