ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += nickchan-keyring
NICKCHAN_KEYRING_VERSION  := 2021.08.06
DEB_NICKCHAN_KEYRING_V    ?= $(NICKCHAN_KEYRING_VERSION)

nickchan-keyring:
	@echo "nickchan-keyring does not need to be built."

nickchan-keyring-package: nickchan-keyring-stage
	# nickchan-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/nickchan-keyring
	mkdir -p $(BUILD_DIST)/nickchan-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# nickchan-keyring.mk Prep nickchan-keyring
	cp -a $(BUILD_MISC)/keyrings/nickchan/nickchan{,-table}.gpg $(BUILD_DIST)/nickchan-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# nickchan-keyring.mk Make .debs
	$(call PACK,nickchan-keyring,DEB_NICKCHAN_KEYRING_V)

	# nickchan-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/nickchan-keyring

.PHONY: nickchan-keyring nickchan-keyring-package
