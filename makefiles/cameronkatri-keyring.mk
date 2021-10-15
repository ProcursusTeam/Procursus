ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += cameronkatri-keyring
CKATRI_KEYRING_VERSION := 2020.11.21
DEB_CKATRI_KEYRING_V   ?= $(CKATRI_KEYRING_VERSION)

cameronkatri-keyring:
	@echo "cameronkatri-keyring does not need to be built."

cameronkatri-keyring-package: cameronkatri-keyring-stage
	# cameronkatri-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/cameronkatri-keyring
	mkdir -p $(BUILD_DIST)/cameronkatri-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	
	# cameronkatri-keyring.mk Prep cameronkatri-keyring
	cp -a $(BUILD_MISC)/keyrings/cameronkatri/{cameronkatri,subcursus}.gpg $(BUILD_DIST)/cameronkatri-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	
	# cameronkatri-keyring.mk Make .debs
	$(call PACK,cameronkatri-keyring,DEB_CKATRI_KEYRING_V)
	
	# cameronkatri-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/cameronkatri-keyring

.PHONY: cameronkatri-keyring cameronkatri-keyring-package
