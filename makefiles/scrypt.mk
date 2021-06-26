ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += scrypt
SCRYPT_VERSION := 1.3.1
DEB_SCRYPT_V   ?= $(SCRYPT_VERSION)

scrypt-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.tarsnap.com/scrypt/scrypt-$(SCRYPT_VERSION).tgz
	$(call EXTRACT_TAR,scrypt-$(SCRYPT_VERSION).tgz,scrypt-$(SCRYPT_VERSION),scrypt)

ifneq ($(wildcard $(BUILD_WORK)/scrypt/.build_complete),)
scrypt:
	@echo "Using previously built scrypt."
else
scrypt: scrypt-setup openssl
	cd $(BUILD_WORK)/scrypt && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-libscrypt-kdf
	+$(MAKE) -C $(BUILD_WORK)/scrypt
	+$(MAKE) -C $(BUILD_WORK)/scrypt install \
		DESTDIR=$(BUILD_STAGE)/scrypt
	touch $(BUILD_WORK)/scrypt/.build_complete
endif

scrypt-package: scrypt-stage
	# scrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/scrypt $(BUILD_DIST)/libscrypt-kdf{1,-dev}
	mkdir -p \
		$(BUILD_DIST)/scrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libscrypt-kdf{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# scrypt.mk Prep scrypt
	cp -a $(BUILD_STAGE)/scrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/scrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# scrypt.mk Prep libscrypt-kdf1
	cp -a $(BUILD_STAGE)/scrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libscrypt-kdf.1.dylib $(BUILD_DIST)/libscrypt-kdf1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# scrypt.mk Prep libscrypt-kdf-dev
	cp -a $(BUILD_STAGE)/scrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libscrypt-kdf.1.dylib) $(BUILD_DIST)/libscrypt-kdf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/scrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libscrypt-kdf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# scrypt.mk Sign
	$(call SIGN,scrypt,general.xml)
	$(call SIGN,libscrypt-kdf1,general.xml)

	# scrypt.mk Make .debs
	$(call PACK,scrypt,DEB_SCRYPT_V)
	$(call PACK,libscrypt-kdf1,DEB_SCRYPT_V)
	$(call PACK,libscrypt-kdf-dev,DEB_SCRYPT_V)

	# scrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/scrypt $(BUILD_DIST)/libscrypt-kdf{1,-dev}

.PHONY: scrypt scrypt-package
