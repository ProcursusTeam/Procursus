ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += cameronkatri-keyring
CKATRI_KEYRING_VERSION := 2020.11.21
DEB_CKATRI_KEYRING_V   ?= $(CKATRI_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/cameronkatri-keyring/.build_complete),)
cameronkatri-keyring:
	@echo "Using previously built cameronkatri-keyring."
else
cameronkatri-keyring: setup
	mkdir -p $(BUILD_STAGE)/cameronkatri-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/cameronkatri/cameronkatri.gpg $(BUILD_STAGE)/cameronkatri-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/cameronkatri/subcursus.gpg $(BUILD_STAGE)/cameronkatri-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/cameronkatri-keyring/.build_complete
endif

cameronkatri-keyring-package: cameronkatri-keyring-stage
	# cameronkatri-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/cameronkatri-keyring
	
	# cameronkatri-keyring.mk Prep cameronkatri-keyring
	cp -a $(BUILD_STAGE)/cameronkatri-keyring $(BUILD_DIST)
	
	# cameronkatri-keyring.mk Make .debs
	$(call PACK,cameronkatri-keyring,DEB_CKATRI_KEYRING_V)
	
	# cameronkatri-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/cameronkatri-keyring

.PHONY: cameronkatri-keyring cameronkatri-keyring-package
