ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += odyssey-keyring
ODYSSEY_KEYRING_VERSION := 2021.07.20
DEB_ODYSSEY_KEYRING_V   ?= $(ODYSSEY_KEYRING_VERSION)

odyssey-keyring:
	@echo "odyssey-keyring does not need to be built."

odyssey-keyring-package: odyssey-keyring-stage
	# odyssey-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/odyssey-keyring
	mkdir -p $(BUILD_DIST)/odyssey-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# odyssey-keyring.mk Prep odyssey-keyring
	cp -a $(BUILD_MISC)/keyrings/odyssey/odyssey.gpg $(BUILD_DIST)/odyssey-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# odyssey-keyring.mk Make .debs
	$(call PACK,odyssey-keyring,DEB_ODYSSEY_KEYRING_V)

	# odyssey-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/odyssey-keyring

.PHONY: odyssey-keyring odyssey-keyring-package
