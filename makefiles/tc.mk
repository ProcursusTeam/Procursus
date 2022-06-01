ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tc
TC_VERSION  := 1.0
DEB_TC_V    ?= $(TC_VERSION)

tc-setup: setup
	$(call GITHUB_ARCHIVE,CRKatri,tc,$(TC_VERSION),v$(TC_VERSION))
	$(call EXTRACT_TAR,tc-$(TC_VERSION).tar.gz,tc-$(TC_VERSION),tc)

ifneq ($(wildcard $(BUILD_WORK)/tc/.build_complete),)
tc:
	@echo "Using previously built tc."
else
tc: tc-setup
	+$(MAKE) -C $(BUILD_WORK)/tc install \
		PREFIX="$(BUILD_STAGE)/tc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	$(call AFTER_BUILD)
endif

tc-package: tc-stage
	# tc.mk Package Structure
	rm -rf $(BUILD_DIST)/tc

	# tc.mk Prep tc
	cp -a $(BUILD_STAGE)/tc $(BUILD_DIST)

	# tc.mk Sign
	$(call SIGN,tc,general.xml)

	# tc.mk Make .debs
	$(call PACK,tc,DEB_TC_V)

	# tc.mk Build cleanup
	rm -rf $(BUILD_DIST)/tc

.PHONY: tc tc-package
