ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += tale-keyring
TALE_KEYRING_VERSION  := 2021.07.08
DEB_TALE_KEYRING_V    ?= $(TALE_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/tale-keyring/.build_complete),)
tale-keyring:
	@echo "Using previously built tale-keyring."
else
tale-keyring: setup
	mkdir -p $(BUILD_STAGE)/tale-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/tale/tale.gpg $(BUILD_STAGE)/tale-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/tale/cherimoya.gpg $(BUILD_STAGE)/tale-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/tale-keyring/.build_complete
endif

tale-keyring-package: tale-keyring-stage
	# tale-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/tale-keyring

	# tale-keyring.mk Prep tale-keyring
	cp -a $(BUILD_STAGE)/tale-keyring $(BUILD_DIST)

	# tale-keyring.mk Make .debs
	$(call PACK,tale-keyring,DEB_TALE_KEYRING_V)

	# tale-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/tale-keyring

.PHONY: tale-keyring tale-keyring-package
