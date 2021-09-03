ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
SUBPROJECTS        += uikittools
else
STRAPPROJECTS      += uikittools
endif
UIKITTOOLS_VERSION := 2.0.6
DEB_UIKITTOOLS_V   ?= $(UIKITTOOLS_VERSION)

uikittools-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,uikittools-ng,$(UIKITTOOLS_VERSION),v$(UIKITTOOLS_VERSION))
	$(call EXTRACT_TAR,uikittools-ng-$(UIKITTOOLS_VERSION).tar.gz,uikittools-ng-$(UIKITTOOLS_VERSION),uikittools)

ifneq ($(wildcard $(BUILD_WORK)/uikittools/.build_complete),)
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: uikittools-setup
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	+$(MAKE) -C $(BUILD_WORK)/uikittools \
		deviceinfo
else
	+$(MAKE) -C $(BUILD_WORK)/uikittools \
		deviceinfo gssc ldrestart sbdidlaunch sbreload uiopen uicache \
		APP_PATH="$(MEMO_PREFIX)/Applications"
endif
	mkdir -p $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	for bin in $$(find $(BUILD_WORK)/uikittools -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
		if [ -f $$bin ] && [ -x $$bin ]; then \
			cp $$bin $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin ; \
			cp $$bin.1 $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 ; \
		fi \
	done
	ln -s deviceinfo $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cfversion
	ln -s deviceinfo $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ecidecid
	ln -s deviceinfo $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uiduid
	$(call AFTER_BUILD)
endif

uikittools-package: uikittools-stage
	# uikittools.mk Package Structure
	rm -rf $(BUILD_DIST)/uikittools

	# uikittools.mk Prep uikittools
	cp -a $(BUILD_STAGE)/uikittools $(BUILD_DIST)

	# uikittools.mk Sign
	$(call SIGN,uikittools,general.xml)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	ldid $(MEMO_LDID_EXTRA_FLAGS) -S$(BUILD_MISC)/entitlements/uiopen.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uiopen
	ldid $(MEMO_LDID_EXTRA_FLAGS) -S$(BUILD_MISC)/entitlements/uicache.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uicache
	ldid $(MEMO_LDID_EXTRA_FLAGS) -S$(BUILD_MISC)/entitlements/sbreload.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sbreload
	ldid $(MEMO_LDID_EXTRA_FLAGS) -S$(BUILD_MISC)/entitlements/gssc.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gssc
	find $(BUILD_DIST)/uikittools -name '.ldid*' -type f -delete
endif

	# uikittools.mk Make .debs
	$(call PACK,uikittools,DEB_UIKITTOOLS_V)

	# uikittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/uikittools

.PHONY: uikittools uikittools-package
