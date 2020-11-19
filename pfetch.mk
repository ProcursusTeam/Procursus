ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pfetch
PFETCH_VERSION := 0.6.0
DEB_PFETCH_V   ?= $(PFETCH_VERSION)

pfetch-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/dylanaraps/pfetch/archive/$(PFETCH_VERSION).tar.gz
	$(call EXTRACT_TAR,$(PFETCH_VERSION).tar.gz,pfetch-$(PFETCH_VERSION),pfetch)

ifneq ($(wildcard $(BUILD_WORK)/pfetch/.build_complete),)
pfetch:
	@echo "Using previously built pfetch."
else
pfetch: pfetch-setup 
	mkdir -p $(BUILD_STAGE)/pfetch/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp $(BUILD_WORK)/pfetch/pfetch $(BUILD_STAGE)/pfetch/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	touch $(BUILD_WORK)/pfetch/.build_complete
endif

pfetch-package: pfetch-stage
	# pfetch.mk Package Structure
	rm -rf $(BUILD_DIST)/pfetch
	mkdir -p $(BUILD_DIST)/pfetch
	
	# pfetch.mk Prep pfetch
	cp -a $(BUILD_STAGE)/pfetch $(BUILD_DIST)
	
	# pfetch.mk Sign
	$(call SIGN,pfetch,general.xml)
	
	# pfetch.mk Make .debs
	$(call PACK,pfetch,DEB_PFETCH_V)
	
	# pfetch.mk Build cleanup
	rm -rf $(BUILD_DIST)/pfetch

.PHONY: pfetch pfetch-package
