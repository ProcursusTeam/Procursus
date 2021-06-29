ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pueue
PUEUE_VERSION := 1.0.0-rc.2
DEB_PUEUE_V   ?= $(PUEUE_VERSION)

pueue-setup: setup
	$(call GITHUB_ARCHIVE,Nukesor,pueue,$(PUEUE_VERSION),v$(PUEUE_VERSION))
	$(call EXTRACT_TAR,pueue-$(PUEUE_VERSION).tar.gz,pueue-$(PUEUE_VERSION),pueue)
	mkdir -p $(BUILD_STAGE)/pueue/{Library/LaunchDaemons,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,sbin,libexec}}

ifneq ($(wildcard $(BUILD_WORK)/pueue/.build_complete),)
pueue:
	@echo "Using previously built pueue."
else
pueue: pueue-setup
	# Compile pueue and binaries to designated places
	cd $(BUILD_WORK)/pueue && SDKROOT="$(TARGET_SYSROOT)" \
	PKG_CONFIG="$(RUST_TARGET)-pkg-config" cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/pueue/target/$(RUST_TARGET)/release/pueue{,d} \
		$(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	ln -s $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/pueue \
		$(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pueue
	# Setup necessary daemon requirements for pueued
	$(SED) -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < \
		$(BUILD_MISC)/pueue/pueued-wrapper > $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/pueued-wrapper
	chmod +x $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/pueued-wrapper
	$(SED) -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < \
		$(BUILD_MISC)/pueue/com.nukesor.pueued.plist > $(BUILD_STAGE)/pueue/$(MEMO_PREFIX)/Library/LaunchDaemons/com.nukesor.pueued.plist
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
