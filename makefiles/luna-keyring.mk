ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += luna-keyring
LUNA_KEYRING_VERSION  := 2024.04.30
DEB_LUNA_KEYRING_V    ?= $(LUNA_KEYRING_VERSION)

luna-keyring:
	@echo "luna-keyring does not need to be built."

luna-keyring-package: luna-keyring-stage
	# luna-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/luna-keyring
	mkdir -p $(BUILD_DIST)/luna-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# luna-keyring.mk Prep luna-keyring
	cp -a $(BUILD_MISC)/keyrings/luna/luna.gpg $(BUILD_DIST)/luna-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# luna-keyring.mk Make .debs
	$(call PACK,luna-keyring,DEB_LUNA_KEYRING_V)

	# luna-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/luna-keyring

.PHONY: luna-keyring luna-keyring-package
