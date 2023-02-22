ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += dust
DUST_VERSION  := 0.7.5
DEB_DUST_V    ?= $(DUST_VERSION)

dust-setup: setup
	$(call GITHUB_ARCHIVE,bootandy,dust,$(DUST_VERSION),v$(DUST_VERSION))
	$(call EXTRACT_TAR,dust-$(DUST_VERSION).tar.gz,dust-$(DUST_VERSION),dust)

ifneq ($(wildcard $(BUILD_WORK)/dust/.build_complete),)
dust:
	@echo "Using previously built dust."
else
dust: dust-setup
	cd $(BUILD_WORK)/dust && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--all-features \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/dust/target/$(RUST_TARGET)/release/dust $(BUILD_STAGE)/dust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dust
	$(call AFTER_BUILD)
endif

dust-package: dust-stage
	# dust.mk Package Structure
	rm -rf $(BUILD_DIST)/dust

	# dust.mk Prep dust
	cp -a $(BUILD_STAGE)/dust $(BUILD_DIST)

	# dust.mk Sign
	$(call SIGN,dust,general.xml)

	# dust.mk Make .debs
	$(call PACK,dust,DEB_DUST_V)

	# dust.mk Build cleanup
	rm -rf $(BUILD_DIST)/dust

.PHONY: dust dust-package
