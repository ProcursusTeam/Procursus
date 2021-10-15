ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += amy-keyring
AMY_KEYRING_VERSION  := 2021.07.10
DEB_AMY_KEYRING_V    ?= $(AMY_KEYRING_VERSION)

amy-keyring:
	@echo "amy-keyring does not need to be built."

amy-keyring-package: amy-keyring-stage
	# amy-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/amy-keyring
	mkdir -p $(BUILD_DIST)/amy-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# amy-keyring.mk Prep amy-keyring
	cp -a $(BUILD_MISC)/keyrings/anamy/anamy-repo.gpg $(BUILD_DIST)/amy-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# amy-keyring.mk Make .debs
	$(call PACK,amy-keyring,DEB_AMY_KEYRING_V)

	# amy-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/amy-keyring

.PHONY: amy-keyring amy-keyring-package
