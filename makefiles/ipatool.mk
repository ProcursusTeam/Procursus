ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


SUBPROJECTS += ipatool
IPATOOL_VERSION := 1.0.8
DEB_IPATOOL_V   ?= $(IPATOOL_VERSION)

ipatool-setup: setup
	$(call GITHUB_ARCHIVE,majd,ipatool,$(IPATOOL_VERSION),v$(IPATOOL_VERSION))
	$(call EXTRACT_TAR,ipatool-$(IPATOOL_VERSION).tar.gz,ipatool-$(IPATOOL_VERSION),ipatool)
	sed -e 's|@IPATOOL_VERSION@|$(IPATOOL_VERSION)|g' < $(BUILD_MISC)/ipatool/Package.swift > $(BUILD_WORK)/ipatool/Sources/CLI/Package.swift
	mkdir -p $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{zsh/site-functions,bash-completion/completions,fish/vendor_completions.d}}

ifneq ($(wildcard $(BUILD_WORK)/ipatool/.build_complete),)
ipatool:
	@echo "Using previously built ipatool."
else
ipatool: ipatool-setup
	cd $(BUILD_WORK)/ipatool; \
		swift build -c release \
		-Xswiftc -sdk -Xswiftc $(TARGET_SYSROOT) \
		-Xswiftc -target -Xswiftc $(LLVM_TARGET)
	
	$(BUILD_WORK)/ipatool/.build/release/ipatool --generate-completion-script zsh > $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_ipatool
 	$(BUILD_WORK)/ipatool/.build/release/ipatool --generate-completion-script bash > $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/ipatool
 	$(BUILD_WORK)/ipatool/.build/release/ipatool --generate-completion-script fish > $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d/ipatool.fish
	cp $(BUILD_WORK)/ipatool/.build/release/ipatool $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
		
	$(call AFTER_BUILD)
endif

ipatool-package: ipatool-stage
	# ipatool.mk Package Structure
	rm -rf $(BUILD_DIST)/ipatool

	# ipatool.mk Prep ipatool
	cp -a $(BUILD_STAGE)/ipatool $(BUILD_DIST)

	# ipatool.mk Sign
	$(call SIGN,ipatool,general.xml)

	# ipatool.mk Make .debs
	$(call PACK,ipatool,DEB_IPATOOL_V)

	# ipatool.mk Build cleanup
	rm -rf $(BUILD_DIST)/ipatool

.PHONY: ipatool ipatool-package
