ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += ironside-keyring
IRONSIDE_KEYRING_VERSION := 2023.02.21
DEB_IRONSIDE_KEYRING_V   ?= $(IRONSIDE_KEYRING_VERSION)

ironside-keyring:
	@echo "ironside-keyring does not need to be built."

ironside-keyring-package: ironside-keyring-stage
	# ironside-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/ironside-keyring
	mkdir -p $(BUILD_DIST)/ironside-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# ironside-keyring.mk Prep ironside-keyring
	cp -a $(BUILD_MISC)/keyrings/ironside/ironside.gpg $(BUILD_DIST)/ironside-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# ironside-keyring.mk Make .debs
	$(call PACK,ironside-keyring,DEB_IRONSIDE_KEYRING_V)

	# ironside-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/ironside-keyring

.PHONY: ironside-keyring ironside-keyring-package
