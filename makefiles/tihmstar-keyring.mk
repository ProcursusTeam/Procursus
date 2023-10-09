ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += tihmstar-keyring
TIHMSTAR_KEYRING_VERSION  := 2023.10.09
DEB_TIHMSTAR_KEYRING_V    ?= $(TIHMSTAR_KEYRING_VERSION)

tihmstar-keyring:
	@echo "tihmstar-keyring does not need to be built."

tihmstar-keyring-package: tihmstar-keyring-stage
	# tihmstar-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/tihmstar-keyring
	mkdir -p $(BUILD_DIST)/tihmstar-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# tihmstar-keyring.mk Prep tihmstar-keyring
	cp -a $(BUILD_MISC)/keyrings/tihmstar/tihmstar-repo.gpg $(BUILD_DIST)/tihmstar-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# tihmstar-keyring.mk Make .debs
	$(call PACK,tihmstar-keyring,DEB_TIHMSTAR_KEYRING_V)

	# tihmstar-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/tihmstar-keyring

.PHONY: tihmstar-keyring tihmstar-keyring-package
