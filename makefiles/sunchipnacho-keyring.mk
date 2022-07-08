ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += sunchipnacho-keyring
SUNCHIPNACHO_KEYRING_VERSION := 2022.02.24
DEB_SUNCHIPNACHO_KEYRING_V   ?= $(SUNCHIPNACHO_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/sunchipnacho-keyring/.build_complete),)
sunchipnacho-keyring:
	@echo "Using previously built sunchipnacho-keyring."
else
sunchipnacho-keyring: setup
	mkdir -p $(BUILD_STAGE)/sunchipnacho-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/sunchipnacho/sunchipnacho.gpg $(BUILD_STAGE)/sunchipnacho-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	$(call AFTER_BUILD)
endif

sunchipnacho-keyring-package: sunchipnacho-keyring-stage
	# sunchipnacho-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/sunchipnacho-keyring

	# sunchipnacho-keyring.mk Prep sunchipnacho-keyring
	cp -a $(BUILD_STAGE)/sunchipnacho-keyring $(BUILD_DIST)

	# sunchipnacho-keyring.mk Make .debs
	$(call PACK,sunchipnacho-keyring,DEB_SUNCHIPNACHO_KEYRING_V)

	# sunchipnacho-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/sunchipnacho-keyring

.PHONY: sunchipnacho-keyring sunchipnacho-keyring-package
