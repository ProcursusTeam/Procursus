ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS          += packix-keyring
PACKIX_KEYRING_VERSION := 2021.07.19
DEB_PACKIX_KEYRING_V   ?= $(PACKIX_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/packix-keyring/.build_complete),)
packix-keyring:
	@echo "Using previously built packix-keyring."
else
packix-keyring: setup
	mkdir -p $(BUILD_STAGE)/packix-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/packix/packix.gpg $(BUILD_STAGE)/packix-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/packix-keyring/.build_complete
endif

packix-keyring-package: packix-keyring-stage
	# packix-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/packix-keyring

	# packix-keyring.mk Prep packix-keyring
	cp -a $(BUILD_STAGE)/packix-keyring $(BUILD_DIST)

	# packix-keyring.mk Make .debs
	$(call PACK,packix-keyring,DEB_PACKIX_KEYRING_V)

	# packix-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/packix-keyring

.PHONY: packix-keyring packix-keyring-package
