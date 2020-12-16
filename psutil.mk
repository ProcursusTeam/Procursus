ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += psutil
PSUTIL_VERSION := 5.7.3
DEB_PSUTIL_V   ?= $(PSUTIL_VERSION)

psutil-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/psutil-$(PSUTIL_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/psutil-$(PSUTIL_VERSION).tar.gz \
		https://github.com/giampaolo/psutil/archive/release-$(PSUTIL_VERSION).tar.gz
	$(call EXTRACT_TAR,psutil-$(PSUTIL_VERSION).tar.gz,psutil-release-$(PSUTIL_VERSION),psutil)

ifneq ($(wildcard $(BUILD_WORK)/psutil/.build_complete),)
psutil:
	@echo "Using previously built psutil."
else
psutil: psutil-setup python3 readline
	cd $(BUILD_WORK)/psutil && python3 ./setup.py install --install-layout=deb --root $(BUILD_STAGE)/psutil

	touch $(BUILD_WORK)/psutil/.build_complete 
endif

psutil-package: psutil-stage
	# psutil.mk Package Structure
	rm -rf $(BUILD_DIST)/psutil
	mkdir -p $(BUILD_DIST)/psutil
	
	# psutil.mk Prep psutil
	cp -a $(BUILD_STAGE)/psutil/usr $(BUILD_DIST)/psutil
	 
	 # psutil.mk Sign
	$(call SIGN,psutil,general.xml)  
	 # psutil.mk Make .debs
	$(call PACK,psutil,DEB_PSUTIL_V)
	 
	 # psutil.mk Build cleanup
	 rm -rf $(BUILD_DIST)/psutil

.PHONY: psutil psutil-package
