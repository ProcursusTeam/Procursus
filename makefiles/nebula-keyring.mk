ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += nebula-keyring
NEBULA_KEYRING_VERSION := 2022.09.15
DEB_NEBULA_KEYRING_V   ?= $(NEBULA_KEYRING_VERSION)

nebula-keyring:
	@echo "nebula-keyring does not need to be built."

nebula-keyring-package: nebula-keyring-stage
	# nebula-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/nebula-keyring
	mkdir -p $(BUILD_DIST)/nebula-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# nebula-keyring.mk Prep nebula-keyring
	cp -a $(BUILD_MISC)/keyrings/nebula/nebula.gpg $(BUILD_DIST)/nebula-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# nebula-keyring.mk Make .debs
	$(call PACK,nebula-keyring,DEB_NEBULA_KEYRING_V)

	# nebula-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/nebula-keyring

.PHONY: nebula-keyring nebula-keyring-package
