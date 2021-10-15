ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += tale-keyring
TALE_KEYRING_VERSION  := 2021.10.10
DEB_TALE_KEYRING_V    ?= $(TALE_KEYRING_VERSION)

tale-keyring:
	@echo "tale-keyring do not need to be built."

tale-keyring-package: tale-keyring-stage
	# tale-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/tale-keyring
	mkdir -p $(BUILD_DIST)/tale-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# tale-keyring.mk Prep tale-keyring
	cp -a $(BUILD_MISC)/keyrings/tale/{tale,cherimoya}.gpg $(BUILD_DIST)/tale-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# tale-keyring.mk Make .debs
	$(call PACK,tale-keyring,DEB_TALE_KEYRING_V)

	# tale-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/tale-keyring

.PHONY: tale-keyring tale-keyring-package
