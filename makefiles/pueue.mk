ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pueue
PUEUE_VERSION := 2.1.0
DEB_PUEUE_V   ?= $(PUEUE_VERSION)

pueue-setup: setup
	$(call GITHUB_ARCHIVE,Nukesor,pueue,$(PUEUE_VERSION),v$(PUEUE_VERSION))
	$(call EXTRACT_TAR,pueue-$(PUEUE_VERSION).tar.gz,pueue-$(PUEUE_VERSION),pueue)
	mkdir -p $(BUILD_STAGE)/pueue/{$(MEMO_PREFIX)/Library/LaunchDaemons,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec}}

ifneq ($(wildcard $(BUILD_WORK)/pueue/.build_complete),)
pueue:
	@echo "Using previously built pueue."
else
pueue: pueue-setup
	# Compile pueue and binaries to designated places
	cd $(BUILD_WORK)/pueue && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/pueue/target/$(RUST_TARGET)/release/pueue{,d} \
		$(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	# Setup necessary daemon requirements for pueued
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < \
		$(BUILD_MISC)/pueue/pueued-wrapper > $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/pueued-wrapper
	chmod +x $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/pueued-wrapper
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < \
		$(BUILD_MISC)/pueue/com.nukesor.pueued.plist > $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)/Library/LaunchDaemons/com.nukesor.pueued.plist
	$(call AFTER_BUILD)
endif

pueue-package: pueue-stage
	# pueue.mk Package Structure
	rm -rf $(BUILD_DIST)/pueue
	cp -a $(BUILD_STAGE)/pueue $(BUILD_DIST)

	# pueue.mk Sign
	$(call SIGN,pueue,general.xml)

	# pueue.mk Make .debs
	$(call PACK,pueue,DEB_PUEUE_V)

	# pueue.mk Build cleanup
	rm -rf $(BUILD_DIST)/pueue

.PHONY: pueue pueue-package
