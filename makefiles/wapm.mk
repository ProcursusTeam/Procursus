ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += wapm
WAPM_VERSION := 0.5.1
DEB_WAPM_V   ?= $(WAPM_VERSION)

wapm-setup: setup
	$(call GITHUB_ARCHIVE,wasmerio,wapm-cli,$(WAPM_VERSION),v$(WAPM_VERSION))
	$(call EXTRACT_TAR,wapm-cli-$(WAPM_VERSION).tar.gz,wapm-cli-$(WAPM_VERSION),wapm)

ifneq ($(wildcard $(BUILD_WORK)/wapm/.build_complete),)
wapm:
	@echo "Using previously built wapm."
else
wapm: wapm-setup
	cd $(BUILD_WORK)/wapm && unset CFLAGS && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/wapm/target/$(RUST_TARGET)/release/wapm $(BUILD_STAGE)/wapm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/wapm
	touch $(BUILD_WORK)/wapm/.build_complete
endif

wapm-package: wapm-stage
	# wapm.mk Package Structure
	rm -rf $(BUILD_DIST)/wapm

	# wapm.mk Prep wapm
	cp -a $(BUILD_STAGE)/wapm $(BUILD_DIST)

	# wapm.mk Sign
	$(call SIGN,wapm,general.xml)

	# wapm.mk Make .debs
	$(call PACK,wapm,DEB_WAPM_V)

	# wapm.mk Build cleanup
	rm -rf $(BUILD_DIST)/wapm

.PHONY: wapm wapm-package
