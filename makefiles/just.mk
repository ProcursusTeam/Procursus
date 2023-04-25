ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += just
JUST_VERSION  := 1.13.0
DEB_JUST_V    ?= $(JUST_VERSION)

just-setup: setup
	$(call GITHUB_ARCHIVE,casey,just,$(JUST_VERSION),$(JUST_VERSION))
	$(call EXTRACT_TAR,just-$(JUST_VERSION).tar.gz,just-$(JUST_VERSION),just)

ifneq ($(wildcard $(BUILD_WORK)/just/.build_complete),)
just:
	@echo "Using previously built just."
else
just: just-setup
	cd $(BUILD_WORK)/just && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--all-features \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/just/target/$(RUST_TARGET)/release/just $(BUILD_STAGE)/just/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/just

	$(INSTALL) -Dm644 $(BUILD_WORK)/just/man/just.1 \
	    -t $(BUILD_STAGE)/just/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(INSTALL) -Dm644 $(BUILD_WORK)/just/completions/just.zsh \
	    $(BUILD_STAGE)/just/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_just
	$(INSTALL) -Dm644 $(BUILD_WORK)/just/completions/just.fish \
		$(BUILD_STAGE)/just/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d/just.fish
	$(INSTALL) -Dm644 $(BUILD_WORK)/just/completions/just.bash \
	    $(BUILD_STAGE)/just/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/just

	$(call AFTER_BUILD)
endif

just-package: just-stage
	# just.mk Package Structure
	rm -rf $(BUILD_DIST)/just

	# just.mk Prep just
	cp -a $(BUILD_STAGE)/just $(BUILD_DIST)

	# just.mk Sign
	$(call SIGN,just,general.xml)

	# just.mk Make .debs
	$(call PACK,just,DEB_JUST_V)

	# just.mk Build cleanup
	rm -rf $(BUILD_DIST)/just

.PHONY: just just-package
