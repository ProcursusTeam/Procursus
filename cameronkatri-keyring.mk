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
	mkdir -p $(BUILD_STAGE)/cameronkatri-keyring/etc/apt/trusted.gpg.d
	cp -a $(BUILD_INFO)/cameronkatri.gpg $(BUILD_STAGE)/cameronkatri-keyring/etc/apt/trusted.gpg.d
	cp -a $(BUILD_INFO)/subcursus.gpg $(BUILD_STAGE)/cameronkatri-keyring/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/cameronkatri-keyring/.build_complete
endif

cameronkatri-keyring-package: cameronkatri-keyring-stage
	# keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/cameronkatri-keyring
	mkdir -p $(BUILD_DIST)/cameronkatri-keyring
	
	# keyring.mk Prep keyring
	cp -a $(BUILD_STAGE)/cameronkatri-keyring/etc $(BUILD_DIST)/cameronkatri-keyring
	
	# keyring.mk Make .debs
	$(call PACK,cameronkatri-keyring,DEB_CKATRI_KEYRING_V)
	
	# keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/cameronkatri-keyring

.PHONY: cameronkatri-keyring cameronkatri-keyring-package
