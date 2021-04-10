ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libzip
LIBZIP_VERSION := 1.7.3
DEB_LIBZIP_V   ?= $(LIBZIP_VERSION)-1

libzip-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://libzip.org/download/libzip-$(LIBZIP_VERSION).tar.gz
	$(call EXTRACT_TAR,libzip-$(LIBZIP_VERSION).tar.gz,libzip-$(LIBZIP_VERSION),libzip)

ifneq ($(wildcard $(BUILD_WORK)/libzip/.build_complete),)
libzip:
	@echo "Using previously built libzip."
else
libzip: libzip-setup xz openssl
	cd $(BUILD_WORK)/libzip && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCOMMON_ARCH=$(DEB_ARCH) \
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
	mkdir -p $(BUILD_DIST)/libzip5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libzip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/man} \
		$(BUILD_DIST)/zip{cmp,merge,tool}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# libzip.mk Prep libzip5
	cp -a $(BUILD_STAGE)/libzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libzip.5*.dylib $(BUILD_DIST)/libzip5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libzip.mk Prep libzip-dev
	cp -a $(BUILD_STAGE)/libzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libzip.5*.dylib) $(BUILD_DIST)/libzip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libzip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/libzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libzip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libzip.mk Prep zip{cmp,merge,tool}
	for bin in zip{cmp,merge,tool}; do \
		cp -a $(BUILD_STAGE)/libzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $(BUILD_DIST)/$$bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
		cp -a $(BUILD_STAGE)/libzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$$bin.1 $(BUILD_DIST)/$$bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
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
