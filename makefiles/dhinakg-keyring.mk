ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += dhinakg-keyring
DHINAKG_KEYRING_VERSION := 2022.12.08
DEB_DHINAKG_KEYRING_V   ?= $(DHINAKG_KEYRING_VERSION)

dhinakg-keyring:
	@echo "dhinakg-keyring does not need to be built."

dhinakg-keyring-package: dhinakg-keyring-stage
	# dhinakg-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/dhinakg-keyring
	mkdir -p $(BUILD_DIST)/dhinakg-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# dhinakg-keyring.mk Prep dhinakg-keyring
	cp -a $(BUILD_MISC)/keyrings/dhinakg/dhinakg.gpg $(BUILD_DIST)/dhinakg-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# dhinakg-keyring.mk Make .debs
	$(call PACK,dhinakg-keyring,DEB_DHINAKG_KEYRING_V)

	# dhinakg-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/dhinakg-keyring

.PHONY: dhinakg-keyring dhinakg-keyring-package
