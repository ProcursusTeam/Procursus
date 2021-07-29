ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += doregon-keyring
DOREGON_KEYRING_VERSION      := 2021.07.12
DEB_DOREGON_KEYRING_V        ?= $(DOREGON_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/doregon-keyring/.build_complete),)
doregon-keyring:
	@echo "Using previously built doregon-keyring."
else
doregon-keyring: setup
	mkdir -p $(BUILD_STAGE)/doregon-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/doregon/doregon-repo.gpg $(BUILD_STAGE)/doregon-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/doregon-keyring/.build_complete
endif

doregon-keyring-package: doregon-keyring-stage
	# doregon-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/doregon-keyring

	# doregon-keyring.mk Prep doregon-keyring
	cp -a $(BUILD_STAGE)/doregon-keyring $(BUILD_DIST)

	# doregon-keyring.mk Make .debs
	$(call PACK,doregon-keyring,DEB_DOREGON_KEYRING_V)

	# doregon-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/doregon-keyring

.PHONY: doregon-keyring doregon-keyring-package
