ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += gping
GPING_VERSION  := 1.2.6
DEB_GPING_V    ?= $(GPING_VERSION)

gping-setup: setup
	$(call GITHUB_ARCHIVE,orf,gping,$(GPING_VERSION),gping-v$(GPING_VERSION))
	$(call EXTRACT_TAR,gping-$(GPING_VERSION).tar.gz,gping-gping-v$(GPING_VERSION),gping)

ifneq ($(wildcard $(BUILD_WORK)/gping/.build_complete),)
gping:
	@echo "Using previously built gping."
else
gping: gping-setup
	cd $(BUILD_WORK)/gping && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--all-features \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/gping/target/$(RUST_TARGET)/release/gping $(BUILD_STAGE)/gping/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gping
	$(call AFTER_BUILD)
endif

gping-package: gping-stage
	# gping.mk Package Structure
	rm -rf $(BUILD_DIST)/gping

	# gping.mk Prep gping
	cp -a $(BUILD_STAGE)/gping $(BUILD_DIST)

	# gping.mk Sign
	$(call SIGN,gping,general.xml)

	# gping.mk Make .debs
	$(call PACK,gping,DEB_GPING_V)

	# gping.mk Build cleanup
	rm -rf $(BUILD_DIST)/gping

.PHONY: gping gping-package
