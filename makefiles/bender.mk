ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS      += bender
BENDER_VERSION   := 1.1.1
DEB_BENDER_V     ?= $(BENDER_VERSION)

bender-setup: setup
	$(call GITHUB_ARCHIVE,aspenluxxxy,bender,$(BENDER_VERSION),v$(BENDER_VERSION))
	$(call EXTRACT_TAR,bender-$(BENDER_VERSION).tar.gz,bender-$(BENDER_VERSION),bender)

ifneq ($(wildcard $(BUILD_WORK)/bender/.build_complete),)
bender:
	@echo "Using previously built bender."
else
bender: bender-setup
	cd $(BUILD_WORK)/bender && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/bender/target/$(RUST_TARGET)/release/bender $(BUILD_STAGE)/bender/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/bender
	touch $(BUILD_WORK)/bender/.build_complete
endif

bender-package: bender-stage
	# bender.mk Package Structure
	rm -rf $(BUILD_DIST)/bender

	# bender.mk Prep bender
	cp -a $(BUILD_STAGE)/bender $(BUILD_DIST)

	# bender.mk Sign
	$(call SIGN,bender,general.xml)

	# bender.mk Make .debs
	$(call PACK,bender,DEB_BENDER_V)

	# bender.mk Build cleanup
	rm -rf $(BUILD_DIST)/bender

.PHONY: bender bender-package

endif
