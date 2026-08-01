ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += packix-keyring
PACKIX_KEYRING_VERSION := 2021.07.19
DEB_PACKIX_KEYRING_V   ?= $(PACKIX_KEYRING_VERSION)-1

packix-keyring:
	@echo "packix-keyring does not need to be built."

packix-keyring-package: packix-keyring-stage
	# packix-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/packix-keyring
	mkdir -p $(BUILD_DIST)/packix-keyring/$(MEMO_PREFIX)/usr/share/keyrings

	# packix-keyring.mk Prep packix-keyring
	cp -a $(BUILD_MISC)/keyrings/packix/packix.gpg $(BUILD_DIST)/packix-keyring/$(MEMO_PREFIX)/usr/share/keyrings

	# packix-keyring.mk Make .debs
	$(call PACK,packix-keyring,DEB_PACKIX_KEYRING_V)

	# packix-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/packix-keyring

.PHONY: packix-keyring packix-keyring-package
