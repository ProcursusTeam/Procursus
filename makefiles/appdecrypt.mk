ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += appdecrypt
APPDECRYPT_VERSION := 2.0
DEB_APPDECRYPT_V   ?= $(APPDECRYPT_VERSION)

appdecrypt-setup: setup
	$(call GITHUB_ARCHIVE,paradiseduo,appdecrypt,$(APPDECRYPT_VERSION),$(APPDECRYPT_VERSION))
	$(call EXTRACT_TAR,appdecrypt-$(APPDECRYPT_VERSION).tar.gz,appdecrypt-$(APPDECRYPT_VERSION),appdecrypt)
	mkdir -p $(BUILD_STAGE)/appdecrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/appdecrypt/.build_complete),)
appdecrypt:
	@echo "Using previously built appdecrypt."
else
appdecrypt: appdecrypt-setup
	cd $(BUILD_WORK)/appdecrypt; \
		swiftc \
		-Osize \
		--target=$(LLVM_TARGET) \
		-sdk $(TARGET_SYSROOT) \
		-o $(BUILD_STAGE)/appdecrypt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/appdecrypt \
		Sources/appdecrypt/{ConsoleIO,dump,main}.swift
	$(call AFTER_BUILD)
endif

appdecrypt-package: appdecrypt-stage
	# appdecrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/appdecrypt
	cp -a $(BUILD_STAGE)/appdecrypt $(BUILD_DIST)

	# appdecrypt.mk Sign
	$(call SIGN,appdecrypt,general.xml)

	# appdecrypt.mk Make .debs
	$(call PACK,appdecrypt,DEB_APPDECRYPT_V)

	# appdecrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/appdecrypt

.PHONY: appdecrypt appdecrypt-package
