ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += yq
YQ_VERSION  := 4.13.0
DEB_YQ_V    ?= $(YQ_VERSION)

yq-setup: setup
	$(call GITHUB_ARCHIVE,mikefarah,yq,$(YQ_VERSION),v$(YQ_VERSION))
	$(call EXTRACT_TAR,yq-$(YQ_VERSION).tar.gz,yq-$(YQ_VERSION),yq)

ifneq ($(wildcard $(BUILD_WORK)/yq/.build_complete),)
yq:
	@echo "Using previously built yq."
else
yq: yq-setup
	cd $(BUILD_WORK)/yq && $(DEFAULT_GOLANG_FLAGS) go build
	$(INSTALL) -Dm755 $(BUILD_WORK)/yq/yq $(BUILD_STAGE)/yq/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/yq
	$(call AFTER_BUILD)
endif

yq-package: yq-stage
	# yq.mk Package Structure
	rm -rf $(BUILD_DIST)/yq
	
	# yq.mk Prep yq
	cp -a $(BUILD_STAGE)/yq $(BUILD_DIST)
	
	# yq.mk Sign
	$(call SIGN,yq,general.xml)
	
	# yq.mk Make .debs
	$(call PACK,yq,DEB_YQ_V)
	
	# yq.mk Build cleanup
	rm -rf $(BUILD_DIST)/yq

.PHONY: yq yq-package
