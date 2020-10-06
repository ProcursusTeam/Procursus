ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libzip
LIBZIP_VERSION := 1.7.3
DEB_LIBZIP_V   ?= $(LIBZIP_VERSION)

libzip-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://libzip.org/download/libzip-$(LIBZIP_VERSION).tar.gz
	$(call EXTRACT_TAR,libzip-$(LIBZIP_VERSION).tar.gz,libzip-$(LIBZIP_VERSION),libzip)

ifneq ($(wildcard $(BUILD_WORK)/libzip/.build_complete),)
libzip:
	@echo "Using previously built libzip."
else
libzip: libzip-setup xz openssl
	cd $(BUILD_WORK)/libzip && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DENABLE_COMMONCRYPTO=OFF \
		-DENABLE_GNUTLS=OFF \
		-DENABLE_MBEDTLS=OFF \
		-DENABLE_WINDOWS_CRYPTO=OFF \
		-DENABLE_OPENSSL=ON
	+$(MAKE) -C $(BUILD_WORK)/libzip
	+$(MAKE) -C $(BUILD_WORK)/libzip install \
		DESTDIR="$(BUILD_STAGE)/libzip"
	+$(MAKE) -C $(BUILD_WORK)/libzip install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libzip/.build_complete
endif

libzip-package: libzip-stage
	# libzip.mk Package Structure
	rm -rf $(BUILD_DIST)/libzip{5,-dev} $(BUILD_DIST)/zip{cmp,merge,tool}
	mkdir -p $(BUILD_DIST)/libzip5/usr/lib \
		$(BUILD_DIST)/libzip-dev/usr/{lib,share/man} \
		$(BUILD_DIST)/zip{cmp,merge,tool}/usr/{bin,share/man/man1}

	# libzip.mk Prep libzip5
	cp -a $(BUILD_STAGE)/libzip/usr/lib/libzip.5*.dylib $(BUILD_DIST)/libzip5/usr/lib

	# libzip.mk Prep libzip-dev
	cp -a $(BUILD_STAGE)/libzip/usr/lib/!(libzip.5*.dylib) $(BUILD_DIST)/libzip-dev/usr/lib
	cp -a $(BUILD_STAGE)/libzip/usr/share/man/man3 $(BUILD_DIST)/libzip-dev/usr/share/man
	cp -a $(BUILD_STAGE)/libzip/usr/include $(BUILD_DIST)/libzip-dev/usr

	# libzip.mk Prep zip{cmp,merge,tool}
	for bin in zip{cmp,merge,tool}; do \
		cp -a $(BUILD_STAGE)/libzip/usr/bin/$$bin $(BUILD_DIST)/$$bin/usr/bin; \
		cp -a $(BUILD_STAGE)/libzip/usr/share/man/man1/$$bin.1 $(BUILD_DIST)/$$bin/usr/share/man/man1; \
	done
	
	# libzip.mk Sign
	$(call SIGN,libzip5,general.xml)
	$(call SIGN,zipcmp,general.xml)
	$(call SIGN,zipmerge,general.xml)
	$(call SIGN,ziptool,general.xml)

	# libzip.mk Make .debs
	$(call PACK,libzip5,DEB_LIBZIP_V)
	$(call PACK,libzip-dev,DEB_LIBZIP_V)
	$(call PACK,zipcmp,DEB_LIBZIP_V)
	$(call PACK,zipmerge,DEB_LIBZIP_V)
	$(call PACK,ziptool,DEB_LIBZIP_V)

	# libzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/libzip{5,-dev} $(BUILD_DIST)/zip{cmp,merge,tool}

.PHONY: libzip libzip-package
