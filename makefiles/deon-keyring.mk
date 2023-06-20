ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += deon-keyring
DEON_KEYRING_VERSION := 2023.04.18
DEB_DEON_KEYRING_V   ?= $(DEON_KEYRING_VERSION)

deon-keyring:
	@echo "deon-keyring does not need to be built."

deon-keyring-package: deon-keyring-stage
	# deon-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/deon-keyring
	mkdir -p $(BUILD_DIST)/deon-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# deon-keyring.mk Prep deon-keyring
	cp -a $(BUILD_MISC)/keyrings/deon/deontw.gpg $(BUILD_DIST)/deon-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# deon-keyring.mk Make .debs
	$(call PACK,deon-keyring,DEB_DEON_KEYRING_V)

	# deon-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/deon-keyring

.PHONY: deon-keyring deon-keyring-package
