ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += Pluto-keyring
PLUTO_KEYRING_VERSION := 2022.02.25
DEB_PLUTO_KEYRING_V   ?= $(PLUTO_KEYRING_VERSION)

Pluto-keyring:
	@echo "Pluto-keyring does not need to be built."

Pluto-keyring-package: Pluto-keyring-stage
	# Pluto-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/Pluto-keyring
	mkdir -p $(BUILD_DIST)/Pluto-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# Pluto-keyring.mk Prep Pluto-keyring
	cp -a $(BUILD_MISC)/keyrings/Pluto/Pluto.gpg $(BUILD_DIST)/Pluto-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# Pluto-keyring.mk Make .debs
	$(call PACK,Pluto-keyring,DEB_PLUTO_KEYRING_V)

	# Pluto-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/Pluto-keyring

.PHONY: Pluto-keyring Pluto-keyring-package
