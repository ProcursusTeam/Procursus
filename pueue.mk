ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pueue
PUEUE_VERSION := 1.0.0-rc.1
DEB_PUEUE_V   ?= $(PUEUE_VERSION)

pueue-setup: setup
	$(call GITHUB_ARCHIVE,Nukesor,pueue,$(PUEUE_VERSION),v$(PUEUE_VERSION))
	$(call EXTRACT_TAR,pueue-$(PUEUE_VERSION).tar.gz,pueue-$(PUEUE_VERSION),pueue)

ifneq ($(wildcard $(BUILD_WORK)/pueue/.build_complete),)
pueue:
	@echo "Using previously built pueue."
else
pueue: pueue-setup
	cd $(BUILD_WORK)/pueue && SDKROOT="$(TARGET_SYSROOT)" \
	PKG_CONFIG="$(RUST_TARGET)-pkg-config" cargo build \
		--release \
		--target=$(RUST_TARGET)
	# Move pueue and pueued binaries to designated places
	$(GINSTALL) -Dm755 $(BUILD_WORK)/pueue/target/$(RUST_TARGET)/release/pueue \
		$(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pueue
	$(GINSTALL) -Dm755 $(BUILD_WORK)/pueue/target/$(RUST_TARGET)/release/pueued \
		$(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pueued
	# Setup necessary daemon requirements for pueued
	mkdir -p $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_MISC)/pueue/com.nukesor.pueued.plist \
		$(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Library/LaunchDaemons
	# "Patch" up LaunchDaemon plist for pueued
	for file in $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Library/LaunchDaemons/*; do \
		$(SED) -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $$file; \
		$(SED) -i 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $$file; \
	done
	touch $(BUILD_WORK)/pueue/.build_complete
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
