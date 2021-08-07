ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += @pkg@-keyring
@PKG@_KEYRING_VERSION := @date@
DEB_@PKG@_KEYRING_V   ?= $(@PKG@_KEYRING_VERSION)

@pkg@-keyring:
	@echo "@pkg@-keyring do not need to be built."

@pkg@-keyring-package: @pkg@-keyring-stage
	# @pkg@-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@-keyring
	mkdir -p $(BUILD_DIST)/@pkg@-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	
	# @pkg@-keyring.mk Prep @pkg@-keyring
	cp -a $(BUILD_MISC)/keyrings/@pkg@/@pkg@.gpg $(BUILD_DIST)/@pkg@-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d
	
	# @pkg@-keyring.mk Make .debs
	$(call PACK,@pkg@-keyring,DEB_@PKG@_KEYRING_V)
	
	# @pkg@-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@-keyring

.PHONY: @pkg@-keyring @pkg@-keyring-package
