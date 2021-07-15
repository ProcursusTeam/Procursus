ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += @pkg@-keyring
@PKG@_KEYRING_VERSION := @date@
DEB_@PKG@_KEYRING_V   ?= $(@PKG@_KEYRING_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/@pkg@-keyring/.build_complete),)
@pkg@-keyring:
	@echo "Using previously built @pkg@-keyring."
else
@pkg@-keyring: setup
	mkdir -p $(BUILD_STAGE)/@pkg@-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	cp -a $(BUILD_MISC)/keyrings/@pkg@/@pkg@.gpg $(BUILD_STAGE)/@pkg@-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	touch $(BUILD_STAGE)/@pkg@-keyring/.build_complete
endif

@pkg@-keyring-package: @pkg@-keyring-stage
	# @pkg@-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@-keyring
	
	# @pkg@-keyring.mk Prep @pkg@-keyring
	cp -a $(BUILD_STAGE)/@pkg@-keyring $(BUILD_DIST)
	
	# @pkg@-keyring.mk Make .debs
	$(call PACK,@pkg@-keyring,DEB_@PKG@_KEYRING_V)
	
	# @pkg@-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@-keyring

.PHONY: @pkg@-keyring @pkg@-keyring-package
