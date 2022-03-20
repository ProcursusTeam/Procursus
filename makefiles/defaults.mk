ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS      += defaults
DEFAULTS_VERSION := 1.0.1
DEB_DEFAULTS_V   ?= $(DEFAULTS_VERSION)

defaults-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,defaults,$(DEFAULTS_VERSION),v$(DEFAULTS_VERSION))
	$(call EXTRACT_TAR,defaults-$(DEFAULTS_VERSION).tar.gz,defaults-$(DEFAULTS_VERSION),defaults)

ifneq ($(wildcard $(BUILD_WORK)/defaults/.build_complete),)
defaults:
	@echo "Using previously built defaults."
else
defaults: defaults-setup
	+$(MAKE) -C $(BUILD_WORK)/defaults
	$(INSTALL) -d $(BUILD_STAGE)/defaults/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(INSTALL) -m755 $(BUILD_WORK)/defaults/defaults $(BUILD_STAGE)/defaults/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/defaults-procursus
	$(call AFTER_BUILD)
endif

defaults-package: defaults-stage
	# defaults.mk Package Structure
	rm -rf $(BUILD_DIST)/defaults

	# defaults.mk Prep defaults
	cp -a $(BUILD_STAGE)/defaults $(BUILD_DIST)

	# defaults.mk Sign
	$(LDID) -S$(BUILD_WORK)/defaults/ent.plist $(BUILD_DIST)/defaults/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/defaults-procursus

	# defaults.mk Make .debs
	$(call PACK,defaults,DEB_DEFAULTS_V)

	# defaults.mk Build cleanup
	rm -rf $(BUILD_DIST)/defaults

.PHONY: defaults defaults-package

endif # ($(MEMO_TARGET),darwin-\*)
