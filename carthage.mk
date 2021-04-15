ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS      += carthage
CARTHAGE_VERSION   := 0.37.0
DEB_CARTHAGE_V     ?= $(CARTHAGE_VERSION)

carthage-setup: setup
	wget -q -O $(BUILD_SOURCE)/Carthage-$(CARTHAGE_VERSION).tar.gz https://github.com/Carthage/Carthage/archive/$(CARTHAGE_VERSION).tar.gz
	$(call EXTRACT_TAR,carthage-$(CARTHAGE_VERSION).tar.gz,carthage-$(CARTHAGE_VERSION),carthage)

ifneq ($(wildcard $(BUILD_WORK)/carthage/.build_complete),)
carthage:
	@echo "Using previously built carthage."
else
carthage: carthage-setup
	mkdir -p $(BUILD_STAGE)/carthage/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	TARGET=$(if $(findstring amd64,$(MEMO_TARGET)),x86_64,arm64) && cd $(BUILD_WORK)/carthage && swift build --arch $$TARGET -c release
	$(CP) $(BUILD_WORK)/carthage/.build/release/carthage $(BUILD_STAGE)/carthage/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	touch $(BUILD_WORK)/carthage/.build_complete
endif

carthage-package: carthage-stage
	# carthage.mk Package Structure
	rm -rf $(BUILD_DIST)/carthage

	# carthage.mk Prep carthage
	cp -a $(BUILD_STAGE)/carthage $(BUILD_DIST)

	# carthage.mk Sign
	$(call SIGN,carthage,general.xml)

	# carthage.mk Make .debs
	$(call PACK,carthage,DEB_CARTHAGE_V)

	# carthage.mk Build cleanup
	rm -rf $(BUILD_DIST)/carthage

.PHONY: carthage carthage-package

endif
