ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pfetch
PFETCH_VERSION := 0.7.0
DEB_PFETCH_V   ?= $(PFETCH_VERSION)

pfetch-setup: setup
	rm -rf $(BUILD_WORK)/pfetch
	mkdir -p $(BUILD_WORK)/pfetch
	cp -af pfetch/* $(BUILD_WORK)/pfetch

ifneq ($(wildcard $(BUILD_WORK)/pfetch/.build_complete),)
pfetch:
	@echo "Using previously built pfetch."
else
pfetch: pfetch-setup 
	+$(MAKE) -C $(BUILD_WORK)/pfetch install \
		DESTDIR=$(BUILD_STAGE)/pfetch \
		PREFIX=/usr
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
