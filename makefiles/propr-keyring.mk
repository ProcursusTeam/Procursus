ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += propr-keyring
PROPR_KEYRING_VERSION := 2021.07.15
DEB_PROPR_KEYRING_V   ?= $(PROPR_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/propr-keyring/.build_complete),)
propr-keyring:
	@echo "Using previously built propr-keyring."
else
propr-keyring: setup
	mkdir -p $(BUILD_STAGE)/propr-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/propr/propr.gpg $(BUILD_STAGE)/propr-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/propr-keyring/.build_complete
endif

propr-keyring-package: propr-keyring-stage
	# propr-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/propr-keyring
	
	# propr-keyring.mk Prep propr-keyring
	cp -a $(BUILD_STAGE)/propr-keyring $(BUILD_DIST)
	
	# propr-keyring.mk Make .debs
	$(call PACK,propr-keyring,DEB_PROPR_KEYRING_V)
	
	# propr-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/propr-keyring

.PHONY: propr-keyring propr-keyring-package
