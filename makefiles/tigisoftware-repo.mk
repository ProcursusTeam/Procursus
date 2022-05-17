ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += tigisoftware-keyring
TIGISOFT_KEYRING_VERSION     := 2021.07.23
DEB_TIGISOFT_KEYRING_V       ?= $(TIGISOFT_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/tigisoftware-keyring/.build_complete),)
tigisoftware-keyring:
	@echo "Using previously built tigisoftware-keyring."
else
tigisoftware-keyring: setup
	mkdir -p $(BUILD_STAGE)/tigisoftware-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/tigisoftware/tigisoftware-repo.gpg $(BUILD_STAGE)/tigisoftware-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	$(call AFTER_BUILD)
endif

tigisoftware-keyring-package: tigisoftware-keyring-stage
	# tigisoftware-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/tigisoftware-keyring

	# tigisoftware-keyring.mk Prep tigisoftware-keyring
	cp -a $(BUILD_STAGE)/tigisoftware-keyring $(BUILD_DIST)

	# tigisoftware-keyring.mk Make .debs
	$(call PACK,tigisoftware-keyring,DEB_TIGISOFT_KEYRING_V)

	# tigisoftware-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/tigisoftware-keyring

.PHONY: tigisoftware-keyring tigisoftware-keyring-package
