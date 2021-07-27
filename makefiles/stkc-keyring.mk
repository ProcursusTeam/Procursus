ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += stkc-keyring
STKC_KEYRING_VERSION      := 2021.07.26
DEB_STKC_KEYRING_V        ?= $(STKC_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/stkc-keyring/.build_complete),)
stkc-keyring:
	@echo "Using previously built stkc-keyring."
else
stkc-keyring: setup
	mkdir -p $(BUILD_STAGE)/stkc-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/stkc/stkc-repo.gpg $(BUILD_STAGE)/stkc-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/stkc-keyring/.build_complete
endif

stkc-keyring-package: stkc-keyring-stage
	# stkc-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/stkc-keyring

	# stkc-keyring.mk Prep stkc-keyring
	cp -a $(BUILD_STAGE)/stkc-keyring $(BUILD_DIST)

	# stkc-keyring.mk Make .debs
	$(call PACK,stkc-keyring,DEB_STKC_KEYRING_V)

	# stkc-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/stkc-keyring

.PHONY: stkc-keyring stkc-keyring-package
