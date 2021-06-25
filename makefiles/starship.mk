ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += starship
STARSHIP_VERSION := 0.53.0
DEB_STARSHIP_V   ?= $(STARSHIP_VERSION)

starship-setup: setup
	$(call GITHUB_ARCHIVE,starship,starship,$(STARSHIP_VERSION),v$(STARSHIP_VERSION))
	$(call EXTRACT_TAR,starship-$(STARSHIP_VERSION).tar.gz,starship-$(STARSHIP_VERSION),starship)
	# remove this when the following upstream PRs are merged:
	#  https://github.com/FillZpp/sys-info-rs/pull/88
	$(call DO_PATCH,starship,starship,-p1)

ifneq ($(wildcard $(BUILD_WORK)/starship/.build_complete),)
starship:
	@echo "Using previously built starship."
else
starship: starship-setup
	cd $(BUILD_WORK)/starship && unset CFLAGS && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/starship/target/$(RUST_TARGET)/release/starship $(BUILD_STAGE)/starship/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/starship
	touch $(BUILD_WORK)/starship/.build_complete
endif

starship-package: starship-stage
	# starship.mk Package Structure
	rm -rf $(BUILD_DIST)/starship

	# starship.mk Prep starship
	cp -a $(BUILD_STAGE)/starship $(BUILD_DIST)

	# starship.mk Sign
	$(call SIGN,starship,general.xml)

	# starship.mk Make .debs
	$(call PACK,starship,DEB_STARSHIP_V)

	# starship.mk Build cleanup
	rm -rf $(BUILD_DIST)/starship

.PHONY: starship starship-package
