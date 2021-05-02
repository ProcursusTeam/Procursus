ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += ye
YE_VERSION  := 1.0
DEB_YE_V    ?= $(YE_VERSION)

ye-setup: setup
	$(call GITHUB_ARCHIVE,BBaoVanC,ye,$(YE_VERSION),v$(YE_VERSION))
	$(call EXTRACT_TAR,ye-$(YE_VERSION).tar.gz,ye-$(YE_VERSION),ye)

ifneq ($(wildcard $(BUILD_WORK)/ye/.build_complete),)
ye:
	@echo "Using previously built ye."
else
ye: ye-setup
	cd $(BUILD_WORK)/ye
	+$(MAKE) -C $(BUILD_WORK)/ye
	+$(MAKE) -C $(BUILD_WORK)/ye install \
		PREFIX=$(BUILD_STAGE)/ye/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/ye/.build_complete
endif

ye-package: ye-stage
	# ye.mk Package Structure
	rm -rf $(BUILD_DIST)/ye

	# ye.mk Prep ye
	cp -a $(BUILD_STAGE)/ye $(BUILD_DIST)

	# ye.mk Sign
	$(call SIGN,ye,general.xml)

	# ye.mk Make .debs
	$(call PACK,ye,DEB_YE_V)

	# ye.mk Build cleanup
	rm -rf $(BUILD_DIST)/ye

.PHONY: ye ye-package
