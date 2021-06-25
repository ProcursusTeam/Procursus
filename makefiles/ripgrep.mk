ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += ripgrep
RIPGREP_VERSION := 12.1.1
DEB_RIPGREP_V   ?= $(RIPGREP_VERSION)-1

ripgrep-setup: setup
	$(call GITHUB_ARCHIVE,BurntSushi,ripgrep,$(RIPGREP_VERSION),$(RIPGREP_VERSION))
	$(call EXTRACT_TAR,ripgrep-$(RIPGREP_VERSION).tar.gz,ripgrep-$(RIPGREP_VERSION),ripgrep)

ifneq ($(wildcard $(BUILD_WORK)/ripgrep/.build_complete),)
ripgrep:
	@echo "Using previously built ripgrep."
else
ripgrep: ripgrep-setup pcre2
	cd $(BUILD_WORK)/ripgrep && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET) \
		--features pcre2
	$(GINSTALL) -Dm755 $(BUILD_WORK)/ripgrep/target/$(RUST_TARGET)/release/rg $(BUILD_STAGE)/ripgrep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rg
	$(GINSTALL) -Dm644 $(BUILD_WORK)/ripgrep/complete/_rg $(BUILD_STAGE)/ripgrep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_rg
	$(GINSTALL) -Dm644 $(BUILD_WORK)/ripgrep/target/$(RUST_TARGET)/release/build/ripgrep-*/out/rg.bash $(BUILD_STAGE)/ripgrep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/rg
	touch $(BUILD_WORK)/ripgrep/.build_complete
endif

ripgrep-package: ripgrep-stage
	# ripgrep.mk Package Structure
	rm -rf $(BUILD_DIST)/ripgrep

	# ripgrep.mk Prep ripgrep
	cp -a $(BUILD_STAGE)/ripgrep $(BUILD_DIST)

	# ripgrep.mk Sign
	$(call SIGN,ripgrep,general.xml)

	# ripgrep.mk Make .debs
	$(call PACK,ripgrep,DEB_RIPGREP_V)

	# ripgrep.mk Build cleanup
	rm -rf $(BUILD_DIST)/ripgrep

.PHONY: ripgrep ripgrep-package
