ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS          += chariz-keyring
CHARIZ_KEYRING_VERSION := 2021.07.18
DEB_CHARIZ_KEYRING_V   ?= $(CHARIZ_KEYRING_VERSION)

chariz-keyring:
	@echo "chariz-keyring do not need to be built."

chariz-keyring-package: chariz-keyring-stage
	# chariz-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/chariz-keyring
	mkdir -p $(BUILD_DIST)/chariz-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# chariz-keyring.mk Prep chariz-keyring
	cp -a $(BUILD_MISC)/keyrings/chariz/chariz.gpg $(BUILD_DIST)/chariz-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# chariz-keyring.mk Make .debs
	$(call PACK,chariz-keyring,DEB_CHARIZ_KEYRING_V)

	# chariz-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/chariz-keyring

.PHONY: chariz-keyring chariz-keyring-package
