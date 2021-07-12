ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += amy-keyring
AMY_KEYRING_VERSION  := 2021.07.10
DEB_AMY_KEYRING_V    ?= $(AMY_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/amy-keyring/.build_complete),)
amy-keyring:
	@echo "Using previously built amy-keyring."
else
amy-keyring: setup
	mkdir -p $(BUILD_STAGE)/amy-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/anamy/anamy-repo.gpg $(BUILD_STAGE)/amy-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/amy-keyring/.build_complete
endif

amy-keyring-package: amy-keyring-stage
	# amy-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/amy-keyring

	# amy-keyring.mk Prep amy-keyring
	cp -a $(BUILD_STAGE)/amy-keyring $(BUILD_DIST)

	# amy-keyring.mk Make .debs
	$(call PACK,amy-keyring,DEB_AMY_KEYRING_V)

	# amy-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/amy-keyring

.PHONY: amy-keyring amy-keyring-package
