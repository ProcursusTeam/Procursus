ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += propr-keyring
PROPR_KEYRING_VERSION := 2021.07.15
DEB_PROPR_KEYRING_V   ?= $(PROPR_KEYRING_VERSION)

propr-keyring:
	@echo "propr-keyring do not need to be built."

propr-keyring-package: propr-keyring-stage
	# propr-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/propr-keyring
	mkdir -p $(BUILD_DIST)/propr-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	
	# propr-keyring.mk Prep propr-keyring
	cp -a $(BUILD_MISC)/keyrings/propr/propr.gpg $(BUILD_DIST)/propr-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	
	# propr-keyring.mk Make .debs
	$(call PACK,propr-keyring,DEB_PROPR_KEYRING_V)
	
	# propr-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/propr-keyring

.PHONY: propr-keyring propr-keyring-package
