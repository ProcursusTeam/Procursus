ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += term-fireworks
TERM-FIREWORKS_VERSION := 1.0.4
DEB_TERM-FIREWORKS_V   ?= $(TERM-FIREWORKS_VERSION)

term-fireworks-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gitlab.com/DarrienG/term-fireworks/-/archive/v$(TERM-FIREWORKS_VERSION)/term-fireworks-v$(TERM-FIREWORKS_VERSION).tar.bz2
	$(call EXTRACT_TAR,term-fireworks-v$(TERM-FIREWORKS_VERSION).tar.bz2,term-fireworks-v$(TERM-FIREWORKS_VERSION),term-fireworks)
	$(call DO_PATCH,term-fireworks,term-fireworks,-p1)

ifneq ($(wildcard $(BUILD_WORK)/term-fireworks/.build_complete),)
term-fireworks:
	@echo "Using previously built term-fireworks."
else
term-fireworks: term-fireworks-setup
	cd $(BUILD_WORK)/term-fireworks && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm775 $(BUILD_WORK)/term-fireworks/target/$(RUST_TARGET)/release/fireworks \
		$(BUILD_STAGE)/term-fireworks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fireworks
	touch $(BUILD_WORK)/term-fireworks/.build_complete
endif

term-fireworks-package: term-fireworks-stage
	# term-fireworks.mk Package Structure
	rm -rf $(BUILD_DIST)/term-fireworks

	# term-fireworks.mk Prep term-fireworks
	cp -a $(BUILD_STAGE)/term-fireworks $(BUILD_DIST)

	# term-fireworks.mk Sign
	$(call SIGN,term-fireworks,general.xml)

	# term-fireworks.mk Make .debs
	$(call PACK,term-fireworks,DEB_TERM-FIREWORKS_V)

	# term-fireworks.mk Build cleanup
	rm -rf $(BUILD_DIST)/term-fireworks

.PHONY: term-fireworks term-fireworks-package
