ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += pup
PUP_COMMIT  := 681d7bb639334bf485476f5872c5bdab10931f9a
PUP_VERSION := 0.4.0+git20190919.$(shell echo $(PUP_COMMIT) | cut -c -7)
DEB_PUP_V   ?= $(PUP_VERSION)

pup-setup: setup
	$(call GITHUB_ARCHIVE,ericchiang,pup,$(PUP_COMMIT),$(PUP_COMMIT))
	$(call EXTRACT_TAR,pup-$(PUP_COMMIT).tar.gz,pup-$(PUP_COMMIT),pup)
	mkdir -p $(BUILD_STAGE)/pup/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/pup/.build_complete),)
pup:
	@echo "Using previously built pup."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
pup: pup-setup
else
pup: pup-setup libiosexec
endif
	cd $(BUILD_WORK)/pup && go get -d -v .
	cd $(BUILD_WORK)/pup && \
		$(DEFAULT_GOLANG_FLAGS) \
		go build
	cp -a $(BUILD_WORK)/pup/pup $(BUILD_STAGE)/pup/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/pup/.build_complete
endif

pup-package: pup-stage
	# pup.mk Package Structure
	rm -rf $(BUILD_DIST)/pup
	
	# pup.mk Prep pup
	cp -a $(BUILD_STAGE)/pup $(BUILD_DIST)
	
	# pup.mk Sign
	$(call SIGN,pup,general.xml)
	
	# pup.mk Make .debs
	$(call PACK,pup,DEB_PUP_V)
	
	# pup.mk Build cleanup
	rm -rf $(BUILD_DIST)/pup

.PHONY: pup pup-package
