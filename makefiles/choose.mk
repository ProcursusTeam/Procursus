ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += choose
CHOOSE_VERSION  := 1.3.3
DEB_CHOOSE_V    ?= $(CHOOSE_VERSION)

choose-setup: setup
	$(call GITHUB_ARCHIVE,theryangeary,choose,$(CHOOSE_VERSION),v$(CHOOSE_VERSION))
	$(call EXTRACT_TAR,choose-$(CHOOSE_VERSION).tar.gz,choose-$(CHOOSE_VERSION),choose)

ifneq ($(wildcard $(BUILD_WORK)/choose/.build_complete),)
choose:
	@echo "Using previously built choose."
else
choose: choose-setup
	cd $(BUILD_WORK)/choose && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--all-features \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/choose/target/$(RUST_TARGET)/release/choose $(BUILD_STAGE)/choose/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/choose
	$(call AFTER_BUILD)
endif

choose-package: choose-stage
	# choose.mk Package Structure
	rm -rf $(BUILD_DIST)/choose

	# choose.mk Prep choose
	cp -a $(BUILD_STAGE)/choose $(BUILD_DIST)

	# choose.mk Sign
	$(call SIGN,choose,general.xml)

	# choose.mk Make .debs
	$(call PACK,choose,DEB_CHOOSE_V)

	# choose.mk Build cleanup
	rm -rf $(BUILD_DIST)/choose

.PHONY: choose choose-package
