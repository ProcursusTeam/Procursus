ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS           += odyssey-keyring
ODYSSEY_KEYRING_VERSION := 2021.07.20
DEB_ODYSSEY_KEYRING_V   ?= $(ODYSSEY_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/odyssey-keyring/.build_complete),)
odyssey-keyring:
	@echo "Using previously built odyssey-keyring."
else
odyssey-keyring: setup
	mkdir -p $(BUILD_STAGE)/odyssey-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/odyssey/odyssey.gpg $(BUILD_STAGE)/odyssey-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/odyssey-keyring/.build_complete
endif

odyssey-keyring-package: odyssey-keyring-stage
	# odyssey-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/odyssey-keyring

	# odyssey-keyring.mk Prep odyssey-keyring
	cp -a $(BUILD_STAGE)/odyssey-keyring $(BUILD_DIST)

	# odyssey-keyring.mk Make .debs
	$(call PACK,odyssey-keyring,DEB_ODYSSEY_KEYRING_V)

	# odyssey-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/odyssey-keyring

.PHONY: odyssey-keyring odyssey-keyring-package
