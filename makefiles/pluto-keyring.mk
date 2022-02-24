ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += pluto-keyring
PLUTO_KEYRING_VERSION  := 2022.02.22
DEB_PLUTO_KEYRING_V    ?= $(PLUTO_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/pluto-keyring/.build_complete),)
pluto-keyring:
	@echo "Using previously built pluto-keyring."
else
pluto-keyring: setup
	mkdir -p $(BUILD_STAGE)/pluto-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/pluto/pluto-repo.gpg $(BUILD_STAGE)/pluto-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/pluto-keyring/.build_complete
endif

pluto-keyring-package: pluto-keyring-stage
	# pluto-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/pluto-keyring

	# pluto-keyring.mk Prep pluto-keyring
	cp -a $(BUILD_STAGE)/pluto-keyring $(BUILD_DIST)

	# pluto-keyring.mk Make .debs
	$(call PACK,pluto-keyring,DEB_PLUTO_KEYRING_V)

	# pluto-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/pluto-keyring

.PHONY: pluto-keyring pluto-keyring-package
