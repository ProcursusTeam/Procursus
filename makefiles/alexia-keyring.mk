ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += alexia-keyring
ALEXIA_KEYRING_VERSION  := 2024.02.20
DEB_ALEXIA_KEYRING_V    ?= $(ALEXIA_KEYRING_VERSION)

alexia-keyring:
	@echo "alexia-keyring does not need to be built."

alexia-keyring-package: alexia-keyring-stage
	# alexia-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/alexia-keyring
	mkdir -p $(BUILD_DIST)/alexia-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# alexia-keyring.mk Prep alexia-keyring
	cp -a $(BUILD_MISC)/keyrings/alexia/alexia.gpg $(BUILD_DIST)/alexia-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# alexia-keyring.mk Make .debs
	$(call PACK,alexia-keyring,DEB_ALEXIA_KEYRING_V)

	# alexia-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/alexia-keyring

.PHONY: alexia-keyring alexia-keyring-package
