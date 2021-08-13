ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
SUBPROJECTS        += uikittools
else
STRAPPROJECTS      += uikittools
endif
UIKITTOOLS_VERSION := 2.0.4
DEB_UIKITTOOLS_V   ?= $(UIKITTOOLS_VERSION)

uikittools-setup: setup
	$(call GITHUB_ARCHIVE,Diatrus,uikittools-ng,$(UIKITTOOLS_VERSION),v$(UIKITTOOLS_VERSION))
	$(call EXTRACT_TAR,uikittools-ng-$(UIKITTOOLS_VERSION).tar.gz,uikittools-ng-$(UIKITTOOLS_VERSION),uikittools)

ifneq ($(wildcard $(BUILD_WORK)/uikittools/.build_complete),)
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: uikittools-setup
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	+$(MAKE) -C $(BUILD_WORK)/uikittools \
		cfversion ecidecid uiduid
else
	+$(MAKE) -C $(BUILD_WORK)/uikittools \
		cfversion ecidecid gssc ldrestart sbdidlaunch sbreload uicache uiduid uiopen
endif
	mkdir -p $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for bin in $$(find $(BUILD_WORK)/uikittools -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
		if [ -f $$bin ] && [ -x $$bin ]; then \
			cp $$bin $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin ; \
		fi \
	done
	$(call AFTER_BUILD)
endif

uikittools-package: uikittools-stage
	# uikittools.mk Package Structure
	rm -rf $(BUILD_DIST)/uikittools

	# uikittools.mk Prep uikittools
	cp -a $(BUILD_STAGE)/uikittools $(BUILD_DIST)

	# uikittools.mk Make .debs
	$(call PACK,uikittools,DEB_UIKITTOOLS_V)

	# uikittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/uikittools

.PHONY: uikittools uikittools-package
