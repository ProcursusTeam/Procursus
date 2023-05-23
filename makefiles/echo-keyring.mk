ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += echo-keyring
ECHO_KEYRING_VERSION := 2023.05.01
DEB_ECHO_KEYRING_V   ?= $(ECHO_KEYRING_VERSION)

echo-keyring:
	@echo "echo-keyring does not need to be built."

echo-keyring-package: echo-keyring-stage
	# echo-keyring.mk Package Structure
	rm -rf $(BUILD_DIST)/echo-keyring
	mkdir -p $(BUILD_DIST)/echo-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# echo-keyring.mk Prep echo-keyring
	cp -a $(BUILD_MISC)/keyrings/echo/echo.gpg $(BUILD_DIST)/echo-keyring/$(MEMO_PREFIX)/etc/apt/trusted.gpg.d

	# echo-keyring.mk Make .debs
	$(call PACK,echo-keyring,DEB_ECHO_KEYRING_V)

	# echo-keyring.mk Build cleanup
	rm -rf $(BUILD_DIST)/echo-keyring

.PHONY: echo-keyring echo-keyring-package
