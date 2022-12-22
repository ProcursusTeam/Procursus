ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += utm-keyring
UTM_KEYRING_VERSION := 2022.05.07
DEB_UTM_KEYRING_V   ?= $(UTM_KEYRING_VERSION)

utm-keyring:
	@echo "utm-keyring does not need to be built."

utm-keyring-package:
	# utm-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/utm-keyring
	mkdir -p $(BUILD_DIST)/utm-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# utm-keyring.mk Prep utm-keyring
	cp -a $(BUILD_MISC)/keyrings/utm/utm.gpg $(BUILD_DIST)/utm-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# utm-keyring.mk Make .debs
	$(call PACK,utm-keyring,DEB_UTM_KEYRING_V)

	# utm-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/utm-keyring

.PHONY: utm-keyring utm-keyring-package
