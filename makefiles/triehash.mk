ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += triehash
TRIEHASH_VERSION := 0.3
DEB_TRIEHASH_V   ?= $(TRIEHASH_VERSION)

triehash-setup: setup
	$(call GITHUB_ARCHIVE,julian-klode,triehash,$(TRIEHASH_VERSION),v$(TRIEHASH_VERSION))
	$(call EXTRACT_TAR,triehash-$(TRIEHASH_VERSION).tar.gz,triehash-$(TRIEHASH_VERSION),triehash)

ifneq ($(wildcard $(BUILD_WORK)/triehash/.build_complete),)
triehash:
	@echo "Using previously built triehash."
else
triehash: triehash-setup
	$(SED) -i 's|/usr/bin|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin|' $(BUILD_WORK)/triehash/triehash.pl
	$(GINSTALL) -Dm775 $(BUILD_WORK)/triehash/triehash.pl \
		$(BUILD_STAGE)/triehash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/triehash
	touch $(BUILD_WORK)/triehash/.build_complete
endif

triehash-package: triehash-stage
	# triehash.mk Package Structure
	rm -rf $(BUILD_DIST)/triehash

	# triehash.mk Prep triehash
	cp -a $(BUILD_STAGE)/triehash $(BUILD_DIST)

	# triehash.mk Make .debs
	$(call PACK,triehash,DEB_TRIEHASH_V)

	# triehash.mk Build cleanup
	rm -rf $(BUILD_DIST)/triehash

.PHONY: triehash triehash-package
