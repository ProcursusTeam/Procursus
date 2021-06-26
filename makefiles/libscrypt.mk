ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libscrypt
LIBSCRYPT_VERSION := 1.21
DEB_LIBSCRYPT_V   ?= $(LIBSCRYPT_VERSION)-1

libscrypt-setup: setup
	$(call GITHUB_ARCHIVE,technion,libscrypt,$(LIBSCRYPT_VERSION),v$(LIBSCRYPT_VERSION))
	$(call EXTRACT_TAR,libscrypt-$(LIBSCRYPT_VERSION).tar.gz,libscrypt-$(LIBSCRYPT_VERSION),libscrypt)

ifneq ($(wildcard $(BUILD_WORK)/libscrypt/.build_complete),)
libscrypt:
	@echo "Using previously built libscrypt."
else
libscrypt: libscrypt-setup
	$(SED) -i 's/install_name_tool/$(I_N_T)/g' $(BUILD_WORK)/libscrypt/Makefile
	$(MAKE) -C $(BUILD_WORK)/libscrypt install-osx install-static \
		DESTDIR=$(BUILD_STAGE)/libscrypt \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CFLAGS="$(CFLAGS) -D_FORTIFY_SOURCE=2 -fPIC" \
		-j1
	$(MAKE) -C $(BUILD_WORK)/libscrypt install-osx install-static \
		DESTDIR=$(BUILD_BASE) \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CFLAGS="$(CFLAGS) -D_FORTIFY_SOURCE=2 -fPIC" \
		-j1
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libscrypt.0.dylib $(BUILD_STAGE)/libscrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libscrypt.0.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libscrypt.0.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libscrypt.0.dylib
	touch $(BUILD_WORK)/libscrypt/.build_complete
endif

libscrypt-package: libscrypt-stage
	# libscrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/libscrypt{0,-dev}
	mkdir -p \
		$(BUILD_DIST)/libscrypt0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libscrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libscrypt.mk Prep libscrypt0
	cp -a $(BUILD_STAGE)/libscrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libscrypt.0.dylib $(BUILD_DIST)/libscrypt0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libscrypt.mk Prep libscrypt-dev
	cp -a $(BUILD_STAGE)/libscrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libscrypt.{a,dylib} $(BUILD_DIST)/libscrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libscrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libscrypt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)


	# libscrypt.mk Sign
	$(call SIGN,libscrypt0,general.xml)

	# libscrypt.mk Make .debs
	$(call PACK,libscrypt0,DEB_LIBSCRYPT_V)
	$(call PACK,libscrypt-dev,DEB_LIBSCRYPT_V)

	# libscrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libscrypt{0,-dev}

.PHONY: libscrypt libscrypt-package
