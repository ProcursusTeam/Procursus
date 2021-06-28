ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += nickchan-keyring
NICKCHAN_KEYRING_VERSION  := 2021.06.13
DEB_NICKCHAN_KEYRING_V    ?= $(NICKCHAN_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/nickchan-keyring/.build_complete),)
nickchan-keyring:
	@echo "Using previously built nickchan-keyring."
else
nickchan-keyring: setup
	mkdir -p $(BUILD_STAGE)/nickchan-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_INFO)/nickchan.gpg $(BUILD_STAGE)/nickchan-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/nickchan-keyring/.build_complete
endif

nickchan-keyring-package: nickchan-keyring-stage
	# nickchan-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/nickchan-keyring

	# nickchan-keyring.mk Prep nickchan-keyring
	cp -a $(BUILD_STAGE)/nickchan-keyring $(BUILD_DIST)

	# nickchan-keyring.mk Make .debs
	$(call PACK,nickchan-keyring,DEB_NICKCHAN_KEYRING_V)

	# nickchan-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/nickchan-keyring

.PHONY: nickchan-keyring nickchan-keyring-package
