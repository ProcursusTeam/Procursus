ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS        += logcleaner
LOGCLEANER_VERSION := 1.0.0
DEB_LOGCLEANER_V   ?= $(LOGCLEANER_VERSION)

logcleaner-setup: setup
	mkdir -p $(BUILD_STAGE)/logcleaner/$(MEMO_PREFIX)/Library/LaunchDaemons

ifneq ($(wildcard $(BUILD_WORK)/logcleaner/.build_complete),)
logcleaner:
	@echo "Using previously built logcleaner."
else
logcleaner: logcleaner-setup
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/moe.absolucy.logcleaner.plist > $(BUILD_STAGE)/logcleaner/$(MEMO_PREFIX)/Library/LaunchDaemons/moe.absolucy.logcleaner.plist
	mkdir -p $(BUILD_WORK)/logcleaner
	$(call AFTER_BUILD)
endif

logcleaner-package: logcleaner-stage
	# logcleaner.mk Package Structure
	rm -rf $(BUILD_DIST)/logcleaner

	# logcleaner.mk Prep logcleaner
	cp -a $(BUILD_STAGE)/logcleaner $(BUILD_DIST)

	# logcleaner.mk Make .debs
	$(call PACK,logcleaner,DEB_LOGCLEANER_V)

	# logcleaner.mk Build cleanup
	rm -rf $(BUILD_DIST)/logcleaner

.PHONY: logcleaner logcleaner-package

endif
