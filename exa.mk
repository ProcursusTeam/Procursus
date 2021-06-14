ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += exa
EXA_VERSION := 0.10.1
DEB_EXA_V   ?= $(EXA_VERSION)

exa-setup: setup
	$(call GITHUB_ARCHIVE,ogham,exa,$(EXA_VERSION),v$(EXA_VERSION))
	$(call EXTRACT_TAR,exa-$(EXA_VERSION).tar.gz,exa-$(EXA_VERSION),exa)

ifneq ($(wildcard $(BUILD_WORK)/exa/.build_complete),)
exa:
	@echo "Using previously built exa."
else
exa: exa-setup
	# Patch Cargo.toml to use aspen's fork of users /w iOS support
	$(SED) -i 's+users = "0.11"+users = {git = "https://github.com/aspenluxxxy/rust-users", branch = "ios"}+g' \
		$(BUILD_WORK)/exa/Cargo.toml
	cd $(BUILD_WORK)/exa && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--no-default-features \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/exa/target/$(RUST_TARGET)/release/exa \
		$(BUILD_STAGE)/exa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/exa
	touch $(BUILD_WORK)/exa/.build_complete
endif

exa-package: exa-stage
	# exa.mk Package Structure
	mkdir -p $(BUILD_DIST)/exa
	cp -a $(BUILD_STAGE)/exa $(BUILD_DIST)

	# exa.mk Sign
	$(call SIGN,exa,general.xml)

	# exa.mk Make .debs
	$(call PACK,exa,DEB_EXA_V)

	# exa.mk Build Cleanup
	rm -rf $(BUILD_DIST)/exa

.PHONY: exa exa-package
