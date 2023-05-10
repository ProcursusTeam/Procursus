ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += snoolie-keyring
SNOOLIE_KEYRING_VERSION := 2023.05.02
DEB_SNOOLIE_KEYRING_V   ?= $(SNOOLIE_KEYRING_VERSION)

snoolie-keyring:
	@echo "snoolie-keyring does not need to be built."

snoolie-keyring-package: snoolie-keyring-stage
	# snoolie-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/snoolie-keyring
	mkdir -p $(BUILD_DIST)/snoolie-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# snoolie-keyring.mk Prep snoolie-keyring
	cp -a $(BUILD_MISC)/keyrings/snoolie/snoolie.gpg $(BUILD_DIST)/snoolie-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# snoolie-keyring.mk Make .debs
	$(call PACK,snoolie-keyring,DEB_SNOOLIE_KEYRING_V)

	# snoolie-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/snoolie-keyring

.PHONY: snoolie-keyring snoolie-keyring-package
