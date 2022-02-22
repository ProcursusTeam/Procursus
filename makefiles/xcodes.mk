ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS += xcodes
XCODES_VERSION := 0.19.0
DEB_XCODES_V   ?= $(XCODES_VERSION)

xcodes-setup: setup
	$(call GITHUB_ARCHIVE,RobotsAndPencils,xcodes,$(XCODES_VERSION),$(XCODES_VERSION))
	$(call EXTRACT_TAR,xcodes-$(XCODES_VERSION).tar.gz,xcodes-$(XCODES_VERSION),xcodes)
	mkdir -p $(BUILD_STAGE)/xcodes/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{zsh/site-functions,bash-completion/completions,fish/vendor_completions.d}}

ifneq ($(wildcard $(BUILD_WORK)/xcodes/.build_complete),)
xcodes:
	@echo "Using previously built xcodes."
else
xcodes: xcodes-setup
	cd $(BUILD_WORK)/xcodes; \
		swift build -c release \
			-Xswiftc -Onone \
			--disable-sandbox \
			--build-path ./.build_host

	cd $(BUILD_WORK)/xcodes; \
		swift build -c release \
			-Xswiftc -Onone \
			-Xswiftc -sdk -Xswiftc $(TARGET_SYSROOT) \
			-Xswiftc -target -Xswiftc $(LLVM_TARGET) \
			--disable-sandbox
	$(BUILD_WORK)/xcodes/.build_host/release/xcodes --generate-completion-script zsh > $(BUILD_STAGE)/xcodes/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_xcodes
	$(BUILD_WORK)/xcodes/.build_host/release/xcodes --generate-completion-script bash > $(BUILD_STAGE)/xcodes/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/xcodes
	$(BUILD_WORK)/xcodes/.build_host/release/xcodes --generate-completion-script fish > $(BUILD_STAGE)/xcodes/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d/xcodes.fish
	cp $(BUILD_WORK)/xcodes/.build/release/xcodes $(BUILD_STAGE)/xcodes/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(call AFTER_BUILD)
endif

xcodes-package: xcodes-stage
	# xcodes.mk Package Structure
	rm -rf $(BUILD_DIST)/xcodes

	# xcodes.mk Prep xcodes
	cp -a $(BUILD_STAGE)/xcodes $(BUILD_DIST)

	# xcodes.mk Sign
	$(call SIGN,xcodes,general.xml)

	# xcodes.mk Make .debs
	$(call PACK,xcodes,DEB_XCODES_V)

	# xcodes.mk Build cleanup
	rm -rf $(BUILD_DIST)/xcodes

.PHONY: xcodes xcodes-package

endif
