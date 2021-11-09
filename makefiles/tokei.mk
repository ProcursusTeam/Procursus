ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += tokei
TOKEI_VERSION  := 12.1.2
DEB_TOKEI_V    ?= $(TOKEI_VERSION)

tokei-setup: setup
	$(call GITHUB_ARCHIVE,XAMPPRocky,tokei,$(TOKEI_VERSION),v$(TOKEI_VERSION))
	$(call EXTRACT_TAR,tokei-v$(TOKEI_VERSION).tar.gz,tokei-$(TOKEI_VERSION),tokei)

ifneq ($(wildcard $(BUILD_WORK)/tokei/.build_complete),)
tokei:
	@echo "Using previously built tokei."
else
tokei: tokei-setup
	cd $(BUILD_WORK)/tokei && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--all-features \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/tokei/target/$(RUST_TARGET)/release/tokei $(BUILD_STAGE)/tokei/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tokei
	$(call AFTER_BUILD)
endif

tokei-package: tokei-stage
	# tokei.mk Package Structure
	rm -rf $(BUILD_DIST)/tokei

	# tokei.mk Prep tokei
	cp -a $(BUILD_STAGE)/tokei $(BUILD_DIST)

	# tokei.mk Sign
	$(call SIGN,tokei,general.xml)

	# tokei.mk Make .debs
	$(call PACK,tokei,DEB_TOKEI_V)

	# tokei.mk Build cleanup
	rm -rf $(BUILD_DIST)/tokei

.PHONY: tokei tokei-package
