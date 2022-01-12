ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                 += nyuszika7h-keyring
NYUSZIKA7H_KEYRING_VERSION  := 2021.07.14
DEB_NYUSZIKA7H_KEYRING_V    ?= $(NYUSZIKA7H_KEYRING_VERSION)

nyuszika7h-keyring:
	@echo "nyuszika7h-keyring does not need to be built."

nyuszika7h-keyring-package: nyuszika7h-keyring-stage
	# nyuszika7h-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/nyuszika7h-keyring
	mkdir -p $(BUILD_DIST)/nyuszika7h-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# nyuszika7h-keyring.mk Prep nyuszika7h-keyring
	cp -a $(BUILD_MISC)/keyrings/nyuszika7h/nyuszika7h.gpg $(BUILD_DIST)/nyuszika7h-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# nyuszika7h-keyring.mk Make .debs
	$(call PACK,nyuszika7h-keyring,DEB_NYUSZIKA7H_KEYRING_V)

	# nyuszika7h-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/nyuszika7h-keyring

.PHONY: nyuszika7h-keyring nyuszika7h-keyring-package
