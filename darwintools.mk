ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += darwintools
DARWINTOOLS_VERSION := 1.2
DEB_DARWINTOOLS_V   ?= $(DARWINTOOLS_VERSION)

darwintools-setup: setup
	rm -rf $(BUILD_WORK)/darwintools
	mkdir -p $(BUILD_WORK)/darwintools
	cp -af darwintools/* $(BUILD_WORK)/darwintools

ifneq ($(wildcard $(BUILD_WORK)/darwintools/.build_complete),)
darwintools:
	@echo "Using previously built darwintools."
else
darwintools: darwintools-setup
	cd $(BUILD_WORK)/darwintools && make
	mkdir -p $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec}
	cp $(BUILD_WORK)/darwintools/sw_vers $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp $(BUILD_WORK)/darwintools/firmware $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cd $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec && ln -sf firmware firmware.sh 
	chmod 0755 $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/firmware
	touch $(BUILD_WORK)/darwintools/.build_complete
endif

darwintools-package: darwintools-stage
	# darwintools.mk Package Structure
	rm -rf $(BUILD_DIST)/darwintools
	mkdir -p $(BUILD_DIST)/darwintools
	
	# darwintools.mk Prep darwintools
	cp -a $(BUILD_STAGE)/darwintools $(BUILD_DIST)
	
	# darwintools.mk Sign
	$(call SIGN,darwintools,general.xml)
	
	# darwintools.mk Make .debs
	$(call PACK,darwintools,DEB_DARWINTOOLS_V)
	
	# darwintools.mk Build cleanup
	rm -rf $(BUILD_DIST)/darwintools

.PHONY: darwintools darwintools-package
