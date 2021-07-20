ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += idevicehacked-keyring
IDHACKED_KEYRING_VERSION     := 2021.07.20
DEB_IDHACKED_KEYRING_V       ?= $(IDHACKED_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/idevicehacked-keyring/.build_complete),)
idevicehacked-keyring:
	@echo "Using previously built idevicehacked-keyring."
else
idevicehacked-keyring: setup
	mkdir -p $(BUILD_STAGE)/idevicehacked-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/idevicehacked/idevicehacked-repo.gpg $(BUILD_STAGE)/idevicehacked-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/idevicehacked-keyring/.build_complete
endif

idevicehacked-keyring-package: idevicehacked-keyring-stage
	# idevicehacked-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/idevicehacked-keyring

	# idevicehacked-keyring.mk Prep idevicehacked-keyring
	cp -a $(BUILD_STAGE)/idevicehacked-keyring $(BUILD_DIST)

	# idevicehacked-keyring.mk Make .debs
	$(call PACK,idevicehacked-keyring,DEB_IDHACKED_KEYRING_V)

	# idevicehacked-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/idevicehacked-keyring

.PHONY: idevicehacked-keyring idevicehacked-keyring-package
