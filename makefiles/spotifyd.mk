ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += spotifyd
SPOTIFYD_VERSION := 0.3.4
DEB_SPOTIFYD_V   ?= $(SPOTIFYD_VERSION)

spotifyd-setup: setup
	$(call GITHUB_ARCHIVE,Spotifyd,spotifyd,v$(SPOTIFYD_VERSION),v$(SPOTIFYD_VERSION))
	$(call EXTRACT_TAR,spotifyd-v$(SPOTIFYD_VERSION).tar.gz,spotifyd-$(SPOTIFYD_VERSION),spotifyd)
	$(call DO_PATCH,spotifyd,spotifyd,-p1)

ifneq ($(wildcard $(BUILD_WORK)/spotifyd/.build_complete),)
spotifyd:
	@echo "Using previously built spotifyd."
else
spotifyd: spotifyd-setup portaudio
	cd $(BUILD_WORK)/spotifyd && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--no-default-features \
		--features dbus_keyring,portaudio_backend,rodio_backend \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/spotifyd/target/$(RUST_TARGET)/release/spotifyd $(BUILD_STAGE)/spotifyd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/spotifyd
	$(call AFTER_BUILD)
endif

spotifyd-package: spotifyd-stage
	# spotifyd.mk Package Structure
	rm -rf $(BUILD_DIST)/spotifyd

	# spotifyd.mk Prep spotifyd
	cp -a $(BUILD_STAGE)/spotifyd $(BUILD_DIST)

	# spotifyd.mk Sign
	$(call SIGN,spotifyd,general.xml)

	# spotifyd.mk Make .debs
	$(call PACK,spotifyd,DEB_SPOTIFYD_V)

	# spotifyd.mk Build cleanup
	rm -rf $(BUILD_DIST)/spotifyd

.PHONY: spotifyd spotifyd-package
