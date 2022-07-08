ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS   += oslog
OSLOG_VERSION := 0.0.1
DEB_OSLOG_V   ?= $(OSLOG_VERSION)

oslog-setup: setup
	$(call GITHUB_ARCHIVE,dlevi309,oslog,$(OSLOG_VERSION),v$(OSLOG_VERSION))
	$(call EXTRACT_TAR,oslog-$(OSLOG_VERSION).tar.gz,oslog-$(OSLOG_VERSION),oslog)
	sed -i '1s|^|#import <Foundation/Foundation.h>\n|' $(BUILD_WORK)/oslog/main.mm

ifneq ($(wildcard $(BUILD_WORK)/oslog/.build_complete),)
oslog:
	@echo "Using previously built oslog."
else
oslog: oslog-setup
	mv $(BUILD_WORK)/oslog/README.md $(BUILD_WORK)/oslog/README
	mv $(BUILD_WORK)/oslog/LICENSE.txt $(BUILD_WORK)/oslog/LICENSE
	mkdir -p $(BUILD_STAGE)/oslog/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(CXX) $(CXXFLAGS) -fobjc-arc $(BUILD_WORK)/oslog/main.mm -o $(BUILD_STAGE)/oslog/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/oslog -framework Foundation
	$(call AFTER_BUILD)
endif

oslog-package: oslog-stage
	# oslog.mk Package Structure
	rm -rf $(BUILD_DIST)/oslog

	# oslog.mk Prep oslog
	cp -a $(BUILD_STAGE)/oslog $(BUILD_DIST)

	# oslog.mk Sign
	$(call SIGN,oslog,oslog.xml)

	# oslog.mk Make .debs
	$(call PACK,oslog,DEB_OSLOG_V)

	# oslog.mk Build cleanup
	rm -rf $(BUILD_DIST)/oslog

.PHONY: oslog oslog-package

endif
