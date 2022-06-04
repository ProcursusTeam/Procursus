ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS         += havoc-keyring
HAVOC_KEYRING_VERSION := 2022.06.03
DEB_HAVOC_KEYRING_V   ?= $(HAVOC_KEYRING_VERSION)

havoc-keyring:
	@echo "havoc-keyring does not need to be built."

havoc-keyring-package: havoc-keyring-stage
	# havoc-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/havoc-keyring
	mkdir -p $(BUILD_DIST)/havoc-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# havoc-keyring.mk Prep havoc-keyring
	cp -a $(BUILD_MISC)/keyrings/havoc/havoc.gpg $(BUILD_DIST)/havoc-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# havoc-keyring.mk Make .debs
	$(call PACK,havoc-keyring,DEB_HAVOC_KEYRING_V)

	# havoc-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/havoc-keyring

.PHONY: havoc-keyring havoc-keyring-package
