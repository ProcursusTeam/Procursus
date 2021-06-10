ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS     += libxcrypt
LIBXCRYPT_VERSION := 4.4.17
DEB_LIBXCRYPT_V   ?= $(LIBXCRYPT_VERSION)

libxcrypt-setup: setup
	$(call GITHUB_ARCHIVE,besser82,libxcrypt,$(LIBXCRYPT_VERSION),v$(LIBXCRYPT_VERSION))
	$(call EXTRACT_TAR,libxcrypt-$(LIBXCRYPT_VERSION).tar.gz,libxcrypt-$(LIBXCRYPT_VERSION),libxcrypt)

ifneq ($(wildcard $(BUILD_WORK)/libxcrypt/.build_complete),)
libxcrypt:
	@echo "Using previously built libxcrypt."
else
libxcrypt: libxcrypt-setup
	cd $(BUILD_WORK)/libxcrypt && autoreconf -iv
	cd $(BUILD_WORK)/libxcrypt && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt install \
		DESTDIR=$(BUILD_STAGE)/libxcrypt
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxcrypt/.build_complete
endif

libxcrypt-package: libxcrypt-stage
	# libxcrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/libcrypt{2,-dev}
	mkdir -p $(BUILD_DIST)/libcrypt{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcrypt.mk Prep libxcrypt
	cp -a $(BUILD_STAGE)/libxcrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcrypt.2.dylib $(BUILD_DIST)/libcrypt2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxcrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcrypt.{a,dylib},pkgconfig} $(BUILD_DIST)/libcrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxcrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libcrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxcrypt.mk Sign
	$(call SIGN,libcrypt2,general.xml)

	# libxcrypt.mk Make .debs
	$(call PACK,libcrypt2,DEB_LIBXCRYPT_V)
	$(call PACK,libcrypt-dev,DEB_LIBXCRYPT_V)

	# libxcrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcrypt{2,-dev}

.PHONY: libxcrypt libxcrypt-package

endif # ($(MEMO_TARGET),darwin-\*)