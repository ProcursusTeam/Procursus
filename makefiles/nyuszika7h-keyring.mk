ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                 += nyuszika7h-keyring
NYUSZIKA7H_KEYRING_VERSION  := 2021.07.14
DEB_NYUSZIKA7H_KEYRING_V    ?= $(NYUSZIKA7H_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/nyuszika7h-keyring/.build_complete),)
nyuszika7h-keyring:
	@echo "Using previously built nyuszika7h-keyring."
else
nyuszika7h-keyring: setup
	mkdir -p $(BUILD_STAGE)/nyuszika7h-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/nyuszika7h/nyuszika7h.gpg $(BUILD_STAGE)/nyuszika7h-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/nyuszika7h-keyring/.build_complete
endif

nyuszika7h-keyring-package: nyuszika7h-keyring-stage
	# nyuszika7h-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/nyuszika7h-keyring

	# nyuszika7h-keyring.mk Prep nyuszika7h-keyring
	cp -a $(BUILD_STAGE)/nyuszika7h-keyring $(BUILD_DIST)

	# nyuszika7h-keyring.mk Make .debs
	$(call PACK,nyuszika7h-keyring,DEB_NYUSZIKA7H_KEYRING_V)

	# nyuszika7h-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/nyuszika7h-keyring

.PHONY: nyuszika7h-keyring nyuszika7h-keyring-package
