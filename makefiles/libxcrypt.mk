ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS     += libxcrypt
else
SUBPROJECTS       += libxcrypt
endif
LIBXCRYPT_VERSION := 4.4.28
DEB_LIBXCRYPT_V   ?= $(LIBXCRYPT_VERSION)

libxcrypt-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/besser82/libxcrypt/releases/download/v$(LIBXCRYPT_VERSION)/libxcrypt-$(LIBXCRYPT_VERSION).tar.xz{$(comma).asc$(comma).sha256sum})
	$(call CHECKSUM_VERIFY,sha256sum,libxcrypt-$(LIBXCRYPT_VERSION).tar.xz)
	$(call PGP_VERIFY,libxcrypt-$(LIBXCRYPT_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,libxcrypt-$(LIBXCRYPT_VERSION).tar.xz,libxcrypt-$(LIBXCRYPT_VERSION),libxcrypt)

ifneq ($(wildcard $(BUILD_WORK)/libxcrypt/.build_complete),)
libxcrypt:
	@echo "Using previously built libxcrypt."
else
libxcrypt: libxcrypt-setup libtool
#	Prebuilding libtool needed for autoreconf to succeed here (why?)
	cd $(BUILD_WORK)/libxcrypt && autoreconf -iv
	cd $(BUILD_WORK)/libxcrypt && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CFLAGS="$(patsubst -flto=thin,,$(CFLAGS))" \
		LDFLAGS="$(patsubst -flto=thin,,$(LDFLAGS))"
	# LTO is disabled here because it will build but not work if compiled with LTO.
	# No matter what you're thinking, just don't try to change it, it will segfault.
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt install \
		DESTDIR=$(BUILD_STAGE)/libxcrypt
	$(call AFTER_BUILD,copy)
endif

libxcrypt-package: libxcrypt-stage
	# libxcrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/libcrypt{2,-dev}
	mkdir -p $(BUILD_DIST)/libcrypt{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcrypt.mk Prep libcrypt2
	cp -a $(BUILD_STAGE)/libxcrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcrypt.2.dylib $(BUILD_DIST)/libcrypt2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcrypt.mk Prep libcrypt-dev
	cp -a $(BUILD_STAGE)/libxcrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libcrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxcrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcrypt.{a,dylib},pkgconfig} $(BUILD_DIST)/libcrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcrypt.mk Sign
	$(call SIGN,libcrypt2,general.xml)

	# libxcrypt.mk Make .debs
	$(call PACK,libcrypt2,DEB_LIBXCRYPT_V)
	$(call PACK,libcrypt-dev,DEB_LIBXCRYPT_V)

	# libxcrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcrypt{2,-dev}

.PHONY: libxcrypt libxcrypt-package
